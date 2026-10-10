import 'package:plane_mobile/presentation/pages/work_item/work_item_search_page.dart';
import 'package:plane_mobile/domain/entities/work_item_page.dart';
import 'package:plane_mobile/domain/entities/comment_page.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/domain/repositories/project_repository.dart';
import 'package:plane_mobile/domain/usecases/get_project.dart';
import 'package:plane_mobile/presentation/widgets/navigation/mobile_shell.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/core/theme/app_theme.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';
import 'package:plane_mobile/domain/usecases/add_comment.dart';
import 'package:plane_mobile/domain/usecases/create_work_item.dart';
import 'package:plane_mobile/domain/usecases/delete_work_item.dart';
import 'package:plane_mobile/domain/usecases/get_comments.dart';
import 'package:plane_mobile/domain/usecases/get_labels.dart';
import 'package:plane_mobile/domain/usecases/get_members.dart';
import 'package:plane_mobile/domain/usecases/get_states.dart';
import 'package:plane_mobile/domain/usecases/get_work_item.dart';
import 'package:plane_mobile/domain/usecases/get_work_items.dart';
import 'package:plane_mobile/domain/usecases/update_work_item.dart';
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart'
    as bloc;
import 'package:plane_mobile/presentation/pages/work_item/create_work_item_page.dart';
import 'package:plane_mobile/presentation/pages/work_item/work_item_detail_page.dart';
import 'package:plane_mobile/presentation/pages/work_item/work_item_list_page.dart';

const previewMember = WorkItemMember(id: 'person', displayName: 'r-takahashi');
const previewState = WorkItemState(
    id: 'backlog', name: 'Backlog', group: 'backlog', color: '#93989B');
const previewItems = [
  WorkItem(
      id: 'item-9',
      name: 'テストタスク２',
      sequenceId: 9,
      description: 'テストタスク',
      descriptionHtml: '<p>テストタスク</p>',
      stateDetail: previewState,
      priority: 'none',
      assignees: [previewMember],
      assigneesIds: ['person']),
  WorkItem(
      id: 'item-8',
      name: 'テストタスク',
      sequenceId: 8,
      stateDetail: previewState,
      priority: 'none',
      assignees: [previewMember]),
];

// This entry point has no transport, credentials or device storage.
class PreviewRepository implements WorkItemRepository, ProjectRepository {
  List<WorkItem> items = [...previewItems];
  List<Comment> comments = [
    Comment(
        id: 'comment-1',
        commentHtml: '<p>テストコメントです。</p>',
        actor: previewMember,
        createdAt: DateTime(2026, 10, 9, 10))
  ];
  @override
  Future<Either<Failure, WorkItemPage>> getWorkItems(String w, String p,
          {String? cursor}) async =>
      Right(WorkItemPage(items: items));
  @override
  Future<Either<Failure, WorkItem>> getWorkItem(
          String w, String p, String id) async =>
      Right(items.firstWhere((i) => i.id == id));
  @override
  Future<Either<Failure, List<WorkItemState>>> getStates(
          String w, String p) async =>
      const Right([
        previewState,
        WorkItemState(
            id: 'started',
            name: 'In progress',
            group: 'started',
            color: '#F59E0B')
      ]);
  @override
  Future<Either<Failure, List<WorkItemLabel>>> getLabels(
          String w, String p) async =>
      const Right([WorkItemLabel(id: 'design', name: 'Design')]);
  @override
  Future<Either<Failure, List<WorkItemMember>>> getMembers(
          String w, String p) async =>
      const Right([previewMember]);
  @override
  Future<Either<Failure, CommentPage>> getComments(
          String w, String p, String id,
          {String? cursor}) async =>
      Right(CommentPage(items: comments));
  @override
  Future<Either<Failure, Comment>> addComment(
      String w, String p, String id, String html) async {
    final c = Comment(
        id: 'comment-${comments.length + 1}',
        commentHtml: html,
        actor: previewMember,
        createdAt: DateTime(2026, 10, 10, 10));
    comments = [...comments, c];
    return Right(c);
  }

