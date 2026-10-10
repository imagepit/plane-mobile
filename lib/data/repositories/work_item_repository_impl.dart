import 'package:plane_mobile/domain/entities/work_item_page.dart';
import 'package:plane_mobile/domain/entities/comment_page.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/data/datasources/work_item_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/state_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/label_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/member_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/comment_remote_datasource.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';

class WorkItemRepositoryImpl implements WorkItemRepository {
  final WorkItemRemoteDataSource _workItemDataSource;
  final StateRemoteDataSource _stateDataSource;
  final LabelRemoteDataSource _labelDataSource;
  final MemberRemoteDataSource _memberDataSource;
  final CommentRemoteDataSource _commentDataSource;

  WorkItemRepositoryImpl(
    this._workItemDataSource,
    this._stateDataSource,
    this._labelDataSource,
    this._memberDataSource,
    this._commentDataSource,
  );

  @override
  Future<Either<Failure, WorkItemPage>> getWorkItems(
      String workspaceSlug, String projectId,
      {String? cursor}) async {
    try {
      final models = await _workItemDataSource
          .getWorkItems(workspaceSlug, projectId, cursor: cursor);
      return Right(models.map((m) => m.toEntity()));
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
  Future<Either<Failure, WorkItem>> getWorkItem(
      String workspaceSlug, String projectId, String itemId) async {
    try {
      final model = await _workItemDataSource.getWorkItem(
          workspaceSlug, projectId, itemId);
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

  @override
  Future<Either<Failure, WorkItem>> createWorkItem(
      String workspaceSlug, String projectId, Map<String, dynamic> data) async {
    try {
      final model = await _workItemDataSource.createWorkItem(
          workspaceSlug, projectId, data);
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

  @override
  Future<Either<Failure, WorkItem>> updateWorkItem(String workspaceSlug,
      String projectId, String itemId, Map<String, dynamic> data) async {
    try {
      final model = await _workItemDataSource.updateWorkItem(
          workspaceSlug, projectId, itemId, data);
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

  @override
  Future<Either<Failure, void>> deleteWorkItem(
      String workspaceSlug, String projectId, String itemId) async {
    try {
      await _workItemDataSource.deleteWorkItem(
          workspaceSlug, projectId, itemId);
      return const Right(null);
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
  Future<Either<Failure, List<WorkItemState>>> getStates(
      String workspaceSlug, String projectId) async {
    try {
      final models = await _stateDataSource.getStates(workspaceSlug, projectId);
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
  Future<Either<Failure, List<WorkItemLabel>>> getLabels(
      String workspaceSlug, String projectId) async {
    try {
      final models = await _labelDataSource.getLabels(workspaceSlug, projectId);
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
  Future<Either<Failure, List<WorkItemMember>>> getMembers(
      String workspaceSlug, String projectId) async {
    try {
      final models =
          await _memberDataSource.getMembers(workspaceSlug, projectId);
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
  Future<Either<Failure, CommentPage>> getComments(
      String workspaceSlug, String projectId, String itemId,
      {String? cursor}) async {
    try {
      final models = await _commentDataSource
          .getComments(workspaceSlug, projectId, itemId, cursor: cursor);
      return Right(models.map((m) => m.toEntity()));
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
  Future<Either<Failure, Comment>> addComment(String workspaceSlug,
      String projectId, String itemId, String commentHtml) async {
    try {
      final model = await _commentDataSource.addComment(
          workspaceSlug, projectId, itemId, commentHtml);
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
