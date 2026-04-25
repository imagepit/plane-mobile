import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetStates {
  final WorkItemRepository _repository;

  GetStates(this._repository);

  Future<Either<Failure, List<WorkItemState>>> call(
      String workspaceSlug, String projectId) async {
    return _repository.getStates(workspaceSlug, projectId);
  }
}