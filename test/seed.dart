import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:nireekshana/db/database.dart';
import 'package:nireekshana/domain/app_sources.dart';
import 'package:nireekshana/domain/book.dart';
import 'package:nireekshana/domain/themes.dart';

const gb = 1000 * 1000 * 1000;
const mb = 1000 * 1000;

/// Seventy days of made-up usage on this device and a phone, a mobile plan
/// close to its warning level, usage per app, a few speed tests and one
/// custom theme.
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
  await seedApps(book);
  final theme = generateTheme(math.Random(7), id: 'harbour', name: 'Harbour');
  await book.saveTheme(theme.id, theme.name, theme.encode());
}

/// Six weeks of usage per app: this laptop's from its counter, the phone's
/// (with foreground bytes) as if they had arrived by sync.
Future<void> seedApps(NetBook book) async {
  final t = today();
  const laptop = [
    ('/usr/lib/firefox/firefox', 'firefox', 1400, 90),
    ('/opt/spotify/spotify', 'spotify', 260, 6),
    ('/usr/bin/steam', 'steam', 900, 20),
    ('/usr/lib/code/code', 'code', 120, 30),
    ('/usr/bin/discord', 'Discord', 180, 40),
    ('/usr/bin/syncthing', 'syncthing', 60, 140),
    ('/usr/bin/curl', 'curl', 15, 2),
    ('unknown TCP', 'Unknown (system)', 8, 4),
  ];
  final rows = <AppCount>[];
  for (var i = 0; i < 45; i++) {
    final day = addDays(t, -i);
    for (final (n, (app, name, rx, tx)) in laptop.indexed) {
      // Steam downloads a game every ten days; curl only appeared lately.
      if (app == '/usr/bin/steam' && i % 10 != 3) continue;
      if (app == '/usr/bin/curl' && i > 2) continue;
      final f = 1 + (i + n) % 4 * 0.25;
      rows.add((
        day: day,
        app: app,
        name: name,
        kind: 'wifi',
        rx: (rx * f * mb).round(),
        tx: (tx * f * mb).round(),
        fg: null,
      ));
    }
  }
  await book.importApps(rows);
  const phone = [
    ('com.google.android.youtube', 'YouTube', 420, 12, 0.9),
    ('com.whatsapp', 'WhatsApp', 60, 35, 0.4),
    ('com.instagram.android', 'Instagram', 180, 10, 0.85),
    ('com.google.android.gms', 'Google Play services', 40, 15, 0.05),
    ('android', 'Android system', 25, 8, 0.0),
  ];
  for (var i = 0; i < 40; i++) {
    final day = addDays(t, -i);
    for (final (app, name, rx, tx, fg) in phone) {
      for (final (kind, share) in [('mobile', 0.3), ('wifi', 0.7)]) {
        final id = 'phone-1|$day|$kind|$app';
        final r = (rx * share * mb).round(), x = (tx * share * mb).round();
        await book.store.save(
          book.db.nirApps,
          AppUsage(
            id: id,
            hlc: '',
            deleted: false,
            device: 'phone-1',
            deviceName: 'Pixel 9',
            day: day,
            app: app,
            name: name,
            kind: kind,
            rx: r,
            tx: x,
            fg: ((r + x) * fg).round(),
          ),
          id,
        );
      }
    }
  }
}
