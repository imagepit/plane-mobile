import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
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

class CreateWorkItemPage extends StatefulWidget {
  final String workspaceSlug;
  final String projectId;

  const CreateWorkItemPage({
    super.key,
    required this.workspaceSlug,
    required this.projectId,
  });

  @override
  State<CreateWorkItemPage> createState() => _CreateWorkItemPageState();
}

class _CreateWorkItemPageState extends State<CreateWorkItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedState;
  String? _selectedPriority = 'none';
  String? _startDate;
  String? _targetDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      )..add(LoadStates(workspaceSlug: widget.workspaceSlug, projectId: widget.projectId))
          ..add(LoadLabels(workspaceSlug: widget.workspaceSlug, projectId: widget.projectId))
          ..add(LoadMembers(workspaceSlug: widget.workspaceSlug, projectId: widget.projectId)),
      child: BlocConsumer<WorkItemBloc, WorkItemState>(
        listener: (context, state) {
          if (state is WorkItemCreated) {
            context.pop();
          }
          if (state is WorkItemError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Create Work Item'),
              actions: [
                TextButton(
                  onPressed: state is WorkItemActionLoading ? null : () => _submit(context),
                  child: const Text('Create'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Enter work item title',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter description (optional)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      minLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildStateDropdown(context, state),
                    const SizedBox(height: 16),
                    _buildPriorityDropdown(),
                    const SizedBox(height: 16),
                    _buildDateField(context, 'Start Date', _startDate, (val) {
                      setState(() => _startDate = val);
                    }),
                    const SizedBox(height: 16),
                    _buildDateField(context, 'Target Date', _targetDate, (val) {
                      setState(() => _targetDate = val);
                    }),
                    const SizedBox(height: 32),
                    if (state is WorkItemActionLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateDropdown(BuildContext context, WorkItemState state) {
    List<DropdownMenuItem<String>> items = const [];
    if (state is StatesLoaded) {
      items = state.states.map((s) => DropdownMenuItem(
            value: s.id,
            child: Text(s.name),
          )).toList();
    }
    return DropdownButtonFormField<String>(
      value: _selectedState,
      decoration: const InputDecoration(
        labelText: 'State',
        isDense: true,
      ),
      items: items,
      onChanged: (val) => setState(() => _selectedState = val),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPriority,
      decoration: const InputDecoration(
        labelText: 'Priority',
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'low', child: Text('Low')),
        DropdownMenuItem(value: 'none', child: Text('None')),
      ],
      onChanged: (val) => setState(() => _selectedPriority = val),
    );
  }

  Widget _buildDateField(BuildContext context, String label, String? value, ValueChanged<String?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null ? DateTime.tryParse(value) ?? DateTime.now() : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().split('T')[0]);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value ?? 'Not set'),
            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _selectedPriority ?? 'none',
    };

    if (_selectedState != null) {
      data['state'] = _selectedState;
    }
    if (_startDate != null) {
      data['start_date'] = _startDate;
    }
    if (_targetDate != null) {
      data['target_date'] = _targetDate;
    }

    context.read<WorkItemBloc>().add(CreateWorkItemEvent(
          workspaceSlug: widget.workspaceSlug,
          projectId: widget.projectId,
          data: data,
        ));
  }
}