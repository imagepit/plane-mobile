// 一時確認用（コミットしない）: 実 Work Item（#7678）の Mermaid / FileTree プレビュー確認
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plane_mobile/app.dart' as app;
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment('SMOKE_BASE_URL');
  const apiToken = String.fromEnvironment('SMOKE_API_TOKEN');
  const slug = String.fromEnvironment('SMOKE_WORKSPACE_SLUG');

  testWidgets('preview blocks check (real item)', (tester) async {
    await Hive.initFlutter();
    await configureDependencies();
    await sl<LocalStorage>().saveConfig(
      selfHostedUrl: baseUrl,
      workspaceSlug: slug,
      apiToken: apiToken,
    );
    await tester.pumpWidget(const app.App());
    await Future<void>.delayed(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text(slug).first);
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('imagepit'));
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 検索ボックスで #7678 を絞り込んで開く
    await tester.enterText(find.byType(TextField).first, '#7678');
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('#7678').first);
    await Future<void>.delayed(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('PREVIEW CHECK: #7678 detail open, holding 35s for screenshots');
    await Future<void>.delayed(const Duration(seconds: 35));
  });
}
