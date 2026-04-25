import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:plane_mobile/core/utils/date_formatter.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/presentation/widgets/work_item/status_badge.dart';
import 'package:plane_mobile/presentation/widgets/work_item/priority_badge.dart';

class WorkItemCard extends StatelessWidget {
  final WorkItem workItem;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const WorkItemCard({
    super.key,
    required this.workItem,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final child = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    workItem.displayId,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  if (workItem.stateDetail != null)
                    StatusBadge(state: workItem.stateDetail!),
                  const SizedBox(width: 8),
                  if (workItem.priority != null &&
                      workItem.priority!.isNotEmpty &&
                      workItem.priority != 'none')
                    PriorityBadge(priority: workItem.priority),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                workItem.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (workItem.labels != null && workItem.labels!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: workItem.labels!.take(3).map((label) {
                    final color = label.color != null && label.color!.isNotEmpty
                        ? _parseColor(label.color!)
                        : Theme.of(context).colorScheme.outline;
                    return Chip(
                      label: Text(
                        label.name,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: color.withAlpha(100)),
                      backgroundColor: color.withAlpha(20),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (workItem.assignees != null && workItem.assignees!.isNotEmpty)
                    _buildAssigneeAvatars(context, workItem.assignees!),
                  const Spacer(),
                  if (workItem.startDate != null || workItem.targetDate != null)
                    _buildDateInfo(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete != null) {
      return Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete?.call(),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildAssigneeAvatars(BuildContext context, List<WorkItemMember> assignees) {
    final displayAssignees = assignees.take(3).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayAssignees.map((member) {
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          );
        }),
        if (assignees.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+${assignees.length - 3}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    final parts = <String>[];
    if (workItem.startDate != null) {
      parts.add(DateFormatter.formatShortDate(workItem.startDate));
    }
    if (workItem.targetDate != null) {
      if (parts.isNotEmpty) parts.add('→');
      parts.add(DateFormatter.formatShortDate(workItem.targetDate));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          parts.join(' '),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.grey;
  }
}