  @override
  Future<Either<Failure, WorkItem>> updateWorkItem(
      String w, String p, String id, Map<String, dynamic> data) async {
    final old = items.firstWhere((i) => i.id == id);
    final candidates = (await getStates(w, p)).getOrElse(() => []);
    final item = WorkItem(
        id: old.id,
        name: data['name'] as String? ?? old.name,
        sequenceId: old.sequenceId,
        description: old.description,
        descriptionHtml: old.descriptionHtml,
        stateDetail: data.containsKey('state')
            ? candidates.firstWhere((x) => x.id == data['state'])
            : old.stateDetail,
        priority: data['priority'] as String? ?? old.priority,
        startDate: data.containsKey('start_date')
            ? data['start_date'] as String?
            : old.startDate,
        targetDate: data.containsKey('target_date')
            ? data['target_date'] as String?
            : old.targetDate,
        assigneesIds: data['assignees'] as List<String>? ?? old.assigneesIds,
        assignees: data.containsKey('assignees')
            ? (data['assignees'] as List<String>).contains('person')
                ? [previewMember]
                : []
            : old.assignees,
        labelIds: data['labels'] as List<String>? ?? old.labelIds);
    items = items.map((i) => i.id == id ? item : i).toList();
    return Right(item);
  }

  @override
  Future<Either<Failure, WorkItem>> createWorkItem(
      String w, String p, Map<String, dynamic> data) async {
    final item = WorkItem(
        id: 'item-${items.length + 10}',
        name: data['name'] as String,
        sequenceId: items.length + 10,
        stateDetail: previewState,
        priority: data['priority'] as String?);
    items = [...items, item];
    return Right(item);
  }

  @override
  Future<Either<Failure, void>> deleteWorkItem(
      String w, String p, String id) async {
    items = items.where((i) => i.id != id).toList();
    return const Right(null);
  }

  @override
  Future<Either<Failure, Project>> getProject(String w, String p) async =>
      const Right(Project(
          id: 'preview',
          name: 'Preview project',
          network: '',
          workspace: 'imagepit',
          identifier: 'IMAGE'));
  @override
  Future<Either<Failure, List<Project>>> getProjects(String w) async =>
      const Right([
        Project(
            id: 'preview',
            name: 'Preview project',
            network: '',
            workspace: 'imagepit',
            identifier: 'IMAGE')
      ]);
}

void registerPreview(PreviewRepository repo) {
  sl.registerSingleton<GetProject>(GetProject(repo));
  sl.registerSingleton<GetWorkItems>(GetWorkItems(repo));
  sl.registerSingleton<GetWorkItem>(GetWorkItem(repo));
  sl.registerSingleton<CreateWorkItem>(CreateWorkItem(repo));
  sl.registerSingleton<UpdateWorkItem>(UpdateWorkItem(repo));
  sl.registerSingleton<DeleteWorkItem>(DeleteWorkItem(repo));
  sl.registerSingleton<GetStates>(GetStates(repo));
  sl.registerSingleton<GetLabels>(GetLabels(repo));
  sl.registerSingleton<GetMembers>(GetMembers(repo));
  sl.registerSingleton<GetComments>(GetComments(repo));
  sl.registerSingleton<AddComment>(AddComment(repo));
  sl.registerFactory<bloc.WorkItemBloc>(() => bloc.WorkItemBloc(
      getWorkItems: sl(),
      getWorkItem: sl(),
      createWorkItem: sl(),
      updateWorkItem: sl(),
      deleteWorkItem: sl(),
      getStates: sl(),
      getLabels: sl(),
      getMembers: sl(),
      getComments: sl(),
      addComment: sl()));
}

