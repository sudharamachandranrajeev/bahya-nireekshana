import 'dart:async';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/counters.dart';
import '../domain/recorder.dart';
import 'providers.dart';

/// How many readings the live chart keeps: two minutes at one a second.
const livePoints = 120;

/// Where today's history comes from on this device.
enum HistorySource {
  /// Not known yet (the first look has not finished).
  checking,

  /// A system record (vnstat, Android's statistics) is imported.
  system,

  /// The app counts while it is open.
  recorder,

  /// Nothing to read on this platform.
  none,
}

/// Whether this device's usage per app can be read.
enum AppsStatus {
  checking,

  /// Imported from the system's record.
  ready,

  /// There is a record, but it needs setting up or allowing first.
  needsSetup,

  /// This platform keeps none.
  none,
}

class LiveState {
  const LiveState({
    this.sample,
    this.rates = Rates.zero,
    this.points = const [],
    this.history = HistorySource.checking,
    this.imported,
    this.error,
    this.apps = AppsStatus.checking,
    this.appsError,
  });

  final Sample? sample;
  final Rates rates;

  /// Bytes per second in and out, oldest first, at most [livePoints].
  final List<({double rx, double tx})> points;
  final HistorySource history;

  /// When the system record was last imported.
  final DateTime? imported;
  final Object? error;
  final AppsStatus apps;

  /// Why the last per-app import failed, if it did.
  final String? appsError;

  LiveState copyWith({
    Sample? sample,
    Rates? rates,
    List<({double rx, double tx})>? points,
    HistorySource? history,
    DateTime? imported,
    Object? error,
    bool clearError = false,
    AppsStatus? apps,
    String? appsError,
    bool clearAppsError = false,
  }) => LiveState(
    sample: sample ?? this.sample,
    rates: rates ?? this.rates,
    points: points ?? this.points,
    history: history ?? this.history,
    imported: imported ?? this.imported,
    error: clearError ? null : (error ?? this.error),
    apps: apps ?? this.apps,
    appsError: clearAppsError ? null : (appsError ?? this.appsError),
  );
}

/// Reads the counters every second while the app runs, and keeps the usage
/// history: it imports the system record every few minutes where there is
/// one, and otherwise counts with the [Recorder], writing once a minute.
/// Each app's usage is imported on the same rhythm, where the system keeps it.
class LiveMonitor extends Notifier<LiveState> {
  Timer? _timer;
  Recorder? _recorder;
  DateTime? _lastFlush;
  DateTime? _lastImport;
  DateTime? _lastAppsImport;
  bool _busy = false;
  bool _appsBusy = false;
  bool _appsHistory = false;

  static const flushEvery = Duration(minutes: 1);
  static const importEvery = Duration(minutes: 5);

  @override
  LiveState build() {
    final probe = ref.watch(probeProvider);
    // Back from the system settings, usage access may have been granted.
    final lifecycle = AppLifecycleListener(
      onResume: () {
        final waiting =
            (state.history == HistorySource.recorder && ref.read(usageSourceProvider) != null) ||
            state.apps == AppsStatus.needsSetup;
        if (waiting) recheck().ignore();
      },
    );
    ref.onDispose(() {
      lifecycle.dispose();
      _timer?.cancel();
      _recorder?.flush().ignore();
    });
    final apps = ref.read(appSourceProvider) == null ? AppsStatus.none : AppsStatus.checking;
    if (probe == null) return LiveState(history: HistorySource.none, apps: apps);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    Future.microtask(_tick);
    return LiveState(apps: apps);
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final s = await ref.read(probeProvider)!.sample();
      final before = state.sample;
      final rates = before == null ? Rates.zero : Rates.between(before, s);
      final points = before == null
          ? state.points
          : [...state.points.skip(state.points.length >= livePoints ? 1 : 0), (rx: rates.rx, tx: rates.tx)];
      state = state.copyWith(sample: s, rates: rates, points: points, clearError: true);
      await _keepHistory(s);
    } catch (e) {
      debugPrint('Bahya Nireekshana: reading counters failed: $e');
      state = state.copyWith(error: e);
    } finally {
      _busy = false;
    }
  }

  Future<void> _keepHistory(Sample s) async {
    final book = ref.read(sessionProvider).book;
    // Timed by the readings, which carry the time they were taken.
    final now = s.at;
    _importApps(now).ignore();
    _lastFlush ??= now;
    if (_recorder == null) {
      _recorder = Recorder(book);
      await _recorder!.start(s);
    } else {
      _recorder!.take(s);
    }
    final source = ref.read(usageSourceProvider);
    final importDue = _lastImport == null || now.difference(_lastImport!) >= importEvery;
    if (source != null && importDue && state.history != HistorySource.recorder) {
      _lastImport = now;
      try {
        if (await source.available()) {
          final changed = await book.importUsage(await source.read(), source.id);
          // The system record covers what the recorder held.
          await _recorder!.discard();
          state = state.copyWith(history: HistorySource.system, imported: now);
          if (changed > 0) _changed();
          return;
        }
      } catch (e) {
        debugPrint('Bahya Nireekshana: ${source.title} import failed: $e');
      }
      state = state.copyWith(history: HistorySource.recorder);
    } else if (source == null && state.history == HistorySource.checking) {
      state = state.copyWith(history: HistorySource.recorder);
    }
    if (state.history == HistorySource.system) {
      if (_recorder!.hasPending) await _recorder!.discard();
      return;
    }
    if (now.difference(_lastFlush!) >= flushEvery) {
      _lastFlush = now;
      final had = _recorder!.hasPending;
      await _recorder!.flush();
      if (had) _changed();
    }
  }

  /// Imports each app's usage: a month the first time, then the last two
  /// days (today's grows, and yesterday's settles after midnight). Runs
  /// beside the readings, since Windows can take a while to answer.
  Future<void> _importApps(DateTime now) async {
    final source = ref.read(appSourceProvider);
    if (source == null || _appsBusy) return;
    if (_lastAppsImport != null && now.difference(_lastAppsImport!) < importEvery) return;
    _appsBusy = true;
    _lastAppsImport = now;
    try {
      if (!await source.available()) {
        _appsHistory = false;
        if (ref.mounted) state = state.copyWith(apps: AppsStatus.needsSetup, clearAppsError: true);
        return;
      }
      final rows = await source.read(days: _appsHistory ? 2 : 31);
      if (!ref.mounted) return;
      final changed = await ref.read(sessionProvider).book.importApps(rows);
      _appsHistory = true;
      if (!ref.mounted) return;
      state = state.copyWith(apps: AppsStatus.ready, clearAppsError: true);
      if (changed > 0) _changed();
    } catch (e) {
      debugPrint('Bahya Nireekshana: ${source.title} import failed: $e');
      if (ref.mounted) state = state.copyWith(apps: AppsStatus.needsSetup, appsError: '$e');
    } finally {
      _appsBusy = false;
    }
  }

  /// Looks at the system records again (after usage access is granted, say).
  Future<void> recheck() async {
    _lastImport = null;
    _lastAppsImport = null;
    state = state.copyWith(history: HistorySource.checking);
    await _tick();
  }

  void _changed() {
    ref.read(revisionProvider.notifier).bump();
    ref.read(syncProvider.notifier).soon();
  }
}

final liveProvider = NotifierProvider<LiveMonitor, LiveState>(LiveMonitor.new);
