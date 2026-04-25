import 'package:flutter/material.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/presentation/widgets/work_item/status_badge.dart';
import 'package:plane_mobile/presentation/widgets/work_item/priority_badge.dart';

class WorkItemHeader extends StatelessWidget {
  final WorkItem workItem;

  const WorkItemHeader({super.key, required this.workItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                workItem.displayId,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 12),
              if (workItem.stateDetail != null) StatusBadge(state: workItem.stateDetail!),
              const SizedBox(width: 8),
              PriorityBadge(priority: workItem.priority),
            ],
          ),
          if (workItem.startDate != null || workItem.targetDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                if (workItem.startDate != null)
                  Text(
                    workItem.startDate!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                if (workItem.startDate != null && workItem.targetDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '→',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                if (workItem.targetDate != null)
                  Text(
                    workItem.targetDate!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}