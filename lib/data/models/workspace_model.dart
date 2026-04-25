import 'package:plane_mobile/domain/entities/workspace.dart';

class WorkspaceModel {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final int? totalMembers;
  final int? totalProjects;

  const WorkspaceModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.totalMembers,
    this.totalProjects,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logo: json['logo'] as String?,
      totalMembers: json['total_members'] as int?,
      totalProjects: json['total_projects'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo': logo,
        'total_members': totalMembers,
        'total_projects': totalProjects,
      };

  Workspace toEntity() => Workspace(
        id: id,
        name: name,
        slug: slug,
        logo: logo,
        memberCount: totalMembers,
        projectCount: totalProjects,
      );
}