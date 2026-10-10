import 'package:plane_mobile/presentation/widgets/navigation/mobile_shell.dart';
import 'package:plane_mobile/presentation/pages/work_item/work_item_search_page.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';
import 'package:plane_mobile/presentation/pages/settings/server_config_page.dart';
import 'package:plane_mobile/presentation/pages/splash/splash_page.dart';
import 'package:plane_mobile/presentation/pages/workspace/workspace_list_page.dart';
import 'package:plane_mobile/presentation/pages/project/project_list_page.dart';
import 'package:plane_mobile/presentation/pages/work_item/work_item_list_page.dart';
import 'package:plane_mobile/presentation/pages/work_item/work_item_detail_page.dart';
import 'package:plane_mobile/presentation/pages/work_item/create_work_item_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final localStorage = sl<LocalStorage>();
    final isConfigured = localStorage.isConfigured;
    final isOnSettings = state.matchedLocation == '/settings';
    final isOnSplash = state.matchedLocation == '/splash';

    if (isOnSplash) return null;

    if (!isConfigured && !isOnSettings) {
      return '/settings';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const ServerConfigPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MobileShell(
          location: state.uri.path,
          workspaceSlug: state.pathParameters['slug'],
          projectId: state.pathParameters['projectId'],
          child: child),
      routes: [
        GoRoute(
            path: '/workspaces',
            builder: (_, state) => const WorkspaceListPage()),
        GoRoute(
            path: '/workspaces/:slug/projects',
            builder: (_, s) =>
                ProjectListPage(workspaceSlug: s.pathParameters['slug']!)),
        GoRoute(
            path: '/workspaces/:slug/projects/:projectId/items',
            builder: (_, s) => WorkItemListPage(
                workspaceSlug: s.pathParameters['slug']!,
                projectId: s.pathParameters['projectId']!),
            routes: [
              GoRoute(
                  path: 'new',
                  builder: (_, s) => CreateWorkItemPage(
                      workspaceSlug: s.pathParameters['slug']!,
                      projectId: s.pathParameters['projectId']!)),
              GoRoute(
                  path: 'search',
                  builder: (_, s) => WorkItemSearchPage(
                      workspaceSlug: s.pathParameters['slug']!,
                      projectId: s.pathParameters['projectId']!)),
              GoRoute(
                  path: ':itemId',
                  builder: (_, s) => WorkItemDetailPage(
                      workspaceSlug: s.pathParameters['slug']!,
                      projectId: s.pathParameters['projectId']!,
                      itemId: s.pathParameters['itemId']!)),
            ]),
      ],
    ),
  ],
);
