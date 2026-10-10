import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';
import 'package:plane_mobile/presentation/widgets/navigation/mobile_shell.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_card.dart';
import 'package:plane_mobile/presentation/widgets/work_item/work_item_filter_bar.dart';

class WorkItemListPage extends StatelessWidget {
  final String workspaceSlug, projectId;
  final bool searchMode;
  const WorkItemListPage(
      {super.key,
      required this.workspaceSlug,
      required this.projectId,
      this.searchMode = false});
  @override
  Widget build(BuildContext context) {
    final session = MobileShell.maybeOf(context)?.session;
    final view = WorkItemListView(
        workspaceSlug: workspaceSlug,
        projectId: projectId,
        searchMode: searchMode);
    if (session != null)
      return BlocProvider.value(value: session.bloc, child: view);
    return BlocProvider(
        create: (_) => sl<WorkItemBloc>()
          ..add(
              LoadWorkItems(workspaceSlug: workspaceSlug, projectId: projectId))
          ..add(LoadStates(workspaceSlug: workspaceSlug, projectId: projectId)),
        child: view);
  }
}

class WorkItemListView extends StatefulWidget {
  final String workspaceSlug, projectId;
  final bool searchMode;
  const WorkItemListView(
      {super.key,
      required this.workspaceSlug,
      required this.projectId,
      this.searchMode = false});
  @override
  State<WorkItemListView> createState() => _WorkItemListViewState();
}

class _WorkItemListViewState extends State<WorkItemListView> {
  final _search = TextEditingController();
  final _localScroll = ScrollController();
  MobileProjectSession? _session;
  String _query = '';
  String? _filterState, _filterPriority;
  String get _path =>
      '/workspaces/${widget.workspaceSlug}/projects/${widget.projectId}/items';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = MobileShell.maybeOf(context)?.session;
    if (_session != session ||
        _query != session?.query ||
        _filterState != session?.filterState ||
        _filterPriority != session?.filterPriority) {
      _session = session;
      _query = session?.query ?? '';
      _search.text = _query;
      _filterState = session?.filterState;
      _filterPriority = session?.filterPriority;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _localScroll.dispose();
    super.dispose();
  }

  void _saveFilters() {
    _session?.query = _query;
    _session?.filterState = _filterState;
    _session?.filterPriority = _filterPriority;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.searchMode ? 'Search' : 'Work items'),
            leading: IconButton(
                tooltip: 'Projects',
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    context.go('/workspaces/${widget.workspaceSlug}/projects')),
            actions: [
              if (!widget.searchMode)
                IconButton(
                    tooltip: 'Search work items',
                    icon: const Icon(Icons.search),
                    onPressed: () => context.go('$_path/search'))
            ]),
        body:
            BlocBuilder<WorkItemBloc, WorkItemState>(builder: (context, state) {
          final identifier = _session?.identifier;
          final items = state.workItems.where((i) {
            final id = identifier == null
                ? i.displayId
                : '$identifier-${i.sequenceId}';
            final query = widget.searchMode ? _query.toLowerCase() : '';
            return (query.isEmpty ||
                    i.name.toLowerCase().contains(query) ||
                    id.toLowerCase().contains(query)) &&
                (_filterState == null || i.stateDetail?.id == _filterState) &&
                (_filterPriority == null ||
                    (i.priority ?? 'none') == _filterPriority);
          }).toList();
          return Column(children: [
            if (widget.searchMode)
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                      key: const ValueKey('work-item-search'),
                      controller: _search,
                      autofocus: false,
                      decoration: const InputDecoration(
                          hintText: 'Search loaded work items',
                          prefixIcon: Icon(Icons.search)),
                      onChanged: (s) => setState(() {
                            _query = s;
                            _saveFilters();
                          }))),
            if (widget.searchMode)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                      state.hasNext
                          ? 'Searching ${state.workItems.length} loaded items · more available'
                          : 'Searching ${state.workItems.length} loaded items in this project',
                      style: Theme.of(context).textTheme.bodySmall)),
            WorkItemFilterBar(
                workspaceSlug: widget.workspaceSlug,
                projectId: widget.projectId,
                states: state.states,
                selectedState: _filterState,
                selectedPriority: _filterPriority,
                error: state.statesError,
                onRetry: () => context.read<WorkItemBloc>().add(LoadStates(
                    workspaceSlug: widget.workspaceSlug,
                    projectId: widget.projectId)),
                onFilterChanged: (s, p) => setState(() {
                      _filterState = s;
                      _filterPriority = p;
                      _saveFilters();
                    })),
            if (state.loading || state.loadingMore)
              const LinearProgressIndicator(minHeight: 2),
            if (state.error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: Text(state.error!)),
                    TextButton(
                        onPressed: () => context.read<WorkItemBloc>().add(
                            LoadWorkItems(
                                workspaceSlug: widget.workspaceSlug,
                                projectId: widget.projectId,
                                append: state.listRetryAppend)),
                        child: const Text('Retry'))
                  ])),
            Expanded(
                child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<WorkItemBloc>().execute(LoadWorkItems(
                          workspaceSlug: widget.workspaceSlug,
                          projectId: widget.projectId));
                    },
                    child: ListView.builder(
                      key: PageStorageKey(
                          'items-${widget.workspaceSlug}-${widget.projectId}-${widget.searchMode}'),
                      controller: widget.searchMode
                          ? _localScroll
                          : _session?.scroll ?? _localScroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: items.length +
                          (items.isEmpty ? 1 : 0) +
                          (state.hasNext ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (items.isEmpty && index == 0)
                          return const Padding(
                              padding: EdgeInsets.all(40),
                              child:
                                  Center(child: Text('No work items found')));
                        if (index >= items.length)
                          return Padding(
                              padding: const EdgeInsets.all(16),
                              child: OutlinedButton(
                                  key: const ValueKey('load-more-items'),
                                  onPressed: state.loadingMore
                                      ? null
                                      : () => context.read<WorkItemBloc>().add(
                                          LoadWorkItems(
                                              workspaceSlug:
                                                  widget.workspaceSlug,
                                              projectId: widget.projectId,
                                              append: true)),
                                  child: const Text('Load more work items')));
                        final item = items[index];
                        return WorkItemCard(
                            key: ValueKey(item.id),
                            workItem: item,
                            identifier: identifier,
                            onTap: () => context.push('$_path/${item.id}'));
                      },
                    ))),
          ]);
        }),
      );
}
