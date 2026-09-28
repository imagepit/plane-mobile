import 'package:flutter/material.dart';

/// IMAGEPIT FileTree（```tree）の1行。
class FileTreeLine {
  final String prefix;
  final String marker;
  final String name;
  final String? callout;
  final bool isRoot;

  const FileTreeLine({
    this.prefix = '',
    this.marker = '',
    required this.name,
    this.callout,
    this.isRoot = false,
  });
}

/// tree-notation.md（design-system のパーサ仕様）の書式を Dart で再現する。
///
/// - 枝線: `├──` / `└──` / `│`（その他の接頭辞はそのまま prefix に残す）
/// - マーカー: `++ `（新規）/ `** `（変更）/ `-- `（削除）/ 無し（変更なし）
/// - callout: ` <--[...]`（末尾の `]` まで）、コメント `# ...` は callout に畳む
/// - 先頭の単独 `.` はルート表示として扱い、名前は空にする
class FileTreeParser {
  static List<FileTreeLine> parse(String source) {
    final lines = <FileTreeLine>[];
    for (final raw in source.split('\n')) {
      if (raw.trim().isEmpty) continue;
      if (raw.trimRight() == '.') {
        lines.add(const FileTreeLine(name: '', isRoot: true));
        continue;
      }

      var text = raw;
      String? callout;
      final calloutIndex = text.indexOf(' <--[');
      if (calloutIndex >= 0 && text.trimRight().endsWith(']')) {
        callout = text
            .substring(calloutIndex + ' <--['.length, text.trimRight().length - 1)
            .trim();
        text = text.substring(0, calloutIndex);
      } else {
        final commentIndex = text.indexOf(' # ');
        if (commentIndex >= 0) {
          callout = text.substring(commentIndex + 3).trim();
          text = text.substring(0, commentIndex);
        }
      }

      var marker = '';
      var name = text;
      final connectorIndex = _connectorEnd(text);
      final prefix = text.substring(0, connectorIndex);
      name = text.substring(connectorIndex).trimLeft();
      for (final m in const ['++ ', '** ', '-- ']) {
        if (name.startsWith(m)) {
          marker = m.trim();
          name = name.substring(m.length);
          break;
        }
      }
      lines.add(FileTreeLine(
        prefix: prefix,
        marker: marker,
        name: name.trimRight(),
        callout: callout,
      ));
    }
    return lines;
  }

  /// 枝線記号とその直後の空白まで（名前の手前まで）を返す。
  /// 枝線が無い行では 0。
  static int _connectorEnd(String text) {
    var end = 0;
    for (final marker in const ['├──', '└──']) {
      final i = text.indexOf(marker);
      if (i >= 0) {
        final e = i + marker.length;
        end = end == 0 ? e : (e < end ? e : end);
      }
    }
    if (end == 0) return 0;
    var j = end;
    while (j < text.length && text[j] == ' ') {
      j++;
    }
    return j;
  }
}

/// FileTree をネイティブ描画する。
class FileTreeView extends StatelessWidget {
  final String source;

  const FileTreeView({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final lines = FileTreeParser.parse(source);
    final scheme = Theme.of(context).colorScheme;
    final mono = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      height: 1.5,
    );

    Color markerColor(String marker) => switch (marker) {
          '++' => Colors.green.shade700,
          '**' => Colors.orange.shade800,
          '--' => scheme.error,
          _ => scheme.onSurface,
        };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            if (line.isRoot)
              const SizedBox(height: 2)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.prefix, style: mono?.copyWith(color: scheme.outline)),
                        if (line.marker.isNotEmpty)
                          Text('${line.marker} ', style: mono?.copyWith(color: markerColor(line.marker), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(line.name, style: mono?.copyWith(color: scheme.onSurface)),
                        ),
                      ],
                    ),
                    if (line.callout != null)
                      Padding(
                        padding: EdgeInsets.only(left: _indentWidth(line.prefix)),
                        child: Text(
                          line.callout!,
                          style: mono?.copyWith(color: scheme.outline, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// callout の折り返しインデント（枝線の幅ぶん）。
  double _indentWidth(String prefix) => prefix.length * 7.2;
}
