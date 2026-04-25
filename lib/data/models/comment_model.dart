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
      actor: json['actor'] != null
          ? WorkItemMemberModel.fromJson(
              json['actor'] as Map<String, dynamic>)
          : json['actor_detail'] != null
              ? WorkItemMemberModel.fromJson(
                  json['actor_detail'] as Map<String, dynamic>)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
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