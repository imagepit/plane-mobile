import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetLabels {
  final WorkItemRepository _repository;

  GetLabels(this._repository);

  Future<Either<Failure, List<WorkItemLabel>>> call(
      String workspaceSlug, String projectId) async {
    return _repository.getLabels(workspaceSlug, projectId);
  }
}