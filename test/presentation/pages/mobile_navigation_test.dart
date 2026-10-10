import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/presentation/widgets/work_item/comment_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/presentation/widgets/navigation/mobile_shell.dart';
import '../../fixtures/mobile_ui_preview.dart';

class UnknownCreationRepo extends PreviewRepository {
  bool fail = true;
  int posts = 0;
  Completer<Either<Failure, WorkItem>>? pending;
  @override
  Future<Either<Failure, WorkItem>> createWorkItem(
      String w, String p, Map<String, dynamic> data) {
    posts++;
    if (pending != null) return pending!.future;
    return fail
        ? Future.value(const Left(ConnectionFailure('Timeout')))
        : super.createWorkItem(w, p, data);
  }
}

void main() {
  setUp(() async {
    await sl.reset();
  });
  tearDown(() async {
    await sl.reset();
  });
  testWidgets('detail return preserves list offset and applies saved attribute',
      (t) async {
    final repo = PreviewRepository();
    repo.items = [
      for (int i = 0; i < 40; i++)
        WorkItem(
            id: 'item-$i',
            name: '項目 $i',
            sequenceId: i,
            stateDetail: previewState,
            priority: 'none')
    ];
    registerPreview(repo);
    final router = createPreviewRouter();
    addTearDown(router.dispose);
    await t.pumpWidget(previewApp(router));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, -650));
    await t.pumpAndSettle();
    final shell = t.state<MobileShellState>(find.byType(MobileShell));
    final offset = shell.session!.scroll.offset;
    router.push('${shell.session!.itemsPath}/item-10');
    await t.pumpAndSettle();
    expect(find.text('IMAGE-10'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-work-item')), findsNothing);
    await t.tap(find.byKey(const ValueKey('property-Priority')));
    await t.pumpAndSettle();
    await t.tap(find.text('Low'));
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Back to work items'));
    await t.pumpAndSettle();
    expect(shell.session!.scroll.offset, closeTo(offset, 1));
    expect(
        shell.session!.bloc.state.workItems
            .firstWhere((x) => x.id == 'item-10')
            .priority,
        'low');
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets('tabs keep search query and filters; keyboard hides navigation',
      (t) async {
    registerPreview(PreviewRepository());
    final router = createPreviewRouter();
    addTearDown(router.dispose);
    await t.pumpWidget(previewApp(router));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('tab-2')));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const ValueKey('work-item-search')), 'IMAGE-9');
    await t.pumpAndSettle();
    expect(find.text('テストタスク２'), findsOneWidget);
    expect(find.text('テストタスク'), findsNothing);
    await t.tap(find.byKey(const ValueKey('tab-1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('tab-2')));
    await t.pumpAndSettle();
    expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('work-item-search')))
            .controller!
            .text,
        'IMAGE-9');
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('tab-0')), findsNothing);
    t.view.resetViewInsets();
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets('direct detail resolves identifier; Home handles no selection',
      (t) async {
    registerPreview(PreviewRepository());
    final router = createPreviewRouter(initialLocation: '/workspaces');
    addTearDown(router.dispose);
    await t.pumpWidget(previewApp(router));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('tab-1')));
    await t.pumpAndSettle();
    expect(find.text('Select a workspace and project first'), findsOneWidget);
    router.go('/workspaces/imagepit/projects/preview/items/item-9');
    await t.pumpAndSettle();
    expect(find.text('IMAGE-9'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets(
      'unknown create preserves input across reopening and blocks unconfirmed retry',
      (t) async {
    final repo = UnknownCreationRepo();
    registerPreview(repo);
    final router = createPreviewRouter();
    addTearDown(router.dispose);
    await t.pumpWidget(previewApp(router));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('create-work-item')));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const ValueKey('new-work-item-title')), 'New draft');
    await t.enterText(
        find.byKey(const ValueKey('new-work-item-description')), '日本語の本文');
    await t.tap(find.byKey(const ValueKey('save-new-work-item')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('save-new-work-item')));
    expect(repo.posts, 1);
    await t.ensureVisible(find.widgetWithText(OutlinedButton, 'Cancel'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('create-work-item')));
    await t.pumpAndSettle();
    expect(find.text('New draft'), findsOneWidget);
    expect(find.text('日本語の本文'), findsOneWidget);
    await t.ensureVisible(find.text('Reload and check work items'));
    await t.pumpAndSettle();
    await t.tap(find.text('Reload and check work items'));
    await t.pumpAndSettle();
    await t.tap(find.text('Not created'));
    await t.pumpAndSettle();
    expect(repo.posts, 1);
    repo.fail = false;
    await t.tap(find.byKey(const ValueKey('save-new-work-item')));
    await t.pumpAndSettle();
    expect(repo.posts, 2);
    expect(find.text('New draft'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets('detail composer uses the selected project draft/snapshot maps',
      (t) async {
    registerPreview(PreviewRepository());
    final router = createPreviewRouter(
        initialLocation: '/workspaces/imagepit/projects/preview/items/item-9');
    addTearDown(router.dispose);
    await t.pumpWidget(previewApp(router));
    await t.pumpAndSettle();
    final shell = t.state<MobileShellState>(find.byType(MobileShell));
    final composer = t.widget<CommentSection>(find.byType(CommentSection));
    expect(identical(composer.drafts, shell.session!.drafts), true);
    expect(
        identical(composer.pendingDrafts, shell.session!.pendingCommentDrafts),
        true);
    expect(identical(composer.postedDrafts, shell.session!.postedDrafts), true);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets(
      'create input is restored on reopening before POST response arrives',
      (t) async {
    final repo = UnknownCreationRepo()..pending = Completer();
    registerPreview(repo);
    final router = createPreviewRouter();
    addTearDown(router.dispose);
    await t.pumpWidget(previewApp(router));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('create-work-item')));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const ValueKey('new-work-item-title')), 'Pending title');
    await t.enterText(find.byKey(const ValueKey('new-work-item-description')),
        'Pending body');
    await t.tap(find.byKey(const ValueKey('save-new-work-item')));
    await t.pump();
    router.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const ValueKey('create-work-item')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Pending title'), findsOneWidget);
    expect(find.text('Pending body'), findsOneWidget);
    expect(repo.posts, 1);
    repo.pending!.complete(const Left(ConnectionFailure('Timeout')));
    await t.pumpAndSettle();
    expect(find.text('Pending body'), findsOneWidget);
    expect(
        t
            .widget<TextButton>(
                find.byKey(const ValueKey('save-new-work-item')))
            .onPressed,
        isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
}
