import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemStateModel {
  final String id;
  final String name;
  final String? color;
  final String? group;
  final int? sequence;
  final bool isDefault;
  final String? slug;

  const WorkItemStateModel({
    required this.id,
    required this.name,
    this.color,
    this.group,
    this.sequence,
    this.isDefault = false,
    this.slug,
  });

  factory WorkItemStateModel.fromJson(Map<String, dynamic> json) {
    return WorkItemStateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      group: json['group'] as String?,
      sequence: json['sequence'] as int?,
      isDefault: json['default'] as bool? ?? false,
      slug: json['slug'] as String?,
    );
  }

  WorkItemState toEntity() => WorkItemState(
        id: id,
        name: name,
        color: color,
        group: group,
        sequence: sequence,
        isDefault: isDefault,
        slug: slug,
      );
}