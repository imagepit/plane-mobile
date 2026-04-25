import 'package:bloc/bloc.dart';
import 'package:plane_mobile/domain/entities/workspace.dart';
import 'package:plane_mobile/domain/usecases/get_workspaces.dart';

part 'workspace_event.dart';
part 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final GetWorkspaces _getWorkspaces;

  WorkspaceBloc({required GetWorkspaces getWorkspaces})
      : _getWorkspaces = getWorkspaces,
        super(WorkspaceInitial()) {
    on<LoadWorkspaces>(_onLoadWorkspaces);
  }

  Future<void> _onLoadWorkspaces(
      LoadWorkspaces event, Emitter<WorkspaceState> emit) async {
    emit(WorkspaceLoading());
    final result = await _getWorkspaces();
    result.fold(
      (failure) => emit(WorkspaceError(message: failure.message)),
      (workspaces) => emit(WorkspacesLoaded(workspaces: workspaces)),
    );
  }
}