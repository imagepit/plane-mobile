import 'package:bloc/bloc.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/domain/usecases/get_projects.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjects _getProjects;

  ProjectBloc({required GetProjects getProjects})
      : _getProjects = getProjects,
        super(ProjectInitial()) {
    on<LoadProjects>(_onLoadProjects);
  }

  Future<void> _onLoadProjects(
      LoadProjects event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await _getProjects(event.workspaceSlug);
    result.fold(
      (failure) => emit(ProjectError(message: failure.message)),
      (projects) => emit(ProjectsLoaded(
        projects: projects,
        workspaceSlug: event.workspaceSlug,
      )),
    );
  }
}