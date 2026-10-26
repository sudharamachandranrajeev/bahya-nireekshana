import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:nireekshana/db/database.dart';
import 'package:nireekshana/domain/book.dart';
import 'package:nireekshana/domain/themes.dart';

const gb = 1000 * 1000 * 1000;
const mb = 1000 * 1000;

/// Seventy days of made-up usage on this device and a phone, a mobile plan
/// close to its warning level, a few speed tests and one custom theme.
Future<void> seedBook(NetBook book) async {
  final t = today();
  final mine = <String, Map<String, ({int rx, int tx})>>{};
  for (var i = 0; i < 70; i++) {
    final day = addDays(t, -i);
    // A weekly rhythm, busier at weekends.
    final weekend = DateTime.parse(day).weekday >= 6;
    mine[day] = {
      'wifi': (rx: (weekend ? 6 : 3) * gb + i * 13 * mb, tx: 400 * mb + i * 3 * mb),
      if (i % 5 == 0) 'ethernet': (rx: 2 * gb, tx: 150 * mb),
    };
  }
  await book.addUsage(mine);
  // The phone's rows, as if they had arrived by sync.
  for (var i = 0; i < 40; i++) {
    final day = addDays(t, -i);
    for (final (kind, rx, tx) in [('mobile', 180 * mb + i * mb, 25 * mb), ('wifi', 900 * mb, 80 * mb)]) {
      final id = 'phone-1|$day|$kind';
      await book.store.save(
        book.db.nirDays,
        DayUsage(
          id: id,
          hlc: '',
          deleted: false,
          device: 'phone-1',
          deviceName: 'Pixel 9',
          day: day,
          kind: kind,
          rx: rx,
          tx: tx,
          source: 'android',
        ),
        id,
      );
    }
  }
  await book.savePlan(
    name: 'Phone data',
    capBytes: 8 * gb,
    cycleDay: 1,
    kinds: 'mobile',
    device: '',
    warnPercent: 80,
  );
  await book.savePlan(
    name: 'Broadband',
    capBytes: 1000 * gb,
    cycleDay: 15,
    kinds: 'all',
    device: '',
    warnPercent: 90,
  );
  for (var i = 0; i < 4; i++) {
    await book.addSpeedTest(
      at: DateTime.now().subtract(Duration(days: i * 3, hours: i)),
      down: (240 - i * 20) * 1000000,
      up: (32 + i) * 1000000,
      latency: 14.0 + i,
      jitter: 1.5,
      kind: 'wifi',
      server: 'LHR · London',
    );
  }
  final theme = generateTheme(math.Random(7), id: 'harbour', name: 'Harbour');
  await book.saveTheme(theme.id, theme.name, theme.encode());
}
