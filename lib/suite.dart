import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/live.dart';
import 'app/providers.dart';
import 'app/session.dart';
import 'domain/bytes.dart';
import 'ui/hints.dart';
import 'ui/look.dart';

/// Bahya Nireekshana as the Brahma suite app hosts it. The suite updates
/// itself, so the app's own updater stays off.
final nireekshanaSuite = SuiteApp(
  identity: nireekshanaIdentity,
  tagline: 'Network monitor',
  icon: Icons.radar,
  open: AppSession.open,
  overrides: (s) => [sessionProvider.overrideWithValue(s as AppSession)],
  hints: nireekshanaHints,
  theme: chosenTheme,
  themeMode: chosenMode,
  home: (onHome) => NireekshanaHome(onHome: onHome),
  builder: (context, child) => Backdrop(child: child ?? const SizedBox.shrink()),
  summary: (_) => const _Summary(),
  onStart: (ref) => Future.microtask(() => ref.read(liveProvider)).ignore(),
);

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(summaryProvider).value;
    final live = ref.watch(liveProvider);
    final plans = ref.watch(planStatusProvider).value ?? const [];
    if (s == null) return const SizedBox(height: 48);
    return SummaryFigures([
      ('↓ ${speed(live.rates.rx)}', 'now'),
      (bytes(s.todayTraffic.total), 'today'),
      if (plans.isNotEmpty)
        (bytes(plans.first.left), 'left of ${plans.first.plan.name}')
      else
        (bytes(s.month.total), 'this month'),
    ]);
  }
}
