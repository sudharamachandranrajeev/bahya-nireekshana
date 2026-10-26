@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nireekshana/domain/app_sources.dart';
import 'package:nireekshana/domain/windows_net.dart';

/// Runs the IP Helper calls against the real Windows API, so a wrong struct
/// offset shows up as nonsense here rather than in the app. CI runs it on a
/// Windows runner; elsewhere it is skipped.
void main() {
  test('interfaces have names and counters', () {
    final list = windowsInterfaces();
    expect(list, isNotEmpty);
    for (final i in list) {
      expect(i.name, isNotEmpty);
      expect(i.rx, greaterThanOrEqualTo(0));
      expect(i.tx, greaterThanOrEqualTo(0));
    }
    // The runner downloaded the repository, so something received data.
    expect(
      list.any((i) => i.up && i.rx > 0),
      isTrue,
      reason: list.map((i) => '${i.name} ${i.rx}').join(', '),
    );
  });

  test('the boot id stays the same between calls', () {
    expect(windowsBootId(), isNotEmpty);
    expect(windowsBootId(), windowsBootId());
  });

  test('connections include a socket this process opened', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final mine = windowsConnections().where((c) => c.localPort == server.port).toList();
      expect(mine, isNotEmpty);
      expect(mine.first.pid, pid);
      expect(mine.first.program, isNotEmpty);
    } finally {
      await server.close();
    }
  });

  test('the data usage per app comes back as rows', () async {
    // A fresh runner may have little attributed usage; the call itself and
    // the JSON it prints are what is checked.
    final List<AppCount> rows;
    try {
      rows = await WindowsAppSource().read(days: 2);
    } on AppSourceException catch (e) {
      // CI runs Windows Server, which has no per-app data usage.
      if (e.message == windowsAppsMissing) {
        markTestSkipped(e.message);
        return;
      }
      rethrow;
    }
    for (final r in rows) {
      expect(r.day, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(r.app, isNotEmpty);
      expect(['wifi', 'ethernet', 'mobile'], contains(r.kind));
    }
    // ignore: avoid_print
    print('${rows.length} rows: ${rows.take(5).map((r) => '${r.name} ${r.rx}').join(', ')}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
