import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/project.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<Project>>> getProjects(String workspaceSlug);
  Future<Either<Failure, Project>> getProject(
      String workspaceSlug, String projectId);
}