import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart' as entities;
import 'package:plane_mobile/domain/entities/work_item_page.dart';
import 'package:plane_mobile/domain/entities/comment_page.dart';
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';
import '../../../fixtures/mobile_ui_preview.dart';

class ControlledRepo extends PreviewRepository {
  Completer<Either<Failure, entities.WorkItem>>? update;
  Completer<Either<Failure, entities.Comment>>? post;
  bool failComments = false,
      failStates = false,
      failUpdate = false,
      failDetail = false,
      failItems = false;
  Completer<Either<Failure, CommentPage>>? delayedComments;
  @override
  Future<Either<Failure, entities.WorkItem>> getWorkItem(
          String w, String p, String id) =>
      failDetail
          ? Future.value(const Left(ConnectionFailure("Detail offline")))
          : super.getWorkItem(w, p, id);
  int posts = 0;
  final commentReplies = <Either<Failure, CommentPage>>[];
  @override
  Future<Either<Failure, entities.WorkItem>> updateWorkItem(
          String w, String p, String id, Map<String, dynamic> data) =>
      update?.future ??
      (failUpdate
          ? Future.value(
              const Left(ServerFailure('Forbidden', statusCode: 403)))
          : super.updateWorkItem(w, p, id, data));
  @override
  Future<Either<Failure, entities.Comment>> addComment(
      String w, String p, String id, String html) {
    posts++;
    return post?.future ?? super.addComment(w, p, id, html);
  }

  @override
  Future<Either<Failure, List<entities.WorkItemState>>> getStates(
          String w, String p) =>
      failStates
          ? Future.value(const Left(ConnectionFailure('States offline')))
          : super.getStates(w, p);
  @override
  Future<Either<Failure, CommentPage>> getComments(
          String w, String p, String id, {String? cursor}) =>
      commentReplies.isNotEmpty
          ? Future.value(commentReplies.removeAt(0))
          : delayedComments?.future ??
              (failComments
                  ? Future.value(
                      const Left(ConnectionFailure('Comments offline')))
                  : super.getComments(w, p, id, cursor: cursor));
  @override
  Future<Either<Failure, WorkItemPage>> getWorkItems(String w, String p,
          {String? cursor}) async =>
      failItems
          ? const Left(ConnectionFailure("List offline"))
          : Right(cursor == null
              ? WorkItemPage(
                  items: [previewItems.first],
                  hasNext: true,
                  nextCursor: 'next')
              : WorkItemPage(items: previewItems));
}

