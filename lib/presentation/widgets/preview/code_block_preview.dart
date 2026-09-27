import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
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

/// HTML 本文を描画し、FileTree / Mermaid のコードブロックはプレビューに差し替える。
class RichHtml extends StatelessWidget {
  final String html;
  final TextStyle? textStyle;

  const RichHtml({super.key, required this.html, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      textStyle: textStyle,
      customWidgetBuilder: codeBlockPreviewBuilder,
    );
  }
}
