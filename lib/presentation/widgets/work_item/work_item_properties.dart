import 'package:flutter/material.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class WorkItemProperties extends StatelessWidget {
  final WorkItem workItem;
  final List<WorkItemState> states;
  final List<WorkItemLabel> labels;
  final List<WorkItemMember> members;
  final ValueChanged<String?>? onStateChanged,
      onPriorityChanged,
      onStartDateChanged,
      onTargetDateChanged;
  final ValueChanged<List<String>>? onLabelsChanged, onAssigneesChanged;
  final String? statesError, labelsError, membersError;
  final VoidCallback? onRetryStates, onRetryLabels, onRetryMembers;
  const WorkItemProperties(
      {super.key,
      required this.workItem,
      required this.states,
      required this.labels,
      required this.members,
      this.onStateChanged,
      this.onPriorityChanged,
      this.onLabelsChanged,
      this.onAssigneesChanged,
      this.onStartDateChanged,
      this.onTargetDateChanged,
      this.statesError,
      this.labelsError,
      this.membersError,
      this.onRetryStates,
      this.onRetryLabels,
      this.onRetryMembers});

  @override
  Widget build(BuildContext context) {
    final memberIds = workItem.assigneesIds ??
        workItem.assignees?.map((m) => m.id).toList() ??
        [];
    final labelIds =
        workItem.labelIds ?? workItem.labels?.map((l) => l.id).toList() ?? [];
    final assigneeNames = memberIds
        .map((id) =>
            members.where((m) => m.id == id).firstOrNull?.fullName ??
            workItem.assignees
                ?.where((m) => m.id == id)
                .firstOrNull
                ?.fullName ??
            id)
        .join(', ');
    final labelNames = labelIds
        .map((id) => labels.where((l) => l.id == id).firstOrNull?.name ?? id)
        .join(', ');
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(70),
                borderRadius: BorderRadius.circular(16)),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(
                  context,
                  'Priority',
                  Icons.indeterminate_check_box_outlined,
                  workItem.displayPriority,
                  onPriorityChanged == null
                      ? null
                      : () => _choose(
                          context,
                          'Priority',
                          ['urgent', 'high', 'medium', 'low', 'none']
                              .map((p) =>
                                  (p, p[0].toUpperCase() + p.substring(1)))
                              .toList(),
                          [workItem.priority ?? 'none'],
                          false,
                          (ids) => onPriorityChanged!(ids.first)),
                  leading: PriorityBadge(
                      priority: workItem.priority, iconOnly: true)),
              _chip(
                  context,
                  'State',
                  Icons.adjust,
                  workItem.stateDetail?.name ?? 'State',
                  onStateChanged == null
                      ? null
                      : () => _choose(
                          context,
                          'State',
                          states.map((s) => (s.id, s.name)).toList(),
                          [
                            if (workItem.stateDetail != null)
                              workItem.stateDetail!.id
                          ],
                          false,
                          (ids) => onStateChanged!(ids.first),
                          error: statesError,
                          retry: onRetryStates),
                  leading: workItem.stateDetail == null
                      ? null
                      : StatusBadge(
                          state: workItem.stateDetail!, iconOnly: true)),
              _chip(
                  context,
                  'Assignees',
                  Icons.person_outline,
                  assigneeNames.isEmpty ? 'Assignees' : assigneeNames,
                  onAssigneesChanged == null
                      ? null
                      : () => _choose(
                          context,
                          'Assignees',
                          members.map((m) => (m.id, m.fullName)).toList(),
                          memberIds,
                          true,
                          onAssigneesChanged!,
                          error: membersError,
                          retry: onRetryMembers)),
              _chip(
                  context,
                  'Start date',
                  Icons.event_available_outlined,
                  workItem.startDate ?? 'Start date',
                  onStartDateChanged == null
                      ? null
                      : () => _date(context, 'Start date', workItem.startDate,
                          onStartDateChanged!)),
              _chip(
                  context,
                  'Due date',
                  Icons.event_outlined,
                  workItem.targetDate ?? 'Due date',
                  onTargetDateChanged == null
                      ? null
                      : () => _date(context, 'Due date', workItem.targetDate,
                          onTargetDateChanged!)),
              _chip(
                  context,
                  'Labels',
                  Icons.sell_outlined,
                  labelNames.isEmpty ? 'Labels' : labelNames,
                  onLabelsChanged == null
                      ? null
                      : () => _choose(
                          context,
                          'Labels',
                          labels.map((l) => (l.id, l.name)).toList(),
                          labelIds,
                          true,
                          onLabelsChanged!,
                          error: labelsError,
                          retry: onRetryLabels)),
            ])));
  }

  Widget _chip(BuildContext ctx, String name, IconData icon, String label,
          VoidCallback? pressed, {Widget? leading}) =>
      ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(ctx).width - 64),
          child: OutlinedButton(
            key: ValueKey('property-$name'),
            onPressed: pressed,
            style: OutlinedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.surface,
                foregroundColor: Theme.of(ctx).colorScheme.onSurfaceVariant,
                side: BorderSide(
                    color:
                        Theme.of(ctx).colorScheme.outlineVariant.withAlpha(70)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              leading ?? Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(
                  child:
                      Text(label, maxLines: 2, overflow: TextOverflow.ellipsis))
            ]),
          ));
  Future<void> _choose(
      BuildContext ctx,
      String title,
      List<(String, String)> choices,
      List<String> ids,
      bool multiple,
      ValueChanged<List<String>> changed,
      {String? error,
      VoidCallback? retry}) async {
    if (error != null) {
      await showDialog(
          context: ctx,
          builder: (c) => AlertDialog(
                  title: Text('Could not load $title'),
                  content: Text(error),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(c);
                          retry?.call();
                        },
                        child: const Text('Retry'))
                  ]));
      return;
    }
    final selected = {...ids};
    String query = '';
    final result = await showModalBottomSheet<List<String>>(
        context: ctx,
        isScrollControlled: true,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (c) => StatefulBuilder(
            builder: (c, update) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(c).bottom),
                    child: SizedBox(
                        height: (MediaQuery.sizeOf(c).height -
                                MediaQuery.viewInsetsOf(c).bottom) *
                            .72,
                        child: Column(children: [
                          Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text(title,
                                  style: Theme.of(c).textTheme.titleLarge)),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                  decoration: InputDecoration(
                                      hintText: 'Search $title',
                                      prefixIcon: const Icon(Icons.search)),
                                  onChanged: (s) =>
                                      update(() => query = s.toLowerCase()))),
                          Expanded(
                              child: ListView(children: [
                            for (final (id, name) in choices.where(
                                (x) => x.$2.toLowerCase().contains(query)))
                              CheckboxListTile(
                                  title: Text(name),
                                  value: selected.contains(id),
                                  onChanged: (v) => update(() {
                                        if (!multiple) selected.clear();
                                        if (v == true)
                                          selected.add(id);
                                        else if (multiple) selected.remove(id);
                                      }))
                          ])),
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('Cancel'))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: FilledButton(
                                        onPressed: !multiple && selected.isEmpty
                                            ? null
                                            : () => Navigator.pop(
                                                c, selected.toList()),
                                        child: const Text('Save')))
                              ])),
                        ]))))));
    if (result != null) changed(result);
  }

  Future<void> _date(BuildContext ctx, String title, String? value,
      ValueChanged<String?> changed) async {
    final action = await showModalBottomSheet<String>(
        context: ctx,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (c) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: Text('Set $title'),
                  onTap: () => Navigator.pop(c, 'pick')),
              if (value != null)
                ListTile(
                    title: const Text('Clear date'),
                    onTap: () => Navigator.pop(c, 'clear')),
              ListTile(
                  title: const Text('Cancel'), onTap: () => Navigator.pop(c))
            ])));
    if (action == 'clear') {
      changed(null);
      return;
    }
    if (action != 'pick' || !ctx.mounted) return;
    final initial = DateTime.tryParse(value ?? '') ?? DateTime.now();
    final picked = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime(initial.year - 50),
        lastDate: DateTime(initial.year + 50));
    if (picked != null) changed(picked.toIso8601String().split('T').first);
  }
}
