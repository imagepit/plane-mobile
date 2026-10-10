import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/domain/usecases/get_project.dart';
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';

class MobileProjectSession {
  final String slug, projectId;
  final WorkItemBloc bloc;
  final ScrollController scroll = ScrollController();
  final Map<String, String> drafts = {};
  final Map<String, String> postedDrafts = {};
  final Map<String, String> pendingCommentDrafts = {};
  String? identifier, name, identifierError;
  String query = '';
  String? filterState, filterPriority;
  MobileProjectSession(this.slug, this.projectId) : bloc = sl<WorkItemBloc>() {
    bloc.add(LoadWorkItems(workspaceSlug: slug, projectId: projectId));
    bloc.add(LoadStates(workspaceSlug: slug, projectId: projectId));
  }
  String get itemsPath => '/workspaces/$slug/projects/$projectId/items';
  Future<void> dispose() async {
    scroll.dispose();
    await bloc.close();
  }
}

class MobileShell extends StatefulWidget {
  final Widget child;
  final String location;
  final String? workspaceSlug, projectId;
  const MobileShell(
      {super.key,
      required this.child,
      required this.location,
      this.workspaceSlug,
      this.projectId});
  static MobileShellState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MobileScope>()?.owner;
  @override
  State<MobileShell> createState() => MobileShellState();
}

class MobileShellState extends State<MobileShell> {
  final _sessions = <String, MobileProjectSession>{};
  MobileProjectSession? session;
  @override
  void initState() {
    super.initState();
    _followRoute();
  }

  @override
  void didUpdateWidget(MobileShell old) {
    super.didUpdateWidget(old);
    _followRoute();
  }

  void _followRoute() {
    final slug = widget.workspaceSlug, id = widget.projectId;
    if (slug != null &&
        id != null &&
        (session?.slug != slug || session?.projectId != id)) {
      session = _sessions.putIfAbsent(
          '$slug/$id', () => MobileProjectSession(slug, id));
      _resolve(session!);
    }
  }

  Future<void> _resolve(MobileProjectSession selected) async {
    final result = await sl<GetProject>()(selected.slug, selected.projectId);
    if (!mounted) return;
    setState(() {
      result.fold((f) => selected.identifierError = f.message, (p) {
        selected.identifier = p.identifier;
        selected.name = p.name;
        selected.identifierError = null;
      });
    });
  }

  void selectProject(String slug, String id,
      {String? identifier, String? name}) {
    setState(() {
      session = _sessions.putIfAbsent(
          '$slug/$id', () => MobileProjectSession(slug, id));
      session!.identifier = identifier;
      session!.name = name;
    });
  }

  @override
  void dispose() {
    for (final s in _sessions.values) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final path = widget.location;
    final tab = path.endsWith('/search')
        ? 2
        : path.contains('/items')
            ? 1
            : 0;
    final canCreate = session != null &&
        (path.endsWith('/items') || path.endsWith('/search'));
    final colors = Theme.of(context).colorScheme;
    return _MobileScope(
        owner: this,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: widget.child,
          floatingActionButton: canCreate && !keyboard
              ? FloatingActionButton(
                  key: const ValueKey('create-work-item'),
                  tooltip: 'Create work item',
                  onPressed: () => context.push('${session!.itemsPath}/new'),
                  child: const Icon(Icons.add, size: 28),
                )
              : null,
          bottomNavigationBar: keyboard
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                                color: colors.outlineVariant.withAlpha(100)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha(18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8))
                            ]),
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(children: [
                              for (final (index, icon, label) in [
                                (0, Icons.home_rounded, 'Home'),
                                (1, Icons.inbox_rounded, 'Work items'),
                                (2, Icons.search_rounded, 'Search')
                              ])
                                Expanded(
                                    child: Semantics(
                                        selected: index == tab,
                                        child: Material(
                                            color: index == tab
                                                ? colors.surfaceContainerHighest
                                                    .withAlpha(140)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(36),
                                            child: IconButton(
                                                key: ValueKey('tab-$index'),
                                                tooltip: label,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                icon: Icon(icon,
                                                    size: 26,
                                                    color: index == tab
                                                        ? colors.onSurface
                                                        : colors
                                                            .onSurfaceVariant),
                                                onPressed: () {
                                                  if (index == 0) {
                                                    context.go('/workspaces');
                                                    return;
                                                  }
                                                  if (session == null) {
                                                    context.go('/workspaces');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Select a workspace and project first')));
                                                    return;
                                                  }
                                                  context.go(index == 1
                                                      ? session!.itemsPath
                                                      : '${session!.itemsPath}/search');
                                                })))),
                            ]))),
                  )),
        ));
  }
}

class _MobileScope extends InheritedWidget {
  final MobileShellState owner;
  const _MobileScope({required this.owner, required super.child});
  @override
  bool updateShouldNotify(_MobileScope old) => true;
}
