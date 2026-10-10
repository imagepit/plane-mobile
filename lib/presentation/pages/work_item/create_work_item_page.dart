import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/domain/entities/work_item.dart' as entities;
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';
import 'package:plane_mobile/presentation/widgets/navigation/mobile_shell.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_properties.dart';

class CreateWorkItemPage extends StatefulWidget {
  final String workspaceSlug, projectId;
  const CreateWorkItemPage(
      {super.key, required this.workspaceSlug, required this.projectId});
  @override
  State<CreateWorkItemPage> createState() => _CreateWorkItemPageState();
}

class _CreateWorkItemPageState extends State<CreateWorkItemPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _description = TextEditingController();
  WorkItemBloc? _bloc;
  bool _owns = false, _sending = false, _checking = false;
  String? _stateId, _startDate, _targetDate;
  String _priority = 'none';
  List<String> _labels = [], _members = [];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc != null) return;
    final shared = MobileShell.maybeOf(context)?.session?.bloc;
    _bloc = shared ?? sl<WorkItemBloc>();
    _owns = shared == null;
    final pending = _bloc!.state.pendingCreate;
    if (pending != null) {
      _name.text = pending['name'] as String? ?? '';
      _description.text = pending['description'] as String? ?? '';
      _priority = pending['priority'] as String? ?? 'none';
      _stateId = pending['state'] as String?;
      _startDate = pending['start_date'] as String?;
      _targetDate = pending['target_date'] as String?;
      _labels = List<String>.from(pending['labels'] as List? ?? []);
      _members = List<String>.from(pending['assignees'] as List? ?? []);
    }
    _bloc!
      ..add(LoadStates(
          workspaceSlug: widget.workspaceSlug, projectId: widget.projectId))
      ..add(LoadLabels(
          workspaceSlug: widget.workspaceSlug, projectId: widget.projectId))
      ..add(LoadMembers(
          workspaceSlug: widget.workspaceSlug, projectId: widget.projectId));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    if (_owns) _bloc?.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending ||
        _bloc!.state.createUncertain ||
        !_form.currentState!.validate()) return;
    setState(() => _sending = true);
    final success = await _bloc!.execute(CreateWorkItemEvent(
        workspaceSlug: widget.workspaceSlug,
        projectId: widget.projectId,
        data: {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'priority': _priority,
          if (_stateId != null) 'state': _stateId,
          if (_startDate != null) 'start_date': _startDate,
          if (_targetDate != null) 'target_date': _targetDate,
          if (_labels.isNotEmpty) 'labels': _labels,
          if (_members.isNotEmpty) 'assignees': _members
        }));
    if (!mounted) return;
    setState(() => _sending = false);
    if (success) context.pop();
  }

  Future<void> _checkCreatedItems() async {
    if (_checking) return;
    setState(() => _checking = true);
    var success = await _bloc!.execute(LoadWorkItems(
        workspaceSlug: widget.workspaceSlug, projectId: widget.projectId));
    while (success && _bloc!.state.hasNext) {
      success = await _bloc!.execute(LoadWorkItems(
          workspaceSlug: widget.workspaceSlug,
          projectId: widget.projectId,
          append: true));
    }
    if (!mounted) return;
    setState(() => _checking = false);
    if (!success) return;
    final posted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Check the reloaded work items'),
                content: SizedBox(
                    width: double.maxFinite,
                    height: 250,
                    child: ListView(children: [
                      Text(
                          'Was "${_bloc!.state.pendingCreate?['name'] ?? _name.text}" already created?'),
                      for (final item in _bloc!.state.workItems)
                        ListTile(
                            title: Text(item.name),
                            subtitle: Text(item.displayId)),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Already created')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Not created'))
                ]));
    if (posted == null || !mounted) return;
    await _bloc!.execute(ResolveCreateUncertainty());
    if (posted && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
      value: _bloc!,
      child: BlocBuilder<WorkItemBloc, WorkItemState>(builder: (context, s) {
        final busy = s.busy || _sending || _checking;
        return Scaffold(
            appBar: AppBar(title: const Text('Create Work Item'), actions: [
              TextButton(
                  key: const ValueKey('save-new-work-item'),
                  onPressed: busy || s.createUncertain ? null : _submit,
                  child: const Text('Create'))
            ]),
            body: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (busy) const LinearProgressIndicator(minHeight: 2),
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                  key: const ValueKey('new-work-item-title'),
                                  controller: _name,
                                  enabled: !busy,
                                  maxLines: null,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  decoration: const InputDecoration(
                                      labelText: 'Title *',
                                      hintText: 'Enter work item title'),
                                  validator: (s) =>
                                      s == null || s.trim().isEmpty
                                          ? 'Title is required'
                                          : null)),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: TextFormField(
                                  key: const ValueKey(
                                      'new-work-item-description'),
                                  controller: _description,
                                  enabled: !busy,
                                  minLines: 3,
                                  maxLines: 8,
                                  decoration: const InputDecoration(
                                      labelText: 'Description',
                                      hintText:
                                          'Enter description (optional)'))),
                          const SizedBox(height: 24),
                          WorkItemProperties(
                              workItem: entities.WorkItem(
                                  id: 'new',
                                  name: '',
                                  sequenceId: 0,
                                  priority: _priority,
                                  stateDetail: s.states
                                      .where((x) => x.id == _stateId)
                                      .firstOrNull,
                                  startDate: _startDate,
                                  targetDate: _targetDate,
                                  labelIds: _labels,
                                  assigneesIds: _members),
                              states: s.states,
                              labels: s.labels,
                              members: s.members,
                              statesError: s.statesError,
                              labelsError: s.labelsError,
                              membersError: s.membersError,
                              onRetryStates: () => _bloc!.add(LoadStates(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId)),
                              onRetryLabels: () => _bloc!.add(LoadLabels(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId)),
                              onRetryMembers: () => _bloc!.add(LoadMembers(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId)),
                              onStateChanged: busy
                                  ? null
                                  : (v) => setState(() => _stateId = v),
                              onPriorityChanged: busy
                                  ? null
                                  : (v) =>
                                      setState(() => _priority = v ?? 'none'),
                              onStartDateChanged: busy
                                  ? null
                                  : (v) => setState(() => _startDate = v),
                              onTargetDateChanged: busy
                                  ? null
                                  : (v) => setState(() => _targetDate = v),
                              onLabelsChanged: busy
                                  ? null
                                  : (v) => setState(() => _labels = v),
                              onAssigneesChanged: busy
                                  ? null
                                  : (v) => setState(() => _members = v)),
                          if (s.createUncertain)
                            Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(children: [
                                  const Text(
                                      'Could not confirm creation. Your input is kept. Check work items before retrying.'),
                                  TextButton(
                                      onPressed:
                                          busy ? null : _checkCreatedItems,
                                      child: const Text(
                                          'Reload and check work items')),
                                ])),
                          if (s.error != null)
                            Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(s.error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error))),
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: OutlinedButton(
                                  onPressed: busy ? null : () => context.pop(),
                                  child: const Text('Cancel'))),
                        ]))));
      }));
}
