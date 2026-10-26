import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;

import '../db/database.dart';
import '../domain/book.dart';
import '../domain/connections.dart';
import '../domain/firewall.dart';
import '../domain/history.dart';
import '../domain/insights.dart';
import '../domain/probe.dart';
import '../domain/sources.dart';
import '../domain/themes.dart';
import '../domain/update.dart';
import '../ui/hints.dart';
import 'session.dart';

/// The open session; main() overrides this before the first frame.
final sessionProvider = Provider<AppSession>((ref) => throw StateError('No session'));

/// HTTP for the speed test and updates; tests override it.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// This device's interface counters; null where the platform has none.
final probeProvider = Provider<NetProbe?>((ref) => NetProbe.forPlatform());

/// This device's system record of past usage (vnstat, Android's statistics).
final usageSourceProvider = Provider<UsageSource?>((ref) => UsageSource.forPlatform());

/// The OpenSnitch firewall; only Linux has it.
final firewallProvider = Provider<Firewall?>((ref) => Platform.isLinux ? const Firewall() : null);

/// The self-updater: main() sets it in a release build of the standalone app.
/// Null in the Brahma suite (which updates itself) and in tests.
final updaterProvider = Provider<Updater?>((ref) => null);

/// What main() and the tests override: the session, under both its own and
/// its shared type, and the app's identity and hints.
List<Override> nireekshanaOverrides(
  AppSession session, {
  http.Client? client,
  Updater? updater,
  List<NetTheme>? builtInThemes,
}) => [
  sessionProvider.overrideWithValue(session),
  coreSessionProvider.overrideWithValue(session),
  appIdentityProvider.overrideWithValue(nireekshanaIdentity),
  hintTextsProvider.overrideWithValue({...coreHints, ...nireekshanaHints}),
  sentinelChecksProvider.overrideWithValue([...coreChecks, lockCheck]),
  if (client != null) httpClientProvider.overrideWithValue(client),
  if (updater != null) ...[
    updaterProvider.overrideWithValue(updater),
    // The app offers its own updates, which install in place; core's
    // banner would only point at the releases page.
    startupUpdateProvider.overrideWith((ref) async => null),
  ],
  if (builtInThemes != null) builtInThemesProvider.overrideWith((ref) => builtInThemes),
];

extension Mutate on WidgetRef {
  /// Runs a write, refreshes the screens and queues a sync.
  Future<T> mutate<T>(Future<T> Function(AppSession s) write) async {
    final result = await write(read(sessionProvider));
    changed();
    return result;
  }
}

// ---- updates ----

/// Set when the user asks for an update check, so one runs even with the
/// start-up check turned off.
class UpdateAsked extends Notifier<bool> {
  @override
  bool build() => false;
  void ask() => state = true;
}

final updateAskedProvider = NotifierProvider<UpdateAsked, bool>(UpdateAsked.new);

/// A newer release for this device, looked for once a run (at start unless
/// the user turned that off in Settings); null when this is the newest,
/// there is no updater, or nobody asked.
final updateProvider = FutureProvider<Release?>((ref) async {
  final updater = ref.watch(updaterProvider);
  if (updater == null) return null;
  if (!ref.watch(updateAskedProvider) && !await ref.read(sessionProvider).book.updateOnStart()) return null;
  return updater.check();
});

final updateOnStartProvider = FutureProvider<bool>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.updateOnStart();
});

// ---- themes ----

/// Reads themes/builtin.json: under its own name in the standalone app,
/// under the package's in the Brahma suite.
Future<List<NetTheme>> loadBuiltInThemes() async {
  String text;
  try {
    text = await rootBundle.loadString('themes/builtin.json');
  } on Object {
    text = await rootBundle.loadString('packages/nireekshana/themes/builtin.json');
  }
  return parseBuiltInThemes(text);
}

final builtInThemesProvider = FutureProvider<List<NetTheme>>((ref) => loadBuiltInThemes());

/// The user's own themes (synced); rows that no longer parse are skipped.
final customThemesProvider = FutureProvider<List<NetTheme>>((ref) async {
  ref.watch(revisionProvider);
  final rows = await ref.watch(sessionProvider).book.themes();
  return [for (final r in rows) ?_tryTheme(r)];
});

NetTheme? _tryTheme(ThemeRow r) {
  try {
    return NetTheme.decode(r.json);
  } on FormatException {
    return null;
  }
}

