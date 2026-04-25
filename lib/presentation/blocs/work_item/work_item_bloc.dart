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
        super(WorkItemInitial()) {
    on<LoadWorkItems>(_onLoadWorkItems);
    on<LoadWorkItemDetail>(_onLoadWorkItemDetail);
    on<CreateWorkItemEvent>(_onCreateWorkItem);
    on<UpdateWorkItemEvent>(_onUpdateWorkItem);
    on<DeleteWorkItemEvent>(_onDeleteWorkItem);
    on<LoadStates>(_onLoadStates);
    on<LoadLabels>(_onLoadLabels);
    on<LoadMembers>(_onLoadMembers);
    on<LoadComments>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
  }

  Future<void> _onLoadWorkItems(
      LoadWorkItems event, Emitter<WorkItemState> emit) async {
    emit(WorkItemLoading());
    final result = await _getWorkItems(event.workspaceSlug, event.projectId);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (workItems) => emit(WorkItemsLoaded(workItems: workItems)),
    );
  }

  Future<void> _onLoadWorkItemDetail(
      LoadWorkItemDetail event, Emitter<WorkItemState> emit) async {
    emit(WorkItemLoading());
    final result = await _getWorkItem(
        event.workspaceSlug, event.projectId, event.itemId);
    // Also load supporting data
    final statesResult = await _getStates(event.workspaceSlug, event.projectId);
    final labelsResult = await _getLabels(event.workspaceSlug, event.projectId);
    final membersResult =
        await _getMembers(event.workspaceSlug, event.projectId);
    final commentsResult = await _getComments(
        event.workspaceSlug, event.projectId, event.itemId);

    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (workItem) => emit(WorkItemDetail(
        workItem: workItem,
        states: statesResult.fold((_) => const [], (s) => s),
        labels: labelsResult.fold((_) => const [], (l) => l),
        members: membersResult.fold((_) => const [], (m) => m),
        comments: commentsResult.fold((_) => const [], (c) => c),
      )),
    );
  }

  Future<void> _onCreateWorkItem(
      CreateWorkItemEvent event, Emitter<WorkItemState> emit) async {
    emit(WorkItemActionLoading(previousState: state));
    final result = await _createWorkItem(
        event.workspaceSlug, event.projectId, event.data);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (workItem) => emit(WorkItemCreated(workItem: workItem)),
    );
  }

  Future<void> _onUpdateWorkItem(
      UpdateWorkItemEvent event, Emitter<WorkItemState> emit) async {
    emit(WorkItemActionLoading(previousState: state));
    final result = await _updateWorkItem(
        event.workspaceSlug, event.projectId, event.itemId, event.data);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (workItem) => emit(WorkItemUpdated(workItem: workItem)),
    );
  }

  Future<void> _onDeleteWorkItem(
      DeleteWorkItemEvent event, Emitter<WorkItemState> emit) async {
    emit(WorkItemActionLoading(previousState: state));
    final result = await _deleteWorkItem(
        event.workspaceSlug, event.projectId, event.itemId);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (_) => emit(WorkItemDeleted()),
    );
  }

  Future<void> _onLoadStates(
      LoadStates event, Emitter<WorkItemState> emit) async {
    final result = await _getStates(event.workspaceSlug, event.projectId);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (states) => emit(StatesLoaded(states: states)),
    );
  }

  Future<void> _onLoadLabels(
      LoadLabels event, Emitter<WorkItemState> emit) async {
    final result = await _getLabels(event.workspaceSlug, event.projectId);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (labels) => emit(LabelsLoaded(labels: labels)),
    );
  }

  Future<void> _onLoadMembers(
      LoadMembers event, Emitter<WorkItemState> emit) async {
    final result = await _getMembers(event.workspaceSlug, event.projectId);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (members) => emit(MembersLoaded(members: members)),
    );
  }

  Future<void> _onLoadComments(
      LoadComments event, Emitter<WorkItemState> emit) async {
    final result = await _getComments(
        event.workspaceSlug, event.projectId, event.itemId);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (comments) => emit(CommentsLoaded(comments: comments)),
    );
  }

  Future<void> _onAddComment(
      AddCommentEvent event, Emitter<WorkItemState> emit) async {
    final result = await _addComment(event.workspaceSlug, event.projectId,
        event.itemId, event.commentHtml);
    result.fold(
      (failure) => emit(WorkItemError(message: failure.message)),
      (_) {
        add(LoadComments(
          workspaceSlug: event.workspaceSlug,
          projectId: event.projectId,
          itemId: event.itemId,
        ));
      },
    );
  }
}