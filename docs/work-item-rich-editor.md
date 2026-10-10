# PWAの作業項目エディタ

詳細のタイトル、本文、空の本文にある「Add description」をタップするか、メニューの「Edit work item」から編集シートを開く。上部に閉じるボタン・識別子・Saveを置き、タイトルと本文を同じ画面で編集する。Saveの成功後に詳細へ戻り、詳細と取得済み一覧の内容を更新する。

本文はHTMLソースを入力させず、ブラウザーのcontenteditableで表示した書式のまま編集する。下部のツールバーでUndo・Redo・太字・斜体・下線・取消線・リンク・キーボードを閉じる操作を提供する。「＋」の追加メニューでは段落、H1〜H6、箇条書き、番号付きリスト、チェックリスト、表、区切り線、引用、コード、Mermaid、ファイルツリーを選べる。表の中では行・列の追加と削除も選べる。保存後のチェックリストは完了状態を表示する。

画像・メンション・数式・埋込みなど、今回のエディタが編集しない既存ブロックは保持表示とし、周囲の文章を編集しても保存データに残す。これらの新規挿入と添付アップロードはこの変更に含まない。ネイティブ版は従来のタイトル編集を維持し、WYSIWYG本文編集はPWAに提供する。

## 保存とデータ保持

- APIは既存の`/api/v1/.../work-items/{id}/`へのPATCHを利用する。変更した`name`と`description_html`だけを送る。未変更のSaveでは通信しない。タイトルだけを変えた場合、本文のHTMLを再保存しない。
- 本文を変えていなければ元のHTMLをそのまま保持する。本文を変えた場合も、既存の属性と対応していないブロックを復元する。Mermaid・ツリーは`pre`/`code`の言語属性、改行、日本語、エンティティを保持する。編集画面ではコードを編集し、保存後は既存の図・ツリープレビューへ戻る。
- Save中は編集・閉じる操作と二重送信を止める。入力変換中はSaveと書式操作を止め、変換後のDOMを反映してから保存する。失敗時はタイトルと本文を残してエラーを表示し、明示的な再試行を受け付ける。
- 編集を閉じるときは未保存変更があれば破棄を確認する。破棄は更新APIを呼ばない。外側のタップやシートのドラッグで下書きを消さない。
- `visualViewport`とsafe areaを使って、HTML入力でFlutterのviewInsetが通知されない場合もキーボード上へツールバーを配置する。シート表示時のアニメーションでツールバーの位置が途中に残る問題も防ぐ。

## 実装と配信

Tiptap 3.31.4 / ProseMirrorのMITライセンスの編集エンジンを、Reactやiframeを使わず同梱する。編集画面の色はFlutterのColorSchemeから渡し、日本語フォントは既存のNoto Sans JPを利用する。

`scripts/editor/`がソース、`assets/editor/`が配信用JS・CSS・依存ライセンスである。`npm run build:editor`でJSとライセンスを生成し、`npm run check:editor`でソース・lockからの生成結果と照合する。CIはエディタ試験とこの照合を行い、通常のFlutter Web成果物へ含める。mainマージ後の自動デプロイの流れは変えない。

エディタへ渡すのはタイトル・本文・識別子と保存コールバックだけで、PATやAPIクライアントを渡さない。HTMLは不活性なtemplateで読み、元の属性や未対応ブロックを実際の編集DOMへ適用しない。新しく貼り付けるHTMLは能動要素・イベント属性を除去し、リンクのスキームを検査する。外部メディアを自動取得せず、CSP・Access・API認証の変更も行わない。

## 検証

Node試験は、書式・ブロック編集、未変更HTML、タイトルのみの保存、本文の消去、失敗後の再試行、Saveの二重操作、日本語の変換中、変更破棄、Mermaid・ツリー、既存の画像・数式・メンション・表・チェックリストと貼付HTMLを確認する。Flutter試験はタイトルと本文からの導線、変更項目だけのPATCH、未変更Save、失敗時の入力保持、保存後のチェック状態を確認する。

実際のreleaseビルドと本番と同じCSPを付けたローカル確認画面で、390px幅のタイトル・本文編集、書式と見出しの追加、Save後の表示を確認した。確認データは通信・認証情報を持たないダミーである。iPhone実機のホーム画面PWAと日本語キーボードの変換・候補選択・キーボード開閉は、マージ後の実機確認事項である。

根拠: [StarterKit](https://tiptap.dev/docs/editor/extensions/functionality/starterkit)、[拡張と属性](https://tiptap.dev/docs/editor/extensions/custom-extensions/extend-existing)、[Table](https://tiptap.dev/docs/editor/extensions/nodes/table)、[TaskList](https://tiptap.dev/docs/editor/extensions/nodes/task-list)。
