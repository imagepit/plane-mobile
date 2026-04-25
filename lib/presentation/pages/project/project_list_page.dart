import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/presentation/blocs/project/project_bloc.dart';
import 'package:plane_mobile/presentation/widgets/project/project_card.dart';

class ProjectListPage extends StatelessWidget {
  final String workspaceSlug;

  const ProjectListPage({super.key, required this.workspaceSlug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectBloc(getProjects: sl())
        ..add(LoadProjects(workspaceSlug: workspaceSlug)),
      child: ProjectListView(workspaceSlug: workspaceSlug),
    );
  }
}

class ProjectListView extends StatelessWidget {
  final String workspaceSlug;

  const ProjectListView({super.key, required this.workspaceSlug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          return switch (state) {
            ProjectLoading() => const Center(child: CircularProgressIndicator()),
            ProjectsLoaded(:final projects) => _buildList(context, projects),
            ProjectError(:final message) => _buildError(context, message),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off, size: 64),
            const SizedBox(height: 16),
            Text('No projects found',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProjectBloc>().add(LoadProjects(workspaceSlug: workspaceSlug));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ProjectCard(
            project: project,
            workspaceSlug: workspaceSlug,
            onTap: () => context.push(
              '/workspaces/$workspaceSlug/projects/${project.id}/items',
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context
                .read<ProjectBloc>()
                .add(LoadProjects(workspaceSlug: workspaceSlug)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}