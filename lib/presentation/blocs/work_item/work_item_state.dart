part of 'work_item_bloc.dart';

/// Reads and writes have independent progress; cached content stays visible.
class WorkItemState {
  final List<entities.WorkItem> workItems;
  final entities.WorkItem? workItem;
  final List<entities.Comment> comments;
  final List<entities.WorkItemState> states;
  final List<entities.WorkItemLabel> labels;
  final List<entities.WorkItemMember> members;
  final bool loading, loadingMore, detailLoading, commentsLoading, busy;
  final String? nextCursor, commentsCursor;
  final bool hasNext,
      commentsHasNext,
      commentsUncertain,
      createUncertain,
      listRetryAppend;
  final Map<String, dynamic>? pendingCreate;
  final String? error, statesError, labelsError, membersError, commentsError;
  final String? completedRequest, failedRequest, savedRequest;
  final entities.WorkItem? createdItem;
  final String? deletedId;
  const WorkItemState(
      {this.workItems = const [],
      this.workItem,
      this.comments = const [],
      this.states = const [],
      this.labels = const [],
      this.members = const [],
      this.loading = false,
      this.loadingMore = false,
      this.detailLoading = false,
      this.commentsLoading = false,
      this.busy = false,
      this.nextCursor,
      this.commentsCursor,
      this.hasNext = false,
      this.commentsHasNext = false,
      this.commentsUncertain = false,
      this.createUncertain = false,
      this.listRetryAppend = false,
      this.pendingCreate,
      this.error,
      this.statesError,
      this.labelsError,
      this.membersError,
      this.commentsError,
      this.completedRequest,
      this.failedRequest,
      this.savedRequest,
      this.createdItem,
      this.deletedId});

  WorkItemState copyWith(
          {List<entities.WorkItem>? workItems,
          entities.WorkItem? workItem,
          List<entities.Comment>? comments,
          List<entities.WorkItemState>? states,
          List<entities.WorkItemLabel>? labels,
          List<entities.WorkItemMember>? members,
          bool? loading,
          bool? loadingMore,
          bool? detailLoading,
          bool? commentsLoading,
          bool? busy,
          String? nextCursor,
          String? commentsCursor,
          bool? hasNext,
          bool? commentsHasNext,
          bool? commentsUncertain,
          bool? createUncertain,
          bool? listRetryAppend,
          Map<String, dynamic>? pendingCreate,
          String? error,
          bool clearError = false,
          String? statesError,
          String? labelsError,
          String? membersError,
          bool clearSupportErrors = false,
          String? commentsError,
          bool clearCommentsError = false,
          String? completedRequest,
          String? failedRequest,
          String? savedRequest,
          entities.WorkItem? createdItem,
          String? deletedId}) =>
      WorkItemState(
        workItems: workItems ?? this.workItems,
        workItem: workItem ?? this.workItem,
        comments: comments ?? this.comments,
        states: states ?? this.states,
        labels: labels ?? this.labels,
        members: members ?? this.members,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        detailLoading: detailLoading ?? this.detailLoading,
        commentsLoading: commentsLoading ?? this.commentsLoading,
        busy: busy ?? this.busy,
        nextCursor: hasNext == false ? null : nextCursor ?? this.nextCursor,
        commentsCursor: commentsHasNext == false
            ? null
            : commentsCursor ?? this.commentsCursor,
        hasNext: hasNext ?? this.hasNext,
        commentsHasNext: commentsHasNext ?? this.commentsHasNext,
        commentsUncertain: commentsUncertain ?? this.commentsUncertain,
        createUncertain: createUncertain ?? this.createUncertain,
        listRetryAppend: listRetryAppend ?? this.listRetryAppend,
        pendingCreate: createUncertain == false
            ? null
            : pendingCreate ?? this.pendingCreate,
        error: clearError ? null : error ?? this.error,
        statesError:
            clearSupportErrors ? statesError : statesError ?? this.statesError,
        labelsError:
            clearSupportErrors ? labelsError : labelsError ?? this.labelsError,
        membersError: clearSupportErrors
            ? membersError
            : membersError ?? this.membersError,
        commentsError:
            clearCommentsError ? null : commentsError ?? this.commentsError,
        completedRequest: completedRequest ?? this.completedRequest,
        failedRequest: failedRequest ?? this.failedRequest,
        savedRequest: savedRequest ?? this.savedRequest,
        createdItem: createdItem ?? this.createdItem,
        deletedId: deletedId ?? this.deletedId,
      );
}
