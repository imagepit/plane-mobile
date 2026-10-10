import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/domain/repositories/project_repository.dart';

class GetProject {
  final ProjectRepository _repository;
  GetProject(this._repository);
  Future<Either<Failure, Project>> call(String slug, String id) =>
      _repository.getProject(slug, id);
}
