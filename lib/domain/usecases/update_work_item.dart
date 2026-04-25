import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class UpdateWorkItem {
  final WorkItemRepository _repository;

  UpdateWorkItem(this._repository);

  Future<Either<Failure, WorkItem>> call(String workspaceSlug,
      String projectId, String itemId, Map<String, dynamic> data) async {
    return _repository.updateWorkItem(workspaceSlug, projectId, itemId, data);
  }
}