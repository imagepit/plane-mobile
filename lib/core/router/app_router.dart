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
    GoRoute(
      path: '/workspaces',
      builder: (context, state) => const WorkspaceListPage(),
    ),
    GoRoute(
      path: '/workspaces/:slug/projects',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return ProjectListPage(workspaceSlug: slug);
      },
    ),
    GoRoute(
      path: '/workspaces/:slug/projects/:projectId/items',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        final projectId = state.pathParameters['projectId']!;
        return WorkItemListPage(workspaceSlug: slug, projectId: projectId);
      },
    ),
    GoRoute(
      path: '/workspaces/:slug/projects/:projectId/items/new',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        final projectId = state.pathParameters['projectId']!;
        return CreateWorkItemPage(workspaceSlug: slug, projectId: projectId);
      },
    ),
    GoRoute(
      path: '/workspaces/:slug/projects/:projectId/items/:itemId',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        final projectId = state.pathParameters['projectId']!;
        final itemId = state.pathParameters['itemId']!;
        return WorkItemDetailPage(
          workspaceSlug: slug,
          projectId: projectId,
          itemId: itemId,
        );
      },
    ),
  ],
);