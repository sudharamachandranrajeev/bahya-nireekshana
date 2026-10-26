@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
