# モバイルUIと受入れ

[CORE-65](https://plane.itpit.net/imagepit/browse/CORE-65/)（Plane MobileのUI改修）の実装仕様。現行Flutterアプリを継続し、PWAの配信先は`https://plane.itpit.net/mobile/`のままとする。計画はPlaneに保存したMobile-UI-v2.2を正本とする。

## 画面と操作

Homeで設定済みワークスペースからプロジェクトを選ぶ。Work itemsとSearchは最後に選んだプロジェクトを開く。未選択時はHomeへ案内する。Homeから設定へ到達できる。

一覧は状態・件名・`project.identifier`と番号・優先度・担当者を行内に置く。直接詳細URLを開いた場合もGetProjectで識別子を取得する。識別子未取得時は`#番号`を表示し、推測しない。FiltersのApply/Cancel/Resetにより状態・優先度を絞り込む。タブ切替や詳細から戻る操作では、一覧の位置、条件、検索語、取得ページをプロジェクトごとのメモリーへ保持する。ページ再読み込み・設定変更ではこの一時保存が終わる。

Searchは現在プロジェクトの取得済み項目の件名・識別子を検索する。取得済み件数と未取得ページの有無を表示する。全ワークスペースの検索とは表示しない。Load moreで取得した後も同じ検索条件を適用する。一覧が空でも引いて更新できる。更新や追加取得に失敗した場合は取得済み内容を保ち、Retryは失敗した先頭/次ページを再取得する。

詳細の属性チップから状態、優先度、担当者、ラベル、開始日、期限を変更する。候補シートは検索・Save・Cancelを持つ。日付は設定・クリア・取消を区別する。確定した属性だけをPATCHし、担当者とラベルはv1 APIの`assignees`/`labels`へUUID配列を送る。状態・ラベル候補は全ページを取得し、途中失敗を空の候補や全件成功として表示しない。API契約は[公式v1仕様](https://developers.plane.so/api-reference/issue/add-issue)を参照する。

属性保存中も本文・コメントを残す。403では旧値を保ち、選んだ変更をRetry saveまたはCancel pending changeで扱う。PATCH応答の展開が不足すれば詳細GETで補完する。その確認GETに失敗した場合はSaved; reload to confirmを表示し、Reloadで確認した詳細を一覧にも反映する。件名はその他メニューのEdit titleから明示保存・取消でき、コメントの再取得で編集途中の文字を上書きしない。削除は同じメニューにあり、確認の取消では要求を送らない。

新規作成は一覧・検索の丸い＋から開く。タイトル、本文、属性を入力し、失敗時は入力を保つ。作成POSTの結果が不明なら再送を止め、全ページを再取得した一覧で保存有無を人が確認する。Already createdなら一覧へ戻り、Not createdなら手動再試行できる。この確認まで入力と再送防止をプロジェクトの状態に保持する。

## コメントと失敗時の動作

本文とコメントは従来のRichHtml、FileTreeを使う。WebのMermaidはソースを表示し、nativeの表示方式を維持する。活動履歴タイムラインを模したダミーの操作は追加しない。

入力欄は下部に固定する。送信開始時の対象ID、本文、入力revisionを固定し、成功したときに同じID/revisionの場合だけ消去する。投稿中の追記・編集、別項目への移動、失敗では現在の全文を保つ。送信中の連打と同じ項目の並行書込みを防ぎ、書込みを自動再送しない。

応答が不明な場合はReload and check commentsから全ページを読み直す。人がAlready posted/Not postedを選ぶまで投稿を止める。確認結果は送信時に固定した本文へ結び付ける。投稿済みの同じ下書きは再投稿を止め、別の本文へ編集したときだけ新規投稿できる。項目ごとの下書き・送信時の本文・確認済み本文はプロジェクトのメモリーへ保持する。ブラウザー再読み込みを越える下書き保存やオフライン再送は提供しない。

コメントのLoad moreはcursorをクエリ値として渡し、応答をIDで重複排除する。途中失敗や繰り返すcursorでは既存内容を保つ。別項目の詳細へ移ると前の項目のコメントを消してから対象の履歴を読み、取り違えを防ぐ。

## 比較資料

基点は`3118d111e984829e861c2adf267f36522e8ce686`。UIを変更する前に最小fixtureだけを追加した`4040bd2`でbeforeを撮影した。同じ日本語2項目、識別子、担当者、コメントをafterの基本データとして使用する。参考原画像は[一覧](ui-references/official-list.jpg)と[詳細](ui-references/official-detail.png)へ変更せずコピーした。画像内の文字は参考データとして扱う。

論理390×844、430×932、横844×390、ライト、文字倍率1.0を比較する。参考端末の機種・倍率は未確認のため、内容幅の比例換算による概算比較とする。固定ピクセルの一致を合格条件にしない。

| 画面・条件 | Before | After |
|---|---|---|
| 一覧390 | [画像](ui-evidence/before-list-390.jpg) | [画像](ui-evidence/after-list-390.jpg) |
| 詳細390 | [画像](ui-evidence/before-detail-390.jpg) | [画像](ui-evidence/after-detail-390.jpg) |
| Filters390 | [画像](ui-evidence/before-filter-390.jpg) | [画像](ui-evidence/after-filter-390.jpg) |
| 作成390 | [画像](ui-evidence/before-create-390.jpg) | [画像](ui-evidence/after-create-390.jpg) |
| 一覧430 | [画像](ui-evidence/before-list-430.jpg) | [画像](ui-evidence/after-list-430.jpg) |
| 詳細430 | [画像](ui-evidence/before-detail-430.jpg) | [画像](ui-evidence/after-detail-430.jpg) |
| 詳細横向き | [画像](ui-evidence/before-detail-landscape.jpg) | [画像](ui-evidence/after-detail-landscape.jpg) |

追加確認は[コメント投稿](ui-evidence/after-comment-390.jpg)、[ダーク](ui-evidence/after-detail-dark-390.jpg)、[文字1.5倍](ui-evidence/after-detail-scale-390.jpg)、[長い日本語・本文・FileTree・多数担当者](ui-evidence/after-detail-complex-390.jpg)へ保存する。これらはPAT・実データ・保存処理を持たないfixtureのブラウザー撮影である。

## 再現方法と検証

```bash
flutter build web --release --target test/fixtures/mobile_ui_preview.dart --no-web-resources-cdn --no-pub
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

`http://127.0.0.1:8765/`で基本データを表示する。fixture専用の`?theme=dark`、`?scale=1.5`、`?complex=1`で追加条件を表示できる。本番entry pointは`lib/main.dart`であり、fixtureへ接続設定やPATを渡さない。本番ビルド・package・配信検査は[README](../README.md)の既存手順に従う。

自動試験はモデルの識別子、cursorの安全なクエリ処理、候補全ページ、途中失敗、更新中の表示保持、書込み連打、コメントのrevision・HTML変換・対象変更、作成結果不明、詳細から戻る位置、検索条件、属性の取消/403、日付クリア、件名下書き、キーボードを対象にする。既存保存・origin制約・HTML無害化のテストも実行する。native smokeは新ナビのKeyへ合わせ、作成行までスクロールしてコメント・削除へ進む。

## 良輔による実機受入れ

ローカルの画面確認とCI成功は実機受入れを代替しない。良輔のmain mergeと既存Environment承認後、[CORE-55](https://plane.itpit.net/imagepit/browse/CORE-55/)（PWA配信）の既存手順で検査済みSHAを手動配備する。

[CORE-56](https://plane.itpit.net/imagepit/browse/CORE-56/)（iPhone実機と継続起動の受入れ）で、Safariとホーム画面起動の一覧→詳細→属性変更→コメント→一覧、新規作成、縦横、日本語キーボード、Wi-Fi/携帯回線を確認する。機種・iOS・日時・SHA・証拠を残し、初回起動から192時間以上の観測を続ける。nativeの本番認証を使ったスモーク、iPhone safe areaとIMEの最終確認は人の実機検証で行う。

全ワークスペースのYour work、通知Inbox、AI、Cycle/Module編集、Push、Service Worker、オフライン編集は今回の対象外。
