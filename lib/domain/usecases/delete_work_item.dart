import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class DeleteWorkItem {
  final WorkItemRepository _repository;

  DeleteWorkItem(this._repository);

  Future<Either<Failure, void>> call(
      String workspaceSlug, String projectId, String itemId) async {
    return _repository.deleteWorkItem(workspaceSlug, projectId, itemId);
  }
}