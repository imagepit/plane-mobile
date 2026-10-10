import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plane_mobile/app.dart' as app;
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';

/// 自社CE（Plane CE v1.4.1）に対するスモークテスト。
///
/// 実行例（値は smoke.local.json に置く。トークンをログに残さない）:
/// `flutter test integration_test/smoke_test.dart --dart-define-from-file=smoke.local.json -d <device-id>`
///
/// スプラッシュの遷移やネットワーク応答は実時間のため、待ちは実時間で行う。
Future<void> _wait(WidgetTester tester, {int seconds = 2}) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment('SMOKE_BASE_URL');
  const apiToken = String.fromEnvironment('SMOKE_API_TOKEN');
  const workspaceSlug = String.fromEnvironment('SMOKE_WORKSPACE_SLUG');
  const projectId = String.fromEnvironment('SMOKE_PROJECT_ID');
  const projectName = String.fromEnvironment('SMOKE_PROJECT_NAME');

  testWidgets('smoke: 設定→接続→一覧→作成→コメント→削除', (tester) async {
    expect(baseUrl, isNotEmpty, reason: 'SMOKE_BASE_URL が必要');
    expect(apiToken, isNotEmpty,
        reason: 'SMOKE_API_TOKEN が smoke.local.json に必要');
    expect(workspaceSlug, isNotEmpty, reason: 'SMOKE_WORKSPACE_SLUG が必要');
    expect(projectId, isNotEmpty, reason: 'SMOKE_PROJECT_ID が必要');

    // 未設定の状態から開始する（保存済み設定があれば消す）
    await Hive.initFlutter();
    await configureDependencies();
    await sl<LocalStorage>().clearConfig();

    // テストのツリーへ載せる（runApp ではファインダーが辿れない）
    await tester.pumpWidget(const app.App());
    await _wait(tester, seconds: 4);

    // --- 設定画面への入力 ---
    expect(find.text('Server URL'), findsOneWidget, reason: '未設定なら設定画面へ遷移する');
    await tester.enterText(find.byType(TextFormField).at(0), baseUrl);
    await tester.enterText(find.byType(TextFormField).at(1), workspaceSlug);
    await tester.enterText(find.byType(TextFormField).at(2), apiToken);

    // --- 接続テスト ---
    await tester.tap(find.text('Test Connection'));
    await _wait(tester, seconds: 4);
    expect(find.textContaining('Connected as'), findsOneWidget,
        reason: '/api/v1/users/me/ で認証できること');
    // ignore: avoid_print
    print('SMOKE OK: connection test (/api/v1/users/me/)');

    // 接続テストの成功画面からは保存できないため、設定を保存して確定させる
    await tester.tap(find.text('Change server'));
    await _wait(tester);
    await tester.enterText(find.byType(TextFormField).at(0), baseUrl);
    await tester.enterText(find.byType(TextFormField).at(1), workspaceSlug);
    await tester.enterText(find.byType(TextFormField).at(2), apiToken);
    await tester.tap(find.text('Save & Connect'));
    await _wait(tester, seconds: 4);

    // --- Workspace → Project → Work Items の一覧表示 ---
    expect(find.text(workspaceSlug), findsWidgets,
        reason: '設定済み slug の Workspace が表示される');
    await tester.tap(find.text(workspaceSlug).first);
    await _wait(tester, seconds: 3);
    expect(find.text(projectName), findsOneWidget, reason: '試験Project が表示される');
    await tester.tap(find.text(projectName));
    await _wait(tester, seconds: 3);
    expect(find.text('Work items'), findsOneWidget);
    // ignore: avoid_print
    print('SMOKE OK: projects / work items listing');

    final dio = sl<DioClient>();
    String listPath() =>
        '/api/v1/workspaces/$workspaceSlug/projects/$projectId/'
        'work-items/?expand=state,assignees,labels';

    Future<String?> findItemIdByName(String title) async {
      String? cursor;
      final seen = <String>{};
      do {
        final res = await dio.get<Map<String, dynamic>>(listPath(),
            queryParameters: {if (cursor != null) 'cursor': cursor});
        // ignore: avoid_print
        print('SMOKE API: GET work-items -> HTTP ${res.statusCode}');
        final results = res.data?['results'] as List<dynamic>? ?? const [];
        for (final item in results) {
          if ((item as Map<String, dynamic>)['name'] == title)
            return item['id'] as String?;
        }
        if (res.data?['next_page_results'] != true) break;
        cursor = res.data?['next_cursor'] as String?;
        expect(cursor, isNotNull);
        expect(seen.add(cursor!), true, reason: 'cursorが繰り返されないこと');
      } while (true);
      return null;
    }

    // --- Work Item 作成 ---
    final title = 'smoke-${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.byKey(const ValueKey('create-work-item')));
    await _wait(tester, seconds: 2);
    final createPage = find.text('Create Work Item');
    // ignore: avoid_print
    print('SMOKE DBG: create page present=${createPage.evaluate().isNotEmpty} '
        'formFields=${find.byType(TextFormField).evaluate().length}');
    await tester.enterText(
        find.byKey(const ValueKey('new-work-item-title')), title);
    final createButton = find.byKey(const ValueKey('save-new-work-item'));
    final enabled = createButton.evaluate().isEmpty
        ? 'button not found'
        : '${tester.widget<TextButton>(createButton).onPressed != null}';
    // ignore: avoid_print
    print(
        'SMOKE DBG: create button found=${createButton.evaluate().length} enabled=$enabled');
    await tester.tap(createButton);
    await _wait(tester, seconds: 4);
    // ignore: avoid_print
    print(
        'SMOKE DBG: after tap, create page present=${createPage.evaluate().isNotEmpty}');
    if (createPage.evaluate().isNotEmpty) {
      final errors = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .where((d) => d.contains('Please enter'))
          .toList();
      // ignore: avoid_print
      print('SMOKE DBG: validation errors=$errors');
    }

    final createdId = await findItemIdByName(title);
    expect(createdId, isNotNull, reason: '作成した Work Item が API で取得できること');
    // ignore: avoid_print
    print('SMOKE OK: created work item id=$createdId name=$title');

    // 作成結果は取得済み一覧へ反映される。
    await _wait(tester, seconds: 2);
    await tester.scrollUntilVisible(find.text(title), 450,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first,
        maxScrolls: 100);
    await _wait(tester);
    expect(find.text(title), findsOneWidget,
        reason: '一覧に作成した Work Item が表示される');

    // --- コメント投稿 ---
    await tester.tap(find.text(title));
    await _wait(tester, seconds: 3);
    final commentBody =
        'smoke-comment-${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(
      find.byKey(const ValueKey('comment-input')),
      commentBody,
    );
    await tester.tap(find.byKey(const ValueKey('send-comment')));
    await _wait(tester, seconds: 4);

    final commentsRes = await dio.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/'
      'work-items/$createdId/comments/',
    );
    // ignore: avoid_print
    print('SMOKE API: GET comments -> HTTP ${commentsRes.statusCode}');
    final comments = commentsRes.data?['results'] as List<dynamic>? ?? const [];
    expect(comments, isNotEmpty, reason: 'コメントが API で取得できること');
    // ignore: avoid_print
    print('SMOKE OK: comment posted count=${comments.length}');

    // --- 削除（後片付け）---
    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
    await _wait(tester, seconds: 2);
    await tester.tap(find.text('Delete'));
    await _wait(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await _wait(tester, seconds: 4);

    expect(await findItemIdByName(title), isNull, reason: '削除後は一覧から消えること');
    // ignore: avoid_print
    print('SMOKE OK: deleted work item id=$createdId');
  });
}
