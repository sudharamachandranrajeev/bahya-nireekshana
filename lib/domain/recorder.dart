import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' show addDays, daysBetween, isoDate;

import 'book.dart';
import 'counters.dart';

/// Usage waiting to be written: day → kind → bytes.
typedef Pending = Map<String, Map<String, ({int rx, int tx})>>;

void addTo(Pending pending, String day, Map<String, ({int rx, int tx})> usage) {
  final d = pending.putIfAbsent(day, () => {});
  for (final e in usage.entries) {
    final had = d[e.key] ?? (rx: 0, tx: 0);
    d[e.key] = (rx: had.rx + e.value.rx, tx: had.tx + e.value.tx);
  }
}

/// Usage that happened while the app was closed, between two readings of
/// the same boot. The counters say how much, not when, so it is spread
/// evenly over the days in between (each day gets its share; the last day
/// any remainder).
Pending spreadUsage(Map<String, ({int rx, int tx})> usage, DateTime from, DateTime to) {
  final first = isoDate(from), last = isoDate(to);
  final days = daysBetween(first, last) + 1;
  final out = <String, Map<String, ({int rx, int tx})>>{};
  for (var i = 0; i < days; i++) {
    final day = addDays(first, i);
    final share = <String, ({int rx, int tx})>{};
    for (final e in usage.entries) {
      final rx = e.value.rx ~/ days, tx = e.value.tx ~/ days;
      share[e.key] = i == days - 1
          ? (rx: e.value.rx - rx * (days - 1), tx: e.value.tx - tx * (days - 1))
          : (rx: rx, tx: tx);
    }
    out[day] = share;
  }
  return out;
}

/// A reading saved between runs (LocalKeys.lastSample).
String encodeSample(Sample s) => jsonEncode({
  'at': s.at.toUtc().toIso8601String(),
  'boot': s.boot,
  'ifaces': [
    for (final i in s.ifaces) {'n': i.name, 'k': i.kind, 'rx': i.rx, 'tx': i.tx},
  ],
});

Sample? decodeSample(String? text) {
  if (text == null || text.isEmpty) return null;
  try {
    final m = jsonDecode(text) as Map<String, Object?>;
    return Sample(DateTime.parse(m['at']! as String).toLocal(), [
      for (final i in m['ifaces']! as List)
        Iface(
          name: (i as Map)['n'] as String,
          kind: i['k'] as String,
          rx: (i['rx'] as num).toInt(),
          tx: (i['tx'] as num).toInt(),
        ),
    ], boot: m['boot'] as String? ?? '');
  } on Object {
    return null;
  }
}

/// Counts this device's usage from its interface counters while the app
/// runs, for devices with no system record to import (Windows; Linux
/// without vnstat; Android without usage access).
///
/// Feed it every reading ([take]); it splits usage at midnight by the
/// reading's time. [flush] writes what it holds and remembers the last
/// reading, so the next start can add what moved while the app was closed.
class Recorder {
  Recorder(this.book);
  final NetBook book;

  Sample? _last;
  final Pending _pending = {};

  bool get hasPending => _pending.isNotEmpty;

  /// The first reading of a run: picks up from the reading saved last time
  /// when it belongs to the same boot.
  Future<void> start(Sample first) async {
    final saved = decodeSample(await book.db.localSetting(LocalKeys.lastSample));
    if (saved != null && saved.boot.isNotEmpty && saved.boot == first.boot && saved.at.isBefore(first.at)) {
      final gap = usageBetween(saved, first);
      if (gap.isNotEmpty) {
        for (final e in spreadUsage(gap, saved.at, first.at).entries) {
          addTo(_pending, e.key, e.value);
        }
      }
    }
    _last = first;
  }

  void take(Sample s) {
    final last = _last;
    _last = s;
    if (last == null) return;
    final usage = usageBetween(last, s);
    if (usage.isNotEmpty) addTo(_pending, isoDate(s.at), usage);
  }

  Future<void> flush() async {
    final last = _last;
    if (_pending.isNotEmpty) {
      final batch = {for (final e in _pending.entries) e.key: Map.of(e.value)};
      _pending.clear();
      await book.addUsage(batch);
    }
    if (last != null) await book.db.setLocalSetting(LocalKeys.lastSample, encodeSample(last));
  }

  /// Drops what is held (a system record covers it) but keeps the place.
  Future<void> discard() async {
    _pending.clear();
    final last = _last;
    if (last != null) await book.db.setLocalSetting(LocalKeys.lastSample, encodeSample(last));
  }
}
