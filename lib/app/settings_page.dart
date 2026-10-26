import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/book.dart';
import '../domain/update.dart';
import '../ui/common.dart';
import 'providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageScaffold(
    title: 'Settings',
    children: [
      if (ref.watch(updaterProvider) case final updater?) _UpdateCard(updater),
      const _AlertsCard(),
      const AppLockCard(),
      const HintsCard(),
      const SyncCard(),
      const SecurityCard(
        network:
            'Bahya Nireekshana reads this device’s network counters and connections locally. It goes online '
            'only for a speed test you start (Cloudflare’s speed test service), to look for updates on GitHub, '
            'and to talk to your sync server if you sign in.',
      ),
      const AboutCard(
        description:
            'Network monitor: live speed, usage history on every device, data plans, speed tests, connections '
            'and the OpenSnitch firewall.',
      ),
    ],
  );
}

class _AlertsCard extends ConsumerStatefulWidget {
  const _AlertsCard();

  @override
  ConsumerState<_AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends ConsumerState<_AlertsCard> {
  /// While dragging; written (and synced) once, when the drag ends.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final factor = _dragging ?? ref.watch(spikeFactorProvider).value ?? 3;
    return SectionCard(
      title: 'Alerts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Call a day unusual at ${factor.toStringAsFixed(1)}× the 30-day average'),
          Slider(
            value: factor.clamp(1.5, 10),
            min: 1.5,
            max: 10,
            divisions: 17,
            label: '${factor.toStringAsFixed(1)}×',
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) async {
              await ref.mutate((s) => s.book.setPref(PrefKeys.spikeFactor, v));
              if (mounted) setState(() => _dragging = null);
            },
          ),
          Text(
            'Plans warn at the level set on each plan.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// This version, and a newer one when GitHub has it, installed from here.
class _UpdateCard extends ConsumerWidget {
  const _UpdateCard(this.updater);
  final Updater updater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider);
    final release = update.value;
    final onStart = ref.watch(updateOnStartProvider).value ?? true;
    final asked = ref.watch(updateAskedProvider);
    const name = 'Bahya Nireekshana';
    return SectionCard(
      title: 'Updates',
      trailing: TextButton(
        onPressed: update.isLoading
            ? null
            : () {
                ref.read(updateAskedProvider.notifier).ask();
                ref.invalidate(updateProvider);
              },
        child: Text(asked || onStart ? 'Check again' : 'Check now'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(switch (update) {
            AsyncLoading() => '$name ${updater.current}. Looking for a newer version…',
            AsyncError(:final error) => '$name ${updater.current}. Could not check: ${describeError(error)}',
            _ when release == null && !asked && !onStart => '$name ${updater.current}.',
            _ when release == null => '$name ${updater.current} is the newest version.',
            _ => '$name ${release.version} is out (this is ${updater.current}).',
          }),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Look for updates when the app starts'),
            subtitle: const Text('Asks before anything is downloaded.'),
            value: onStart,
            onChanged: (v) => ref.mutate((s) => s.book.setUpdateOnStart(v)),
          ),
          if (release != null && !update.isLoading) ...[
            if (release.notes.isNotEmpty) ...[
              Text(release.notes, maxLines: 8, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => installUpdate(context, updater, release),
                  icon: const Icon(Icons.system_update_outlined),
                  label: const Text('Update now'),
                ),
                TextButton.icon(
                  onPressed: () => openLink(context, releasesPage),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('All releases'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks whether to install [release] now; installs it on yes.
Future<void> offerUpdate(BuildContext context, Updater updater, Release release) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Bahya Nireekshana ${release.version} is out'),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Text(
          [
            'You have ${updater.current}. Update now? Your data stays as it is.',
            if (release.notes.isNotEmpty) release.notes,
          ].join('\n\n'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update now')),
      ],
    ),
  );
  if (go == true && context.mounted) await installUpdate(context, updater, release);
}

/// Downloads, checks and installs [release], then offers a restart on Linux.
Future<void> installUpdate(BuildContext context, Updater updater, Release release) async {
  final said = await runTask(
    context,
    title: 'Updating to ${release.version}',
    status: 'Downloading…',
    task: (progress) async {
      final file = await updater.download(
        release,
        onProgress: (d) => progress('Downloading… ${(d * 100).round()}%'),
      );
      progress('Installing…');
      return updater.install(file);
    },
  );
  if (said == null || !context.mounted) return;
  if (updater.os != 'linux') return showMessage(context, said);
  final restart = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Bahya Nireekshana ${release.version} is installed'),
      content: const Text('Restart the app to use it. Your data stays as it is.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restart now')),
      ],
    ),
  );
  if (restart == true) await Updater.restartLinux();
}
