/// Usage history worked out from the day rows: totals, series, breakdowns,
/// data plans and alerts. Pure functions over [DayUsage], so every number
/// can be tested and nothing is stored twice.
library;

import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';

import '../db/database.dart';

export '../db/database.dart' show DayUsage, DataPlan;

/// Bytes in and out.
class Traffic {
  const Traffic(this.rx, this.tx);
  final int rx;
  final int tx;
  static const zero = Traffic(0, 0);

  int get total => rx + tx;
  Traffic operator +(Traffic o) => Traffic(rx + o.rx, tx + o.tx);

  /// Share of the total that went out, 0 to 1.
  double get upShare => total == 0 ? 0 : tx / total;
}

/// Which rows to count.
class UsageFilter {
  const UsageFilter({this.devices = const {}, this.kinds = const {}});

  /// Empty means every device / every kind.
  final Set<String> devices;
  final Set<String> kinds;

  bool matches(DayUsage d) => allows(d.device, d.kind);

  bool allows(String device, String kind) =>
      (devices.isEmpty || devices.contains(device)) && (kinds.isEmpty || kinds.contains(kind));

  UsageFilter copyWith({Set<String>? devices, Set<String>? kinds}) =>
      UsageFilter(devices: devices ?? this.devices, kinds: kinds ?? this.kinds);
}

/// One bar of a chart: a day, an ISO week (its Monday) or a month (its 1st).
class Bucket {
  const Bucket(this.start, this.end, this.traffic, {this.byKind = const {}});
  final String start;

  /// Inclusive.
  final String end;
  final Traffic traffic;
  final Map<String, Traffic> byKind;
}

enum Granularity { day, week, month }

/// Monday of the week [day] is in.
String mondayOf(String day) {
  final d = DateTime.parse(day);
  return addDays(day, -(d.weekday - 1));
}

/// Totals by day, by kind and by device for the rows [filter] keeps.
class UsageIndex {
  UsageIndex(Iterable<DayUsage> rows, {this.filter = const UsageFilter()}) {
    for (final r in rows) {
      if (r.deleted) continue;
      devices[r.device] = r.deviceName.isEmpty ? (devices[r.device] ?? '') : r.deviceName;
      if (!filter.matches(r)) continue;
      final t = Traffic(r.rx, r.tx);
      _byDay[r.day] = (_byDay[r.day] ?? Traffic.zero) + t;
      (_byDayKind[r.day] ??= {}).update(r.kind, (o) => o + t, ifAbsent: () => t);
      (_byDayDevice[r.day] ??= {}).update(r.device, (o) => o + t, ifAbsent: () => t);
    }
  }

  final UsageFilter filter;

  /// Every device seen (filtered or not), id → latest name.
  final Map<String, String> devices = {};
  final Map<String, Traffic> _byDay = {};
  final Map<String, Map<String, Traffic>> _byDayKind = {};
  final Map<String, Map<String, Traffic>> _byDayDevice = {};

  bool get isEmpty => _byDay.isEmpty;

  /// The first day with any usage.
  String? get firstDay => _byDay.keys.isEmpty ? null : (_byDay.keys.toList()..sort()).first;

  Traffic day(String day) => _byDay[day] ?? Traffic.zero;

  /// Inclusive range.
  Traffic range(String from, String to) {
    var t = Traffic.zero;
    for (final e in _byDay.entries) {
      if (e.key.compareTo(from) >= 0 && e.key.compareTo(to) <= 0) t += e.value;
    }
    return t;
  }

  Map<String, Traffic> kindsIn(String from, String to) => _split(_byDayKind, from, to);

  Map<String, Traffic> devicesIn(String from, String to) => _split(_byDayDevice, from, to);

  Map<String, Traffic> _split(Map<String, Map<String, Traffic>> by, String from, String to) {
    final out = <String, Traffic>{};
    for (final e in by.entries) {
      if (e.key.compareTo(from) < 0 || e.key.compareTo(to) > 0) continue;
      for (final k in e.value.entries) {
        out.update(k.key, (o) => o + k.value, ifAbsent: () => k.value);
      }
    }
    return out;
  }

  /// [count] buckets ending with the one holding [today], oldest first.
  List<Bucket> buckets(Granularity g, String today, int count) {
    final out = <Bucket>[];
    var start = switch (g) {
      Granularity.day => today,
      Granularity.week => mondayOf(today),
      Granularity.month => monthStart(today),
    };
    for (var i = 0; i < count; i++) {
      final end = switch (g) {
        Granularity.day => start,
        Granularity.week => addDays(start, 6),
        Granularity.month => monthEnd(start),
      };
      out.add(Bucket(start, end, range(start, end), byKind: kindsIn(start, end)));
      start = switch (g) {
        Granularity.day => addDays(start, -1),
        Granularity.week => addDays(start, -7),
        Granularity.month => addMonths(start, -1),
      };
    }
    return out.reversed.toList();
  }