GoRouter createPreviewRouter(
        {String initialLocation =
            '/workspaces/imagepit/projects/preview/items'}) =>
    GoRouter(initialLocation: initialLocation, routes: [
      ShellRoute(
          builder: (_, s, child) => MobileShell(
              location: s.uri.path,
              workspaceSlug: s.pathParameters['slug'],
              projectId: s.pathParameters['projectId'],
              child: child),
          routes: [
            GoRoute(
                path: '/workspaces',
                builder: (c, s) => Scaffold(
                    appBar: AppBar(title: const Text('Home')),
                    body: ListTile(
                        title: const Text('imagepit'),
                        onTap: () => c.go('/workspaces/imagepit/projects')))),
            GoRoute(
                path: '/workspaces/:slug/projects',
                builder: (c, s) => Scaffold(
                    appBar: AppBar(title: const Text('Projects')),
                    body: ListTile(
                        title: const Text('Preview project'),
                        onTap: () {
                          MobileShell.maybeOf(c)?.selectProject(
                              'imagepit', 'preview',
                              identifier: 'IMAGE', name: 'Preview project');
                          c.go('/workspaces/imagepit/projects/preview/items');
                        }))),
            GoRoute(
                path: '/workspaces/:slug/projects/:projectId/items',
                builder: (_, s) => const WorkItemListPage(
                    workspaceSlug: 'imagepit', projectId: 'preview'),
                routes: [
                  GoRoute(
                      path: 'new',
                      builder: (_, s) => const CreateWorkItemPage(
                          workspaceSlug: 'imagepit', projectId: 'preview')),
                  GoRoute(
                      path: 'search',
                      builder: (_, s) => const WorkItemSearchPage(
                          workspaceSlug: 'imagepit', projectId: 'preview')),
                  GoRoute(
                      path: ':itemId',
                      builder: (_, s) => WorkItemDetailPage(
                          workspaceSlug: 'imagepit',
                          projectId: 'preview',
                          itemId: s.pathParameters['itemId']!)),
                ]),
          ]),
    ]);

Widget previewApp(GoRouter router, {bool dark = false, double scale = 1}) =>
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
    );
void main() {
  final params = Uri.base.queryParameters;
  final repo = PreviewRepository();
  if (params['complex'] == '1') {
    repo.items = [
      repo.items.first.copyWith(
          name: '長い日本語の作業項目名・担当者が多い場合でも属性とコメントへ迷わず到達できるか確認する',
          descriptionHtml: '<p>長い本文の表示確認です。</p>' * 8 +
              '<pre><code class="language-file-tree">.\n├── ++ 新規.dart\n└── ** 修正.dart</code></pre>' +
              '<pre><code class="language-mermaid">graph TD; A--&gt;B;</code></pre>',
          assignees: [
            previewMember,
            const WorkItemMember(id: 'two', displayName: '日本語の担当者'),
            const WorkItemMember(id: 'three', displayName: '追加担当者')
          ],
          assigneesIds: [
            'person',
            'two',
            'three'
          ],
          labelIds: [
            'design'
          ]),
      repo.items.last
    ];
  }
  if (params['rich'] == '1') {
    repo.items = [
      repo.items.first.copyWith(
          name: '本文の図とツリー表示',
          descriptionHtml:
              '<h2>依存図</h2><pre><code class="language-mermaid">flowchart RL\n'
              'subgraph dispatcher["imagepit/imagepit"]\ncheck["実装計画の検査"]\nend\n'
              'subgraph canary["plane-dispatcher-canary"]\n'
              'proof["★新規 core8-plan-proof.txt"]\nreport["★新規 core8-required-report.txt"]\nend\n'
              'check -.-> proof\ncheck -.-> report</code></pre>'
              '<h2>ツリー差分</h2><pre data-language="tree"><code>.\n'
              '└── canary/\n    └── plane-dispatcher-canary/\n'
              '        ├── ++ core8-plan-proof.txt &lt;--[計画内ファイル]\n'
              '        └── ++ core8-required-report.txt &lt;--[必須の報告]</code></pre>'),
      repo.items.last,
    ];
  }
  if (params['rich'] == 'invalid') {
    repo.items = [
      repo.items.first.copyWith(
          name: '構文エラーの表示確認',
          descriptionHtml:
              '<pre><code class="language-mermaid">not a valid diagram</code></pre>'),
      repo.items.last
    ];
  }
  registerPreview(repo);
  runApp(previewApp(createPreviewRouter(),
      dark: params['theme'] == 'dark' ||
          const String.fromEnvironment('PREVIEW_THEME') == 'dark',
      scale: double.tryParse(params['scale'] ??
              const String.fromEnvironment('PREVIEW_SCALE',
                  defaultValue: '1')) ??
          1));
}
