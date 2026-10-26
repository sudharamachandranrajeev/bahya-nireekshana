import 'dart:convert';

import 'package:brahma_core/brahma_core.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';

/// Synced preferences. The prefs table is shared by every Brahma app, so
/// Bahya Nireekshana's keys start with its id.
abstract final class PrefKeys {
  /// Alert when today's usage is this many times the 30-day average.
  static const spikeFactor = 'nireekshana.alerts.spike';
}

/// Settings that stay on this device.
abstract final class LocalKeys {
  static const theme = 'nireekshana.theme';
  static const mode = 'nireekshana.mode';
  static const updateOnStart = 'nireekshana.update.on_start';

  /// The last counters the recorder saw, so usage while the app was closed
  /// is not lost (see Recorder).
  static const lastSample = 'nireekshana.recorder.last';
}

/// One day's usage on one kind of network, ready to write.
typedef DayCount = ({String day, String kind, int rx, int tx});

/// The write path and the reads the screens share.
class NetBook {
  NetBook(this.store, {this.deviceName = ''});
  final Store store;

  /// This device's name, written next to its usage so other devices can
  /// show it.
  final String deviceName;

  AppDatabase get db => store.db as AppDatabase;
  String get device => store.deviceId;

  Future<T> pref<T>(String key, T fallback) async {
    final row = await (db.select(db.prefs)..where((p) => p.id.equals(key))).getSingleOrNull();
    if (row == null || row.deleted) return fallback;
    final v = jsonDecode(row.value);
    return v is T ? v : fallback;
  }

  Future<void> setPref(String key, Object value) => store.save(
    db.prefs,
    PrefsCompanion.insert(id: key, value: jsonEncode(value), deleted: const Value(false)),
    key,
  );

  Future<bool> updateOnStart() async => await db.localSetting(LocalKeys.updateOnStart) != 'off';

  Future<void> setUpdateOnStart(bool on) => db.setLocalSetting(LocalKeys.updateOnStart, on ? 'on' : 'off');

  // ---- usage ----

  String _dayId(String day, String kind) => '$device|$day|$kind';

  /// Adds bytes this device moved (the recorder's counts).
  Future<void> addUsage(Map<String, Map<String, ({int rx, int tx})>> byDay) async {
    if (byDay.isEmpty) return;
    await db.transaction(() async {
      for (final day in byDay.entries) {
        for (final k in day.value.entries) {
          if (k.value.rx == 0 && k.value.tx == 0) continue;
          final id = _dayId(day.key, k.key);
          final had = await (db.select(db.nirDays)..where((d) => d.id.equals(id))).getSingleOrNull();
          await store.save(
            db.nirDays,
            DayUsage(
              id: id,
              hlc: '',
              deleted: false,
              device: device,
              deviceName: deviceName,
              day: day.key,
              kind: k.key,
              rx: (had == null || had.deleted ? 0 : had.rx) + k.value.rx,
              tx: (had == null || had.deleted ? 0 : had.tx) + k.value.tx,
              source: had?.source ?? 'recorder',
            ),
            id,
          );
        }
      }
    });
  }

  /// Replaces this device's days with a system source's totals (vnstat, or
  /// Android's statistics). Only rows that changed are written, so a
  /// repeated import sends nothing to sync. Returns how many changed.
  Future<int> importUsage(List<DayCount> counts, String source) async {
    var changed = 0;
    await db.transaction(() async {
      for (final c in counts) {
        final id = _dayId(c.day, c.kind);
        final had = await (db.select(db.nirDays)..where((d) => d.id.equals(id))).getSingleOrNull();
        if (had != null && !had.deleted && had.rx == c.rx && had.tx == c.tx && had.source == source) continue;
        if (had == null && c.rx == 0 && c.tx == 0) continue;
        await store.save(
          db.nirDays,
          DayUsage(
            id: id,
            hlc: '',
            deleted: false,
            device: device,
            deviceName: deviceName,
            day: c.day,
            kind: c.kind,
            rx: c.rx,
            tx: c.tx,
            source: source,
          ),
          id,
        );
        changed++;
      }
    });
    return changed;
  }

  /// Every device's usage from [from] on (inclusive).
  Future<List<DayUsage>> usageSince(String from) =>
      (db.select(db.nirDays)..where((d) => d.deleted.not() & d.day.isBiggerOrEqualValue(from))).get();

  /// Forgets a device's usage on this account (an old phone, say).
  Future<void> forgetDevice(String deviceId) async {
    final rows = await (db.select(
      db.nirDays,
    )..where((d) => d.device.equals(deviceId) & d.deleted.not())).get();
    await db.transaction(() async {
      for (final r in rows) {
        await store.remove(db.nirDays, r.id);
      }
    });
  }

  // ---- plans ----

  Future<List<DataPlan>> plans() =>
      (db.select(db.nirPlans)
            ..where((p) => p.deleted.not())
            ..orderBy([(p) => OrderingTerm.asc(p.created)]))
          .get();

  Future<void> savePlan({
    String? id,
    required String name,
    required int capBytes,
    required int cycleDay,
    required String kinds,
    required String device,
    required int warnPercent,
  }) {
    final key = id ?? newId();
    return store.save(
      db.nirPlans,
      NirPlansCompanion.insert(
        id: key,
        name: name,
        capBytes: capBytes,
        cycleDay: Value(cycleDay.clamp(1, 28)),
        kinds: Value(kinds),
        device: Value(device),
        warnPercent: Value(warnPercent.clamp(1, 100)),
        created: today(),
        deleted: const Value(false),
      ),
      key,
    );
  }

  Future<void> removePlan(String id) => store.remove(db.nirPlans, id);

  // ---- speed tests ----

  Future<void> addSpeedTest({
    required DateTime at,
    required int down,
    required int up,
    required double latency,
    required double jitter,
    required String kind,
    required String server,
  }) {
    final id = newId();
    return store.save(
      db.nirSpeedTests,
      NirSpeedTestsCompanion.insert(
        id: id,
        device: device,
        deviceName: Value(deviceName),
        at: at.toUtc().toIso8601String(),
        down: down,
        up: up,
        latency: latency,
        jitter: Value(jitter),
        kind: Value(kind),
        server: Value(server),
      ),
      id,
    );
  }

  Future<List<SpeedTest>> speedTests() =>
      (db.select(db.nirSpeedTests)
            ..where((t) => t.deleted.not())
            ..orderBy([(t) => OrderingTerm.desc(t.at)]))
          .get();

  Future<void> removeSpeedTest(String id) => store.remove(db.nirSpeedTests, id);

  // ---- themes ----

  Future<List<ThemeRow>> themes() =>
      (db.select(db.nirThemes)
            ..where((t) => t.deleted.not())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<void> saveTheme(String id, String name, String json) => store.save(
    db.nirThemes,
    NirThemesCompanion.insert(
      id: id,
      name: name,
      json: json,
      updated: DateTime.now().toUtc().toIso8601String(),
      deleted: const Value(false),
    ),
    id,
  );

  Future<void> removeTheme(String id) => store.remove(db.nirThemes, id);
}
