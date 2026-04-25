import 'package:flutter/material.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

class StatusBadge extends StatelessWidget {
  final WorkItemState state;

  const StatusBadge({super.key, required this.state});

  Color _getColor(BuildContext context) {
    if (state.color != null && state.color!.isNotEmpty) {
      final hex = state.color!.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    switch (state.group?.toLowerCase()) {
      case 'backlog':
        return Theme.of(context).colorScheme.outline;
      case 'todo':
        return Theme.of(context).colorScheme.tertiary;
      case 'in_progress':
        return Theme.of(context).colorScheme.primary;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getIcon() {
    switch (state.group?.toLowerCase()) {
      case 'backlog':
        return Icons.inbox;
      case 'todo':
        return Icons.circle_outlined;
      case 'in_progress':
        return Icons.autorenew;
      case 'done':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            state.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}