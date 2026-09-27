import 'package:plane_mobile/data/models/state_model.dart';
import 'package:plane_mobile/data/models/label_model.dart';
import 'package:plane_mobile/data/models/member_model.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemModel {
  final String id;
  final String name;
  final int sequenceId;
  final String? description;
  final String? descriptionHtml;
  final WorkItemStateModel? stateDetail;
  final List<String>? labelIds;
  final List<WorkItemLabelModel>? labels;
  final List<WorkItemMemberModel>? assignees;
  final List<String>? assigneesIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? startDate;
  final String? targetDate;
  final String? priority;
  final String? projectId;
  final String? workspaceSlug;
  final WorkItemMemberModel? createdBy;
  final String? estimatePoint;
  final int? attachmentCount;
  final int? linkCount;
  final bool? isFavorite;

  const WorkItemModel({
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

  factory WorkItemModel.fromJson(Map<String, dynamic> json) {
    final labels = _labelsFrom(json['labels']);
    final assignees = _membersFrom(json['assignees']);
    return WorkItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sequenceId: json['sequence_id'] as int? ?? 0,
      description: (json['description'] as String?) ??
          (json['description_html'] as String?),
      descriptionHtml: json['description_html'] as String?,
      stateDetail: _stateFrom(json),
      labelIds: (json['label_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          labels.map((e) => e.id).toList(),
      labels: labels,
      assignees: assignees,
      assigneesIds: (json['assignees_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          assignees.map((e) => e.id).toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      startDate: json['start_date'] as String?,
      targetDate: json['target_date'] as String?,
      priority: json['priority'] as String?,
      projectId: json['project'] as String?,
      workspaceSlug: json['workspace'] as String?,
      createdBy: json['created_by'] is Map<String, dynamic>
          ? WorkItemMemberModel.fromJson(
              json['created_by'] as Map<String, dynamic>)
          : json['created_by'] != null
              ? WorkItemMemberModel.fromJson(
                  {'id': (json['created_by'] as Object).toString()})
              : null,
      estimatePoint: json['estimate_point'] as String?,
      attachmentCount: json['attachment_count'] as int?,
      linkCount: json['link_count'] as int?,
      isFavorite: json['is_favorite'] as bool?,
    );
  }

  /// v1 では `state` が expand 済みオブジェクト（color/group/id/name）で返る。
  /// 旧キー `state_detail` も受け付ける。
  static WorkItemStateModel? _stateFrom(Map<String, dynamic> json) {
    final legacy = json['state_detail'];
    if (legacy is Map<String, dynamic>) {
      return WorkItemStateModel.fromJson(legacy);
    }
    final state = json['state'];
    if (state is Map<String, dynamic>) {
      return WorkItemStateModel.fromJson(state);
    }
    return null;
  }

  /// labels / assignees は ID文字列と id 付きオブジェクトの両方で来るため両対応で読む。
  static List<WorkItemLabelModel> _labelsFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => WorkItemLabelModel.fromJson(
            e is Map<String, dynamic> ? e : {'id': e.toString()}))
        .toList();
  }

  static List<WorkItemMemberModel> _membersFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => WorkItemMemberModel.fromJson(
            e is Map<String, dynamic> ? e : {'id': e.toString()}))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sequence_id': sequenceId,
        'description': description,
        'description_html': descriptionHtml,
        'start_date': startDate,
        'target_date': targetDate,
        'priority': priority,
        'state': stateDetail?.id,
        'label_ids': labelIds,
        'assignees_ids': assigneesIds,
        'project': projectId,
        'workspace': workspaceSlug,
      };

  WorkItem toEntity() => WorkItem(
        id: id,
        name: name,
        sequenceId: sequenceId,
        description: description,
        descriptionHtml: descriptionHtml,
        stateDetail: stateDetail?.toEntity(),
        labelIds: labelIds,
        labels: labels?.map((e) => e.toEntity()).toList(),
        assignees: assignees?.map((e) => e.toEntity()).toList(),
        assigneesIds: assigneesIds,
        createdAt: createdAt,
        updatedAt: updatedAt,
        startDate: startDate,
        targetDate: targetDate,
        priority: priority,
        projectId: projectId,
        workspaceSlug: workspaceSlug,
        createdBy: createdBy?.toEntity(),
        estimatePoint: estimatePoint,
        attachmentCount: attachmentCount,
        linkCount: linkCount,
        isFavorite: isFavorite,
      );
}