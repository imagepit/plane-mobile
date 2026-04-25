import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
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
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_card.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_filter_bar.dart';

class WorkItemListPage extends StatelessWidget {
  final String workspaceSlug;
  final String projectId;

  const WorkItemListPage({
    super.key,
    required this.workspaceSlug,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkItemBloc(
        getWorkItems: sl<GetWorkItems>(),
        getWorkItem: sl<GetWorkItem>(),
        createWorkItem: sl<CreateWorkItem>(),
        updateWorkItem: sl<UpdateWorkItem>(),
        deleteWorkItem: sl<DeleteWorkItem>(),
        getStates: sl<GetStates>(),
        getLabels: sl<GetLabels>(),
        getMembers: sl<GetMembers>(),
        getComments: sl<GetComments>(),
        addComment: sl<AddComment>(),
      )..add(LoadWorkItems(workspaceSlug: workspaceSlug, projectId: projectId)),
      child: WorkItemListView(
        workspaceSlug: workspaceSlug,
        projectId: projectId,
      ),
    );
  }
}

class WorkItemListView extends StatefulWidget {
  final String workspaceSlug;
  final String projectId;

  const WorkItemListView({
    super.key,
    required this.workspaceSlug,
    required this.projectId,
  });

  @override
  State<WorkItemListView> createState() => _WorkItemListViewState();
}

class _WorkItemListViewState extends State<WorkItemListView> {
  String _searchQuery = '';
  String? _filterState;
  String? _filterPriority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search work items...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          WorkItemFilterBar(
            workspaceSlug: widget.workspaceSlug,
            projectId: widget.projectId,
            onFilterChanged: (state, priority) {
              setState(() {
                _filterState = state;
                _filterPriority = priority;
              });
            },
          ),
          Expanded(
            child: BlocConsumer<WorkItemBloc, WorkItemState>(
              listener: (context, state) {
                if (state is WorkItemDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Work item deleted')),
                  );
                  context.read<WorkItemBloc>().add(LoadWorkItems(
                    workspaceSlug: widget.workspaceSlug,
                    projectId: widget.projectId,
                  ));
                }
                if (state is WorkItemCreated) {
                  context.read<WorkItemBloc>().add(LoadWorkItems(
                    workspaceSlug: widget.workspaceSlug,
                    projectId: widget.projectId,
                  ));
                }
              },
              builder: (context, state) {
                return switch (state) {
                  WorkItemLoading() => const Center(child: CircularProgressIndicator()),
                  WorkItemsLoaded(:final workItems) => _buildList(
                      context,
                      workItems
                          .where((item) => _matchesFilter(item))
                          .toList(),
                    ),
                  WorkItemError(:final message) => _buildError(context, message),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '/workspaces/${widget.workspaceSlug}/projects/${widget.projectId}/items/new',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _matchesFilter(entities.WorkItem item) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      if (!item.name.toLowerCase().contains(query) &&
          !item.displayId.toLowerCase().contains(query)) {
        return false;
      }
    }
    if (_filterState != null && item.stateDetail?.name != _filterState) {
      return false;
    }
    if (_filterPriority != null && item.priority != _filterPriority) {
      return false;
    }
    return true;
  }

  Widget _buildList(BuildContext context, List<entities.WorkItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 64),
            const SizedBox(height: 16),
            Text('No work items found',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WorkItemBloc>().add(LoadWorkItems(
          workspaceSlug: widget.workspaceSlug,
          projectId: widget.projectId,
        ));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return WorkItemCard(
            workItem: item,
            onTap: () => context.push(
              '/workspaces/${widget.workspaceSlug}/projects/${widget.projectId}/items/${item.id}',
            ),
            onDelete: () {
              context.read<WorkItemBloc>().add(DeleteWorkItemEvent(
                workspaceSlug: widget.workspaceSlug,
                projectId: widget.projectId,
                itemId: item.id,
              ));
            },
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
            onPressed: () => context.read<WorkItemBloc>().add(LoadWorkItems(
              workspaceSlug: widget.workspaceSlug,
              projectId: widget.projectId,
            )),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}