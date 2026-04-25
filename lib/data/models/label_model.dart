import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemLabelModel {
  final String id;
  final String name;
  final String? color;
  final String? description;
  final bool isActive;
  final String? parent;

  const WorkItemLabelModel({
    required this.id,
    required this.name,
    this.color,
    this.description,
    this.isActive = true,
    this.parent,
  });

  factory WorkItemLabelModel.fromJson(Map<String, dynamic> json) {
    return WorkItemLabelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      parent: json['parent'] as String?,
    );
  }

  WorkItemLabel toEntity() => WorkItemLabel(
        id: id,
        name: name,
        color: color,
        description: description,
        isActive: isActive,
        parent: parent,
      );
}