/// The theme used before the list has loaded, and when the chosen one is
/// gone: Radar, the first built-in theme.
const fallbackTheme = NetTheme(
  id: 'radar',
  name: 'Radar',
  seed: Color(0xFF0FA3B1),
  accent: Color(0xFFFFB020),
  download: Color(0xFF1FB5E0),
  upload: Color(0xFFFF7A45),
  lightBackground: Color(0xFFF3F7F8),
  darkBackground: Color(0xFF0B1214),
  radius: 18,
  builtIn: true,
);

/// Every theme, built-in first.
final allThemesProvider = FutureProvider<List<NetTheme>>(
  (ref) async => [
    ...await ref.watch(builtInThemesProvider.future),
    ...await ref.watch(customThemesProvider.future),
  ],
);

class Appearance {
  const Appearance(this.theme, this.mode);
  final NetTheme theme;
  final ThemeMode mode;
}

/// The chosen theme and light/dark mode, kept on this device.
final appearanceProvider = FutureProvider<Appearance>((ref) async {
  ref.watch(revisionProvider);
  final db = ref.watch(sessionProvider).db;
  final id = await db.localSetting(LocalKeys.theme);
  final mode = switch (await db.localSetting(LocalKeys.mode)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  final themes = await ref.watch(allThemesProvider.future);
  return Appearance(themes.where((t) => t.id == id).firstOrNull ?? themes.firstOrNull ?? fallbackTheme, mode);
});

Future<void> chooseTheme(WidgetRef ref, String id) async {
  await ref.read(sessionProvider).db.setLocalSetting(LocalKeys.theme, id);
  ref.changed();
}

Future<void> chooseMode(WidgetRef ref, ThemeMode mode) async {
  await ref.read(sessionProvider).db.setLocalSetting(LocalKeys.mode, mode.name);
  ref.changed();
}

// ---- usage ----

/// Every device's day rows for the last 13 months.
final usageRowsProvider = FutureProvider<List<DayUsage>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.usageSince(addMonths(monthStart(ref.watch(todayProvider)), -13));
});

class UsageFilterState extends Notifier<UsageFilter> {
  @override
  UsageFilter build() => const UsageFilter();
  void set(UsageFilter f) => state = f;
}

/// The Usage page's choice of devices and kinds of network.
final usageFilterProvider = NotifierProvider<UsageFilterState, UsageFilter>(UsageFilterState.new);

/// The rows the Usage page shows, filtered.
final usageIndexProvider = FutureProvider<UsageIndex>(
  (ref) async =>
      UsageIndex(await ref.watch(usageRowsProvider.future), filter: ref.watch(usageFilterProvider)),
);

/// Every row, unfiltered: what the Now page, plans and alerts count.
final allUsageProvider = FutureProvider<UsageIndex>(
  (ref) async => UsageIndex(await ref.watch(usageRowsProvider.future)),
);

final summaryProvider = FutureProvider<UsageSummary>(
  (ref) async => UsageSummary(await ref.watch(allUsageProvider.future), ref.watch(todayProvider)),
);

final plansProvider = FutureProvider<List<DataPlan>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.plans();
});

final planStatusProvider = FutureProvider<List<PlanStatus>>((ref) async {
  final rows = await ref.watch(usageRowsProvider.future);
  final today = ref.watch(todayProvider);
  return [for (final p in await ref.watch(plansProvider.future)) PlanStatus(p, rows, today)];
});

final spikeFactorProvider = FutureProvider<double>((ref) async {
  ref.watch(revisionProvider);
  final v = await ref.watch(sessionProvider).book.pref<num>(PrefKeys.spikeFactor, 3);
  return v.toDouble();
});

final insightsProvider = FutureProvider<List<Insight>>(
  (ref) async => insightsFor(
    summary: await ref.watch(summaryProvider.future),
    plans: await ref.watch(planStatusProvider.future),
    spikeFactor: await ref.watch(spikeFactorProvider.future),
  ),
);

// ---- speed tests, connections, firewall ----

final speedTestsProvider = FutureProvider<List<SpeedTest>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.speedTests();
});

/// Open connections, read when the Connections page asks.
final connectionsProvider = FutureProvider.autoDispose<List<Connection>>((ref) => readConnections());

final firewallStatusProvider = FutureProvider.autoDispose<FirewallStatus?>((ref) async {
  final f = ref.watch(firewallProvider);
  return f?.status();
});

final rulesProvider = FutureProvider.autoDispose<({List<RuleItem> items, String generated})>((ref) {
  final f = ref.watch(firewallProvider);
  if (f == null) throw FirewallException('Only Linux has the firewall.');
  return f.rules();
});
