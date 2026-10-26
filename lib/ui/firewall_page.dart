import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/firewall.dart';

/// OpenSnitch on Linux, as the bar widget shows it: saved answers and the
/// block and allow lists, changed through the helper with pkexec.
class FirewallPage extends ConsumerStatefulWidget {
  const FirewallPage({super.key});

  @override
  ConsumerState<FirewallPage> createState() => _FirewallPageState();
}

class _FirewallPageState extends ConsumerState<FirewallPage> {
  final _entry = TextEditingController();
  final _search = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _entry.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _change(List<String> args, String done) async {
    setState(() => _busy = true);
    final ok = await guarded(context, () => ref.read(firewallProvider)!.change(args));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      // The helper rewrites the summary as it finishes.
      ref.invalidate(rulesProvider);
      showMessage(context, done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(firewallStatusProvider);
    return PageScaffold(
      title: 'Firewall',
      banner: 'page.firewall',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(firewallStatusProvider);
            ref.invalidate(rulesProvider);
          },
        ),
      ],
      children: [
        AsyncView(
          status,
          builder: (s) {
            if (s == null) return const SizedBox.shrink();
            if (!s.ready) {
              return EmptyState(
                icon: Icons.shield_outlined,
                title: 'The firewall is not set up',
                message:
                    'Run omarchy/install.sh with sudo once from the Bahya Nireekshana source. It installs '
                    'OpenSnitch, the rules helper and vnstat.${s.daemon == 'missing' ? '' : ' OpenSnitch is ${s.daemon}.'}',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.daemon != 'active')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: StatusLabel(Status.warning, 'OpenSnitch is not running, so no rule applies now.'),
                  ),
                _addCard(context),
                _rules(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _addCard(BuildContext context) {
    final c = classifyEntry(_entry.text);
    final valid = c.kind != null;
    return SectionCard(
      title: 'Block or allow a site or address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _entry,
            decoration: InputDecoration(
              hintText: 'example.com, 203.0.113.7 or 10.0.0.0/8',
              errorText: c.error.isEmpty ? null : c.error,
              helperText: valid
                  ? (c.kind == 'site' ? 'A site, with its subdomains' : 'An IP address or network')
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: !valid || _busy
                    ? null
                    : () async {
                        await _change(addArgs(c.kind!, c.value, block: true), '${c.value} is blocked.');
                        _entry.clear();
                      },
                icon: const Icon(Icons.block),
                label: const Text('Block'),
              ),
              OutlinedButton.icon(
                onPressed: !valid || _busy
                    ? null
                    : () async {
                        await _change(addArgs(c.kind!, c.value, block: false), '${c.value} is allowed.');
                        _entry.clear();
                      },
                icon: const Icon(Icons.check),
                label: const Text('Allow'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rules(BuildContext context) {
    final rules = ref.watch(rulesProvider);
    final q = _search.text.trim().toLowerCase();
    return AsyncView(
      rules,
      onRetry: () => ref.invalidate(rulesProvider),
      builder: (r) {
        final items = [
          for (final i in r.items)
            if (q.isEmpty || i.title.toLowerCase().contains(q) || i.detail.toLowerCase().contains(q)) i,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Find a rule',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            for (final section in ruleSections.entries)
              if (items.where((i) => i.kind == section.key).toList() case final list when list.isNotEmpty)
                SectionCard(
                  title: '${section.value} (${list.length})',
                  child: Column(children: [for (final i in list) _ruleTile(context, i)]),
                ),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.rule,
                title: 'No rules',
                message: 'OpenSnitch saves one each time you answer it.',
              ),
          ],
        );
      },
    );
  }

  Widget _ruleTile(BuildContext context, RuleItem i) {
    final system = i.kind == 'system';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        i.blocked ? Icons.block : Icons.check_circle_outline,
        color: i.blocked ? StatusColors.critical : StatusColors.good,
      ),
      title: Text(i.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [i.blocked ? 'Blocked' : 'Allowed', if (i.detail.isNotEmpty) i.detail].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: system
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Change',
              enabled: !_busy,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'flip', child: Text(i.blocked ? 'Allow instead' : 'Block instead')),
                const PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
              onSelected: (v) async {
                if (v == 'flip') {
                  return _change(i.flipArgs, '${i.title} is ${i.blocked ? 'allowed' : 'blocked'}.');
                }
                final ok = await confirm(
                  context,
                  title: 'Remove this rule?',
                  message: i.source == 'rule'
                      ? 'OpenSnitch will ask again the next time ${i.title} connects.'
                      : '${i.title} leaves the list.',
                  action: 'Remove',
                  destructive: true,
                );
                if (ok) await _change(i.deleteArgs, 'Removed.');
              },
            ),
    );
  }
}
