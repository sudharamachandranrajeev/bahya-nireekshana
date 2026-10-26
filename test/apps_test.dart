import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nireekshana/db/database.dart';
import 'package:nireekshana/domain/app_sources.dart';
import 'package:nireekshana/domain/app_stats.dart';
import 'package:nireekshana/domain/book.dart';
import 'package:nireekshana/domain/history.dart';

import 'support.dart';

const mb = 1000 * 1000;

AppUsage app(
  String day,
  String app,
  int rx,
  int tx, {
  String kind = 'wifi',
  String device = 'a',
  String? name,
  int? fg,
}) => AppUsage(
  id: '$device|$day|$kind|$app',
  hlc: '',
  deleted: false,
  device: device,
  deviceName: device == 'a' ? 'Laptop' : 'Phone',
  day: day,
  app: app,
  name: name ?? app,
  kind: kind,
  rx: rx,
  tx: tx,
  fg: fg,
);

void main() {
  group('sources', () {
    test('the Linux counter file is read from a day on, and odd rows are tolerated', () {
      const file = '''
{"version": 1, "updated": "2026-10-26T10:00:00+00:00", "days": {
  "2026-10-20": [{"app": "/usr/bin/old", "name": "old", "kind": "wifi", "rx": 5, "tx": 5}],
  "2026-10-25": [
    {"app": "/usr/lib/firefox/firefox", "name": "firefox", "kind": "wifi", "rx": 1000, "tx": 200},
    {"app": "/usr/lib/firefox/firefox", "name": "firefox", "kind": "ethernet", "rx": 50, "tx": 5},
    {"app": "/usr/bin/idle", "name": "idle", "kind": "wifi", "rx": 0, "tx": 0},
    "not a row"
  ]}}''';
      final rows = parseCollectorApps(file, from: '2026-10-21');
      expect(rows, hasLength(2));
      final wifi = rows.firstWhere((r) => r.kind == 'wifi');
      expect(
        (wifi.day, wifi.app, wifi.name, wifi.rx, wifi.tx, wifi.fg),
        ('2026-10-25', '/usr/lib/firefox/firefox', 'firefox', 1000, 200, null),
      );
      expect(() => parseCollectorApps('{"version": 2}'), throwsFormatException);
    });

    test('Windows rows from several profiles of one kind are summed and named by file', () {
      const json = '''[
  {"day": "2026-10-26", "app": "C:\\\\Program Files\\\\Mozilla Firefox\\\\firefox.exe", "name": "", "kind": "wifi", "rx": 100, "tx": 10},
  {"day": "2026-10-26", "app": "C:\\\\Program Files\\\\Mozilla Firefox\\\\firefox.exe", "name": "", "kind": "wifi", "rx": 50, "tx": 5},
  {"day": "2026-10-26", "app": "Microsoft.WindowsStore_8wekyb3d8bbwe", "name": "Microsoft Store", "kind": "ethernet", "rx": 7, "tx": 1}
]''';
      final rows = parseWindowsApps(json);
      expect(rows, hasLength(2));
      final ff = rows.firstWhere((r) => r.kind == 'wifi');
      expect((ff.name, ff.rx, ff.tx), ('firefox.exe', 150, 15));
      expect(rows.firstWhere((r) => r.kind == 'ethernet').name, 'Microsoft Store');
      // A single object (PowerShell unwraps one-element arrays) and nothing at all.
      expect(
        parseWindowsApps('{"day": "2026-10-26", "app": "x", "name": "x", "kind": "wifi", "rx": 1, "tx": 1}'),
        hasLength(1),
      );
      expect(parseWindowsApps('  '), isEmpty);
    });

    test('foreground bytes add up where known and stay unknown where not', () {
      final merged = mergeAppCounts([
        (day: 'd', app: 'a', name: 'A', kind: 'wifi', rx: 1, tx: 1, fg: 2),
        (day: 'd', app: 'a', name: 'A', kind: 'wifi', rx: 1, tx: 1, fg: 1),
        (day: 'd', app: 'b', name: 'B', kind: 'wifi', rx: 1, tx: 1, fg: null),
      ]);
      expect(merged.firstWhere((r) => r.app == 'a').fg, 3);
      expect(merged.firstWhere((r) => r.app == 'b').fg, isNull);
    });

    test('the Windows script asks for whole days in the invariant calendar', () {
      expect(windowsAppScript, contains('GetAttributedNetworkUsageAsync'));
      expect(windowsAppScript, contains('InvariantCulture'));
      expect(windowsAppScript, contains('__DAYS__'));
    });
  });

  group('periods', () {
    test('each period is compared with the one before, of the same length', () {
      expect(periodRange(AppPeriod.today, '2026-10-26'), (
        from: '2026-10-26',
        to: '2026-10-26',
        prevFrom: '2026-10-25',
        prevTo: '2026-10-25',
      ));
      expect(periodRange(AppPeriod.week, '2026-10-26'), (
        from: '2026-10-20',
        to: '2026-10-26',
        prevFrom: '2026-10-13',
        prevTo: '2026-10-19',
      ));
      expect(periodRange(AppPeriod.days30, '2026-10-26').prevFrom, '2026-08-28');
      expect(periodRange(AppPeriod.month, '2026-10-26'), (
        from: '2026-10-01',
        to: '2026-10-26',
        prevFrom: '2026-09-01',
        prevTo: '2026-09-26',
      ));
      // The 31st meets the end of a 30-day month.
      expect(periodRange(AppPeriod.month, '2026-10-31').prevTo, '2026-09-30');
    });
  });

  group('report', () {
    final range = periodRange(AppPeriod.week, '2026-10-26');
    final rows = [
      app('2026-10-26', 'firefox', 600 * mb, 40 * mb),
      app('2026-10-25', 'firefox', 300 * mb, 20 * mb),
      app('2026-10-15', 'firefox', 200 * mb, 10 * mb),
      app('2026-10-24', 'steam', 900 * mb, 10 * mb),
      app('2026-10-26', 'youtube', 100 * mb, 0, kind: 'mobile', device: 'p', fg: 90 * mb),
      app('2026-10-26', 'youtube', 100 * mb, 0, device: 'p', fg: 50 * mb),
      app('2026-10-16', 'youtube', 50 * mb, 0, device: 'p'),
      app('2026-10-26', 'curl', 1 * mb, 0),
      app('2026-10-01', 'gone', 1 * mb, 0),
    ];

    test('apps are ranked, compared with the week before, and new ones found', () {
      final r = AppsReport(rows, range: range);
      expect(r.apps.map((a) => a.app), ['firefox', 'steam', 'youtube', 'curl']);
      final ff = r.find('firefox')!;
      expect(ff.total, 960 * mb);
      expect(ff.previous.total, 210 * mb);
      expect(ff.change, closeTo(750 / 210, 1e-9));
      expect(ff.activeDays, 2);
      expect(ff.peak!.key, '2026-10-26');
      expect(r.newApps.map((a) => a.app), ['steam', 'curl']);
      expect(r.find('gone'), isNull);
      expect(r.total.total, (960 + 910 + 200 + 1) * mb);
      expect(r.previousTotal.total, 260 * mb);
      expect(r.topShare(), closeTo(2070 / 2071, 1e-9));
      expect(r.devices, {'a': 'Laptop', 'p': 'Phone'});
    });

    test('background share counts only the apps whose system said', () {
      final r = AppsReport(rows, range: range);
      final yt = r.find('youtube')!;
      expect(yt.background, closeTo(1 - 140 / 200, 1e-9));
      expect(r.find('firefox')!.background, isNull);
      expect(r.background, closeTo(1 - 140 / 200, 1e-9));
      expect(yt.byKind.keys, unorderedEquals(['wifi', 'mobile']));
    });

    test('filters by kind and device', () {
      final mobile = AppsReport(
        rows,
        range: range,
        filter: const UsageFilter(kinds: {'mobile'}),
      );
      expect(mobile.apps.map((a) => a.app), ['youtube']);
      expect(mobile.find('youtube')!.total, 100 * mb);
      final laptop = AppsReport(
        rows,
        range: range,
        filter: const UsageFilter(devices: {'a'}),
      );
      expect(laptop.find('youtube'), isNull);
      // The device list is for the filter chips, so it ignores the filter.
      expect(laptop.devices.keys, containsAll(['a', 'p']));
    });

    test('top and rest split, and a daily series with the gaps filled', () {
      final r = AppsReport(rows, range: range);
      final split = r.topAndRest(2);
      expect(split.top.map((a) => a.app), ['firefox', 'steam']);
      expect(split.rest, 201 * mb);
      final daily = appDaily(rows, 'firefox', from: '2026-10-24', to: '2026-10-26');
      expect([for (final d in daily) d.traffic.total], [0, 320 * mb, 640 * mb]);
    });
  });

  group('book', () {
    late Store store;
    late NetBook book;
    setUp(() async {
      store = await Store.open(memoryDatabase());
      book = NetBook(store, deviceName: 'Laptop');
    });
    tearDown(() => store.db.close());

    test('importing writes only what changed', () async {
      final rows = [
        (day: '2026-10-26', app: '/usr/bin/curl', name: 'curl', kind: 'wifi', rx: 10, tx: 1, fg: null),
        (day: '2026-10-25', app: '/usr/bin/curl', name: 'curl', kind: 'wifi', rx: 5, tx: 1, fg: null),
      ];
      expect(await book.importApps(rows), 2);
      expect(await book.importApps(rows), 0);
      expect(
        await book.importApps([
          (day: '2026-10-26', app: '/usr/bin/curl', name: 'curl', kind: 'wifi', rx: 20, tx: 2, fg: null),
        ]),
        1,
      );
      final saved = await book.appsSince('2026-10-26');
      expect(saved.single.rx, 20);
      expect(saved.single.device, store.deviceId);
      expect(saved.single.deviceName, 'Laptop');
    });

    test('forgetting a device forgets its apps too', () async {
      await store.save(book.db.nirApps, app('2026-10-26', 'x', 1, 1, device: 'old'), 'old|2026-10-26|wifi|x');
      await book.forgetDevice('old');
      expect(await book.appsSince('2000-01-01'), isEmpty);
    });
  });

  test('a version 1 database gains the apps table and keeps its rows', () async {
    final dir = await Directory.systemTemp.createTemp('nireekshana-migrate');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db
        .into(db.nirDays)
        .insert(
          NirDaysCompanion.insert(id: 'a|2026-10-26|wifi', device: 'a', day: '2026-10-26', kind: 'wifi'),
        );
    // Back to how version 1 left it.
    await db.customStatement('DROP TABLE nir_apps');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect(await db.select(db.nirDays).get(), hasLength(1));
    await db.into(db.nirApps).insert(app('2026-10-26', 'x', 1, 1));
    expect(await db.select(db.nirApps).get(), hasLength(1));
    final indexes = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index'").get();
    expect(indexes.map((r) => r.read<String>('name')), contains('nir_apps_day'));
    await db.close();
  });
}
