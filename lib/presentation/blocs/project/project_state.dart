part of 'project_bloc.dart';

abstract class ProjectState {}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectsLoaded extends ProjectState {
  final List<Project> projects;
  final String workspaceSlug;
  ProjectsLoaded({required this.projects, required this.workspaceSlug});
}

class ProjectError extends ProjectState {
  final String message;
  ProjectError({required this.message});
}