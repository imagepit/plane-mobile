import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/data/datasources/workspace_remote_datasource.dart';
import 'package:plane_mobile/domain/entities/workspace.dart';
import 'package:plane_mobile/domain/repositories/workspace_repository.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceRemoteDataSource _remoteDataSource;

  WorkspaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Workspace>>> getWorkspaces() async {
    try {
      final models = await _remoteDataSource.getWorkspaces();
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
}