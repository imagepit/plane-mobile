import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/workspace.dart';
import 'package:plane_mobile/domain/repositories/workspace_repository.dart';

class GetWorkspaces {
  final WorkspaceRepository _repository;

  GetWorkspaces(this._repository);

  Future<Either<Failure, List<Workspace>>> call() async {
    return _repository.getWorkspaces();
  }
}