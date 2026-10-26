import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nireekshana/domain/book.dart';
import 'package:nireekshana/domain/bytes.dart';
import 'package:nireekshana/domain/connections.dart';
import 'package:nireekshana/domain/counters.dart';
import 'package:nireekshana/domain/firewall.dart';
import 'package:nireekshana/domain/history.dart';
import 'package:nireekshana/domain/insights.dart';
import 'package:nireekshana/domain/probe.dart';
import 'package:nireekshana/domain/recorder.dart';
import 'package:nireekshana/domain/sources.dart';
import 'package:nireekshana/domain/speedtest.dart';
import 'package:nireekshana/domain/themes.dart';
import 'package:nireekshana/domain/update.dart';

import 'support.dart';

const gb = 1000 * 1000 * 1000;
const mb = 1000 * 1000;

DayUsage row(String day, String kind, int rx, int tx, {String device = 'a', String name = 'Laptop'}) =>
    DayUsage(
      id: '$device|$day|$kind',
      hlc: '',
      deleted: false,
      device: device,
      deviceName: name,
      day: day,
      kind: kind,
      rx: rx,
      tx: tx,
      source: 'recorder',
    );

DataPlan plan({
  int cap = 10 * gb,
  int cycleDay = 1,
  String kinds = 'all',
  String device = '',
  int warn = 80,
}) => DataPlan(
  id: 'p',
  hlc: '',
  deleted: false,
  name: 'Phone',
  capBytes: cap,
  cycleDay: cycleDay,
  kinds: kinds,
  device: device,
  warnPercent: warn,
  created: '2026-01-01',
);

Sample sample(int seconds, Map<String, (int, int)> counters, {String boot = 'b1', String kind = 'wifi'}) =>
    Sample(DateTime(2026, 10, 26, 12).add(Duration(seconds: seconds)), [
      for (final e in counters.entries)
        Iface(name: e.key, kind: e.key.startsWith('wg') ? 'vpn' : kind, rx: e.value.$1, tx: e.value.$2),
    ], boot: boot);