  /// The busiest day in a range, or null when nothing moved.
  ({String day, Traffic traffic})? peak(String from, String to) {
    ({String day, Traffic traffic})? best;
    for (final e in _byDay.entries) {
      if (e.key.compareTo(from) < 0 || e.key.compareTo(to) > 0) continue;
      if (best == null || e.value.total > best.traffic.total) best = (day: e.key, traffic: e.value);
    }
    return best;
  }

  /// Average per day over the [days] days before [today] (today left out,
  /// as it is not over), counting only days since the first record.
  double dailyAverage(String today, int days) {
    final first = firstDay;
    if (first == null) return 0;
    var from = addDays(today, -days);
    if (from.compareTo(first) < 0) from = first;
    final to = addDays(today, -1);
    if (to.compareTo(from) < 0) return 0;
    return range(from, to).total / (daysBetween(from, to) + 1);
  }
}

/// The figures the Usage page leads with.
class UsageSummary {
  UsageSummary(UsageIndex index, this.today)
    : todayTraffic = index.day(today),
      yesterday = index.day(addDays(today, -1)),
      week = index.range(mondayOf(today), today),
      month = index.range(monthStart(today), today),
      // The same stretch of last month, for a fair comparison.
      lastMonthToDate = index.range(addMonths(monthStart(today), -1), _sameDayLastMonth(today)),
      average30 = index.dailyAverage(today, 30),
      peak30 = index.peak(addDays(today, -29), today);

  final String today;
  final Traffic todayTraffic;
  final Traffic yesterday;
  final Traffic week;
  final Traffic month;
  final Traffic lastMonthToDate;
  final double average30;
  final ({String day, Traffic traffic})? peak30;

  /// This month against the same days of last month: +0.25 is 25% more;
  /// null when last month had nothing to compare with.
  double? get monthChange => lastMonthToDate.total == 0 ? null : month.total / lastMonthToDate.total - 1;

  /// A whole month at this month's pace.
  int get monthProjection {
    final day = int.parse(today.substring(8));
    final length = int.parse(monthEnd(today).substring(8));
    return (month.total / day * length).round();
  }
}

String _sameDayLastMonth(String day) {
  final start = addMonths(monthStart(day), -1);
  final want = int.parse(day.substring(8));
  final last = int.parse(monthEnd(start).substring(8));
  return '${start.substring(0, 8)}${math.min(want, last).toString().padLeft(2, '0')}';
}

// ---- data plans ----

/// The allowance period [day] falls in for a plan renewing on [cycleDay].
({String start, String end}) cycleOf(String day, int cycleDay) {
  final c = cycleDay.clamp(1, 28);
  final dayOfMonth = int.parse(day.substring(8));
  var start = '${day.substring(0, 8)}${c.toString().padLeft(2, '0')}';
  if (dayOfMonth < c) start = addMonths(start, -1);
  return (start: start, end: addDays(addMonths(start, 1), -1));
}

enum PlanState { fine, onTrackToExceed, warning, over }

/// Where a plan stands on [today].
class PlanStatus {
  PlanStatus(this.plan, Iterable<DayUsage> rows, this.today)
    : cycle = cycleOf(today, plan.cycleDay),
      used = UsageIndex(
        rows,
        filter: UsageFilter(
          devices: plan.device.isEmpty ? const {} : {plan.device},
          kinds: plan.kinds == 'all' ? const {} : {plan.kinds},
        ),
      ).range(cycleOf(today, plan.cycleDay).start, today).total;

  final DataPlan plan;
  final String today;
  final ({String start, String end}) cycle;
  final int used;

  int get daysTotal => daysBetween(cycle.start, cycle.end) + 1;
  int get daysElapsed => daysBetween(cycle.start, today) + 1;
  int get daysLeft => daysTotal - daysElapsed;
  int get left => math.max(0, plan.capBytes - used);
  double get share => plan.capBytes <= 0 ? 0 : used / plan.capBytes;

  /// The whole period at the pace so far.
  int get projected => (used / daysElapsed * daysTotal).round();

  /// What can be used each remaining day (today included) to stay inside.
  int get dailyBudget => (left / math.max(1, daysLeft + 1)).floor();

  PlanState get state {
    if (used >= plan.capBytes) return PlanState.over;
    if (share * 100 >= plan.warnPercent) return PlanState.warning;
    // A pace read off the first two days says little.
    if (daysElapsed >= 3 && projected > plan.capBytes) return PlanState.onTrackToExceed;
    return PlanState.fine;
  }
}
