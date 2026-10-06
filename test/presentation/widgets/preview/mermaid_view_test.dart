import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/presentation/widgets/preview/mermaid_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  testWidgets('Web displays Mermaid source without initialising a WebView',
      (tester) async {
    const source =
        'graph TD; A[<img src="https://blocked.invalid/">] --> B[<script>alert(1)</script>]';
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MermaidView(source: source))));
    await tester.pumpAndSettle();
    expect(find.text(source), findsOneWidget);
    expect(find.byType(WebViewWidget), findsNothing);
    expect(tester.takeException(), isNull);
  }, skip: !kIsWeb);
}
