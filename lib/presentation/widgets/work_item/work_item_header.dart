import 'package:flutter/material.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemHeader extends StatelessWidget {
  final WorkItem workItem;
  final String? identifier;
  const WorkItemHeader({super.key, required this.workItem, this.identifier});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(
        identifier == null || identifier!.isEmpty
            ? workItem.displayId
            : '$identifier-${workItem.sequenceId}',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ));
}
