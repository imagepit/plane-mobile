import 'package:plane_mobile/domain/entities/project.dart';

class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final String network;
  final String workspace;
  final String? defaultAssignee;
  final int? memberCount;
  final int? stateCount;
  final int? issueCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final bool isMember;
  final String? icon;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.network,
    required this.workspace,
    this.defaultAssignee,
    this.memberCount,
    this.stateCount,
    this.issueCount,
    this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.isMember = true,
    this.icon,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      network: json['network']?.toString() ?? '',
      workspace: json['workspace'] as String? ?? '',
      defaultAssignee: json['default_assignee'] as String?,
      memberCount: json['member_count'] as int?,
      stateCount: json['state_count'] as int?,
      issueCount: json['issue_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? true,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cover_image': coverImage,
        'network': network,
        'workspace': workspace,
        'default_assignee': defaultAssignee,
        'member_count': memberCount,
        'state_count': stateCount,
        'issue_count': issueCount,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_favorite': isFavorite,
        'is_member': isMember,
        'icon': icon,
      };

  Project toEntity() => Project(
        id: id,
        name: name,
        description: description,
        coverImage: coverImage,
        network: network,
        workspace: workspace,
        defaultAssignee: defaultAssignee,
        memberCount: memberCount,
        stateCount: stateCount,
        issueCount: issueCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isFavorite: isFavorite,
        isMember: isMember,
        icon: icon,
      );
}