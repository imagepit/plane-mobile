import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class CreateWorkItem {
  final WorkItemRepository _repository;

  CreateWorkItem(this._repository);

  Future<Either<Failure, WorkItem>> call(
      String workspaceSlug, String projectId, Map<String, dynamic> data) async {
    return _repository.createWorkItem(workspaceSlug, projectId, data);
  }
}