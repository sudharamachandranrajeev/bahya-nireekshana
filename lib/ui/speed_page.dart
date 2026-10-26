import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/live.dart';
import '../app/providers.dart';
import '../domain/bytes.dart';
import '../domain/counters.dart';
import '../domain/speedtest.dart';
import 'common.dart';
import 'look.dart';

class SpeedPage extends ConsumerStatefulWidget {
  const SpeedPage({super.key});

  @override
  ConsumerState<SpeedPage> createState() => _SpeedPageState();
}

class _SpeedPageState extends ConsumerState<SpeedPage> {
  SpeedProgress? _progress;
  SpeedResult? _result;
  double _down = 0;
  double _up = 0;

  bool get _running => _progress != null && _progress!.phase != SpeedPhase.done;

  Future<void> _run() async {
    final before = ref.read(liveProvider).sample;
    setState(() {
      _progress = const SpeedProgress(SpeedPhase.latency);
      _result = null;
      _down = _up = 0;
    });
    try {
      final result = await SpeedTester(ref.read(httpClientProvider)).run(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
            if (p.phase == SpeedPhase.download) _down = p.bitsPerSecond;
            if (p.phase == SpeedPhase.upload) _up = p.bitsPerSecond;
          });
        },
      );
      // The kind of network the test ran over: whichever moved the most.
      final after = ref.read(liveProvider).sample;
      var kind = '';
      if (before != null && after != null) {
        final moved = usageBetween(before, after).entries.toList()
          ..sort((a, b) => (b.value.rx + b.value.tx).compareTo(a.value.rx + a.value.tx));
        if (moved.isNotEmpty) kind = moved.first.key;
      }
      await ref.mutate(
        (s) => s.book.addSpeedTest(
          at: DateTime.now(),
          down: result.down,
          up: result.up,
          latency: result.latency,
          jitter: result.jitter,
          kind: kind,
          server: result.server,
        ),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _down = result.down.toDouble();
        _up = result.up.toDouble();
        _progress = const SpeedProgress(SpeedPhase.done, share: 1);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _progress = null);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final net = NetColors.of(context);
    final t = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width > 560;
    final p = _progress;
    return PageScaffold(
      title: 'Speed test',
      children: [
        SectionCard(
          title: 'Test this connection',
          hint: 'speed.how',
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
                    value: _down,
                    text: speed(_down / 8),
                    color: net.download,
                    size: wide ? 200 : 150,
                  ),
                  SpeedGauge(
                    label: 'Upload',
                    icon: Icons.north,
                    value: _up,
                    text: speed(_up / 8),
                    color: net.upload,
                    size: wide ? 200 : 150,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_running) ...[
                Meter(value: p!.share),
                const SizedBox(height: 8),
                Text(switch (p.phase) {
                  SpeedPhase.latency =>
                    p.latency > 0
                        ? 'Measuring latency… ${p.latency.toStringAsFixed(0)} ms'
                        : 'Measuring latency…',
                  SpeedPhase.download => 'Measuring download…',
                  SpeedPhase.upload => 'Measuring upload…',
                  SpeedPhase.done => 'Done',
                }),
              ] else ...[
                if (_result case final r?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Latency ${r.latency.toStringAsFixed(0)} ms · jitter ${r.jitter.toStringAsFixed(1)} ms · ${r.server}',
                      style: t.textTheme.bodyMedium?.merge(tabular),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _run,
                  icon: const Icon(Icons.speed),
                  label: Text(_result == null ? 'Start' : 'Test again'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uses about 100 MB of data.',
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const _History(),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(speedTestsProvider).value ?? const [];
    if (tests.isEmpty) return const SizedBox.shrink();
    final net = NetColors.of(context);
    final t = Theme.of(context);
    final today = ref.watch(todayProvider);
    final recent = tests.take(10).toList();
    final downs = [for (final x in recent) x.down.toDouble()]..sort();
    final best = tests.fold<int>(0, (m, x) => math.max(m, x.down));
    final peak = tests.take(30).fold<int>(1, (m, x) => math.max(m, math.max(x.down, x.up)));
    return Column(
      children: [
        TileGrid(
          minWidth: 170,
          children: [
            KpiTile(label: 'Latest download', value: speed(tests.first.down / 8), icon: Icons.south),
            KpiTile(label: 'Latest upload', value: speed(tests.first.up / 8), icon: Icons.north),
            KpiTile(
              label: 'Typical download',
              value: speed(downs[downs.length ~/ 2] / 8),
              icon: Icons.equalizer,
              caption: 'Median of the last ${recent.length}',
            ),
            KpiTile(label: 'Best download', value: speed(best / 8), icon: Icons.emoji_events_outlined),
          ],
        ),
        SectionCard(
          title: 'Results',
          child: Column(
            children: [
              for (final x in tests.take(30))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                whenLabel(x.at, today),
                                if (x.kind.isNotEmpty) kindLabel(x.kind),
                                if (x.deviceName.isNotEmpty) x.deviceName,
                              ].join(' · '),
                              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    '↓ ${speed(x.down / 8)}',
                                    style: tabular.copyWith(color: net.download),
                                  ),
                                ),
                                Expanded(
                                  child: Meter(value: x.down / peak, color: net.download, height: 5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    '↑ ${speed(x.up / 8)}',
                                    style: tabular.copyWith(color: net.upload),
                                  ),
                                ),
                                Expanded(
                                  child: Meter(value: x.up / peak, color: net.upload, height: 5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${x.latency.toStringAsFixed(0)} ms · jitter ${x.jitter.toStringAsFixed(1)} ms'
                              '${x.server.isEmpty ? '' : ' · ${x.server}'}',
                              style: t.textTheme.bodySmall?.merge(tabular),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            guarded(context, () => ref.mutate((s) => s.book.removeSpeedTest(x.id))),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
