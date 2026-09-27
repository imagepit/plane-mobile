// 一時確認用（コミットしない）: HTML 描画の確認のため詳細画面を開いて待機する
import 'package:flutter/material.dart';
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
  const projectName = String.fromEnvironment('SMOKE_PROJECT_NAME');

  testWidgets('html rendering check', (tester) async {
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
    await tester.tap(find.text(projectName));
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('smoke-html-check'));
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('HTML CHECK: detail open, holding 25s for screenshots');
    await Future<void>.delayed(const Duration(seconds: 25));
  });
}
