/// Figures for the Apps page, worked out from the per-app rows.
library;

import 'package:brahma_core/brahma_core.dart';

import '../db/database.dart';
import 'history.dart';

/// The spans the Apps page compares.
enum AppPeriod {
  today('Today'),
  week('7 days'),
  days30('30 days'),
  month('Month');

  const AppPeriod(this.label);
  final String label;
}

/// A period and the one before it, of the same length, as inclusive days.
typedef PeriodRange = ({String from, String to, String prevFrom, String prevTo});

PeriodRange periodRange(AppPeriod p, String today) {
  switch (p) {
    case AppPeriod.today:
      final y = addDays(today, -1);
      return (from: today, to: today, prevFrom: y, prevTo: y);
    case AppPeriod.week || AppPeriod.days30:
      final n = p == AppPeriod.week ? 7 : 30;
      return (
        from: addDays(today, -(n - 1)),
        to: today,
        prevFrom: addDays(today, -(2 * n - 1)),
        prevTo: addDays(today, -n),
      );
    case AppPeriod.month:
      // Last month up to the same day, so a part month meets a part month.
      final from = monthStart(today);
      final prevFrom = monthStart(addMonths(from, -1));
      final sameDay = addDays(prevFrom, daysBetween(from, today));
      final prevEnd = monthEnd(prevFrom);
      return (
        from: from,
        to: today,
        prevFrom: prevFrom,
        prevTo: sameDay.compareTo(prevEnd) > 0 ? prevEnd : sameDay,
      );
  }
}

/// One app's usage over a period.
class AppStat {
  AppStat(this.app, this.name);
  final String app;
  String name;
  Traffic traffic = Traffic.zero;
  Traffic previous = Traffic.zero;

  /// Foreground bytes, and the bytes of rows that said (only Android's do).
  int fg = 0;
  int fgKnown = 0;
  final Map<String, Traffic> byDay = {};
  final Map<String, Traffic> byKind = {};
  final Map<String, Traffic> byDevice = {};

  int get total => traffic.total;

  /// Against the period before; null when it used nothing then.
  double? get change => previous.total == 0 ? null : (total - previous.total) / previous.total;

  /// The share moved while the app was not on screen; null where unknown.
  double? get background => fgKnown == 0 ? null : 1 - fg / fgKnown;

  /// Days in the period it used the network.
  int get activeDays => byDay.length;

  /// Its biggest day.
  MapEntry<String, Traffic>? get peak =>
      byDay.entries.isEmpty ? null : byDay.entries.reduce((a, b) => b.value.total > a.value.total ? b : a);
}

/// The Apps page's figures for one period, filtered by device and kind.
class AppsReport {
  AppsReport(List<AppUsage> rows, {required this.range, this.filter = const UsageFilter()}) {
    final stats = <String, AppStat>{};
    var previous = Traffic.zero;
    for (final r in rows) {
      devices[r.device] = r.deviceName;
      if (!filter.allows(r.device, r.kind)) continue;
      final t = Traffic(r.rx, r.tx);
      if (_within(r.day, range.prevFrom, range.prevTo)) {
        previous += t;
        (stats[r.app] ??= AppStat(r.app, r.name)).previous += t;
      }
      if (!_within(r.day, range.from, range.to)) continue;
      final s = stats[r.app] ??= AppStat(r.app, r.name);
      // The name a device reported last (an app renamed in an update).
      s.name = r.name;
      s.traffic += t;
      s.byDay[r.day] = (s.byDay[r.day] ?? Traffic.zero) + t;
      s.byKind[r.kind] = (s.byKind[r.kind] ?? Traffic.zero) + t;
      s.byDevice[r.device] = (s.byDevice[r.device] ?? Traffic.zero) + t;
      if (r.fg != null) {
        s.fg += r.fg!;
        s.fgKnown += t.total;
      }
    }
    apps = stats.values.where((s) => s.total > 0).toList()..sort((a, b) => b.total.compareTo(a.total));
    previousTotal = previous;
  }

  final PeriodRange range;
  final UsageFilter filter;

  /// Every device with app rows, id to name, whatever the filter.
  final Map<String, String> devices = {};

  /// Apps that used the network in the period, the most first.
  late final List<AppStat> apps;
  late final Traffic previousTotal;

  static bool _within(String day, String from, String to) =>
      day.compareTo(from) >= 0 && day.compareTo(to) <= 0;

  bool get isEmpty => apps.isEmpty;

  late final Traffic total = apps.fold(Traffic.zero, (s, a) => s + a.traffic);

  /// Against the period before; null when nothing was counted then.
  double? get change =>
      previousTotal.total == 0 ? null : (total.total - previousTotal.total) / previousTotal.total;

  /// The share of the period's traffic the top [n] apps moved.
  double topShare([int n = 3]) =>
      total.total == 0 ? 0 : apps.take(n).fold<int>(0, (s, a) => s + a.total) / total.total;

  /// Background share over the apps whose system said; null where none did.
  double? get background {
    final known = apps.fold<int>(0, (s, a) => s + a.fgKnown);
    if (known == 0) return null;
    return 1 - apps.fold<int>(0, (s, a) => s + a.fg) / known;
  }

  /// Apps that used nothing in the period before, when that period has
  /// any usage to compare with.
  List<AppStat> get newApps => previousTotal.total == 0
      ? const []
      : [
          for (final a in apps)
            if (a.previous.total == 0) a,
        ];

  /// Usage by kind of network across every app.
  Map<String, Traffic> get byKind {
    final out = <String, Traffic>{};
    for (final a in apps) {
      for (final e in a.byKind.entries) {
        out[e.key] = (out[e.key] ?? Traffic.zero) + e.value;
      }
    }
    return out;
  }

  /// The first [n] apps and the rest summed, for a breakdown.
  ({List<AppStat> top, int rest}) topAndRest(int n) =>
      (top: apps.take(n).toList(), rest: apps.skip(n).fold<int>(0, (s, a) => s + a.total));

  AppStat? find(String app) => apps.where((a) => a.app == app).firstOrNull;
}

/// One app's daily usage from [from] to [to], one entry a day.
List<({String day, Traffic traffic})> appDaily(
  List<AppUsage> rows,
  String app, {
  required String from,
  required String to,
  UsageFilter filter = const UsageFilter(),
}) {
  final byDay = <String, Traffic>{};
  for (final r in rows) {
    if (r.app != app || !filter.allows(r.device, r.kind)) continue;
    if (r.day.compareTo(from) < 0 || r.day.compareTo(to) > 0) continue;
    byDay[r.day] = (byDay[r.day] ?? Traffic.zero) + Traffic(r.rx, r.tx);
  }
  return [
    for (var d = from; d.compareTo(to) <= 0; d = addDays(d, 1)) (day: d, traffic: byDay[d] ?? Traffic.zero),
  ];
}
