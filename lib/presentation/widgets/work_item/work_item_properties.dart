import 'package:flutter/material.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemProperties extends StatelessWidget {
  final WorkItem workItem;
  final List<WorkItemState> states;
  final List<WorkItemLabel> labels;
  final List<WorkItemMember> members;
  final void Function(String? value)? onStateChanged;
  final void Function(String? value)? onPriorityChanged;
  final void Function(List<String> ids)? onLabelsChanged;
  final void Function(List<String> ids)? onAssigneesChanged;
  final void Function(String? value)? onStartDateChanged;
  final void Function(String? value)? onTargetDateChanged;

  const WorkItemProperties({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildStateSelector(context),
          const SizedBox(height: 12),
          _buildPrioritySelector(context),
          const SizedBox(height: 12),
          _buildAssigneeSelector(context),
          const SizedBox(height: 12),
          _buildLabelSelector(context),
          const SizedBox(height: 12),
          _buildDateField(context, 'Start Date', workItem.startDate, onStartDateChanged),
          const SizedBox(height: 12),
          _buildDateField(context, 'Target Date', workItem.targetDate, onTargetDateChanged),
        ],
      ),
    );
  }

  Widget _buildStateSelector(BuildContext context) {
    return _PropertyRow(
      label: 'State',
      child: DropdownButtonFormField<String>(
        initialValue: workItem.stateDetail?.id,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: states.map((state) {
          return DropdownMenuItem(
            value: state.id,
            child: Text(state.name),
          );
        }).toList(),
        onChanged: onStateChanged,
      ),
    );
  }

  Widget _buildPrioritySelector(BuildContext context) {
    return _PropertyRow(
      label: 'Priority',
      child: DropdownButtonFormField<String>(
        initialValue: workItem.priority ?? 'none',
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: const [
          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
          DropdownMenuItem(value: 'high', child: Text('High')),
          DropdownMenuItem(value: 'medium', child: Text('Medium')),
          DropdownMenuItem(value: 'low', child: Text('Low')),
          DropdownMenuItem(value: 'none', child: Text('None')),
        ],
        onChanged: onPriorityChanged,
      ),
    );
  }

  Widget _buildAssigneeSelector(BuildContext context) {
    final assigneeIds = workItem.assigneesIds ?? [];
    return _PropertyRow(
      label: 'Assignees',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          ...assigneeIds.map((id) {
            final member = members.where((m) => m.id == id).firstOrNull;
            return Chip(
              label: Text(member?.fullName ?? id, style: const TextStyle(fontSize: 12)),
              onDeleted: onAssigneesChanged != null
                  ? () {
                      onAssigneesChanged!(assigneeIds.where((a) => a != id).toList());
                    }
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }),
          ActionChip(
            label: const Text('+ Add', style: TextStyle(fontSize: 12)),
            onPressed: () => _showMemberPicker(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _showMemberPicker(BuildContext context) {
    final assigneeIds = workItem.assigneesIds ?? [];
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text('Select Assignees', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            onAssigneesChanged?.call(assigneeIds);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...members.map((member) => CheckboxListTile(
                        value: assigneeIds.contains(member.id),
                        title: Text(member.fullName),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              assigneeIds.add(member.id);
                            } else {
                              assigneeIds.remove(member.id);
                            }
                          });
                        },
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabelSelector(BuildContext context) {
    final labelIds = workItem.labelIds ?? [];
    return _PropertyRow(
      label: 'Labels',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          ...labelIds.map((id) {
            final label = labels.where((l) => l.id == id).firstOrNull;
            return Chip(
              label: Text(label?.name ?? id, style: const TextStyle(fontSize: 12)),
              onDeleted: onLabelsChanged != null
                  ? () {
                      onLabelsChanged!(labelIds.where((l) => l != id).toList());
                    }
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }),
          ActionChip(
            label: const Text('+ Add', style: TextStyle(fontSize: 12)),
            onPressed: () => _showLabelPicker(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _showLabelPicker(BuildContext context) {
    final labelIds = List<String>.from(workItem.labelIds ?? []);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text('Select Labels', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            onLabelsChanged?.call(labelIds);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...labels.map((label) => CheckboxListTile(
                        value: labelIds.contains(label.id),
                        title: Text(label.name),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              labelIds.add(label.id);
                            } else {
                              labelIds.remove(label.id);
                            }
                          });
                        },
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context, String label, String? value, ValueChanged<String?>? onChanged) {
    return _PropertyRow(
      label: label,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value != null ? DateTime.tryParse(value) ?? DateTime.now() : DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null && onChanged != null) {
            onChanged(picked.toIso8601String().split('T')[0]);
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ?? 'Not set',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _PropertyRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}