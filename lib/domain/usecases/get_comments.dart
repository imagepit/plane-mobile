import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetComments {
  final WorkItemRepository _repository;

  GetComments(this._repository);

  Future<Either<Failure, List<Comment>>> call(
      String workspaceSlug, String projectId, String itemId) async {
    return _repository.getComments(workspaceSlug, projectId, itemId);
  }
}