import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetWorkItems {
  final WorkItemRepository _repository;

  GetWorkItems(this._repository);

  Future<Either<Failure, List<WorkItem>>> call(
      String workspaceSlug, String projectId) async {
    return _repository.getWorkItems(workspaceSlug, projectId);
  }
}