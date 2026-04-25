import 'package:flutter/material.dart';

class WorkItemFilterBar extends StatelessWidget {
  final String workspaceSlug;
  final String projectId;
  final void Function(String? state, String? priority) onFilterChanged;

  const WorkItemFilterBar({
    super.key,
    required this.workspaceSlug,
    required this.projectId,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip<String>(
              label: 'State',
              icon: Icons.flag,
              items: const ['Backlog', 'Todo', 'In Progress', 'Done', 'Cancelled'],
              valueMapper: (v) => v.toLowerCase().replaceAll(' ', '_'),
              onSelected: (value) => onFilterChanged(value, null),
              onDeselected: () => onFilterChanged(null, null),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChip<String>(
              label: 'Priority',
              icon: Icons.signal_cellular_alt,
              items: const ['Urgent', 'High', 'Medium', 'Low', 'None'],
              valueMapper: (v) => v.toLowerCase(),
              onSelected: (value) => onFilterChanged(null, value),
              onDeselected: () => onFilterChanged(null, null),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String Function(String) valueMapper;
  final void Function(String) onSelected;
  final VoidCallback onDeselected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.items,
    required this.valueMapper,
    required this.onSelected,
    required this.onDeselected,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showFilterDialog(context),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        onDeselected();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.map((item) => ListTile(
                    title: Text(item),
                    onTap: () {
                      onSelected(valueMapper(item));
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}