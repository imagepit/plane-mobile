part of 'work_item_bloc.dart';

abstract class WorkItemEvent {}

class LoadWorkItems extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  LoadWorkItems({required this.workspaceSlug, required this.projectId});
}

class LoadWorkItemDetail extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  final String itemId;
  LoadWorkItemDetail({
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
  });
}

class CreateWorkItemEvent extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  final Map<String, dynamic> data;
  CreateWorkItemEvent({
    required this.workspaceSlug,
    required this.projectId,
    required this.data,
  });
}

class UpdateWorkItemEvent extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  final String itemId;
  final Map<String, dynamic> data;
  UpdateWorkItemEvent({
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
    required this.data,
  });
}

class DeleteWorkItemEvent extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  final String itemId;
  DeleteWorkItemEvent({
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
  });
}

class LoadStates extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  LoadStates({required this.workspaceSlug, required this.projectId});
}

class LoadLabels extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  LoadLabels({required this.workspaceSlug, required this.projectId});
}

class LoadMembers extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  LoadMembers({required this.workspaceSlug, required this.projectId});
}

class LoadComments extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  final String itemId;
  LoadComments({
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
  });
}

class AddCommentEvent extends WorkItemEvent {
  final String workspaceSlug;
  final String projectId;
  final String itemId;
  final String commentHtml;
  AddCommentEvent({
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
    required this.commentHtml,
  });
}