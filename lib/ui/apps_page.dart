import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/live.dart';
import '../app/providers.dart';
import '../domain/app_sources.dart';
import '../domain/app_stats.dart';
import '../domain/bytes.dart';
import '../domain/counters.dart';
import '../domain/history.dart';
import '../domain/sources.dart';
import 'common.dart';
import 'look.dart';

/// How many apps the list shows before "Show all".
const _shortList = 25;

/// Apps drawn in their own colour in the breakdown; the rest are summed.
const _ringApps = 5;

class AppsPage extends ConsumerStatefulWidget {
  const AppsPage({super.key});

  @override
  ConsumerState<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends ConsumerState<AppsPage> {
  final _search = TextEditingController();
  bool _all = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(appsReportProvider);
    final status = ref.watch(liveProvider.select((l) => (l.apps, l.appsError)));
    return PageScaffold(
      title: 'Apps',
      banner: 'page.apps',
      children: [
        if (status.$1 == AppsStatus.needsSetup || status.$2 != null) _SourceCard(status.$1, status.$2),
        AsyncView(
          report,
          onRetry: () => ref.invalidate(appRowsProvider),
          builder: (r) {
            if (r.isEmpty && r.devices.isEmpty) {
              return EmptyState(
                icon: Icons.apps,
                title: 'No usage per app yet',
                message: status.$1 == AppsStatus.none
                    ? 'This device keeps no record of each app’s usage. Devices that do, and sync with this '
                          'one, show theirs here.'
                    : 'Each app’s usage appears here once the system’s record has been read.',
              );
            }
            final query = _search.text.trim().toLowerCase();
            final listed = query.isEmpty
                ? r.apps
                : r.apps.where(
                    (a) => a.name.toLowerCase().contains(query) || a.app.toLowerCase().contains(query),
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Controls(r),
                if (r.isEmpty)
                  const EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'Nothing in this period',
                    message: 'No app used the network in this period with these filters.',
                  )
                else ...[
                  _Figures(r),
                  _Breakdown(r),
                  SectionCard(
                    title: 'Every app',
                    hint: 'apps.list',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (r.apps.length > 8) ...[
                          TextField(
                            controller: _search,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Find an app',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                        ],
                        for (final a in _all || query.isNotEmpty ? listed : listed.take(_shortList))
                          _AppRow(a, rank: r.apps.indexOf(a), total: r.total.total),
                        if (!_all && query.isEmpty && r.apps.length > _shortList)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => setState(() => _all = true),
                              child: Text('Show all ${r.apps.length}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Why this device's apps are missing, and what to do about it.
class _SourceCard extends ConsumerWidget {
  const _SourceCard(this.status, this.error);
  final AppsStatus status;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(appSourceProvider);
    final recheck = TextButton(
      onPressed: () => ref.read(liveProvider.notifier).recheck(),
      child: const Text('Check again'),
    );
    final (String text, List<Widget> actions) = switch (source) {
      AndroidAppSource() when error == null => (
        'Allow usage access to see how much data each app on this phone uses, on Wi-Fi and mobile data, '
            'in the foreground and background.',
        [
          FilledButton.tonal(
            onPressed: AndroidStatsSource().requestAccess,
            child: const Text('Allow usage access'),
          ),
        ],
      ),
      LinuxAppSource() when error == null => (
        'Usage per app on Linux comes from the nireekshana-apps service, which counts with nethogs. Set it up '
            'once from the repository: sudo omarchy/install.sh',
        [
          TextButton.icon(
            onPressed: () => copyText(context, 'sudo omarchy/install.sh', what: 'Command copied.'),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy command'),
          ),
          recheck,
        ],
      ),
      _ => (error ?? 'This device’s usage per app could not be read.', [recheck]),
    };
    return SectionCard(
      title: 'Apps on this device',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls(this.r);
  final AppsReport r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(appsViewProvider);
    final set = ref.read(appsViewProvider.notifier).set;
    final f = view.filter;
    Set<String> toggle(Set<String> s, String v) => s.contains(v) ? ({...s}..remove(v)) : {...s, v};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<AppPeriod>(
              showSelectedIcon: false,
              segments: [for (final p in AppPeriod.values) ButtonSegment(value: p, label: Text(p.label))],
              selected: {view.period},
              onSelectionChanged: (s) => set(view.copyWith(period: s.first)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in usageKinds.where((k) => k != 'other'))
                FilterChip(
                  avatar: Icon(kindIcon(k), size: 18),
                  label: Text(kindLabel(k)),
                  selected: f.kinds.contains(k),
                  onSelected: (_) => set(view.copyWith(filter: f.copyWith(kinds: toggle(f.kinds, k)))),
                ),
              if (r.devices.length > 1)
                for (final d in r.devices.entries)
                  FilterChip(
                    avatar: const Icon(Icons.devices_outlined, size: 18),
                    label: Text(d.value.isEmpty ? 'Unnamed device' : d.value),
                    selected: f.devices.contains(d.key),
                    onSelected: (_) =>
                        set(view.copyWith(filter: f.copyWith(devices: toggle(f.devices, d.key)))),
                  ),
              if (f.kinds.isNotEmpty || f.devices.isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.clear, size: 18),
                  label: const Text('Everything'),
                  onPressed: () => set(view.copyWith(filter: const UsageFilter())),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _percent(double v) => '${(v * 100).round()}%';

String _change(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${(v * 100).round()}%';

class _Figures extends StatelessWidget {
  const _Figures(this.r);
  final AppsReport r;

  @override
  Widget build(BuildContext context) {
    final top = r.apps.first;
    final background = r.background;
    final fresh = r.newApps;
    return TileGrid(
      minWidth: 170,
      children: [
        KpiTile(
          label: 'All apps',
          value: bytes(r.total.total),
          icon: Icons.data_usage,
          caption: 'Before: ${bytes(r.previousTotal.total)} (${_change(r.change)})',
        ),
        KpiTile(
          label: 'Apps online',
          value: '${r.apps.length}',
          icon: Icons.apps,
          caption: fresh.isEmpty
              ? 'None new'
              : '${fresh.length} new: ${fresh.take(2).map((a) => a.name).join(', ')}',
        ),
        KpiTile(
          label: 'Top app',
          value: top.name,
          icon: Icons.emoji_events_outlined,
          caption: '${bytes(top.total)} · ${_percent(top.total / r.total.total)}',
        ),
        KpiTile(
          label: 'Top 3 share',
          value: _percent(r.topShare()),
          icon: Icons.pie_chart_outline,
          hint: 'apps.top',
          caption: 'Of all apps’ traffic',
        ),
        if (background != null)
          KpiTile(
            label: 'Background',
            value: _percent(background),
            icon: Icons.visibility_off_outlined,
            hint: 'apps.background',
            caption: 'While not on screen',
          ),
        KpiTile(
          label: 'Upload share',
          value: _percent(r.total.upShare),
          icon: Icons.north,
          caption: '${bytes(r.total.tx)} sent',
        ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown(this.r);
  final AppsReport r;

  @override
  Widget build(BuildContext context) {
    final split = r.topAndRest(_ringApps);
    final kinds = r.byKind.entries.where((e) => e.value.total > 0).toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final t = Theme.of(context);
    return SectionCard(
      title: 'Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShareRing(
            parts: [
              for (final (i, a) in split.top.indexed)
                (label: a.name, value: a.total, color: seriesColor(context, i)),
              if (split.rest > 0)
                (label: 'Other apps', value: split.rest, color: t.colorScheme.outlineVariant),
            ],
          ),
          if (kinds.length > 1) ...[
            const SizedBox(height: 16),
            Text('By network', style: t.textTheme.titleSmall),
            const SizedBox(height: 8),
            ShareRing(
              size: 96,
              parts: [
                for (final k in kinds)
                  (label: kindLabel(k.key), value: k.value.total, color: kindColor(context, k.key)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A round badge with the app's first letter.
class AppBadge extends StatelessWidget {
  const AppBadge(this.name, {super.key, this.color, this.size = 36});
  final String name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.outline;
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.18), shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: size * 0.42),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow(this.a, {required this.rank, required this.total});
  final AppStat a;
  final int rank;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final net = NetColors.of(context);
    final color = rank < _ringApps ? seriesColor(context, rank) : null;
    final change = a.change;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AppDetailPage(app: a.app, name: a.name),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            AppBadge(a.name, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(a.name, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
                      ),
                      Text(bytes(a.total), style: t.textTheme.titleSmall?.merge(tabular)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Meter(value: total == 0 ? 0 : a.total / total, color: color, height: 5),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (final k in a.byKind.keys) ...[
                        Icon(kindIcon(k), size: 14, color: t.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '↓ ${bytes(a.traffic.rx)}',
                                style: TextStyle(color: net.download),
                              ),
                              const TextSpan(text: '  '),
                              TextSpan(
                                text: '↑ ${bytes(a.traffic.tx)}',
                                style: TextStyle(color: net.upload),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.merge(tabular),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        change == null ? 'new' : _change(change),
                        style: t.textTheme.bodySmall
                            ?.merge(tabular)
                            .copyWith(color: t.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One app: its figures for the chosen period and its last 30 days.
class AppDetailPage extends ConsumerWidget {
  const AppDetailPage({super.key, required this.app, required this.name});
  final String app;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(appsReportProvider);
    final rows = ref.watch(appRowsProvider);
    final view = ref.watch(appsViewProvider);
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: AsyncView(
        report,
        builder: (r) {
          final s = r.find(app);
          final rank = s == null ? -1 : r.apps.indexOf(s);
          final daily = appDaily(
            rows.value ?? const [],
            app,
            from: addDays(today, -29),
            to: today,
            filter: view.filter,
          );
          final t = Theme.of(context);
          final net = NetColors.of(context);
          final shown = daily.fold(Traffic.zero, (sum, d) => sum + d.traffic);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppBadge(
                            name,
                            size: 48,
                            color: rank >= 0 && rank < _ringApps ? seriesColor(context, rank) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: t.textTheme.titleLarge),
                                SelectableText(
                                  app,
                                  style: t.textTheme.bodySmall?.copyWith(
                                    color: t.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (s == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('No usage in ${view.period.label.toLowerCase()} with these filters.'),
                        )
                      else
                        TileGrid(
                          minWidth: 170,
                          children: [
                            KpiTile(
                              label: view.period.label,
                              value: bytes(s.total),
                              icon: Icons.data_usage,
                              caption: 'Before: ${bytes(s.previous.total)} (${_change(s.change)})',
                            ),
                            KpiTile(
                              label: 'Rank',
                              value: '#${rank + 1}',
                              icon: Icons.leaderboard_outlined,
                              caption:
                                  '${_percent(r.total.total == 0 ? 0 : s.total / r.total.total)} of all apps',
                            ),
                            KpiTile(
                              label: 'Daily average',
                              value: bytes(s.activeDays == 0 ? 0 : s.total ~/ s.activeDays),
                              icon: Icons.av_timer,
                              caption: 'On ${s.activeDays} day${s.activeDays == 1 ? '' : 's'} it was online',
                            ),
                            if (s.peak case final p?)
                              KpiTile(
                                label: 'Busiest day',
                                value: bytes(p.value.total),
                                icon: Icons.local_fire_department_outlined,
                                caption: niceDate(p.key),
                              ),
                            KpiTile(
                              label: 'Upload share',
                              value: _percent(s.traffic.upShare),
                              icon: Icons.north,
                              caption: '↓ ${bytes(s.traffic.rx)} · ↑ ${bytes(s.traffic.tx)}',
                            ),
                            if (s.background case final b?)
                              KpiTile(
                                label: 'Background',
                                value: _percent(b),
                                icon: Icons.visibility_off_outlined,
                                hint: 'apps.background',
                                caption: '${bytes(s.fgKnown - s.fg)} off screen',
                              ),
                          ],
                        ),
                      SectionCard(
                        title: 'Last 30 days',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UsageBars(
                              values: [for (final d in daily) (rx: d.traffic.rx, tx: d.traffic.tx)],
                              labels: [for (final d in daily) shortDay(d.day)],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Total ${bytes(shown.total)}',
                                  style: t.textTheme.titleSmall?.merge(tabular),
                                ),
                                LegendDot(net.download, 'Download ${bytes(shown.rx)}'),
                                LegendDot(net.upload, 'Upload ${bytes(shown.tx)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (s != null && (s.byKind.length > 1 || s.byDevice.length > 1))
                        SectionCard(
                          title: 'Where it was used',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.byKind.length > 1)
                                ShareRing(
                                  size: 96,
                                  parts: [
                                    for (final k in s.byKind.entries)
                                      (
                                        label: kindLabel(k.key),
                                        value: k.value.total,
                                        color: kindColor(context, k.key),
                                      ),
                                  ],
                                ),
                              if (s.byDevice.length > 1) ...[
                                const SizedBox(height: 16),
                                for (final (i, d) in s.byDevice.entries.indexed)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(r.devices[d.key] ?? 'Unnamed device')),
                                            Text(bytes(d.value.total), style: tabular),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Meter(
                                          value: d.value.total / s.total,
                                          color: seriesColor(context, i + 4),
                                          height: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
