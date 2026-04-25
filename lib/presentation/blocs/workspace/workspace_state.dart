part of 'workspace_bloc.dart';

abstract class WorkspaceState {}

class WorkspaceInitial extends WorkspaceState {}

class WorkspaceLoading extends WorkspaceState {}

class WorkspacesLoaded extends WorkspaceState {
  final List<Workspace> workspaces;
  WorkspacesLoaded({required this.workspaces});
}

class WorkspaceError extends WorkspaceState {
  final String message;
  WorkspaceError({required this.message});
}