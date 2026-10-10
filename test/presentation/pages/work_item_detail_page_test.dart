import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/errors/failures.dart';
import 'package:plane_mobile/domain/entities/work_item.dart' as entities;
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';
import 'package:plane_mobile/presentation/pages/work_item/work_item_detail_page.dart';
import '../../fixtures/mobile_ui_preview.dart';

class ForbiddenRepo extends PreviewRepository {
  bool forbidden = false;
  int writes = 0;
  Map<String, dynamic>? lastWrite;
  @override
  Future<Either<Failure, entities.WorkItem>> updateWorkItem(
      String w, String p, String id, Map<String, dynamic> data) {
    writes++;
    lastWrite = Map.of(data);
    return forbidden
        ? Future.value(const Left(ServerFailure('Forbidden', statusCode: 403)))
        : super.updateWorkItem(w, p, id, data);
  }
}

void main() {
  late ForbiddenRepo repo;
  late WorkItemBloc bloc;
  setUp(() async {
    await sl.reset();
    repo = ForbiddenRepo();
    registerPreview(repo);
  });
  tearDown(() async {
    await bloc.close();
    await sl.reset();
  });
  Future<void> mount(WidgetTester t) async {
    // Create the event queue in the widget test's zone, as the real page does.
    bloc = sl<WorkItemBloc>();
    bloc.add(LoadWorkItemDetail(
        workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
    await t.pumpWidget(MaterialApp(
        home: BlocProvider.value(
            value: bloc,
            child: const WorkItemDetailView(
                workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'))));
    await t.pumpAndSettle();
  }

  testWidgets('attribute chip opens a sheet; cancel does not PATCH', (t) async {
    await mount(t);
    await t.tap(find.byKey(const ValueKey('property-Priority')));
    await t.pumpAndSettle();
    await t.tap(find.text('Low'));
    await t.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await t.pumpAndSettle();
    expect(repo.writes, 0);
    expect(bloc.state.workItem?.priority, 'none');
  });
  testWidgets('direct save and 403 keep body/comments visible', (t) async {
    await mount(t);
    await t.tap(find.byKey(const ValueKey('property-Priority')));
    await t.pumpAndSettle();
    await t.tap(find.text('Low'));
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    expect(bloc.state.workItem?.priority, 'low');
    expect(find.text('テストタスク２'), findsOneWidget);
    expect(find.text('テストコメントです。', findRichText: true), findsOneWidget);
    repo.forbidden = true;
    await t.tap(find.byKey(const ValueKey('property-Priority')));
    await t.pumpAndSettle();
    await t.tap(find.text('High'));
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    expect(bloc.state.workItem?.priority, 'low');
    expect(find.text('テストタスク２'), findsOneWidget);
    expect(find.text('Forbidden'), findsOneWidget);
    expect(find.byKey(const ValueKey('comment-input')), findsOneWidget);
  });
  testWidgets('comment input remains above keyboard while detail scrolls',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 844);
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.reset);
    await mount(t);
    await t.pumpAndSettle();
    expect(t.getBottomLeft(find.byKey(const ValueKey('comment-input'))).dy,
        lessThanOrEqualTo(544));
    await t.drag(
        find.byKey(const ValueKey('detail-scroll')), const Offset(0, -200));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('comment-input')), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'assignee/label sheets send v1 UUID fields and allow empty selection',
      (t) async {
    await mount(t);
    await t.tap(find.byKey(const ValueKey('property-Assignees')));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(CheckboxListTile, 'r-takahashi'));
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    expect(repo.lastWrite, {'assignees': <String>[]});
    expect(bloc.state.workItem!.assignees, isEmpty);
    await t.tap(find.byKey(const ValueKey('property-Labels')));
    await t.pumpAndSettle();
    await t.tap(find.text('Design'));
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    expect(repo.lastWrite, {
      'labels': ['design']
    });
    expect(bloc.state.workItem!.labelIds, ['design']);
  });
  testWidgets('state edit and date clear change only the chosen property',
      (t) async {
    repo.items[0] = repo.items[0]
        .copyWith(startDate: '2026-10-10', targetDate: '2026-10-20');
    await mount(t);
    await t.tap(find.byKey(const ValueKey('property-State')));
    await t.pumpAndSettle();
    await t.tap(find.text('In progress'));
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    expect(repo.lastWrite, {'state': 'started'});
    await t.tap(find.byKey(const ValueKey('property-Start date')));
    await t.pumpAndSettle();
    await t.tap(find.text('Clear date'));
    await t.pumpAndSettle();
    expect(repo.lastWrite, {'start_date': null});
    expect(bloc.state.workItem!.startDate, isNull);
    expect(bloc.state.workItem!.targetDate, '2026-10-20');
  });
  testWidgets('title draft survives comment rebuild and forbidden save',
      (t) async {
    await mount(t);
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit title'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('edit-title')), '編集途中の日本語');
    bloc.add(
        LoadComments(workspaceSlug: 'w', projectId: 'p', itemId: 'item-9'));
    await t.pumpAndSettle();
    expect(find.text('編集途中の日本語'), findsOneWidget);
    repo.forbidden = true;
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await t.pumpAndSettle();
    expect(find.text('編集途中の日本語'), findsOneWidget);
    expect(bloc.state.workItem!.name, previewItems.first.name);
    final writes = repo.writes;
    await t.tap(find.widgetWithText(TextButton, 'Cancel'));
    await t.pumpAndSettle();
    expect(repo.writes, writes);
  });
}