void main() {
  group('sizes', () {
    test('bytes and speeds read in powers of 1000', () {
      expect(bytes(0), '0 B');
      expect(bytes(1500), '1.5 kB');
      expect(bytes(12 * gb), '12 GB');
      expect(bytes(12340 * mb), '12.3 GB');
      expect(bytes(250 * gb), '250 GB');
      expect(speed(1200000), '9.6 Mbps');
      expect(speed(0), '0 bps');
    });

    test('allowances parse from what people type', () {
      expect(parseBytes('20 GB'), 20 * gb);
      expect(parseBytes('500mb'), 500 * mb);
      expect(parseBytes('1.5 TB'), 1500 * gb);
      expect(parseBytes('1234'), 1234);
      expect(parseBytes('lots'), isNull);
    });
  });

  group('counters', () {
    test('linux interfaces get a kind from their name and hardware', () {
      expect(linuxKind('lo', physical: false, wireless: false), 'loopback');
      expect(linuxKind('wlan0', physical: true, wireless: true), 'wifi');
      expect(linuxKind('enp3s0', physical: true, wireless: false), 'ethernet');
      expect(linuxKind('wg0', physical: false, wireless: false), 'vpn');
      expect(linuxKind('wwan0', physical: true, wireless: false), 'mobile');
      expect(linuxKind('docker0', physical: false, wireless: false), 'virtual');
    });

    test('usage between readings ignores VPNs and survives counter resets', () {
      final a = sample(0, {'wlan0': (1000, 500), 'wg0': (10, 10)});
      final b = sample(10, {'wlan0': (3000, 900), 'wg0': (999, 999)});
      expect(usageBetween(a, b), {'wifi': (rx: 2000, tx: 400)});
      // The link came back: the counter restarted, so all it holds is new.
      final c = sample(20, {'wlan0': (100, 50)});
      expect(usageBetween(b, c), {'wifi': (rx: 100, tx: 50)});
      // Another boot never subtracts.
      expect(usageBetween(b, sample(30, {'wlan0': (5000, 5000)}, boot: 'b2')), isEmpty);
    });

    test('rates are bytes a second over the counted links', () {
      final r = Rates.between(sample(0, {'wlan0': (0, 0)}), sample(2, {'wlan0': (2000, 1000)}));
      expect(r.rx, 1000);
      expect(r.tx, 500);
      expect(r.byIface['wlan0'], (rx: 1000.0, tx: 500.0));
    });

    test('/proc/net/dev rows are read', () {
      const text = '''Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:  123456     100    0    0    0     0          0         0   123456     100    0    0    0     0       0          0
wlan0: 987654321  1000    0    0    0     0          0         0 12345678    900    0    0    0     0       0          0''';
      expect(parseNetDev(text), [
        (name: 'lo', rx: 123456, tx: 123456),
        (name: 'wlan0', rx: 987654321, tx: 12345678),
      ]);
    });

    test('the linux probe reads a /proc and /sys tree', () async {
      final root = await Directory.systemTemp.createTemp('nir');
      addTearDown(() => root.delete(recursive: true));
      Future<void> put(String path, String text) async {
        final f = File('${root.path}/$path');
        await f.parent.create(recursive: true);
        await f.writeAsString(text);
      }

      await put(
        'proc/net/dev',
        'h\nh\n lo: 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0\nwlp2s0: 500 0 0 0 0 0 0 0 70 0 0 0 0 0 0 0\n',
      );
      await put('proc/sys/kernel/random/boot_id', 'boot-1\n');
      await put('sys/class/net/wlp2s0/operstate', 'up\n');
      await Directory('${root.path}/sys/class/net/wlp2s0/wireless').create(recursive: true);
      final s = await LinuxProbe(root: root.path).sample();
      expect(s.boot, 'boot-1');
      expect(s.ifaces.single.name, 'wlp2s0');
      expect(s.ifaces.single.kind, 'wifi');
      expect(s.rx, 500);
    });
  });

  group('recorder', () {
    test('usage while closed is spread evenly over the days', () {
      final out = spreadUsage(
        {'wifi': (rx: 1000, tx: 10)},
        DateTime(2026, 10, 1, 22),
        DateTime(2026, 10, 3, 1),
      );
      expect(out.keys, ['2026-10-01', '2026-10-02', '2026-10-03']);
      expect(out['2026-10-01']!['wifi'], (rx: 333, tx: 3));
      expect(out['2026-10-03']!['wifi'], (rx: 334, tx: 4));
    });

    test('a saved reading comes back as it went', () {
      final s = sample(0, {'wlan0': (12, 34)});
      final back = decodeSample(encodeSample(s))!;
      expect(back.boot, s.boot);
      expect(back.at, s.at);
      expect(back.ifaces.single.rx, 12);
      expect(decodeSample('nonsense'), isNull);
    });

    test('a new run picks up usage from while the app was closed', () async {
      final store = await Store.open(memoryDatabase());
      addTearDown(store.db.close);
      final book = NetBook(store);
      final first = Recorder(book);
      await first.start(sample(0, {'wlan0': (1000, 100)}));
      first.take(sample(60, {'wlan0': (2000, 200)}));
      await first.flush();
      // The next start, an hour later on the same boot.
      final second = Recorder(book);
      await second.start(sample(3660, {'wlan0': (7000, 700)}));
      await second.flush();
      final rows = await book.usageSince('2000-01-01');
      expect(rows.single.rx, 6000);
      expect(rows.single.tx, 600);
    });
  });

  group('book', () {
    test('importing the same record twice writes nothing the second time', () async {
      final store = await Store.open(memoryDatabase());
      addTearDown(store.db.close);
      final book = NetBook(store, deviceName: 'Laptop');
      final counts = [
        (day: '2026-10-25', kind: 'wifi', rx: 100, tx: 10),
        (day: '2026-10-26', kind: 'wifi', rx: 50, tx: 5),
      ];
      expect(await book.importUsage(counts, 'vnstat'), 2);
      expect(await book.importUsage(counts, 'vnstat'), 0);
      expect(await book.importUsage([(day: '2026-10-26', kind: 'wifi', rx: 80, tx: 5)], 'vnstat'), 1);
      final rows = await book.usageSince('2026-10-26');
      expect(rows.single.rx, 80);
      expect(rows.single.deviceName, 'Laptop');
    });

    test('recorded usage adds up within a day', () async {
      final store = await Store.open(memoryDatabase());
      addTearDown(store.db.close);
      final book = NetBook(store);
      await book.addUsage({
        '2026-10-26': {'wifi': (rx: 10, tx: 1)},
      });
      await book.addUsage({
        '2026-10-26': {'wifi': (rx: 5, tx: 2)},
      });
      final r = (await book.usageSince('2026-10-26')).single;
      expect((r.rx, r.tx), (15, 3));
    });

    test('preferences are kept as JSON', () async {
      final store = await Store.open(memoryDatabase());
      addTearDown(store.db.close);
      final book = NetBook(store);
      expect(await book.pref<num>(PrefKeys.spikeFactor, 3), 3);
      await book.setPref(PrefKeys.spikeFactor, 4.5);
      expect(await book.pref<num>(PrefKeys.spikeFactor, 3), 4.5);
    });
  });

  group('history', () {
    final rows = [
      row('2026-10-26', 'wifi', 3 * gb, 1 * gb),
      row('2026-10-25', 'wifi', 1 * gb, 0),
      row('2026-10-25', 'mobile', 500 * mb, 0, device: 'b', name: 'Phone'),
      row('2026-09-26', 'wifi', 2 * gb, 0),
      row('2026-09-03', 'ethernet', 1 * gb, 0),
    ];

    test('ranges, kinds and devices add up', () {
      final ix = UsageIndex(rows);
      expect(ix.day('2026-10-25').total, 1500 * mb);
      expect(ix.range('2026-10-01', '2026-10-31').total, 5500 * mb);
      expect(ix.kindsIn('2026-10-25', '2026-10-25')['mobile']!.rx, 500 * mb);
      expect(ix.devicesIn('2026-10-01', '2026-10-31')['b']!.total, 500 * mb);
      expect(ix.devices, {'a': 'Laptop', 'b': 'Phone'});
    });

    test('a filter keeps only the chosen devices and kinds', () {
      final ix = UsageIndex(rows, filter: const UsageFilter(kinds: {'mobile'}));
      expect(ix.range('2026-01-01', '2026-12-31').total, 500 * mb);
      // Every device stays listed, so the filter can be changed back.
      expect(ix.devices.keys, containsAll(['a', 'b']));
    });

    test('buckets run oldest first and end with the current one', () {
      final ix = UsageIndex(rows);
      final days = ix.buckets(Granularity.day, '2026-10-26', 3);
      expect([for (final b in days) b.start], ['2026-10-24', '2026-10-25', '2026-10-26']);
      final weeks = ix.buckets(Granularity.week, '2026-10-26', 2);
      expect(weeks.last.start, '2026-10-26'); // a Monday
      expect(weeks.first.end, '2026-10-25');
      final months = ix.buckets(Granularity.month, '2026-10-26', 2);
      expect(months.first.traffic.total, 3 * gb);
      expect(months.first.byKind.keys, containsAll(['wifi', 'ethernet']));
    });

    test('the summary compares with the same days of last month', () {
      final s = UsageSummary(UsageIndex(rows), '2026-10-26');
      expect(s.todayTraffic.total, 4 * gb);
      expect(s.yesterday.total, 1500 * mb);
      expect(s.month.total, 5500 * mb);
      expect(s.lastMonthToDate.total, 3 * gb);
      expect(s.monthChange, closeTo(5.5 / 3 - 1, 1e-9));
      expect(s.monthProjection, (5500 * mb / 26 * 31).round());
      expect(s.peak30!.day, '2026-10-26');
    });

    test('the allowance period follows the renewal day', () {
      expect(cycleOf('2026-10-26', 15), (start: '2026-10-15', end: '2026-11-14'));
      expect(cycleOf('2026-10-10', 15), (start: '2026-09-15', end: '2026-10-14'));
      expect(cycleOf('2026-03-01', 1), (start: '2026-03-01', end: '2026-03-31'));
    });

    test('a plan warns, runs out and budgets the rest', () {
      final usage = [
        for (var d = 1; d <= 10; d++) row('2026-10-${'$d'.padLeft(2, '0')}', 'mobile', 500 * mb, 0),
      ];
      final fine = PlanStatus(plan(cap: 20 * gb, kinds: 'mobile'), usage, '2026-10-10');
      expect(fine.used, 5 * gb);
      expect(fine.state, PlanState.fine);
      expect(fine.daysLeft, 21);
      expect(fine.dailyBudget, (15 * gb / 22).floor());
      final pace = PlanStatus(plan(cap: 12 * gb), usage, '2026-10-10');
      expect(pace.state, PlanState.onTrackToExceed);
      final warn = PlanStatus(plan(cap: 6 * gb), usage, '2026-10-10');
      expect(warn.state, PlanState.warning);
      final over = PlanStatus(plan(cap: 4 * gb), usage, '2026-10-10');
      expect(over.state, PlanState.over);
      expect(over.left, 0);
      // Another kind of network does not count.
      expect(PlanStatus(plan(kinds: 'wifi'), usage, '2026-10-10').used, 0);
    });

    test('insights call out plans, busy days and heavy uploads', () {
      final usage = [
        for (var d = 1; d <= 25; d++) row('2026-10-${'$d'.padLeft(2, '0')}', 'wifi', 300 * mb, 0),
        row('2026-10-26', 'wifi', 1 * gb, 2 * gb),
      ];
      final summary = UsageSummary(UsageIndex(usage), '2026-10-26');
      final list = insightsFor(
        summary: summary,
        plans: [PlanStatus(plan(cap: 9 * gb), usage, '2026-10-26')],
      );
      expect(list.map((i) => i.title), [
        'Phone is used up',
        'Unusually busy day',
        'More going out than coming in',
      ]);
      expect(list.first.level, InsightLevel.critical);
      expect(insightsFor(summary: summary, plans: const [], spikeFactor: 20).map((i) => i.title), [
        'More going out than coming in',
      ]);
    });
  });

  group('sources', () {
    test('vnstat days are totalled by kind of network', () {
      final json = jsonEncode({
        'interfaces': [
          for (final (name, rx) in [
            ('wlan0', 100),
            ('wlp3s0', 50),
            ('enp0s31f6', 7),
            ('wg0', 999),
            ('docker0', 5),
          ])
            {
              'name': name,
              'traffic': {
                'day': [
                  {
                    'date': {'year': 2026, 'month': 10, 'day': 26},
                    'rx': rx,
                    'tx': 1,
                  },
                ],
              },
            },
        ],
      });
      final days = parseVnstatDays(json);
      expect(days, hasLength(2));
      expect(days.firstWhere((d) => d.kind == 'wifi'), (day: '2026-10-26', kind: 'wifi', rx: 150, tx: 2));
      expect(days.firstWhere((d) => d.kind == 'ethernet').rx, 7);
    });
  });

  group('connections', () {
    test('/proc/net/tcp rows decode addresses and states', () {
      const text =
          '''  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
   0: 0100007F:0035 00000000:0000 0A 00000000:00000000 00:00000000 00000000   101        0 2222 1
   1: 1401A8C0:C738 22D8B85D:01BB 01 00000000:00000000 00:00000000 00000000  1000        0 3333 1''';
      final rows = parseProcNet(text, 'tcp');
      expect(rows[0].connection.local, '127.0.0.1');
      expect(rows[0].connection.localPort, 53);
      expect(rows[0].connection.listening, isTrue);
      expect(rows[1].connection.remote, '93.184.216.34');
      expect(rows[1].connection.remotePort, 443);
      expect(rows[1].connection.state, 'established');
      expect(rows[1].inode, 3333);
    });

    test('programs, private addresses and grouping', () {
      expect(programName(r'C:\Program Files\Mozilla Firefox\firefox.exe'), 'firefox');
      expect(programName('/usr/bin/curl'), 'curl');
      expect(isPrivateAddress('192.168.1.1'), isTrue);
      expect(isPrivateAddress('100.100.1.1'), isTrue);
      expect(isPrivateAddress('::ffff:10.0.0.1'), isTrue);
      expect(isPrivateAddress('fd00::1'), isTrue);
      expect(isPrivateAddress('93.184.216.34'), isFalse);
      final groups = byProgram(sampleConnections);
      expect(groups.first.program, 'firefox');
      expect(groups.first.open, 2);
      expect(groups.first.peers, ['93.184.216.34', '2606:2800:220:1::1']);
    });
  });

  group('firewall', () {
    test('the export becomes rows, lists included, list rules left out', () {
      final r = parseRulesExport(FakeFirewall.export)!;
      final byTitle = {for (final i in r.items) i.title: i};
      expect(byTitle.keys, containsAll(['firefox', 'curl', 'ads.example.net', '203.0.113.0/24']));
      expect(byTitle['firefox']!.kind, 'app');
      expect(byTitle['firefox']!.detail, contains('to example.com'));
      expect(byTitle['curl']!.blocked, isTrue);
      expect(byTitle['curl']!.flipArgs, ['set-action', 'curl.json', 'allow']);
      expect(byTitle['ads.example.net']!.flipArgs, ['list-add', 'allow-domains', 'ads.example.net']);
      expect(byTitle['203.0.113.0/24']!.deleteArgs, ['list-remove', 'block-nets', '203.0.113.0/24']);
      expect(r.items.where((i) => i.kind == 'system'), hasLength(1));
      expect(parseRulesExport('{'), isNull);
    });

    test('what is typed is classified before the helper sees it', () {
      expect(classifyEntry('Example.COM.').kind, 'site');
      expect(classifyEntry('Example.COM.').value, 'example.com');
      expect(classifyEntry('10.0.0.0/8').kind, 'address');
      expect(classifyEntry('2001:db8::/32').kind, 'address');
      expect(classifyEntry('300.1.1.1').error, isNotEmpty);
      expect(classifyEntry('*.example.com').error, contains('Wildcards'));
      expect(classifyEntry('not a host').kind, isNull);
      expect(addArgs('site', 'example.com', block: true), ['list-add', 'block-domains', 'example.com']);
      expect(addArgs('address', '10.0.0.1', block: false), ['list-add', 'allow-nets', '10.0.0.1']);
    });
  });

  group('themes', () {
    test('the built-in list is valid and its ids unique', () {
      final list = builtInThemes();
      expect(list.length, greaterThanOrEqualTo(8));
      expect(list.first.id, 'radar');
      expect({for (final t in list) t.id}, hasLength(list.length));
      expect(list.every((t) => t.builtIn), isTrue);
    });

    test('a theme survives a round trip through JSON', () {
      final t = builtInThemes().firstWhere((t) => t.id == 'terminal');
      final back = NetTheme.decode(t.encode());
      expect(back.toJson(), t.toJson());
      expect(back.font, 'mono');
      expect(back.builtIn, isFalse);
    });

    test('bad themes say what is wrong', () {
      final good = builtInThemes().first.toJson();
      void bad(Map<String, Object?> change, String message) => expect(
        () => NetTheme.fromJson({...good, ...change}),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(message))),
      );
      bad({'format': 'other'}, 'not a Bahya Nireekshana theme');
      bad({'id': 'Has Spaces'}, 'id');
      bad({'seed': 'blue'}, '"seed"');
      bad({'radius': 99}, '"radius"');
      bad({'font': 'serif'}, '"font"');
      expect(() => NetTheme.decode('{'), throwsFormatException);
    });

    test('ids come from names and stay clear of taken ones', () {
      expect(themeIdFor('My Theme!', {}), 'my-theme');
      expect(themeIdFor('My Theme', {'my-theme', 'my-theme-2'}), 'my-theme-3');
      expect(themeIdFor('***', {}), 'theme');
    });

    test('generated themes keep the data colours readable', () {
      for (var seed = 0; seed < 50; seed++) {
        final t = generateTheme(math.Random(seed), id: 'x', name: 'X');
        expect(contrast(t.download, t.darkBackground), greaterThan(2), reason: 'seed $seed');
        expect(contrast(t.upload, t.darkBackground), greaterThan(2), reason: 'seed $seed');
      }
      expect(contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
      expect(hexOf(parseHex('#1fb5e0')!), '#1FB5E0');
    });
  });

  group('speed test', () {
    test('summaries of the measurements', () {
      expect(median([3, 1, 2]), 2);
      expect(median([1, 2, 3, 4]), 2.5);
      expect(jitterOf([10, 12, 11]), 1.5);
      expect(reportedSpeed([for (var i = 1; i <= 10; i++) i * 1.0]), 10);
      expect(reportedSpeed([]), 0);
    });

    test('a run talks only to the speed test service and reports its server', () async {
      final asked = <String>{};
      final client = MockClient((r) async {
        asked.add(r.url.host);
        if (r.url.path == '/meta') return http.Response('{"colo":"LHR","city":"London"}', 200);
        if (r.url.path == '/__down') {
          return http.Response.bytes(List.filled(int.parse(r.url.queryParameters['bytes']!), 0), 200);
        }
        return http.Response('', 200);
      });
      final phases = <SpeedPhase>{};
      final result = await SpeedTester(client).run(onProgress: (p) => phases.add(p.phase));
      expect(asked, {'speed.cloudflare.com'});
      expect(result.server, 'LHR · London');
      expect(result.down, greaterThan(0));
      expect(phases, containsAll(SpeedPhase.values));
    });

    test('a refusing server is reported plainly', () async {
      final client = MockClient((_) async => http.Response('no', 503));
      expect(
        SpeedTester(client).run(),
        throwsA(isA<SpeedTestException>().having((e) => e.message, 'message', contains('503'))),
      );
    });
  });

  group('updates', () {
    test('versions compare by number', () {
      expect(isNewer('0.2.0', '0.1.9'), isTrue);
      expect(isNewer('0.10.0', '0.9.0'), isTrue);
      expect(isNewer('0.1.0', '0.1.0'), isFalse);
      expect(isNewer('v1.0.0', '0.9.0'), isTrue);
    });
  });
}
