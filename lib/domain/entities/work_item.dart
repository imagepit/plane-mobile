class WorkItem {
  final String id;
  final String name;
  final int sequenceId;
  final String? description;
  final String? descriptionHtml;
  final WorkItemState? stateDetail;
  final List<String>? labelIds;
  final List<WorkItemLabel>? labels;
  final List<WorkItemMember>? assignees;
  final List<String>? assigneesIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? startDate;
  final String? targetDate;
  final String? priority;
  final String? projectId;
  final String? workspaceSlug;
  final WorkItemMember? createdBy;
  final String? estimatePoint;
  final int? attachmentCount;
  final int? linkCount;
  final bool? isFavorite;

  const WorkItem({
    required this.id,
    required this.name,
    required this.sequenceId,
    this.description,
    this.descriptionHtml,
    this.stateDetail,
    this.labelIds,
    this.labels,
    this.assignees,
    this.assigneesIds,
    this.createdAt,
    this.updatedAt,
    this.startDate,
    this.targetDate,
    this.priority,
    this.projectId,
    this.workspaceSlug,
    this.createdBy,
    this.estimatePoint,
    this.attachmentCount,
    this.linkCount,
    this.isFavorite,
  });

  String get displayId => '#$sequenceId';

  String get displayPriority {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      case 'none':
        return 'None';
      default:
        return 'None';
    }
  }

  WorkItem copyWith({
    String? id,
    String? name,
    int? sequenceId,
    String? description,
    String? descriptionHtml,
    WorkItemState? stateDetail,
    List<String>? labelIds,
    List<WorkItemLabel>? labels,
    List<WorkItemMember>? assignees,
    List<String>? assigneesIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? startDate,
    String? targetDate,
    String? priority,
    String? projectId,
    String? workspaceSlug,
    WorkItemMember? createdBy,
    String? estimatePoint,
    int? attachmentCount,
    int? linkCount,
    bool? isFavorite,
  }) {
    return WorkItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sequenceId: sequenceId ?? this.sequenceId,
      description: description ?? this.description,
      descriptionHtml: descriptionHtml ?? this.descriptionHtml,
      stateDetail: stateDetail ?? this.stateDetail,
      labelIds: labelIds ?? this.labelIds,
      labels: labels ?? this.labels,
      assignees: assignees ?? this.assignees,
      assigneesIds: assigneesIds ?? this.assigneesIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      workspaceSlug: workspaceSlug ?? this.workspaceSlug,
      createdBy: createdBy ?? this.createdBy,
      estimatePoint: estimatePoint ?? this.estimatePoint,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      linkCount: linkCount ?? this.linkCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class WorkItemState {
  final String id;
  final String name;
  final String? color;
  final String? group;
  final int? sequence;
  final bool isDefault;
  final String? slug;

  const WorkItemState({
    required this.id,
    required this.name,
    this.color,
    this.group,
    this.sequence,
    this.isDefault = false,
    this.slug,
  });
}

class WorkItemLabel {
  final String id;
  final String name;
  final String? color;
  final String? description;
  final bool isActive;
  final String? parent;

  const WorkItemLabel({
    required this.id,
    required this.name,
    this.color,
    this.description,
    this.isActive = true,
    this.parent,
  });
}

class WorkItemMember {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? avatar;

  const WorkItemMember({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.avatar,
  });

  String get fullName {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    return email ?? id;
  }
}

class Comment {
  final String id;
  final String commentHtml;
  final String? comment;
  final WorkItemMember? actor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.commentHtml,
    this.comment,
    this.actor,
    this.createdAt,
    this.updatedAt,
  });
}