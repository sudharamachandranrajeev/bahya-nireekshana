/// System records of past usage, which are better than the app's own
/// recorder because they count while the app is closed: vnstat on Linux
/// and the network statistics Android keeps.
library;

import 'dart:convert';
import 'dart:io';

import 'book.dart';
import 'counters.dart';
import 'probe.dart';

/// A system record this device can import its daily usage from.
abstract class UsageSource {
  /// Stored with each imported row (DayUsage.source).
  String get id;
  String get title;

  /// Whether it can be read now (installed, permitted).
  Future<bool> available();

  /// Daily totals for the last [days] days.
  Future<List<DayCount>> read({int days = 62});

  static UsageSource? forPlatform() {
    if (Platform.isLinux) return VnstatSource();
    if (Platform.isAndroid) return AndroidStatsSource();
    return null;
  }
}

/// Linux: the vnstat daemon's database, through `vnstat --json`.
class VnstatSource implements UsageSource {
  @override
  String get id => 'vnstat';
  @override
  String get title => 'vnstat';

  @override
  Future<bool> available() async {
    try {
      return (await Process.run('vnstat', ['--version'])).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  Future<List<DayCount>> read({int days = 62}) async {
    final r = await Process.run('vnstat', ['--json', 'd', '$days']);
    if (r.exitCode != 0) throw StateError('vnstat failed: ${'${r.stderr}'.trim()}');
    return parseVnstatDays('${r.stdout}');
  }
}

/// `vnstat --json d` as daily totals by kind. vnstat keeps no interface
/// types, so the kind comes from the name (wl* Wi-Fi, en*/eth* Ethernet,
/// ww* mobile); tunnels and virtual links are left out like everywhere else.
List<DayCount> parseVnstatDays(String json) {
  final root = jsonDecode(json);
  final totals = <String, ({int rx, int tx})>{};
  for (final iface in (root is Map ? root['interfaces'] : null) as List? ?? const []) {
    if (iface is! Map) continue;
    final name = '${iface['name']}';
    final kind = linuxKind(
      name,
      physical: RegExp(r'^(en|eth)').hasMatch(name),
      wireless: name.startsWith('wl'),
    );
    if (!usageKinds.contains(kind)) continue;
    final daysList = (iface['traffic'] as Map?)?['day'] as List? ?? const [];
    for (final d in daysList) {
      if (d is! Map || d['date'] is! Map) continue;
      final date = d['date'] as Map;
      final day = '${date['year']}-${'${date['month']}'.padLeft(2, '0')}-${'${date['day']}'.padLeft(2, '0')}';
      final key = '$day|$kind';
      final had = totals[key] ?? (rx: 0, tx: 0);
      totals[key] = (
        rx: had.rx + ((d['rx'] as num?)?.toInt() ?? 0),
        tx: had.tx + ((d['tx'] as num?)?.toInt() ?? 0),
      );
    }
  }
  return [
    for (final e in totals.entries)
      (day: e.key.split('|')[0], kind: e.key.split('|')[1], rx: e.value.rx, tx: e.value.tx),
  ];
}

/// Android: NetworkStatsManager through MainActivity.kt. Needs usage access,
/// which the user grants in the system settings ([requestAccess]).
class AndroidStatsSource implements UsageSource {
  @override
  String get id => 'android';
  @override
  String get title => 'Android network statistics';

  @override
  Future<bool> available() async => await AndroidProbe.channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  /// Opens the system's usage access screen.
  Future<void> requestAccess() => AndroidProbe.channel.invokeMethod<void>('openUsageAccess');

  @override
  Future<List<DayCount>> read({int days = 62}) async {
    final list = await AndroidProbe.channel.invokeListMethod<Map>('deviceUsage', {'days': days}) ?? const [];
    return [
      for (final m in list)
        (
          day: '${m['day']}',
          kind: '${m['kind']}',
          rx: (m['rx'] as num?)?.toInt() ?? 0,
          tx: (m['tx'] as num?)?.toInt() ?? 0,
        ),
    ];
  }
}
