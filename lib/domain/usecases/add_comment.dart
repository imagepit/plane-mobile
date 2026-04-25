import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class AddComment {
  final WorkItemRepository _repository;

  AddComment(this._repository);

  Future<Either<Failure, Comment>> call(String workspaceSlug,
      String projectId, String itemId, String commentHtml) async {
    return _repository.addComment(workspaceSlug, projectId, itemId, commentHtml);
  }
}