import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/book.dart';
import '../domain/status_bar.dart';
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
      if (StatusBarSpeed.supported) const _StatusBarCard(),
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

/// Android: the live speed in the status bar, and what keeps it running.
class _StatusBarCard extends StatefulWidget {
  const _StatusBarCard();

  @override
  State<_StatusBarCard> createState() => _StatusBarCardState();
}

class _StatusBarCardState extends State<_StatusBarCard> with WidgetsBindingObserver {
  static const _speed = StatusBarSpeed();
  StatusBarFacts? _facts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the system settings or a permission prompt: read again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final facts = await _speed.status();
    if (mounted) setState(() => _facts = facts);
  }

  Future<void> _toggle(bool on) async {
    final facts = await _speed.setEnabled(on);
    if (mounted) setState(() => _facts = facts);
    // Turning it on asks for what it needs, one prompt at a time.
    if (on && !facts.notifications) {
      await _speed.askNotifications();
    } else if (on && !facts.unrestricted) {
      await _speed.askBattery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final facts = _facts;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SectionCard(
      title: 'Status bar speed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show live speed in the status bar'),
            subtitle: const Text(
              'Download speed as the status bar icon, download and upload in the notification. '
              'Keeps running with the app closed; pauses while the screen is off.',
            ),
            value: facts?.enabled ?? false,
            onChanged: facts == null ? null : _toggle,
          ),
          if (facts != null && facts.enabled) ...[
            if (!facts.notifications)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_off_outlined),
                title: const Text('Notifications are off, so the speed is hidden'),
                trailing: TextButton(onPressed: _speed.askNotifications, child: const Text('Allow')),
              ),
            if (!facts.unrestricted)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.battery_alert_outlined),
                title: const Text('Battery optimization may stop it'),
                trailing: TextButton(onPressed: _speed.askBattery, child: const Text('Allow')),
              )
            else
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.battery_full_outlined),
                title: Text('Battery optimization is off for this app'),
              ),
            Text(
              'Motorola and some other phones have their own limits as well: in App info, set Battery to '
              'Unrestricted and turn on Allow background usage. Don’t swipe the app away with “Clear all” '
              'if your phone stops it then; lock it in recents instead.',
              style: muted,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _speed.openAppInfo,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open App info'),
              ),
            ),
          ],
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
