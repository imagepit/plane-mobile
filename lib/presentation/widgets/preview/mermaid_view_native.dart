import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

/// Mermaid（```mermaid）を同梱の mermaid.min.js で描画する。
///
/// 外部 URL は読み込まず、アセット同梱の JS（mermaid 11.16.0・#7678 と同じ版）のみを
/// 使う。描画に失敗した場合はソース表示へフォールバックする。
class MermaidView extends StatefulWidget {
  final String source;

  const MermaidView({super.key, required this.source});

  @override
  State<MermaidView> createState() => _MermaidViewState();
}

class _MermaidViewState extends State<MermaidView> {
  WebViewController? _controller;
  double _height = 200;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final js = await rootBundle.loadString('assets/mermaid/mermaid.min.js');
      // ソースは HTML として埋め込む（mermaid は要素の textContent を読む）。
      // JSON エンコードすると引用符と \n がそのまま混ざり構文エラーになる。
      final escapedSource = widget.source
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{margin:0;background:transparent;}</style>
<script>$js</script>
</head>
<body>
<pre class="mermaid">$escapedSource</pre>
<script>
  try {
    mermaid.initialize({ startOnLoad: true, securityLevel: 'strict' });
  } catch (e) {
    document.body.textContent = 'RENDER_ERROR';
  }
</script>
</body>
</html>
''';
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));
      controller.setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _measure(controller),
        onWebResourceError: (_) {
          if (mounted) setState(() => _failed = true);
        },
      ));
      await controller.loadHtmlString(html);
      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _measure(WebViewController controller) async {
    try {
      final raw = await controller.runJavaScriptReturningResult(
          'Math.max(document.body.scrollHeight, 120)');
      final height = double.tryParse(raw.toString()) ?? _height;
      if (mounted) {
        setState(() => _height = height.clamp(120, 2000));
      }
    } catch (_) {
      // 測定に失敗しても初期高さのまま表示する
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_failed || _controller == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.source,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontFamily: 'monospace'),
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: _height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
