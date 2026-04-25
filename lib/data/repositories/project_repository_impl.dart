import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/data/datasources/project_remote_datasource.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource _remoteDataSource;

  ProjectRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Project>>> getProjects(
      String workspaceSlug) async {
    try {
      final models = await _remoteDataSource.getProjects(workspaceSlug);
      return Right(models.map((m) => m.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    }
  }

  @override
  Future<Either<Failure, Project>> getProject(
      String workspaceSlug, String projectId) async {
    try {
      final model =
          await _remoteDataSource.getProject(workspaceSlug, projectId);
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    }
  }
}