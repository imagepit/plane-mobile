import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetWorkItem {
  final WorkItemRepository _repository;

  GetWorkItem(this._repository);

  Future<Either<Failure, WorkItem>> call(
      String workspaceSlug, String projectId, String itemId) async {
    return _repository.getWorkItem(workspaceSlug, projectId, itemId);
  }
}