import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';

abstract class WorkItemRepository {
  Future<Either<Failure, List<WorkItem>>> getWorkItems(
      String workspaceSlug, String projectId);
  Future<Either<Failure, WorkItem>> getWorkItem(
      String workspaceSlug, String projectId, String itemId);
  Future<Either<Failure, WorkItem>> createWorkItem(
      String workspaceSlug, String projectId, Map<String, dynamic> data);
  Future<Either<Failure, WorkItem>> updateWorkItem(String workspaceSlug,
      String projectId, String itemId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteWorkItem(
      String workspaceSlug, String projectId, String itemId);
  Future<Either<Failure, List<WorkItemState>>> getStates(
      String workspaceSlug, String projectId);
  Future<Either<Failure, List<WorkItemLabel>>> getLabels(
      String workspaceSlug, String projectId);
  Future<Either<Failure, List<WorkItemMember>>> getMembers(
      String workspaceSlug, String projectId);
  Future<Either<Failure, List<Comment>>> getComments(
      String workspaceSlug, String projectId, String itemId);
  Future<Either<Failure, Comment>> addComment(
      String workspaceSlug, String projectId, String itemId, String commentHtml);
}