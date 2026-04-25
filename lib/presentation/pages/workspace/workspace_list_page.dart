import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/domain/entities/workspace.dart';
import 'package:plane_mobile/presentation/blocs/workspace/workspace_bloc.dart';
import 'package:plane_mobile/presentation/widgets/workspace/workspace_card.dart';

class WorkspaceListPage extends StatelessWidget {
  const WorkspaceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkspaceBloc(getWorkspaces: sl())..add(LoadWorkspaces()),
      child: const WorkspaceListView(),
    );
  }
}

class WorkspaceListView extends StatelessWidget {
  const WorkspaceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<WorkspaceBloc, WorkspaceState>(
        builder: (context, state) {
          return switch (state) {
            WorkspaceLoading() => const Center(child: CircularProgressIndicator()),
            WorkspacesLoaded(:final workspaces) => _buildList(context, workspaces),
            WorkspaceError(:final message) => _buildError(context, message),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Workspace> workspaces) {
    if (workspaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off, size: 64),
            const SizedBox(height: 16),
            Text('No workspaces found',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WorkspaceBloc>().add(LoadWorkspaces());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workspaces.length,
        itemBuilder: (context, index) {
          final workspace = workspaces[index];
          return WorkspaceCard(
            workspace: workspace,
            onTap: () => context.push('/workspaces/${workspace.slug}/projects'),
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
            onPressed: () =>
                context.read<WorkspaceBloc>().add(LoadWorkspaces()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}