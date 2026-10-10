import 'package:flutter/material.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemFilterBar extends StatelessWidget {
  final String workspaceSlug, projectId;
  final List<WorkItemState> states;
  final String? selectedState, selectedPriority, error;
  final VoidCallback? onRetry;
  final void Function(String? state, String? priority) onFilterChanged;
  const WorkItemFilterBar(
      {super.key,
      required this.workspaceSlug,
      required this.projectId,
      required this.onFilterChanged,
      this.states = const [],
      this.selectedState,
      this.selectedPriority,
      this.error,
      this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey('work-item-filters'),
            onPressed: () => _open(context),
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(selectedState == null && selectedPriority == null
                ? 'Filters'
                : 'Filters · active'),
            style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          )));
  Future<void> _open(BuildContext context) async {
    String? state = selectedState, priority = selectedPriority;
    final result = await showModalBottomSheet<(String?, String?)>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => SafeArea(
                child: SizedBox(
                    height: MediaQuery.sizeOf(ctx).height * .7,
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(children: [
                            Text('Filters',
                                style: Theme.of(ctx).textTheme.titleLarge),
                            const Spacer(),
                            TextButton(
                                onPressed: () => update(() {
                                      state = null;
                                      priority = null;
                                    }),
                                child: const Text('Reset'))
                          ])),
                      Expanded(
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                            Text('State',
                                style: Theme.of(ctx).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            if (error != null) ...[
                              Text(error!),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    onRetry?.call();
                                  },
                                  child: const Text('Retry states'))
                            ] else
                              Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: states
                                      .map((s) => ChoiceChip(
                                          label: Text(s.name),
                                          selected: state == s.id,
                                          onSelected: (v) => update(
                                              () => state = v ? s.id : null)))
                                      .toList()),
                            const SizedBox(height: 24),
                            Text('Priority',
                                style: Theme.of(ctx).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  'urgent',
                                  'high',
                                  'medium',
                                  'low',
                                  'none'
                                ]
                                    .map((p) => ChoiceChip(
                                        label: Text(p[0].toUpperCase() +
                                            p.substring(1)),
                                        selected: priority == p,
                                        onSelected: (v) => update(
                                            () => priority = v ? p : null)))
                                    .toList()),
                          ])),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, (state, priority)),
                                    child: const Text('Apply')))
                          ])),
                    ])))));
    if (result != null) onFilterChanged(result.$1, result.$2);
  }
}
