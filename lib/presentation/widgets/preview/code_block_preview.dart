import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:plane_mobile/core/theme/typography.dart';
import 'package:plane_mobile/presentation/widgets/preview/file_tree_view.dart';
import 'package:plane_mobile/presentation/widgets/preview/mermaid_view.dart';

/// `language-file-tree` / `language-mermaid` のコードブロックを
/// プレビュー表示へ差し替える。class が無いブロックは通常のコード表示のまま。
Widget? codeBlockPreviewBuilder(dom.Element element) {
  final localName = element.localName;
  if (localName != 'pre' && localName != 'code') return null;

  final code = localName == 'code' ? element : element.querySelector('code');
  final target = code ?? element;
  final classes = target.className.split(RegExp(r'\s+'));
  final text = target.text;
  if (text.trim().isEmpty) return null;

  if (classes.contains('language-file-tree')) {
    return FileTreeView(source: text);
  }
  if (classes.contains('language-mermaid')) {
    return MermaidView(source: text);
  }
  return null;
}

bool _safeLink(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || value.contains(RegExp(r'[\x00-\x20\\]'))) return false;
  return uri.scheme.isEmpty ||
      const ['https', 'http', 'mailto'].contains(uri.scheme.toLowerCase());
}

/// Web bodies are inert text/layout; remote media must never load automatically.
String sanitizeWebHtml(String html) {
  final fragment = parser.parseFragment(html);
  const blocked = {
    'script',
    'iframe',
    'object',
    'embed',
    'img',
    'picture',
    'video',
    'audio',
    'source',
    'track',
    'svg',
    'math',
    'style',
    'link',
    'meta',
    'base',
    'form',
    'input',
    'button',
    'textarea',
    'select',
    'canvas',
    'template',
  };
  const attributes = {
    'class',
    'title',
    'colspan',
    'rowspan',
    'scope',
    'dir',
    'lang'
  };
  for (final element in fragment.querySelectorAll('*').toList()) {
    if (blocked.contains(element.localName)) {
      element.remove();
      continue;
    }
    element.attributes.removeWhere((name, value) =>
        !attributes.contains(name) &&
        !(element.localName == 'a' && name == 'href' && _safeLink(value)));
  }
  return fragment.outerHtml;
}

/// HTML 本文を描画し、FileTree / Mermaid のコードブロックはプレビューに差し替える。
class RichHtml extends StatelessWidget {
  final String html;
  final TextStyle? textStyle;

  const RichHtml({super.key, required this.html, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      kIsWeb ? sanitizeWebHtml(html) : html,
      textStyle: textStyle,
      customStylesBuilder: (element) => kIsWeb &&
              const {'pre', 'code', 'kbd', 'samp', 'tt'}
                  .contains(element.localName)
          ? {'font-family': 'monospace, ${AppTypography.webFontFamily}'}
          : null,
      customWidgetBuilder: codeBlockPreviewBuilder,
    );
  }
}
