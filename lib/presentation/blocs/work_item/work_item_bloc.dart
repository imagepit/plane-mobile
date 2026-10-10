import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item_page.dart';
import 'package:bloc/bloc.dart';
import 'package:plane_mobile/domain/entities/work_item.dart' as entities;
import 'package:plane_mobile/domain/usecases/get_work_items.dart';
import 'package:plane_mobile/domain/usecases/get_work_item.dart';
import 'package:plane_mobile/domain/usecases/create_work_item.dart';
import 'package:plane_mobile/domain/usecases/update_work_item.dart';
import 'package:plane_mobile/domain/usecases/delete_work_item.dart';
import 'package:plane_mobile/domain/usecases/get_states.dart';
import 'package:plane_mobile/domain/usecases/get_labels.dart';
import 'package:plane_mobile/domain/usecases/get_members.dart';
import 'package:plane_mobile/domain/usecases/get_comments.dart';
import 'package:plane_mobile/domain/usecases/add_comment.dart';

part 'work_item_event.dart';
part 'work_item_state.dart';

class WorkItemBloc extends Bloc<WorkItemEvent, WorkItemState> {
  final GetWorkItems _getWorkItems;
  final GetWorkItem _getWorkItem;
  final CreateWorkItem _createWorkItem;
  final UpdateWorkItem _updateWorkItem;
  final DeleteWorkItem _deleteWorkItem;
  final GetStates _getStates;
  final GetLabels _getLabels;
  final GetMembers _getMembers;
  final GetComments _getComments;
  final AddComment _addComment;

  WorkItemBloc({
    required GetWorkItems getWorkItems,
    required GetWorkItem getWorkItem,
    required CreateWorkItem createWorkItem,
    required UpdateWorkItem updateWorkItem,
    required DeleteWorkItem deleteWorkItem,
    required GetStates getStates,
    required GetLabels getLabels,
    required GetMembers getMembers,
    required GetComments getComments,
    required AddComment addComment,
  })  : _getWorkItems = getWorkItems,
        _getWorkItem = getWorkItem,
        _createWorkItem = createWorkItem,
        _updateWorkItem = updateWorkItem,
        _deleteWorkItem = deleteWorkItem,
        _getStates = getStates,
        _getLabels = getLabels,
        _getMembers = getMembers,
        _getComments = getComments,
        _addComment = addComment,
        super(const WorkItemState()) {
    // One ordered event queue prevents a late read from overwriting a write.
    on<WorkItemEvent>(_handle,
        transformer: (events, mapper) => events.asyncExpand(mapper));
  }
  final _uncertainItems = <String>{};
  bool isCommentUncertain(String itemId) => _uncertainItems.contains(itemId);
  final _pendingWrites = <String>{};
  final _itemCursors = <String>{};
  final _commentCursors = <String>{};

  @override
  void add(WorkItemEvent event) {
    if (event is WriteWorkItem && !_pendingWrites.add(event.key)) return;
    super.add(event);
  }

  Future<bool> execute(WorkItemEvent event) async {
    if (event is WriteWorkItem && _pendingWrites.contains(event.key))
      return false;
    final completion =
        stream.firstWhere((s) => s.completedRequest == event.requestId);
    add(event);
    final done = await completion;
    return done.failedRequest != event.requestId;
  }

  bool _uncertainFailure(Failure failure) =>
      failure is ConnectionFailure ||
      (failure is ServerFailure &&
          (failure.statusCode == null || failure.statusCode! >= 500));
  String? _failureMessage(dynamic either) =>
      either.fold<String?>((f) => f.message as String, (_) => null);
  List<T> _merge<T>(List<T> old, List<T> added, String Function(T) id) => {
        for (final x in old) id(x): x,
        for (final x in added) id(x): x
      }.values.toList();

