part of 'work_item_bloc.dart';

int _requestSeed = 0;

abstract class WorkItemEvent {
  final String requestId;
  WorkItemEvent({String? requestId})
      : requestId = requestId ?? '${++_requestSeed}';
}

class LoadWorkItems extends WorkItemEvent {
  final String workspaceSlug, projectId;
  final bool append;
  LoadWorkItems(
      {required this.workspaceSlug,
      required this.projectId,
      this.append = false,
      super.requestId});
}

class LoadWorkItemDetail extends WorkItemEvent {
  final String workspaceSlug, projectId, itemId;
  LoadWorkItemDetail(
      {required this.workspaceSlug,
      required this.projectId,
      required this.itemId,
      super.requestId});
}

class LoadStates extends WorkItemEvent {
  final String workspaceSlug, projectId;
  LoadStates(
      {required this.workspaceSlug, required this.projectId, super.requestId});
}

class LoadLabels extends WorkItemEvent {
  final String workspaceSlug, projectId;
  LoadLabels(
      {required this.workspaceSlug, required this.projectId, super.requestId});
}

class LoadMembers extends WorkItemEvent {
  final String workspaceSlug, projectId;
  LoadMembers(
      {required this.workspaceSlug, required this.projectId, super.requestId});
}

class LoadComments extends WorkItemEvent {
  final String workspaceSlug, projectId, itemId;
  final bool append, allPages;
  LoadComments(
      {required this.workspaceSlug,
      required this.projectId,
      required this.itemId,
      this.append = false,
      this.allPages = false,
      super.requestId});
}

abstract class WriteWorkItem extends WorkItemEvent {
  final String workspaceSlug, projectId;
  final String? itemId;
  WriteWorkItem(
      {required this.workspaceSlug,
      required this.projectId,
      this.itemId,
      super.requestId});
  String get key => '$workspaceSlug/$projectId/${itemId ?? 'new'}';
}

class CreateWorkItemEvent extends WriteWorkItem {
  final Map<String, dynamic> data;
  CreateWorkItemEvent(
      {required super.workspaceSlug,
      required super.projectId,
      required this.data,
      super.requestId});
}

class UpdateWorkItemEvent extends WriteWorkItem {
  final Map<String, dynamic> data;
  UpdateWorkItemEvent(
      {required super.workspaceSlug,
      required super.projectId,
      required String itemId,
      required this.data,
      super.requestId})
      : super(itemId: itemId);
}

class DeleteWorkItemEvent extends WriteWorkItem {
  DeleteWorkItemEvent(
      {required super.workspaceSlug,
      required super.projectId,
      required String itemId,
      super.requestId})
      : super(itemId: itemId);
}

class AddCommentEvent extends WriteWorkItem {
  final String commentHtml;
  AddCommentEvent(
      {required super.workspaceSlug,
      required super.projectId,
      required String itemId,
      required this.commentHtml,
      super.requestId})
      : super(itemId: itemId);
}

class ResolveCommentUncertainty extends WorkItemEvent {
  final String itemId;
  ResolveCommentUncertainty({required this.itemId});
}

class ResolveCreateUncertainty extends WorkItemEvent {}
