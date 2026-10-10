import 'package:plane_mobile/domain/entities/comment_page.dart';
import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetComments {
  final WorkItemRepository _repository;

  GetComments(this._repository);

  Future<Either<Failure, CommentPage>> call(
      String workspaceSlug, String projectId, String itemId,
      {String? cursor}) async {
    return _repository.getComments(workspaceSlug, projectId, itemId,
        cursor: cursor);
  }
}
