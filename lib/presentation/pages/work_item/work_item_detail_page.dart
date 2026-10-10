import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/domain/entities/work_item.dart' as entities;
import 'package:plane_mobile/presentation/widgets/editor/work_item_editor.dart';
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';
import 'package:plane_mobile/presentation/widgets/navigation/mobile_shell.dart';
import 'package:plane_mobile/presentation/widgets/preview/code_block_preview.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_header.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_properties.dart';
import 'package:plane_mobile/presentation/widgets/work_item/comment_section.dart';

class WorkItemDetailPage extends StatefulWidget {
  final String workspaceSlug, projectId, itemId;
  const WorkItemDetailPage(
      {super.key,
      required this.workspaceSlug,
      required this.projectId,
      required this.itemId});
  @override
  State<WorkItemDetailPage> createState() => _WorkItemDetailPageState();
}

class _WorkItemDetailPageState extends State<WorkItemDetailPage> {
  WorkItemBloc? _bloc;
  bool _owns = false;
  String? _loaded;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shared = MobileShell.maybeOf(context)?.session?.bloc;
    if (_bloc == null || (shared != null && shared != _bloc)) {
      if (_owns) _bloc?.close();
      _bloc = shared ?? sl<WorkItemBloc>();
      _owns = shared == null;
      _loaded = null;
    }
  }

  @override
  void dispose() {
    if (_owns) _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = '${widget.workspaceSlug}/${widget.projectId}/${widget.itemId}';
    if (_loaded != key) {
      _loaded = key;
      _bloc!.add(LoadWorkItemDetail(
          workspaceSlug: widget.workspaceSlug,
          projectId: widget.projectId,
          itemId: widget.itemId));
    }
    return BlocProvider.value(
        value: _bloc!,
        child: WorkItemDetailView(
            workspaceSlug: widget.workspaceSlug,
            projectId: widget.projectId,
            itemId: widget.itemId));
  }
}

class WorkItemDetailView extends StatefulWidget {
  final String workspaceSlug, projectId, itemId;
  const WorkItemDetailView(
      {super.key,
      required this.workspaceSlug,
      required this.projectId,
      required this.itemId});
  @override
  State<WorkItemDetailView> createState() => _WorkItemDetailViewState();
}

class _WorkItemDetailViewState extends State<WorkItemDetailView> {
  bool _editorOpen = false, _saving = false;
  Map<String, dynamic>? _failedField;
  WorkItemBloc get bloc => context.read<WorkItemBloc>();
  LoadWorkItemDetail get reload => LoadWorkItemDetail(
      workspaceSlug: widget.workspaceSlug,
      projectId: widget.projectId,
      itemId: widget.itemId);
  LoadComments comments({bool append = false, bool allPages = false}) =>
      LoadComments(
          workspaceSlug: widget.workspaceSlug,
          projectId: widget.projectId,
          itemId: widget.itemId,
          append: append,
          allPages: allPages);
  void _back() {
    if (context.canPop())
      context.pop();
    else
      context.go(
          '/workspaces/${widget.workspaceSlug}/projects/${widget.projectId}/items');
  }

  Future<bool> _update(Map<String, dynamic> data,
      {bool remember = true}) async {
    if (_saving) return false;
    setState(() => _saving = true);
    final success = await bloc.execute(UpdateWorkItemEvent(
        workspaceSlug: widget.workspaceSlug,
        projectId: widget.projectId,
        itemId: widget.itemId,
        data: data));
    if (!mounted) return success;
    setState(() {
      _saving = false;
      _failedField = success || !remember ? null : Map.of(data);
    });
    return success;
  }

  Future<void> _editContent(entities.WorkItem item,
      {bool focusTitle = false}) async {
    if (_editorOpen || _saving || bloc.state.busy) return;
    _editorOpen = true;
    final targetBloc = bloc;
    final identifier = MobileShell.maybeOf(context)?.session?.identifier;
    try {
      await showWorkItemEditor(context,
          title: item.name,
          html: item.descriptionHtml ?? item.description ?? '',
          identifier: identifier == null || identifier.isEmpty
              ? item.displayId
              : '$identifier-${item.sequenceId}',
          focusTitle: focusTitle, onSave: (title, changedHtml) async {
        final patch = <String, dynamic>{
          if (title != item.name) 'name': title,
          if (changedHtml != null) 'description_html': changedHtml,
        };
        if (patch.isEmpty) return null;
        final saved = await _update(patch, remember: false);
        return saved
            ? null
            : targetBloc.state.error ?? 'Could not save. Please try again.';
      });
    } finally {
      _editorOpen = false;
    }
  }

