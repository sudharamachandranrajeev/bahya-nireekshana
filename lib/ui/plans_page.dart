import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/bytes.dart';
import '../domain/counters.dart';
import '../domain/history.dart';
import 'look.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(planStatusProvider);
    return PageScaffold(
      title: 'Plans',
      banner: 'page.plans',
      fab: FloatingActionButton.extended(
        onPressed: () => editPlan(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add plan'),
      ),
      children: [
        AsyncView(
          plans,
          onRetry: () => ref.invalidate(plansProvider),
          builder: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.data_usage,
                  title: 'No data plans',
                  message:
                      'Add your mobile data or broadband allowance to see how much is left and what you can use '
                      'each day.',
                  actions: [
                    FilledButton(onPressed: () => editPlan(context, ref), child: const Text('Add a plan')),
                  ],
                )
              : Column(children: [for (final p in list) _PlanCard(p)]),
        ),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard(this.s);
  final PlanStatus s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final p = s.plan;
    final (status, color) = switch (s.state) {
      PlanState.over => ('Over the allowance', StatusColors.critical),
      PlanState.warning => ('Past ${p.warnPercent}%', StatusColors.warning),
      PlanState.onTrackToExceed => ('On pace to run out', StatusColors.serious),
      PlanState.fine => ('On track', StatusColors.good),
    };
    final devices = ref.watch(allUsageProvider).value?.devices ?? const {};
    final scope = [
      p.kinds == 'all' ? 'All networks' : kindLabel(p.kinds),
      p.device.isEmpty ? 'every device' : (devices[p.device]?.ifEmpty('one device') ?? 'one device'),
      'renews on day ${p.cycleDay}',
    ].join(' · ');
    return SectionCard(
      title: p.name,
      trailing: PopupMenuButton<String>(
        tooltip: 'More',
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (v) async {
          if (v == 'edit') return editPlan(context, ref, plan: p);
          final ok = await confirm(
            context,
            title: 'Delete ${p.name}?',
            message: 'Usage history stays; only the plan goes.',
            action: 'Delete',
            destructive: true,
          );
          if (ok && context.mounted) await guarded(context, () => ref.mutate((x) => x.book.removePlan(p.id)));
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(scope, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${bytes(s.used)} of ${bytes(p.capBytes)}',
                  style: t.textTheme.headlineSmall?.merge(tabular),
                ),
              ),
              StatusLabel(switch (s.state) {
                PlanState.over => Status.critical,
                PlanState.warning => Status.warning,
                PlanState.onTrackToExceed => Status.serious,
                PlanState.fine => Status.good,
              }, status),
            ],
          ),
          const SizedBox(height: 10),
          Meter(value: s.share, color: color, height: 10),
          const SizedBox(height: 4),
          // Where the period is, so the bar reads against the calendar.
          Align(
            alignment: Alignment(-1 + 2 * (s.daysElapsed / s.daysTotal).clamp(0, 1), 0),
            child: Container(width: 2, height: 8, color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Fact('Left', bytes(s.left)),
              _Fact('Days left', '${s.daysLeft}'),
              _Fact('Per day to stay inside', bytes(s.dailyBudget), hint: 'plan.budget'),
              _Fact('At this pace', bytes(s.projected)),
              _Fact('Period', '${niceDate(s.cycle.start)} – ${niceDate(s.cycle.end)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        Text(value, style: t.textTheme.titleSmall?.merge(tabular)),
      ],
    );
    return hint == null ? text : Hint(hint!, child: text);
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// Adds a plan, or edits [plan].
Future<void> editPlan(BuildContext context, WidgetRef ref, {DataPlan? plan}) async {
  final devices = ref.read(allUsageProvider).value?.devices ?? const <String, String>{};
  await showDialog<void>(
    context: context,
    builder: (_) => _PlanDialog(plan: plan, devices: devices, ref: ref),
  );
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({required this.plan, required this.devices, required this.ref});
  final DataPlan? plan;
  final Map<String, String> devices;
  final WidgetRef ref;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final _name = TextEditingController(text: widget.plan?.name ?? 'Mobile data');
  late final _cap = TextEditingController(
    text: widget.plan == null ? '20 GB' : bytes(widget.plan!.capBytes, digits: 2),
  );
  late int _cycle = widget.plan?.cycleDay ?? 1;
  late String _kinds = widget.plan?.kinds ?? 'mobile';
  late String _device = widget.plan?.device ?? '';
  late double _warn = (widget.plan?.warnPercent ?? 80).clamp(50, 100).toDouble();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _cap.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cap = parseBytes(_cap.text);
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Give the plan a name.');
    if (cap == null || cap <= 0) return setState(() => _error = 'Enter an allowance like 20 GB or 500 MB.');
    final ok = await guarded(
      context,
      () => widget.ref.mutate(
        (s) => s.book.savePlan(
          id: widget.plan?.id,
          name: name,
          capBytes: cap,
          cycleDay: _cycle,
          kinds: _kinds,
          device: _device,
          warnPercent: _warn.round(),
        ),
      ),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.plan == null ? 'Add a data plan' : 'Edit ${widget.plan!.name}'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cap,
            decoration: InputDecoration(
              labelText: 'Allowance',
              helperText: 'Like 20 GB or 500 MB',
              errorText: _error,
            ),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9. kKmMgGtTbB]'))],
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _cycle,
            decoration: const InputDecoration(labelText: 'Renews on day'),
            items: [for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d'))],
            onChanged: (v) => setState(() => _cycle = v ?? 1),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kinds,
            decoration: const InputDecoration(labelText: 'Counts'),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Every network')),
              for (final k in ['mobile', 'wifi', 'ethernet'])
                DropdownMenuItem(value: k, child: Text(kindLabel(k))),
            ],
            onChanged: (v) => setState(() => _kinds = v ?? 'all'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.devices.containsKey(_device) ? _device : '',
            decoration: const InputDecoration(labelText: 'Devices'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Every device')),
              for (final d in widget.devices.entries)
                DropdownMenuItem(value: d.key, child: Text(d.value.isEmpty ? 'Unnamed device' : d.value)),
            ],
            onChanged: (v) => setState(() => _device = v ?? ''),
          ),
          const SizedBox(height: 16),
          Text('Warn at ${_warn.round()}%'),
          Slider(
            value: _warn,
            min: 50,
            max: 100,
            divisions: 10,
            label: '${_warn.round()}%',
            onChanged: (v) => setState(() => _warn = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
