import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class GetMembers {
  final WorkItemRepository _repository;

  GetMembers(this._repository);

  Future<Either<Failure, List<WorkItemMember>>> call(
      String workspaceSlug, String projectId) async {
    return _repository.getMembers(workspaceSlug, projectId);
  }
}