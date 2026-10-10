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
class PreviewRepository implements WorkItemRepository {
  List<WorkItem> items = [...previewItems];
  List<Comment> comments = [
    Comment(
        id: 'comment-1',
        commentHtml: '<p>テストコメントです。</p>',
        actor: previewMember,
        createdAt: DateTime(2026, 10, 9, 10))
  ];
  @override
  Future<Either<Failure, List<WorkItem>>> getWorkItems(
          String w, String p) async =>
      Right(items);
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
  Future<Either<Failure, List<Comment>>> getComments(
          String w, String p, String id) async =>
      Right(comments);
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
    final item = old.copyWith(
        name: data['name'] as String?,
        priority: data['priority'] as String?,
        startDate: data['start_date'] as String?,
        targetDate: data['target_date'] as String?);
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
}

void registerPreview(PreviewRepository repo) {
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

void main() {
  registerPreview(PreviewRepository());
  final router = GoRouter(
      initialLocation: '/workspaces/imagepit/projects/preview/items',
      routes: [
        GoRoute(
            path: '/workspaces/:slug/projects/:projectId/items',
            builder: (_, s) => const WorkItemListPage(
                workspaceSlug: 'imagepit', projectId: 'preview')),
        GoRoute(
            path: '/workspaces/:slug/projects/:projectId/items/new',
            builder: (_, s) => const CreateWorkItemPage(
                workspaceSlug: 'imagepit', projectId: 'preview')),
        GoRoute(
            path: '/workspaces/:slug/projects/:projectId/items/:itemId',
            builder: (_, s) => WorkItemDetailPage(
                workspaceSlug: 'imagepit',
                projectId: 'preview',
                itemId: s.pathParameters['itemId']!)),
      ]);
  runApp(MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router));
}
