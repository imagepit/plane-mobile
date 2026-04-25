part of 'work_item_bloc.dart';

abstract class WorkItemState {}

class WorkItemInitial extends WorkItemState {}

class WorkItemLoading extends WorkItemState {}

class WorkItemsLoaded extends WorkItemState {
  final List<entities.WorkItem> workItems;
  WorkItemsLoaded({required this.workItems});
}

class WorkItemDetail extends WorkItemState {
  final entities.WorkItem workItem;
  final List<entities.Comment> comments;
  final List<entities.WorkItemState> states;
  final List<entities.WorkItemLabel> labels;
  final List<entities.WorkItemMember> members;
  WorkItemDetail({
    required this.workItem,
    this.comments = const [],
    this.states = const [],
    this.labels = const [],
    this.members = const [],
  });
}

class WorkItemCreated extends WorkItemState {
  final entities.WorkItem workItem;
  WorkItemCreated({required this.workItem});
}

class WorkItemUpdated extends WorkItemState {
  final entities.WorkItem workItem;
  WorkItemUpdated({required this.workItem});
}

class WorkItemDeleted extends WorkItemState {}

class StatesLoaded extends WorkItemState {
  final List<entities.WorkItemState> states;
  StatesLoaded({required this.states});
}

class LabelsLoaded extends WorkItemState {
  final List<entities.WorkItemLabel> labels;
  LabelsLoaded({required this.labels});
}

class MembersLoaded extends WorkItemState {
  final List<entities.WorkItemMember> members;
  MembersLoaded({required this.members});
}

class CommentsLoaded extends WorkItemState {
  final List<entities.Comment> comments;
  CommentsLoaded({required this.comments});
}

class WorkItemError extends WorkItemState {
  final String message;
  WorkItemError({required this.message});
}

class WorkItemActionLoading extends WorkItemState {
  final WorkItemState previousState;
  WorkItemActionLoading({required this.previousState});
}