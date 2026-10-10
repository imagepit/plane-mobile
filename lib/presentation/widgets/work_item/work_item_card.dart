import 'package:flutter/material.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class WorkItemCard extends StatelessWidget {
  final WorkItem workItem;
  final String? identifier;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const WorkItemCard(
      {super.key,
      required this.workItem,
      required this.onTap,
      this.identifier,
      this.onDelete});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: workItem.stateDetail == null
                      ? const Icon(Icons.circle_outlined, size: 22)
                      : StatusBadge(
                          state: workItem.stateDetail!, iconOnly: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(workItem.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                        identifier == null || identifier!.isEmpty
                            ? workItem.displayId
                            : '$identifier-${workItem.sequenceId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ])),
              const SizedBox(width: 12),
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: PriorityBadge(
                      priority: workItem.priority, iconOnly: true)),
              const SizedBox(width: 10),
              if (workItem.assignees?.isNotEmpty == true) ...[
                MemberAvatar(member: workItem.assignees!.first),
                if (workItem.assignees!.length > 1)
                  Text('+${workItem.assignees!.length - 1}',
                      style: Theme.of(context).textTheme.labelSmall),
              ] else
                const SizedBox(width: 24),
            ])),
      );
}

/// Only images on the configured origin are requested. Never attach the PAT.
class MemberAvatar extends StatelessWidget {
  final WorkItemMember member;
  final double radius;
  const MemberAvatar({super.key, required this.member, this.radius = 12});
  Uri? get imageUri {
    final raw = member.avatar;
    if (raw == null || raw.isEmpty || !sl.isRegistered<DioClient>())
      return null;
    final base = Uri.tryParse(sl<DioClient>().baseUrl),
        candidate = Uri.tryParse(raw);
    if (base == null || candidate == null || base.host.isEmpty) return null;
    final resolved = base.resolveUri(candidate);
    return resolved.origin == base.origin &&
            resolved.userInfo.isEmpty &&
            resolved.scheme == 'https'
        ? resolved
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
        radius: radius,
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        child: Text(
            member.fullName.isEmpty
                ? '?'
                : member.fullName.characters.first.toUpperCase(),
            style: TextStyle(fontSize: radius)));
    final image = imageUri;
    return image == null
        ? fallback
        : ClipOval(
            child: Image.network(image.toString(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => fallback));
  }
}
