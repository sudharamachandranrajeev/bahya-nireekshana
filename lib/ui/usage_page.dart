import 'dart:convert';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/bytes.dart';
import '../domain/counters.dart';
import '../domain/history.dart';
import 'common.dart';
import 'look.dart';

/// How many bars each granularity shows.
const _bars = {Granularity.day: 30, Granularity.week: 12, Granularity.month: 12};

class UsagePage extends ConsumerStatefulWidget {
  const UsagePage({super.key});

  @override
  ConsumerState<UsagePage> createState() => _UsagePageState();
}

class _UsagePageState extends ConsumerState<UsagePage> {
  Granularity _g = Granularity.day;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(usageIndexProvider);
    final today = ref.watch(todayProvider);
    return PageScaffold(
      title: 'Usage',
      banner: 'page.usage',
      actions: [
        HintIconButton(
          'action.export',
          icon: Icons.download_outlined,
          label: 'Export CSV',
          onPressed: () => _export(context),
        ),
      ],
      children: [
        AsyncView(
          index,
          onRetry: () => ref.invalidate(usageRowsProvider),
          builder: (ix) {
            if (ix.isEmpty && ix.devices.isEmpty) {
              return const EmptyState(
                icon: Icons.bar_chart,
                title: 'No usage yet',
                message: 'Usage appears here as this device counts it. Devices that sync with this one add theirs.',
              );
            }
            final buckets = ix.buckets(_g, today, _bars[_g]!);
            final sel = _selected == null || _selected! >= buckets.length ? null : buckets[_selected!];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Filters(ix),
                _ChartCard(
                  g: _g,
                  buckets: buckets,
                  selected: _selected,
                  onGranularity: (g) => setState(() {
                    _g = g;
                    _selected = null;
                  }),
                  onSelect: (i) => setState(() => _selected = _selected == i ? null : i),
                ),
                _Figures(ix, today),
                _Breakdown(
                  ix,
                  from: sel?.start ?? buckets.first.start,
                  to: sel?.end ?? today,
                  title: sel == null ? 'Shown above' : _bucketTitle(_g, sel),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final rows = await ref.read(usageRowsProvider.future);
    final sorted = [...rows]
      ..sort((a, b) => a.day == b.day ? a.device.compareTo(b.device) : a.day.compareTo(b.day));
    String cell(String v) => v.contains(RegExp('[",\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
    final csv = StringBuffer('day,device,kind,download_bytes,upload_bytes,source\n');
    for (final r in sorted) {
      csv.writeln(
        [r.day, cell(r.deviceName.isEmpty ? r.device : r.deviceName), r.kind, r.rx, r.tx, r.source].join(','),
      );
    }
    if (!context.mounted) return;
    await saveBytes(
      context,
      'nireekshana-usage-${ref.read(todayProvider)}.csv',
      Uint8List.fromList(utf8.encode(csv.toString())),
      mime: 'text/csv',
    );
  }
}

String _bucketTitle(Granularity g, Bucket b) => switch (g) {
  Granularity.day => niceDate(b.start),
  Granularity.week => 'Week of ${shortDay(b.start)}',
  Granularity.month => monthLabel(b.start.substring(0, 7), year: true),
};

class _Filters extends ConsumerWidget {
  const _Filters(this.ix);
  final UsageIndex ix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(usageFilterProvider);
    final set = ref.read(usageFilterProvider.notifier).set;
    Set<String> toggle(Set<String> s, String v) => s.contains(v) ? ({...s}..remove(v)) : {...s, v};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in usageKinds)
            FilterChip(
              avatar: Icon(kindIcon(k), size: 18),
              label: Text(kindLabel(k)),
              selected: f.kinds.contains(k),
              onSelected: (_) => set(f.copyWith(kinds: toggle(f.kinds, k))),
            ),
          if (ix.devices.length > 1)
            for (final d in ix.devices.entries)
              FilterChip(
                avatar: const Icon(Icons.devices_outlined, size: 18),
                label: Text(d.value.isEmpty ? 'Unnamed device' : d.value),
                selected: f.devices.contains(d.key),
                onSelected: (_) => set(f.copyWith(devices: toggle(f.devices, d.key))),
              ),
          if (f.kinds.isNotEmpty || f.devices.isNotEmpty)
            ActionChip(
              avatar: const Icon(Icons.clear, size: 18),
              label: const Text('Everything'),
              onPressed: () => set(const UsageFilter()),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.g,
    required this.buckets,
    required this.selected,
    required this.onGranularity,
    required this.onSelect,
  });

  final Granularity g;
  final List<Bucket> buckets;
  final int? selected;
  final ValueChanged<Granularity> onGranularity;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final net = NetColors.of(context);
    final sel = selected == null || selected! >= buckets.length ? null : buckets[selected!];
    final shown = sel?.traffic ?? buckets.fold<Traffic>(Traffic.zero, (s, b) => s + b.traffic);
    return SectionCard(
      title: switch (g) {
        Granularity.day => 'Last 30 days',
        Granularity.week => 'Last 12 weeks',
        Granularity.month => 'Last 12 months',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<Granularity>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Granularity.day, label: Text('Days')),
                ButtonSegment(value: Granularity.week, label: Text('Weeks')),
                ButtonSegment(value: Granularity.month, label: Text('Months')),
              ],
              selected: {g},
              onSelectionChanged: (s) => onGranularity(s.first),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Usage chart, ${buckets.length} bars',
            child: UsageBars(
              values: [for (final b in buckets) (rx: b.traffic.rx, tx: b.traffic.tx)],
              labels: [
                for (final b in buckets)
                  switch (g) {
                    Granularity.month => shortMonth(b.start),
                    _ => shortDay(b.start),
                  },
              ],
              selected: selected,
              onSelect: onSelect,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                sel == null
                    ? 'Total ${bytes(shown.total)}'
                    : '${_bucketTitle(g, sel)}: ${bytes(shown.total)}',
                style: t.textTheme.titleSmall?.merge(tabular),
              ),
              LegendDot(net.download, 'Download ${bytes(shown.rx)}'),
              LegendDot(net.upload, 'Upload ${bytes(shown.tx)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures(this.ix, this.today);
  final UsageIndex ix;
  final String today;

  @override
  Widget build(BuildContext context) {
    final s = UsageSummary(ix, today);
    final change = s.monthChange;
    return TileGrid(
      minWidth: 170,
      children: [
        KpiTile(label: 'This week', value: bytes(s.week.total), icon: Icons.view_week_outlined),
        KpiTile(
          label: 'This month',
          value: bytes(s.month.total),
          icon: Icons.calendar_month_outlined,
          hint: 'usage.projection',
          caption: 'On pace for ${bytes(s.monthProjection)}',
        ),
        KpiTile(
          label: 'Vs last month',
          value: change == null ? '—' : '${change >= 0 ? '+' : ''}${(change * 100).round()}%',
          icon: Icons.compare_arrows,
          hint: 'usage.change',
          caption: change == null
              ? 'Nothing to compare yet'
              : 'Last month by now: ${bytes(s.lastMonthToDate.total)}',
        ),
        KpiTile(
          label: 'Daily average',
          value: bytes(s.average30),
          icon: Icons.av_timer,
          caption: 'Over the last 30 days',
        ),
        if (s.peak30 case final p?)
          KpiTile(
            label: 'Busiest day',
            value: bytes(p.traffic.total),
            icon: Icons.local_fire_department_outlined,
            caption: niceDate(p.day),
          ),
        KpiTile(
          label: 'Upload share',
          value: '${(s.month.upShare * 100).round()}%',
          icon: Icons.north,
          caption: 'Of this month’s traffic',
        ),
      ],
    );
  }
}

class _Breakdown extends ConsumerWidget {
  const _Breakdown(this.ix, {required this.from, required this.to, required this.title});
  final UsageIndex ix;
  final String from;
  final String to;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kinds = ix.kindsIn(from, to).entries.where((e) => e.value.total > 0).toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final devices = ix.devicesIn(from, to).entries.where((e) => e.value.total > 0).toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final thisDevice = ref.watch(sessionProvider).store.deviceId;
    if (kinds.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Breakdown · $title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShareRing(
            parts: [
              for (final k in kinds)
                (label: kindLabel(k.key), value: k.value.total, color: kindColor(context, k.key)),
            ],
          ),
          if (devices.length > 1 || ix.devices.length > 1) ...[
            const SizedBox(height: 16),
            Text('By device', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final (i, d) in devices.indexed)
              _DeviceRow(
                id: d.key,
                name: ix.devices[d.key] ?? '',
                traffic: d.value,
                share: d.value.total / devices.fold<int>(0, (s, e) => s + e.value.total),
                color: seriesColor(context, i + 4),
                mine: d.key == thisDevice,
              ),
          ],
        ],
      ),
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({
    required this.id,
    required this.name,
    required this.traffic,
    required this.share,
    required this.color,
    required this.mine,
  });

  final String id;
  final String name;
  final Traffic traffic;
  final double share;
  final Color color;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = '${name.isEmpty ? 'Unnamed device' : name}${mine ? ' (this one)' : ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
                    Text(bytes(traffic.total), style: tabular),
                  ],
                ),
                const SizedBox(height: 6),
                Meter(value: share, color: color, height: 6),
              ],
            ),
          ),
          if (!mine)
            PopupMenuButton<String>(
              tooltip: 'More',
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'forget', child: Text('Forget this device’s usage')),
              ],
              onSelected: (_) async {
                final ok = await confirm(
                  context,
                  title: 'Forget $label?',
                  message:
                      'Its usage is removed from every synced device. If it still runs Bahya Nireekshana, it adds '
                      'new usage again.',
                  action: 'Forget',
                  destructive: true,
                );
                if (ok && context.mounted) {
                  await guarded(context, () => ref.mutate((s) => s.book.forgetDevice(id)));
                }
              },
            ),
        ],
      ),
    );
  }
}
