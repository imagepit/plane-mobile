import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:plane_mobile/presentation/widgets/work_item/work_item_header.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_properties.dart';
import 'package:plane_mobile/presentation/widgets/work_item/comment_section.dart';

class WorkItemDetailPage extends StatelessWidget {
  final String workspaceSlug;
  final String projectId;
  final String itemId;

  const WorkItemDetailPage({
    super.key,
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
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
      )..add(LoadWorkItemDetail(
          workspaceSlug: workspaceSlug,
          projectId: projectId,
          itemId: itemId,
        )),
      child: WorkItemDetailView(
        workspaceSlug: workspaceSlug,
        projectId: projectId,
        itemId: itemId,
      ),
    );
  }
}

class WorkItemDetailView extends StatefulWidget {
  final String workspaceSlug;
  final String projectId;
  final String itemId;

  const WorkItemDetailView({
    super.key,
    required this.workspaceSlug,
    required this.projectId,
    required this.itemId,
  });

  @override
  State<WorkItemDetailView> createState() => _WorkItemDetailViewState();
}

class _WorkItemDetailViewState extends State<WorkItemDetailView> {
  bool _isEditing = false;
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Item'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () => _toggleEdit(context),
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: BlocConsumer<WorkItemBloc, WorkItemState>(
        listener: (context, state) {
          if (state is WorkItemDeleted) {
            Navigator.of(context).pop();
          }
          if (state is WorkItemUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Work item updated')),
            );
            setState(() => _isEditing = false);
          }
          if (state is WorkItemError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkItemLoading || state is WorkItemActionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WorkItemDetail) {
            return _buildContent(context, state.workItem, state.states,
                state.labels, state.members, state.comments, state is WorkItemActionLoading);
          }
          if (state is WorkItemError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<WorkItemBloc>().add(LoadWorkItemDetail(
                          workspaceSlug: widget.workspaceSlug,
                          projectId: widget.projectId,
                          itemId: widget.itemId,
                        )),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    entities.WorkItem workItem,
    List<entities.WorkItemState> states,
    List<entities.WorkItemLabel> labels,
    List<entities.WorkItemMember> members,
    List<entities.Comment> comments,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkItemHeader(workItem: workItem),
          const Divider(height: 1),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController..text = workItem.name,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                workItem.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          if (workItem.description != null && workItem.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                workItem.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const Divider(height: 1),
          WorkItemProperties(
            workItem: workItem,
            states: states,
            labels: labels,
            members: members,
            onStateChanged: _isEditing ? (val) => _updateField(context, {'state': val}) : null,
            onPriorityChanged: _isEditing ? (val) => _updateField(context, {'priority': val}) : null,
            onLabelsChanged: _isEditing ? (val) => _updateField(context, {'label_ids': val}) : null,
            onAssigneesChanged: _isEditing ? (val) => _updateField(context, {'assignees_ids': val}) : null,
            onStartDateChanged: _isEditing ? (val) => _updateField(context, {'start_date': val}) : null,
            onTargetDateChanged: _isEditing ? (val) => _updateField(context, {'target_date': val}) : null,
          ),
          const Divider(height: 1),
          CommentSection(
            comments: comments,
            isLoading: isLoading,
            onAddComment: (commentHtml) {
              context.read<WorkItemBloc>().add(AddCommentEvent(
                    workspaceSlug: widget.workspaceSlug,
                    projectId: widget.projectId,
                    itemId: widget.itemId,
                    commentHtml: commentHtml,
                  ));
            },
          ),
        ],
      ),
    );
  }

  void _toggleEdit(BuildContext context) {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (!_isEditing && _titleController.text.isNotEmpty) {
      final state = context.read<WorkItemBloc>().state;
      if (state is WorkItemDetail && _titleController.text != state.workItem.name) {
        context.read<WorkItemBloc>().add(UpdateWorkItemEvent(
          workspaceSlug: widget.workspaceSlug,
          projectId: widget.projectId,
          itemId: widget.itemId,
          data: {'name': _titleController.text},
        ));
      }
    }
  }

  void _updateField(BuildContext context, Map<String, dynamic> data) {
    context.read<WorkItemBloc>().add(UpdateWorkItemEvent(
      workspaceSlug: widget.workspaceSlug,
      projectId: widget.projectId,
      itemId: widget.itemId,
      data: data,
    ));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Work Item'),
        content: const Text('Are you sure you want to delete this work item? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkItemBloc>().add(DeleteWorkItemEvent(
                workspaceSlug: widget.workspaceSlug,
                projectId: widget.projectId,
                itemId: widget.itemId,
              ));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}