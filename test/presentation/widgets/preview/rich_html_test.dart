import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:plane_mobile/core/theme/app_theme.dart';
import 'package:plane_mobile/core/theme/typography.dart';
import 'package:plane_mobile/presentation/widgets/preview/code_block_preview.dart';
import 'package:plane_mobile/presentation/widgets/preview/file_tree_view.dart';
import 'package:plane_mobile/presentation/widgets/preview/mermaid_view.dart';

void main() {
  test(
      'tree and mermaid languages on pre or code and data-language are recognised',
      () {
    for (final markup in [
      '<pre><code class="language-tree">.\n└── ++ hello.dart &lt;--[new file]</code></pre>',
      '<pre class="language-tree"><code>.\n└── ++ hello.dart</code></pre>',
      '<pre data-language="tree"><code>.&lt;br&gt;└── hello.dart</code></pre>',
      '<pre><code data-language="file-tree">.\n└── hello.dart</code></pre>',
    ]) {
      final element =
          parseFragment(sanitizeWebHtml(markup)).querySelector('pre')!;
      expect(codeBlockPreviewBuilder(element), isA<FileTreeView>());
    }
    final mermaid = parseFragment(
            '<pre data-language="mermaid"><code>graph TD; A--&gt;B;</code></pre>')
        .querySelector('pre')!;
    expect(codeBlockPreviewBuilder(mermaid), isA<MermaidView>());
    final plain = parseFragment('<pre><code>plain_code()</code></pre>')
        .querySelector('pre')!;
    expect(codeBlockPreviewBuilder(plain), isNull);
  });

  test('code block line breaks and entities survive preview extraction', () {
    final element = parseFragment(
            '<pre><code class="language-tree">.<br>└── ++ a&amp;b.dart &lt;--[説明]</code></pre>')
        .querySelector('pre')!;
    final tree = codeBlockPreviewBuilder(element) as FileTreeView;
    expect(tree.source, '.\n└── ++ a&b.dart <--[説明]');
  });

  testWidgets('Web code retains monospace and can fall back to Japanese glyphs',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(
          body: RichHtml(
              html:
                  '<p><code>日本語のコメント</code></p><pre><code>状態を更新する();</code></pre>')),
    ));
    await tester.pumpAndSettle();
    final styles = <TextStyle>[];
    void visit(InlineSpan span, TextStyle inherited) {
      if (span is! TextSpan) return;
      final style = inherited.merge(span.style);
      if (span.text?.contains(RegExp(r'[日本語状態]')) ?? false) styles.add(style);
      for (final child in span.children ?? <InlineSpan>[]) {
        visit(child, style);
      }
    }

    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      visit(widget.text, const TextStyle());
    }
    expect(styles, hasLength(2));
    for (final style in styles) {
      expect(style.fontFamily, 'monospace');
      expect(style.fontFamilyFallback, contains(AppTypography.webFontFamily));
    }
  }, skip: !kIsWeb);

  test(
      'sanitizer removes executable markup, event handlers, CSS URLs and automatic embeds',
      () {
    final clean = sanitizeWebHtml(
        '''<p onclick="alert(1)" style="background:url(https://outside.example/image)">Safe body</p>
<script>EXECUTABLE</script><iframe src="https://outside.example">EMBED</iframe>
<img src="https://outside.example/track"><video src="https://outside.example/media"></video>
<svg><a xlink:href="javascript:alert(1)">SVG</a></svg>
<a href="javascript:alert(1)">Bad link</a><a href="data:text/html,evil">Data link</a>
<a href="java&#x0a;script:alert(1)">Obfuscated</a>
<a href="https://example.com">Good link</a>''');
    expect(clean, isNot(contains('EXECUTABLE')));
    expect(clean, isNot(contains('outside.example')));
    expect(clean, isNot(contains('javascript')));
    expect(clean, isNot(contains('data:text')));
    expect(clean, isNot(contains('onclick')));
    expect(clean, isNot(contains('style=')));
    expect(clean, contains('Safe body'));
    expect(
        parseFragment(clean)
            .querySelectorAll('a')
            .where((e) => e.attributes.containsKey('href'))
            .length,
        1);
  });

  testWidgets(
      'Web preserves body, table, code and FileTree while blocking unsafe content',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: RichHtml(html: '''
<p>Readable body</p><table><tr><th>Heading</th><td>Cell value</td></tr></table>
<pre><code>plain_code()</code></pre>
<pre><code class="language-file-tree">.
└── ++ hello.dart &lt;--[new file]</code></pre>
<script>HIDDEN SCRIPT</script><iframe src="https://outside.example">HIDDEN FRAME</iframe>
''')))));
    await tester.pumpAndSettle();
    final rendered = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .join('\n');
    expect(rendered, contains('Readable body'));
    expect(rendered, contains('Heading'));
    expect(rendered, contains('Cell value'));
    expect(rendered, contains('plain_code()'));
    expect(rendered, contains('hello.dart'));
    expect(rendered, isNot(contains('HIDDEN')));
    expect(find.byType(FileTreeView), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !kIsWeb);
}
