part of 'project_bloc.dart';

abstract class ProjectEvent {}

class LoadProjects extends ProjectEvent {
  final String workspaceSlug;
  LoadProjects({required this.workspaceSlug});
}