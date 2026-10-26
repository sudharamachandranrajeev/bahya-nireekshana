import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' show UserFacingError;
import 'package:http/http.dart' as http;

/// A failed speed test, worded for the user.
class SpeedTestException implements Exception, UserFacingError {
  SpeedTestException(this.message);
  @override
  final String message;
  @override
  String toString() => message;
}

/// Where a running test is.
enum SpeedPhase { latency, download, upload, done }

class SpeedProgress {
  const SpeedProgress(this.phase, {this.bitsPerSecond = 0, this.latency = 0, this.share = 0});
  final SpeedPhase phase;

  /// The speed measured so far in this phase.
  final double bitsPerSecond;
  final double latency;

  /// 0 to 1 through the whole test.
  final double share;
}

class SpeedResult {
  const SpeedResult({
    required this.down,
    required this.up,
    required this.latency,
    required this.jitter,
    required this.server,
  });

  /// Bits per second.
  final int down;
  final int up;

  /// Milliseconds.
  final double latency;
  final double jitter;
  final String server;
}

/// The middle value; 0 for none.
double median(List<double> values) {
  if (values.isEmpty) return 0;
  final s = [...values]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

/// The mean step between consecutive round trips.
double jitterOf(List<double> values) {
  if (values.length < 2) return 0;
  var sum = 0.0;
  for (var i = 1; i < values.length; i++) {
    sum += (values[i] - values[i - 1]).abs();
  }
  return sum / (values.length - 1);
}

/// The speed a test reports from its transfers: the 90th percentile, so one
/// slow start does not drag it down and one lucky burst does not lift it.
double reportedSpeed(List<double> bitsPerSecond) {
  if (bitsPerSecond.isEmpty) return 0;
  final s = [...bitsPerSecond]..sort();
  return s[math.min(s.length - 1, (s.length * 0.9).floor())];
}

/// A speed test against Cloudflare's public speed test service
/// (speed.cloudflare.com), the one its own web page uses. Nothing is sent
/// but the test data; the result stays on the device (and the user's synced
/// devices).
class SpeedTester {
  SpeedTester(this._http, {this.base = 'https://speed.cloudflare.com'});
  final http.Client _http;
  final String base;

  static const _agent = {'user-agent': 'BahyaNireekshana'};

  /// Download and upload sizes, smallest first; each phase stops once it
  /// has run [phaseLimit].
  static const downloads = [100000, 1000000, 10000000, 25000000, 50000000];
  static const uploads = [100000, 1000000, 5000000, 10000000];
  static const phaseLimit = Duration(seconds: 10);

  Future<SpeedResult> run({void Function(SpeedProgress p)? onProgress}) async {
    try {
      final server = await _server();
      // Latency: tiny requests, each timed from send to first byte.
      final trips = <double>[];
      for (var i = 0; i < 12; i++) {
        final watch = Stopwatch()..start();
        final r = await _http
            .get(Uri.parse('$base/__down?bytes=0'), headers: _agent)
            .timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) throw SpeedTestException('The speed test server answered ${r.statusCode}.');
        trips.add(watch.elapsedMicroseconds / 1000);
        onProgress?.call(
          SpeedProgress(SpeedPhase.latency, latency: median(trips), share: 0.1 * (i + 1) / 12),
        );
      }
      // The first request includes setting up the connection.
      final steady = trips.length > 2 ? trips.sublist(1) : trips;

      final down = <double>[];
      final downWatch = Stopwatch()..start();
      for (final size in downloads) {
        down.add(await _download(size));
        onProgress?.call(
          SpeedProgress(
            SpeedPhase.download,
            bitsPerSecond: reportedSpeed(down),
            share: 0.1 + 0.5 * math.min(1, downWatch.elapsed.inMilliseconds / phaseLimit.inMilliseconds),
          ),
        );
        if (downWatch.elapsed > phaseLimit) break;
      }

      final up = <double>[];
      final upWatch = Stopwatch()..start();
      final random = math.Random();
      for (final size in uploads) {
        up.add(await _upload(size, random));
        onProgress?.call(
          SpeedProgress(
            SpeedPhase.upload,
            bitsPerSecond: reportedSpeed(up),
            share: 0.6 + 0.4 * math.min(1, upWatch.elapsed.inMilliseconds / phaseLimit.inMilliseconds),
          ),
        );
        if (upWatch.elapsed > phaseLimit) break;
      }
      final result = SpeedResult(
        down: reportedSpeed(down).round(),
        up: reportedSpeed(up).round(),
        latency: median(steady),
        jitter: jitterOf(steady),
        server: server,
      );
      onProgress?.call(const SpeedProgress(SpeedPhase.done, share: 1));
      return result;
    } on TimeoutException {
      throw SpeedTestException('The speed test server stopped answering.');
    } on http.ClientException catch (e) {
      throw SpeedTestException('No connection to the speed test server: ${e.message}');
    }
  }

  /// Which Cloudflare data centre answers: "LHR · London". The service also
  /// reports the caller's address; that is not kept.
  Future<String> _server() async {
    try {
      final r = await _http
          .get(Uri.parse('$base/meta'), headers: _agent)
          .timeout(const Duration(seconds: 10));
      final m = jsonDecode(r.body);
      if (m is Map) return [m['colo'], m['city']].whereType<String>().join(' · ');
    } on Object {
      // Only a label; the test goes on without it.
    }
    return 'Cloudflare';
  }

  Future<double> _download(int size) async {
    final watch = Stopwatch()..start();
    final r = await _http
        .send(http.Request('GET', Uri.parse('$base/__down?bytes=$size'))..headers.addAll(_agent))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw SpeedTestException('The speed test server answered ${r.statusCode}.');
    var got = 0;
    // Timed from the first byte, so the round trip is not counted as slowness.
    Stopwatch? flow;
    await for (final chunk in r.stream.timeout(const Duration(seconds: 15))) {
      flow ??= Stopwatch()..start();
      got += chunk.length;
    }
    final seconds = (flow ?? watch).elapsedMicroseconds / 1e6;
    return seconds <= 0 ? 0 : got * 8 / seconds;
  }

  Future<double> _upload(int size, math.Random random) async {
    final body = Uint8List(size);
    for (var i = 0; i < size; i += 4096) {
      body[i] = random.nextInt(256);
    }
    final watch = Stopwatch()..start();
    final r = await _http
        .post(
          Uri.parse('$base/__up'),
          headers: {..._agent, 'content-type': 'application/octet-stream'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw SpeedTestException('The speed test server answered ${r.statusCode}.');
    final seconds = watch.elapsedMicroseconds / 1e6;
    return seconds <= 0 ? 0 : size * 8 / seconds;
  }
}
