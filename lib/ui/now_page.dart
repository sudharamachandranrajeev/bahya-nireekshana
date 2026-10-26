import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/live.dart';
import '../app/providers.dart';
import '../domain/bytes.dart';
import '../domain/counters.dart';
import '../domain/history.dart';
import '../domain/insights.dart';
import '../domain/sources.dart';
import 'common.dart';
import 'look.dart';

class NowPage extends ConsumerWidget {
  const NowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveProvider);
    return PageScaffold(
      title: 'Now',
      banner: 'page.now',
      children: [
        if (live.history == HistorySource.none)
          const EmptyState(
            icon: Icons.sensors_off_outlined,
            title: 'No network counters here',
            message: 'This platform does not let Bahya Nireekshana read the network. Synced devices still show below.',
          )
        else
          _LiveCard(live),
        const _Today(),
        const _Insights(),
        if (live.sample case final s? when s.ifaces.isNotEmpty) _Interfaces(s, live.rates),
        _HistoryCard(live),
      ],
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard(this.live);
  final LiveState live;

  @override
  Widget build(BuildContext context) {
    final net = NetColors.of(context);
    final wide = MediaQuery.sizeOf(context).width > 560;
    final gauge = wide ? 190.0 : 150.0;
    return SectionCard(
      title: 'Live',
      trailing: live.error == null
          ? null
          : Tooltip(
              message: describeError(live.error!),
              child: const Icon(Icons.error_outline, color: StatusColors.critical),
            ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              SpeedGauge(
                label: 'Download',
                icon: Icons.south,
                value: live.rates.rx * 8,
                text: speed(live.rates.rx),
                color: net.download,
                size: gauge,
              ),
              SpeedGauge(
                label: 'Upload',
                icon: Icons.north,
                value: live.rates.tx * 8,
                text: speed(live.rates.tx),
                color: net.upload,
                size: gauge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Speed over the last two minutes',
            child: LiveChart(points: live.points, capacity: livePoints, height: wide ? 180 : 140),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              LegendDot(net.download, 'Download'),
              LegendDot(net.upload, 'Upload'),
              Text(
                'Last 2 minutes',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Today extends ConsumerWidget {
  const _Today();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final plans = ref.watch(planStatusProvider).value ?? const [];
    return AsyncView(
      summary,
      onRetry: () => ref.invalidate(usageRowsProvider),
      builder: (s) => TileGrid(
        minWidth: 170,
        children: [
          KpiTile(
            label: 'Today',
            value: bytes(s.todayTraffic.total),
            icon: Icons.today_outlined,
            caption: '↓ ${bytes(s.todayTraffic.rx)} · ↑ ${bytes(s.todayTraffic.tx)}',
          ),
          KpiTile(
            label: 'Yesterday',
            value: bytes(s.yesterday.total),
            icon: Icons.history,
            caption: s.average30 > 0 ? '30-day average ${bytes(s.average30)}' : null,
          ),
          KpiTile(
            label: 'This month',
            value: bytes(s.month.total),
            icon: Icons.calendar_month_outlined,
            hint: 'usage.projection',
            caption: 'On pace for ${bytes(s.monthProjection)}',
          ),
          if (plans.isNotEmpty)
            KpiTile(
              label: plans.first.plan.name,
              value: '${bytes(plans.first.left)} left',
              icon: Icons.data_usage,
              caption: '${plans.first.daysLeft} days to go',
              status: switch (plans.first.state) {
                PlanState.over => (color: StatusColors.critical, icon: Icons.error_outline),
                PlanState.warning => (color: StatusColors.warning, icon: Icons.warning_amber_rounded),
                PlanState.onTrackToExceed => (color: StatusColors.serious, icon: Icons.trending_up),
                PlanState.fine => null,
              },
            ),
        ],
      ),
    );
  }
}

class _Insights extends ConsumerWidget {
  const _Insights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(insightsProvider).value ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Worth a look',
      child: Column(
        children: [
          for (final i in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch (i.level) {
                  InsightLevel.critical => Icons.error_outline,
                  InsightLevel.warning => Icons.warning_amber_rounded,
                  InsightLevel.info => Icons.info_outline,
                },
                color: switch (i.level) {
                  InsightLevel.critical => StatusColors.critical,
                  InsightLevel.warning => StatusColors.warning,
                  InsightLevel.info => Theme.of(context).colorScheme.primary,
                },
              ),
              title: Text(i.title),
              subtitle: Text(i.detail),
            ),
        ],
      ),
    );
  }
}

class _Interfaces extends StatelessWidget {
  const _Interfaces(this.sample, this.rates);
  final Sample sample;
  final Rates rates;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final net = NetColors.of(context);
    final list = [...sample.ifaces]..sort((a, b) => (b.rx + b.tx).compareTo(a.rx + a.tx));
    return SectionCard(
      title: 'Interfaces',
      child: Column(
        children: [
          for (final i in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(kindIcon(i.kind), color: i.up ? t.colorScheme.primary : t.disabledColor),
              title: Text(i.label.isEmpty ? i.name : i.label),
              subtitle: Text(
                [
                  if (i.label.isNotEmpty && i.label != i.name) i.name,
                  kindLabel(i.kind),
                  if (!i.counted) 'not counted',
                  if (!i.up) 'down',
                  '${bytes(i.rx + i.tx)} since start',
                ].join(' · '),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '↓ ${speed(rates.byIface[i.name]?.rx ?? 0)}',
                    style: t.textTheme.bodySmall?.merge(tabular).copyWith(color: net.download),
                  ),
                  Text(
                    '↑ ${speed(rates.byIface[i.name]?.tx ?? 0)}',
                    style: t.textTheme.bodySmall?.merge(tabular).copyWith(color: net.upload),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard(this.live);
  final LiveState live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(usageSourceProvider);
    final (text, action) = switch (live.history) {
      HistorySource.checking => ('Looking for this device’s usage record…', null),
      HistorySource.system => (
        'History comes from ${source?.title ?? 'the system'}, which counts even while this app is closed.',
        null,
      ),
      HistorySource.recorder when source is AndroidStatsSource => (
        'Bahya Nireekshana counts while it is open. Allow usage access to import Android’s own record, '
            'which counts all the time.',
        FilledButton.tonal(onPressed: source.requestAccess, child: const Text('Allow usage access')),
      ),
      HistorySource.recorder when source is VnstatSource => (
        'Bahya Nireekshana counts while it is open. Install vnstat (omarchy/install.sh does) to count all the '
            'time, including before the app was installed.',
        TextButton(
          onPressed: () => ref.read(liveProvider.notifier).recheck(),
          child: const Text('Check again'),
        ),
      ),
      HistorySource.recorder => ('Bahya Nireekshana counts this device’s usage while it is open.', null),
      HistorySource.none => (
        'This device keeps no usage record. Other devices’ history arrives by sync.',
        null,
      ),
    };
    return SectionCard(
      title: 'History on this device',
      hint: 'usage.source',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}