  Future<CommentCheckResult> _checkComments() async {
    final itemId = widget.itemId;
    final success = await bloc.execute(comments(allPages: true));
    if (!mounted || !success || widget.itemId != itemId)
      return CommentCheckResult.failed;
    final posted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Check the reloaded comments'),
                content: const Text(
                    'Is your previous comment in the history? Confirm before retrying to avoid posting it twice.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Already posted')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Not posted'))
                ]));
    if (posted == null || !mounted || widget.itemId != itemId)
      return CommentCheckResult.failed;
    await bloc.execute(ResolveCommentUncertainty(itemId: itemId));
    return posted ? CommentCheckResult.posted : CommentCheckResult.notPosted;
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<WorkItemBloc, WorkItemState>(
        listenWhen: (p, s) => p.deletedId != s.deletedId,
        listener: (context, s) {
          if (s.deletedId == widget.itemId) _back();
        },
        builder: (context, s) {
          final item = s.workItem?.id == widget.itemId ? s.workItem : null;
          final busy = s.busy || _saving;
          return Scaffold(
              appBar: AppBar(
                  leading: IconButton(
                      tooltip: 'Back to work items',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _back),
                  actions: [
                    PopupMenuButton<String>(
                        enabled: !busy,
                        onSelected: (v) async {
                          if (v == 'edit' && item != null)
                            _editContent(item, focusTitle: true);
                          if (v == 'delete') {
                            final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                        title: const Text('Delete Work Item'),
                                        content: const Text(
                                            'This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text('Cancel')),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text('Delete'))
                                        ]));
                            if (confirmed == true && mounted)
                              bloc.add(DeleteWorkItemEvent(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId,
                                  itemId: widget.itemId));
                          }
                        },
                        itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit work item')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete'))
                            ])
                  ]),
              body: item == null
                  ? Center(
                      child: s.detailLoading
                          ? const CircularProgressIndicator()
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(s.error ?? 'Could not load this work item'),
                              TextButton(
                                  onPressed: () => bloc.add(reload),
                                  child: const Text('Retry'))
                            ]))
                  : CommentSection(
                      itemId: widget.itemId,
                      drafts: MobileShell.maybeOf(context)?.session?.drafts,
                      pendingDrafts: MobileShell.maybeOf(context)
                          ?.session
                          ?.pendingCommentDrafts,
                      postedDrafts:
                          MobileShell.maybeOf(context)?.session?.postedDrafts,
                      comments: s.comments,
                      isLoading: s.commentsLoading,
                      hasNext: s.commentsHasNext,
                      error: s.commentsError,
                      uncertain: s.commentsUncertain,
                      onLoadMore: () => bloc.add(comments(append: true)),
                      onReload: () => bloc.add(comments()),
                      onCheckComments: _checkComments,
                      onAddComment: (html) async {
                        final success = await bloc.execute(AddCommentEvent(
                            workspaceSlug: widget.workspaceSlug,
                            projectId: widget.projectId,
                            itemId: widget.itemId,
                            commentHtml: html));
                        return success
                            ? CommentSendResult.sent
                            : bloc.isCommentUncertain(widget.itemId)
                                ? CommentSendResult.uncertain
                                : CommentSendResult.failed;
                      },
                      body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (busy || s.detailLoading)
                              const LinearProgressIndicator(minHeight: 2),
                            WorkItemHeader(
                                workItem: item,
                                identifier: MobileShell.maybeOf(context)
                                    ?.session
                                    ?.identifier),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GestureDetector(
                                    key: const ValueKey('edit-work-item-title'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: busy
                                        ? null
                                        : () => _editContent(item,
                                            focusTitle: true),
                                    child: Semantics(
                                        button: true,
                                        label: 'Edit work item title',
                                        child: Text(item.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall)))),
                            const SizedBox(height: 12),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GestureDetector(
                                    key: const ValueKey(
                                        'edit-work-item-description'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        busy ? null : () => _editContent(item),
                                    child: Semantics(
                                        button: true,
                                        label: 'Edit work item description',
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                minHeight: 60,
                                                minWidth: double.infinity),
                                            child: (item.descriptionHtml ??
                                                        item.description ??
                                                        '')
                                                    .isEmpty
                                                ? Text('Add description',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.copyWith(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant))
                                                : RichHtml(
                                                    html: item.descriptionHtml ?? item.description!,
                                                    textStyle: Theme.of(context).textTheme.bodyLarge))))),
                            const SizedBox(height: 24),
                            if (s.error != null)
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s.error!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error)),
                                        Row(children: [
                                          TextButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => bloc.add(reload),
                                              child: const Text('Reload')),
                                          if (_failedField != null) ...[
                                            TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : () =>
                                                        _update(_failedField!),
                                                child:
                                                    const Text('Retry save')),
                                            TextButton(
                                                onPressed: () => setState(
                                                    () => _failedField = null),
                                                child: const Text(
                                                    'Cancel pending change'))
                                          ]
                                        ])
                                      ])),
                            WorkItemProperties(
                              workItem: item,
                              states: s.states,
                              labels: s.labels,
                              members: s.members,
                              statesError: s.statesError,
                              labelsError: s.labelsError,
                              membersError: s.membersError,
                              onRetryStates: () => bloc.add(LoadStates(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId)),
                              onRetryLabels: () => bloc.add(LoadLabels(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId)),
                              onRetryMembers: () => bloc.add(LoadMembers(
                                  workspaceSlug: widget.workspaceSlug,
                                  projectId: widget.projectId)),
                              onStateChanged:
                                  busy ? null : (v) => _update({'state': v}),
                              onPriorityChanged:
                                  busy ? null : (v) => _update({'priority': v}),
                              onLabelsChanged:
                                  busy ? null : (v) => _update({'labels': v}),
                              onAssigneesChanged: busy
                                  ? null
                                  : (v) => _update({'assignees': v}),
                              onStartDateChanged: busy
                                  ? null
                                  : (v) => _update({'start_date': v}),
                              onTargetDateChanged: busy
                                  ? null
                                  : (v) => _update({'target_date': v}),
                            ),
                          ]),
                    ));
        },
      );
}