  Future<void> _handle(WorkItemEvent e, Emitter<WorkItemState> emit) async {
    bool success = true;
    try {
      if (e is ResolveCreateUncertainty) {
        emit(state.copyWith(createUncertain: false));
      } else if (e is ResolveCommentUncertainty) {
        _uncertainItems.remove(e.itemId);
        emit(state.copyWith(commentsUncertain: false));
      } else if (e is LoadWorkItems) {
        if (e.append && !state.hasNext) {
          emit(state.copyWith(completedRequest: e.requestId));
          return;
        }
        emit(state.copyWith(
            loading: !e.append,
            loadingMore: e.append,
            listRetryAppend: e.append,
            clearError: true));
        final cursor = e.append ? state.nextCursor : null;
        final result =
            await _getWorkItems(e.workspaceSlug, e.projectId, cursor: cursor);
        result.fold((f) {
          success = false;
          emit(state.copyWith(error: f.message));
        }, (page) {
          if (!e.append) _itemCursors.clear();
          if (page.hasNext &&
              (!_itemCursors.add(page.nextCursor!) ||
                  page.nextCursor == cursor)) {
            success = false;
            emit(state.copyWith(error: 'Repeated pagination cursor'));
            return;
          }
          emit(state.copyWith(
              workItems: _merge(
                  e.append ? state.workItems : [], page.items, (x) => x.id),
              nextCursor: page.nextCursor,
              hasNext: page.hasNext));
        });
        emit(state.copyWith(loading: false, loadingMore: false));
      } else if (e is LoadWorkItemDetail) {
        final sameItem = state.workItem?.id == e.itemId;
        emit(state.copyWith(
            detailLoading: true,
            clearError: true,
            commentsUncertain: _uncertainItems.contains(e.itemId),
            comments: sameItem ? null : [],
            commentsHasNext: sameItem ? null : false,
            clearCommentsError: !sameItem,
            commentsLoading: true));
        final item = await _getWorkItem(e.workspaceSlug, e.projectId, e.itemId);
        item.fold((f) {
          success = false;
          emit(state.copyWith(error: f.message));
        },
            (item) => emit(state.copyWith(
                workItem: item,
                workItems: _merge(state.workItems, [item], (x) => x.id))));
        if (success) {
          // Start independent supporting reads together.
          final states = _getStates(e.workspaceSlug, e.projectId);
          final labels = _getLabels(e.workspaceSlug, e.projectId);
          final members = _getMembers(e.workspaceSlug, e.projectId);
          final comments = _getComments(e.workspaceSlug, e.projectId, e.itemId);
          final sr = await states,
              lr = await labels,
              mr = await members,
              cr = await comments;
          final page =
              cr.fold<CursorPage<entities.Comment>?>((_) => null, (p) => p);
          if (page != null || !sameItem) _commentCursors.clear();
          if (page?.nextCursor != null) _commentCursors.add(page!.nextCursor!);
          emit(state.copyWith(
              states: sr.fold((_) => state.states, (s) => s),
              labels: lr.fold((_) => state.labels, (s) => s),
              members: mr.fold((_) => state.members, (s) => s),
              clearSupportErrors: true,
              statesError: _failureMessage(sr),
              labelsError: _failureMessage(lr),
              membersError: _failureMessage(mr),
              comments: page?.items ?? (sameItem ? state.comments : []),
              commentsCursor:
                  page?.nextCursor ?? (sameItem ? state.commentsCursor : null),
              commentsHasNext:
                  page?.hasNext ?? (sameItem && state.commentsHasNext),
              clearCommentsError: page != null,
              commentsError: _failureMessage(cr)));
        }
        emit(state.copyWith(detailLoading: false, commentsLoading: false));
      } else if (e is LoadStates) {
        final result = await _getStates(e.workspaceSlug, e.projectId);
        success = result.isRight();
        emit(state.copyWith(
            states: result.fold((_) => state.states, (x) => x),
            clearSupportErrors: true,
            statesError: _failureMessage(result),
            labelsError: state.labelsError,
            membersError: state.membersError));
      } else if (e is LoadLabels) {
        final result = await _getLabels(e.workspaceSlug, e.projectId);
        success = result.isRight();
        emit(state.copyWith(
            labels: result.fold((_) => state.labels, (x) => x),
            clearSupportErrors: true,
            labelsError: _failureMessage(result),
            statesError: state.statesError,
            membersError: state.membersError));
      } else if (e is LoadMembers) {
        final result = await _getMembers(e.workspaceSlug, e.projectId);
        success = result.isRight();
        emit(state.copyWith(
            members: result.fold((_) => state.members, (x) => x),
            clearSupportErrors: true,
            membersError: _failureMessage(result),
            statesError: state.statesError,
            labelsError: state.labelsError));
      } else if (e is LoadComments) {
        if (e.append && !state.commentsHasNext) {
          emit(state.copyWith(completedRequest: e.requestId));
          return;
        }
        emit(state.copyWith(commentsLoading: true, clearCommentsError: true));
        String? cursor = e.append ? state.commentsCursor : null;
        final loaded = <entities.Comment>[];
        final seen = e.append ? {..._commentCursors} : <String>{};
        CursorPage<entities.Comment>? last;
        do {
          final result = await _getComments(
              e.workspaceSlug, e.projectId, e.itemId,
              cursor: cursor);
          result.fold((f) {
            success = false;
            emit(state.copyWith(commentsError: f.message));
          }, (page) {
            last = page;
          });
          if (!success) break;
          if (last!.hasNext &&
              (!seen.add(last!.nextCursor!) || last!.nextCursor == cursor)) {
            success = false;
            emit(state.copyWith(commentsError: 'Repeated pagination cursor'));
            break;
          }
          loaded.addAll(last!.items);
          cursor = last!.nextCursor;
        } while (e.allPages && last!.hasNext);
        if (success) {
          _commentCursors
            ..clear()
            ..addAll(seen);
          emit(state.copyWith(
              comments:
                  _merge(e.append ? state.comments : [], loaded, (x) => x.id),
              commentsCursor: last!.nextCursor,
              commentsHasNext: last!.hasNext,
              clearCommentsError: true));
        }
        emit(state.copyWith(commentsLoading: false));
      } else if (e is WriteWorkItem) {
        if (e is AddCommentEvent && _uncertainItems.contains(e.itemId)) {
          _pendingWrites.remove(e.key);
          emit(state.copyWith(
              completedRequest: e.requestId,
              failedRequest: e.requestId,
              commentsUncertain: true));
          return;
        }
        emit(state.copyWith(busy: true, clearError: true));
        if (e is CreateWorkItemEvent) {
          if (state.createUncertain) {
            _pendingWrites.remove(e.key);
            emit(state.copyWith(
                busy: false,
                completedRequest: e.requestId,
                failedRequest: e.requestId));
            return;
          }
          emit(state.copyWith(pendingCreate: Map.of(e.data)));
          final result =
              await _createWorkItem(e.workspaceSlug, e.projectId, e.data);
          result.fold((f) {
            success = false;
            emit(state.copyWith(
                error: f.message, createUncertain: _uncertainFailure(f)));
          },
              (item) => emit(state.copyWith(
                  createUncertain: false,
                  createdItem: item,
                  workItems: _merge(state.workItems, [item], (x) => x.id))));
        } else if (e is UpdateWorkItemEvent) {
          final result = await _updateWorkItem(
              e.workspaceSlug, e.projectId, e.itemId!, e.data);
          entities.WorkItem? updated;
          result.fold((f) {
            success = false;
            emit(state.copyWith(error: f.message));
          }, (x) => updated = x);
          if (updated != null &&
              (updated!.stateDetail == null ||
                  updated!.assignees?.any((x) => x.fullName == x.id) == true ||
                  updated!.labels?.any((x) => x.name.isEmpty) == true)) {
            // PATCH may omit expand; preserve the old display if completion GET fails.
            final full =
                await _getWorkItem(e.workspaceSlug, e.projectId, e.itemId!);
            full.fold((f) {
              success = false;
              emit(state.copyWith(
                  error: 'Saved; reload to confirm: ${f.message}'));
            }, (x) => updated = x);
          }
          if (success && updated != null)
            emit(state.copyWith(
                workItem: state.workItem?.id == e.itemId ? updated : null,
                workItems: _merge(state.workItems, [updated!], (x) => x.id),
                savedRequest: e.requestId));
        } else if (e is DeleteWorkItemEvent) {
          final result =
              await _deleteWorkItem(e.workspaceSlug, e.projectId, e.itemId!);
          result.fold((f) {
            success = false;
            emit(state.copyWith(error: f.message));
          },
              (_) => emit(state.copyWith(
                  deletedId: e.itemId,
                  workItems: state.workItems
                      .where((x) => x.id != e.itemId)
                      .toList())));
        } else if (e is AddCommentEvent) {
          final result = await _addComment(
              e.workspaceSlug, e.projectId, e.itemId!, e.commentHtml);
          result.fold((f) {
            success = false;
            if (f is ConnectionFailure ||
                (f is ServerFailure &&
                    (f.statusCode == null || f.statusCode! >= 500)))
              _uncertainItems.add(e.itemId!);
            emit(state.copyWith(
                error: f.message,
                commentsUncertain: f is ConnectionFailure ||
                    (f is ServerFailure &&
                        (f.statusCode == null || f.statusCode! >= 500))));
          }, (comment) {
            _uncertainItems.remove(e.itemId);
            if (state.workItem?.id == e.itemId)
              emit(state.copyWith(
                  comments: _merge(state.comments, [comment], (x) => x.id),
                  commentsUncertain: false,
                  savedRequest: e.requestId));
          });
        }
        _pendingWrites.remove(e.key);
        emit(state.copyWith(busy: false));
      }
    } catch (_) {
      success = false;
      if (e is WriteWorkItem) _pendingWrites.remove(e.key);
      if (e is AddCommentEvent) _uncertainItems.add(e.itemId!);
      emit(state.copyWith(
        loading: false,
        loadingMore: false,
        detailLoading: false,
        commentsLoading: false,
        busy: false,
        commentsUncertain: e is AddCommentEvent ? true : null,
        createUncertain: e is CreateWorkItemEvent ? true : null,
        error: 'Could not confirm the request. Your current content is kept.',
      ));
    }
    emit(state.copyWith(
        completedRequest: e.requestId,
        failedRequest: success ? null : e.requestId));
  }
}
