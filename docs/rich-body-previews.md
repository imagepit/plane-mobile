# PWA本文のMermaid・ファイルツリー表示

`language-mermaid`のコードブロックは同梱Mermaid 11.16.0でSVGの図として表示する。図の全画面表示、拡大・移動、ソース切替に対応する。`tree` / `file-tree`は既存FileTreeのフォルダー・ファイル・追加／修正／削除マークと注釈で表示する。言語は`pre`または`code`の`language-*`クラスと`data-language`から取得し、`br`とHTML entityを保持する。通常のコードはそのまま表示する。説明とコメントは同じRichHtmlを使う。

WebViewやiframeは追加しない。既存のCSP・同一origin・同梱日本語フォントを維持する。Mermaidの設定はstrict、HTML labelなしに固定し、本文からthemeCSSや安全性設定を変更できないようにする。画像ノードは構文解析後、画像レイアウト前に拒否する。外部リソースを読むCSSは描画前に拒否する。構文エラー、未対応のメディア／CSS、読込み失敗時はソースを表示する。遅れた描画結果は新しい本文・テーマへ上書きしない。

## 検証

2026-10-10、Flutter試験85件成功・Web限定4件はVMでskip。Chromeは89件成功。analyze error/warning 0。パッケージ試験20件成功。実Mermaidを使うNode試験4件で、引用符付き画像属性、CSSリソース／escape／entity、init／frontmatterによる設定変更、構文エラーを検証した。CIにも同じNode試験を追加する。

Chrome widget試験ではplatform viewがモックになるため、SVGの実描画は別途ローカルrelease previewで確認した。HTTP応答には本番と同じ`web/_headers`を適用し、390×844の明暗テーマで日本語の依存図と`data-language="tree"`のツリーを確認した。ソース切替と復帰、全画面表示・ズーム・閉じる、構文エラー時のソース表示も確認した。ブラウザーのCSP違反はなかった。ダミー項目だけを使い、PATやAPIへの接続は行わない。

- [明るいテーマ](ui-evidence/rich-body-light-390.jpg)
- [暗いテーマ](ui-evidence/rich-body-dark-390.jpg)

iPhone実機でのピンチ操作とホーム画面起動は未実施。merge後の自動配備が成功したら、PWAを終了して開き直し、実際の本文を確認する。
