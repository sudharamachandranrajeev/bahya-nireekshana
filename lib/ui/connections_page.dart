import 'dart:async';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/connections.dart';
import '../domain/firewall.dart';

/// Which connections to show.
enum _Scope { internet, all }

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  Timer? _timer;
  final _search = TextEditingController();
  _Scope _scope = _Scope.internet;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_paused) ref.invalidate(connectionsProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool _keep(Connection c) => switch (_scope) {
    _Scope.internet => c.hasPeer && !c.loopback && !c.lan,
    _Scope.all => true,
  };

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(connectionsProvider);
    final query = _search.text.trim().toLowerCase();
    return PageScaffold(
      title: 'Connections',
      banner: 'page.connections',
      actions: [
        IconButton(
          tooltip: _paused ? 'Resume' : 'Pause',
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          onPressed: () => setState(() => _paused = !_paused),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(connectionsProvider),
        ),
      ],
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Program or address',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SegmentedButton<_Scope>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Scope.internet, label: Text('Internet')),
                ButtonSegment(value: _Scope.all, label: Text('Everything')),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncView(
          all,
          onRetry: () => ref.invalidate(connectionsProvider),
          builder: (list) {
            final shown = [
              for (final c in list)
                if (_keep(c) &&
                    (query.isEmpty ||
                        c.program.toLowerCase().contains(query) ||
                        c.path.toLowerCase().contains(query) ||
                        c.remote.contains(query)))
                  c,
            ];
            if (shown.isEmpty) {
              return EmptyState(
                icon: Icons.cable_outlined,
                title: list.isEmpty ? 'No connections to show' : 'Nothing matches',
                message: list.isEmpty
                    ? 'The system lists none, or does not let this app see them.'
                    : 'Try Everything to include local and listening sockets.',
              );
            }
            final groups = byProgram(shown);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${shown.length} connections from ${groups.length} programs',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final g in groups) _ProgramCard(g),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  const _ProgramCard(this.g);
  final ProgramConnections g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final firewall = ref.watch(firewallProvider);
    final ready = ref.watch(firewallStatusProvider).value?.ready ?? false;
    final peers = g.peers;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          leading: const Icon(Icons.apps_outlined),
          title: Text(g.program.isEmpty ? 'Unknown program' : g.program),
          subtitle: Text(
            [
              if (g.open > 0) '${g.open} open',
              if (g.listening > 0) '${g.listening} listening',
              if (peers.isNotEmpty)
                peers.take(3).join(', ') + (peers.length > 3 ? ' +${peers.length - 3}' : ''),
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            if (g.path.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SelectableText(g.path, style: t.textTheme.bodySmall),
              ),
            for (final c in g.connections)
              ListTile(
                dense: true,
                title: Text(
                  c.hasPeer ? '${c.remote}:${c.remotePort}' : 'Listening on ${c.local}:${c.localPort}',
                  style: tabular,
                ),
                subtitle: Text(
                  [
                    c.protocol.toUpperCase(),
                    if (c.state.isNotEmpty) c.state,
                    if (c.hasPeer) 'from port ${c.localPort}',
                    if (c.loopback) 'this machine' else if (c.lan) 'local network',
                    if (c.pid > 0) 'pid ${c.pid}',
                  ].join(' · '),
                ),
                trailing: firewall != null && ready && c.hasPeer && !c.loopback
                    ? IconButton(
                        tooltip: 'Block ${c.remote} for every app',
                        icon: const Icon(Icons.block),
                        onPressed: () => _block(context, ref, firewall, c.remote),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _block(BuildContext context, WidgetRef ref, Firewall firewall, String address) async {
    final ok = await confirm(
      context,
      title: 'Block $address?',
      message:
          'OpenSnitch will refuse every connection to $address, from every program. Undo it on the Firewall '
          'page.',
      action: 'Block',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final value = address.startsWith('::ffff:') ? address.substring(7) : address;
    if (await guarded(context, () => firewall.change(addArgs('address', value, block: true))) &&
        context.mounted) {
      ref.invalidate(rulesProvider);
      showMessage(context, '$value is blocked.');
    }
  }
}