void main() {
  late ControlledRepo repo;
  late WorkItemBloc bloc;
  setUp(() async {
    await sl.reset();
    repo = ControlledRepo();
    registerPreview(repo);
    bloc = sl<WorkItemBloc>();
    await bloc.execute(LoadWorkItemDetail(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
  });
  tearDown(() async {
    await bloc.close();
    await sl.reset();
  });
  test('pending/failed update retains detail, candidates and comments',
      () async {
    repo.update = Completer();
    final write = bloc.execute(UpdateWorkItemEvent(
        workspaceSlug: 'w',
        projectId: 'p',
        itemId: 'item-9',
        data: {'priority': 'low'}));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.busy, true);
    expect(bloc.state.workItem?.name, previewItems.first.name);
    expect(bloc.state.comments, isNotEmpty);
    repo.update!
        .complete(const Left(ServerFailure('Forbidden', statusCode: 403)));
    expect(await write, false);
    expect(bloc.state.workItem?.priority, 'none');
    expect(bloc.state.comments, isNotEmpty);
    expect(bloc.state.error, 'Forbidden');
  });
  test('successful update changes detail and cached list without empty state',
      () async {
    await bloc.execute(LoadWorkItems(workspaceSlug: 'w', projectId: 'p'));
    expect(
        await bloc.execute(UpdateWorkItemEvent(
            workspaceSlug: 'w',
            projectId: 'p',
            itemId: 'item-9',
            data: {'priority': 'low'})),
        true);
    expect(bloc.state.workItem?.priority, 'low');
    expect(bloc.state.workItems.first.priority, 'low');
    expect(bloc.state.comments, isNotEmpty);
  });
  test('comment POST is once; unknown failure retains detail and draft barrier',
      () async {
    repo.post = Completer();
    final e = AddCommentEvent(
        workspaceSlug: 'w',
        projectId: 'p',
        itemId: 'item-9',
        commentHtml: '<p>Draft</p>');
    final send = bloc.execute(e);
    await Future<void>.delayed(Duration.zero);
    expect(
        await bloc.execute(AddCommentEvent(
            workspaceSlug: 'w',
            projectId: 'p',
            itemId: 'item-9',
            commentHtml: '<p>Draft</p>')),
        false);
    repo.post!.complete(const Left(ConnectionFailure('Timeout')));
    expect(await send, false);
    expect(repo.posts, 1);
    expect(bloc.state.commentsUncertain, true);
    expect(bloc.state.workItem, isNotNull);
    await bloc.execute(LoadComments(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-9', allPages: true));
    expect(repo.posts, 1);
    expect(bloc.state.commentsUncertain, true);
    await bloc.execute(ResolveCommentUncertainty(itemId: 'item-9'));
    expect(bloc.state.commentsUncertain, false);
  });
  test('comment/supporting retrieval failure keeps detail and explicit errors',
      () async {
    repo.failComments = true;
    repo.failStates = true;
    await bloc.execute(LoadWorkItemDetail(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
    expect(bloc.state.workItem, isNotNull);
    expect(bloc.state.statesError, 'States offline');
    expect(bloc.state.commentsError, 'Comments offline');
    expect(bloc.state.comments, isNotEmpty);
  });
  test('two pages merge by ID; list remains during comment reload failure',
      () async {
    await bloc.execute(LoadWorkItems(workspaceSlug: 'w', projectId: 'p'));
    await bloc.execute(
        LoadWorkItems(workspaceSlug: 'w', projectId: 'p', append: true));
    expect(bloc.state.workItems.map((x) => x.id), ['item-9', 'item-8']);
    expect(bloc.state.hasNext, false);
    final original = bloc.state.comments;
    repo.failComments = true;
    expect(
        await bloc.execute(
            LoadComments(workspaceSlug: 'w', projectId: 'p', itemId: 'item-9')),
        false);
    expect(bloc.state.comments, original);
    expect(bloc.state.workItem, isNotNull);
  });
  test('new item never displays previous comments while supporting reads wait',
      () async {
    repo.delayedComments = Completer();
    final load = bloc.execute(LoadWorkItemDetail(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-8'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.workItem!.id, 'item-8');
    expect(bloc.state.comments, isEmpty);
    repo.delayedComments!.complete(const Right(CommentPage(items: [])));
    await load;
  });
  test('failed PATCH completion GET recovers detail and cached row on reload',
      () async {
    await bloc.execute(LoadWorkItems(workspaceSlug: 'w', projectId: 'p'));
    repo.failDetail = true;
    repo.update = Completer()
      ..complete(const Right(entities.WorkItem(
          id: 'item-9', name: 'テストタスク２', sequenceId: 9, priority: 'low')));
    expect(
        await bloc.execute(UpdateWorkItemEvent(
            workspaceSlug: 'w',
            projectId: 'p',
            itemId: 'item-9',
            data: {'priority': 'low'})),
        false);
    expect(bloc.state.workItems.first.priority, 'none');
    repo.failDetail = false;
    repo.items[0] = repo.items[0].copyWith(priority: 'low');
    await bloc.execute(LoadWorkItemDetail(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
    expect(bloc.state.workItems.first.priority, 'low');
    expect(bloc.state.workItem!.priority, 'low');
  });
  test('refresh and append failures retain their own retry mode', () async {
    await bloc.execute(LoadWorkItems(workspaceSlug: 'w', projectId: 'p'));
    repo.failItems = true;
    expect(
        await bloc.execute(LoadWorkItems(workspaceSlug: 'w', projectId: 'p')),
        false);
    expect(bloc.state.listRetryAppend, false);
    expect(bloc.state.workItems, isNotEmpty);
    expect(
        await bloc.execute(
            LoadWorkItems(workspaceSlug: 'w', projectId: 'p', append: true)),
        false);
    expect(bloc.state.listRetryAppend, true);
    expect(bloc.state.workItems, isNotEmpty);
  });
  test(
      'comment pages deduplicate and keep content on partial failure or repeated cursor',
      () async {
    const first = entities.Comment(id: 'first', commentHtml: '<p>First</p>');
    const updated =
        entities.Comment(id: 'first', commentHtml: '<p>Updated</p>');
    const second = entities.Comment(id: 'second', commentHtml: '<p>Second</p>');
    repo.commentReplies.addAll([
      const Right(
          CommentPage(items: [first], hasNext: true, nextCursor: 'next')),
      const Right(CommentPage(items: [updated, second]))
    ]);
    await bloc.execute(
        LoadComments(workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
    await bloc.execute(LoadComments(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-9', append: true));
    expect(bloc.state.comments.map((c) => c.id), ['first', 'second']);
    expect(bloc.state.comments.first.commentHtml, updated.commentHtml);
    repo.commentReplies.addAll([
      const Right(
          CommentPage(items: [first], hasNext: true, nextCursor: 'next')),
      const Left(ConnectionFailure('Second page offline'))
    ]);
    final before = bloc.state.comments;
    expect(
        await bloc.execute(LoadComments(
            workspaceSlug: 'w',
            projectId: 'p',
            itemId: 'item-9',
            allPages: true)),
        false);
    expect(bloc.state.comments, before);
    repo.commentReplies.addAll([
      const Right(
          CommentPage(items: [first], hasNext: true, nextCursor: 'same')),
      const Right(
          CommentPage(items: [second], hasNext: true, nextCursor: 'same'))
    ]);
    await bloc.execute(
        LoadComments(workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
    expect(
        await bloc.execute(LoadComments(
            workspaceSlug: 'w',
            projectId: 'p',
            itemId: 'item-9',
            append: true)),
        false);
    expect(bloc.state.comments, [first]);
    expect(bloc.state.commentsError, contains('Repeated'));
  });
}
