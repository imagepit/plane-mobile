import 'package:plane_mobile/data/models/member_model.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

class CommentModel {
  final String id;
  final String commentHtml;
  final String? comment;
  final WorkItemMemberModel? actor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommentModel({
    required this.id,
    required this.commentHtml,
    this.comment,
    this.actor,
    this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String? ?? '',
      commentHtml: json['comment_html'] as String? ?? '',
      comment: json['comment'] as String?,
      actor: _actorFrom(json),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// v1 では `actor` は ID文字列。id 付きオブジェクト（旧 `actor_detail`）も受ける。
  static WorkItemMemberModel? _actorFrom(Map<String, dynamic> json) {
    for (final key in ['actor', 'actor_detail', 'created_by']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return WorkItemMemberModel.fromJson(value);
      }
      if (value is String && value.isNotEmpty) {
        return WorkItemMemberModel.fromJson({'id': value});
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'comment_html': commentHtml,
        'comment': comment,
      };

  Comment toEntity() => Comment(
        id: id,
        commentHtml: commentHtml,
        comment: comment,
        actor: actor?.toEntity(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}