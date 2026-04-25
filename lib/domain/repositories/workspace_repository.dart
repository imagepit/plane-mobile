import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/workspace.dart';

abstract class WorkspaceRepository {
  Future<Either<Failure, List<Workspace>>> getWorkspaces();
}