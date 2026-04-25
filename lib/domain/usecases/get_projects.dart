import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/domain/repositories/project_repository.dart';

class GetProjects {
  final ProjectRepository _repository;

  GetProjects(this._repository);

  Future<Either<Failure, List<Project>>> call(String workspaceSlug) async {
    return _repository.getProjects(workspaceSlug);
  }
}