import 'package:flutter/material.dart';
import 'package:plane_mobile/core/theme/app_theme.dart';
import 'package:plane_mobile/domain/entities/project.dart';
import 'package:plane_mobile/presentation/widgets/preview/code_block_preview.dart';
import 'package:plane_mobile/presentation/widgets/project/project_card.dart';

// 実データや認証情報を使わず、本番と同じCSPで字形を目視確認する。
void main() => runApp(const JapaneseFontPreview());

class JapaneseFontPreview extends StatefulWidget {
  const JapaneseFontPreview({super.key});

  @override
  State<JapaneseFontPreview> createState() => _JapaneseFontPreviewState();
}

class _JapaneseFontPreviewState extends State<JapaneseFontPreview> {
  var dark = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          appBar: AppBar(title: const Text('日本語表示の確認'), actions: [
            IconButton(
              tooltip: 'テーマ切り替え',
              onPressed: () => setState(() => dark = !dark),
              icon: const Icon(Icons.brightness_6),
            ),
          ]),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            for (final name in ['共通基盤', '教育', 'メディア'])
              ProjectCard(
                project: Project(
                  id: name,
                  name: name,
                  description: '日本語の説明と Work Item の状態を確認します。',
                  network: 'private',
                  workspace: 'example',
                ),
                workspaceSlug: 'example',
                onTap: () {},
              ),
            const TextField(
              decoration: InputDecoration(labelText: '課題のタイトル'),
            ),
            const SizedBox(height: 16),
            const RichHtml(html: '''
<p>漢字・ひらがな・カタカナ：開始日、終了日、関連を更新します。</p>
<pre><code>// 日本語のコメント\n状態を更新する();</code></pre>
<pre><code class="language-file-tree">.
└── ++ 共通基盤 &lt;--[日本語の注釈]</code></pre>
'''),
          ]),
        ),
      );
}
