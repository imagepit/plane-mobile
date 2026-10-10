# Plane Mobile

セルフホスト版Planeの作業項目（issue・チケット）を、外出先から操作するためのFlutterアプリです。

## 主な機能

- 接続先URLとAPIトークンを指定してセルフホスト版Planeへ接続
- ワークスペースとプロジェクトの閲覧
- 作業項目の閲覧・作成・編集
- 状態と優先度による絞り込み、取得済み項目の検索
- ホーム・作業項目・検索の下部ナビゲーション
- 属性チップによる直接編集と下部固定のコメント入力
- コメントの追加・閲覧
- ダークテーマ・ライトテーマの切り替え
- 一覧を下に引いて更新

画面と失敗時の操作、ダミー画像による改修前後の比較は[モバイルUI仕様](docs/mobile-ui.md)、Flutterのデザイン責務は[DESIGN.md](DESIGN.md)を参照してください。検索は選択中プロジェクトの取得済み範囲です。追加ページがある場合は取得済み件数とLoad moreを表示します。通信失敗でも本文と下書きを保ち、作成・コメントの結果が不明なら履歴を確認するまで再送を止めます。

## アーキテクチャ

クリーンアーキテクチャを採用し、BLoCで状態を管理します。

```text
lib/
  app.dart                  # テーマ・BlocProviderを組み込んだMaterialApp.router
  main.dart                 # 起動処理（Hiveの初期化・DI）
  core/
    constants/              # アプリの定数
    di/                     # GetItによる依存性の注入
    errors/                 # 独自の例外・失敗型
    network/                # Dioクライアント・インターセプター
    router/                 # 認証ガードを含むGoRouterの設定
    storage/                # 設定・認証情報の保存
    theme/                  # Material 3のテーマ（ライト・ダーク）
    utils/                  # 日付の書式設定など
  data/
    datasources/            # APIとの通信
    models/                 # fromJson/toJsonを持つデータモデル
    repositories/           # リポジトリの実装
  domain/
    entities/               # ドメインのエンティティ
    repositories/           # リポジトリのインターフェース
    usecases/               # ユースケース
  presentation/
    blocs/                  # BLoC（イベント・状態・処理）
    pages/                  # 各画面
    widgets/                # 再利用するUI部品
```

## 技術構成

| 用途 | ライブラリ |
|------|------------|
| 状態管理 | flutter_bloc |
| HTTP通信 | Dio |
| 保存 | Hive + Hive Flutter |
| 画面遷移 | go_router |
| 依存性の注入 | get_it |
| 関数型の処理 | dartz（Either） |

## 開発に必要な環境

- Flutter 3.x（Dart >= 3.3.0）
- Android SDK（API 21以上）/ Xcode（iOS 12以上）
- APIを利用できるセルフホスト版Plane

## セットアップ

```bash
# リポジトリを取得
git clone <repo-url> && cd plane-mobile

# 依存パッケージを取得
flutter pub get

# freezed/json_serializableを使う場合のコード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

## 起動

```bash
# 接続した端末・エミュレーターで起動
flutter run

# flavorを設定している場合の起動
flutter run --flavor dev
```

## ビルド

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 接続設定

初回起動時の設定画面で、次の情報を入力します。Web版の接続先は現在のHTTPS originに固定されます。詳しくは「iPhone向けWebアプリ」を参照してください。

1. **Server URL（接続先URL）**: セルフホスト版PlaneのURL。例: `https://plane.example.com`。ネイティブ版では、`http://<host>:8080`のような内部APIの接続先も指定できます。
2. **Workspace Slug（ワークスペースのslug）**: 開くワークスペースの識別名。個人アクセストークンで利用できるワークスペース一覧APIがないため、明示的に入力します。
3. **API Token（APIトークン）**: Planeで発行した個人APIトークン。

URLとslugは端末・ブラウザーに保存し、トークンは専用の保存先へ置きます。詳しくは「認証情報の保存」を参照してください。APIリクエストには`X-Api-Key: {token}`を付けます。REST APIのパスは`/api/v1/`です。旧形式の`/api/`ではAPIトークン認証を利用できません。

設定を変更するには、ワークスペース一覧画面の設定アイコンをタップします。

## 本文のプレビュー

作業項目の説明とコメントはHTMLで表示します。さらに、redmine-nextの表示に合わせて次のコードブロックをプレビューします。

- `language-file-tree`: IMAGEPITのFileTreeをアプリのUIで表示します。`++`は追加、`**`は修正、`--`は削除、` <--[...]`は注釈を表します。枝の接続記号を含む書式は、`design-system`のツリー表記に従います。
- `language-mermaid`: ネイティブ版では、同梱の`assets/mermaid/mermaid.min.js`を使ってWebViewで図を表示します。redmine-nextと同じmermaid 11.16.0で、MITライセンスです。外部URLは読み込みません。描画できない場合はソースを表示します。Web版ではWebViewを使わず、常にソースを表示します。

これらの言語指定がないコードブロックは、通常のコードとして表示します。

## スモークテスト

`integration_test/smoke_test.dart`は、実際のPlane CEに接続して次の操作を確認します。

設定入力 → 接続テスト → ワークスペース・プロジェクト・作業項目の一覧表示 → 作業項目作成 → コメント追加 → 削除

1. Gitの管理対象外となるローカルの`smoke.local.json`に、次のキーと値を設定します。`SMOKE_API_TOKEN`には個人アクセストークンを入れます。このファイルにはトークンが含まれるため、コミットや貼り付けをしないでください。必要なキーは`SMOKE_BASE_URL`、`SMOKE_API_TOKEN`、`SMOKE_WORKSPACE_SLUG`、`SMOKE_PROJECT_ID`、`SMOKE_PROJECT_NAME`です。
2. テスト専用プロジェクトを使います。作成する作業項目には`smoke-`で始まるタイトルを付けるため、残った項目を識別できます。
3. 次のコマンドを実行します。

```bash
flutter test integration_test/smoke_test.dart \
  --dart-define-from-file=smoke.local.json -d <device-id>
```

トークンを`--dart-define=`で指定したコマンド全体をログへ貼り付けないでください。トークンはGitの管理対象外のファイルにだけ置きます。ログには作成した作業項目のIDとHTTPステータスを出し、トークンの値を含めないようにします。

## 認証情報の保存

### iPhone向けWebアプリ

Web版の配信先は`https://plane.itpit.net/mobile/`です。Safariで開き、Webサイトへのサインインを求められたら認証します。その後、共有メニューの「ホーム画面に追加」を選びます。ホーム画面の「Plane Mobile」から起動でき、XcodeやApple Developer Programへの加入は不要です。

Web版の設定画面では、接続先が現在のHTTPS origin（スキーム・ホスト・ポート）に固定されます。ワークスペースのslugと個人APIトークンを入力してください。APIには同じoriginの`/api/v1/`から接続し、`/mobile/api/v1/`は使いません。保存済みのURLで接続先を変更することもできません。ネイティブ版では接続先URLを指定できます。

Web版のAPI通信にはFetchのsame-originモードを使い、トークンを転送する前にリダイレクトを拒否します。そのため、サインイン画面へのリダイレクトは、応答を読めない通信失敗として表示されます。Safariで`/mobile/`を開き直してサインインしてください。

Web版の日本語表示には、アプリに同梱したNoto Sans JPを使います。ライト・ダークの両テーマで、プロジェクト名、本文、入力欄、コード内の日本語にも適用します。フォントは`/mobile/`配下から配信し、外部のフォント配信サービスへ接続する必要はありません。初回の取得量は約9.6 MB増えます。ネイティブ版のフォント設定は従来どおりです。

フォントの取得元は[Google FontsのNoto Sans JP](https://github.com/google/fonts/tree/295d98a7a0c17c68f1341eaeea354e7960ea70d3/ofl/notosansjp)です。可変フォントを変更せず同梱し、SIL Open Font License 1.1を`assets/fonts/OFL.txt`へ保存しています。

Web版では、`flutter_secure_storage` 9.2.4の実験的なWebCrypto実装でトークンを暗号化し、ブラウザーに保存します。認証情報の名前空間は`plane_mobile_pwa_credentials_v1`です。非機密設定は別のHive boxである`plane_mobile_pwa_settings_v1`へ保存します。同じoriginで動くJavaScriptは鍵とトークンへアクセスできるため、iOS Keychainと同等の保護にはなりません。HTTPSが必要です。ブラウザーのデータ削除や保存制限によって、設定の再入力が必要になる場合があります。

設定を保存するときは、IndexedDBへの書込みが確定したことと、保存した値が一致することを確認してから成功を表示します。保存が途中で失敗した場合はAPIを利用できない状態にし、削除可能なら新たに保存したトークンを消します。再読込み時にも未完了の保存を検出します。

Webのトークンは設定保存の確認が終わるまで有効にしません。トークン候補を書き込む前に、暗号化した有効化マーカーを`pending`にします。設定の保存を確認できた後だけ`ready`へ切り替えます。設定確認とトークン候補の削除が両方失敗しても、再読込み後にその候補を有効にしません。トークンはHive、URL、ビルド時のdefine、アプリのログへ入れません。

「Clear saved settings（保存済み設定を消去）」を使うと、保存済みトークンと接続設定を削除できます。保存データを復元できない場合も、設定画面を開いて再入力できます。保存や削除が失敗した場合はエラーを表示します。Webサイトのデータ保存を許可して再試行するか、SafariでこのWebサイトのデータを消去してください。同じoriginのデータを消去すると、デスクトップ版Planeのセッションも失われます。

Webサイトへのサインイン（Cloudflare Access）と個人APIトークンは別の認証です。サインイン用のHTML応答を受けた場合は、Webサイトへのサインインを案内します。JSONの401はトークンの無効・失効、JSONの403はAPIへのアクセス拒否を表します。応答を読めない通信失敗も再認証が原因の場合がありますが、原因を断定しません。Safariで`/mobile/`を開き直してサインインし、再試行してください。書込みは自動で再試行しないため、先に作業項目やコメントが保存されたか確認してください。

Web版の本文では、テキスト・表・コード・FileTreeを表示します。MermaidはWebViewを使わずソースを表示します。スクリプト、フレーム、イベント属性、危険なリンク形式、自動で読み込む外部メディアは本文のHTMLから除去します。ネイティブ版のMermaid表示は維持します。ホーム画面のアイコンには、既存の設定画面で使っているMaterialの`flight_takeoff`とプライマリーの青色を使います。maskableアイコンは安全領域に図柄を収めます。

JavaScriptのrelease版を、`/mobile/`配下に配置する前提でビルドします。

```bash
flutter build web --release --base-href /mobile/ --no-web-resources-cdn
```

Service Worker、オフライン編集、バックグラウンド同期、Push通知はありません。releaseの配信・更新・ロールバックは[CORE-55（Cloudflare配信）](https://plane.itpit.net/imagepit/browse/CORE-55/)、iPhoneの受入れは[CORE-56（実機受入れ）](https://plane.itpit.net/imagepit/browse/CORE-56/)で扱います。ローカルのブラウザー試験だけでは、iPhoneのホーム画面起動・safe areaの表示・8日以上後の受入れを確認したことにはなりません。

Web版の検証コマンドです。

```bash
flutter analyze --no-fatal-infos
flutter test
flutter test --platform chrome
```

試験にはダミーの認証情報と、ネイティブの安全な保存先を模したモックを使います。ブラウザーの保存処理は、製品と同じ保存クラスを使うrelease版の検証用アプリでも確認します。端末のKeychainや本番トークンは読みません。

### ネイティブアプリ

APIトークンは、`flutter_secure_storage`を通じてiOS Keychain / Android Keystoreへ保存します。Hiveや他の平文の保存先へは書き込みません。

- Hiveへトークンを保存していた旧版からの更新後、初回起動で`api_token`を安全な保存先へ移し、Hive boxから削除します。
- 永続化は、完了をawaitできる`LocalStorage.saveConfig()` / `CredentialStore.saveToken()`を通じて行います。互換性のため同期セッターの`set apiToken`を残していますが、メモリー上のキャッシュだけを更新し、永続化しません。設定画面では`saveConfig()`だけを使います。
- `LocalStorage.clearConfig()`はHiveの設定と安全な保存先のトークンを消去します。設定をリセットすると、端末にトークンは残りません。

## 各層の役割

- **データ層**: DioでPlane APIを呼び出します。モデルはJSONとドメインのエンティティを変換します。リポジトリの実装はDioExceptionをFailureへ変換し、dartzのEitherで結果を返します。
- **ドメイン層**: エンティティは通常のDartクラスです。リポジトリのインターフェースで契約を定義し、ユースケースに各業務処理をまとめます。
- **表示層**: BLoCで状態遷移を管理します。画面にはBlocProviderを配置し、再利用するUI部品をウィジェットとして実装します。

## 使用するAPI

すべてのパスは`{BASE_API}/api/v1/`配下にあり、`X-Api-Key`で認証します。プロジェクトのメンバー一覧は配列を直接返します。それ以外の一覧は、`results` / `next_cursor` / `next_page_results`を持つカーソル形式でページを分割します。

| 対象 | メソッド | パス |
|------|----------|------|
| ワークスペース | — | トークンで取得できる一覧APIがないため、設定したslugを使う |
| プロジェクト | GET | `/api/v1/workspaces/{slug}/projects/` |
| 作業項目 | GET | `/api/v1/workspaces/{slug}/projects/{id}/work-items/?expand=state,assignees,labels` |
| 作業項目 | POST | `/api/v1/workspaces/{slug}/projects/{id}/work-items/` |
| 作業項目 | PATCH | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/` |
| 作業項目 | DELETE | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/` |
| 状態 | GET | `/api/v1/workspaces/{slug}/projects/{id}/states/` |
| ラベル | GET | `/api/v1/workspaces/{slug}/projects/{id}/labels/` |
| メンバー | GET | `/api/v1/workspaces/{slug}/projects/{id}/members/` |
| コメント | GET | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/comments/` |
| コメント | POST | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/comments/` |
| ユーザー | GET | `/api/v1/users/me/`（接続テストで使用） |

## テスト

```bash
flutter test
```

## CloudflareへのWeb配信

配信先は`https://plane.itpit.net/mobile/`です。Workers Static Assetsの配信元を`build/pwa`とし、アプリをその中の`mobile/`へ配置します。RouteはHTTPSの`/mobile/*`だけです。末尾スラッシュのない`/mobile`はRouteの対象外なので、利用者には必ず`/mobile/`を案内してください。既存のデスクトップ画面、`/api/v1/`、Runnerの接続経路は変更しません。workers.devとpreview URLは無効です。

### ローカルで配信を確認する

Flutter **3.47.5**、Node **22.22.2**、Python 3を使います。Wrangler **4.147.0**をnpmのlockで固定しています。

```bash
npm ci --ignore-scripts --no-audit --no-fund
flutter pub get --enforce-lockfile
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
flutter test --no-pub --platform chrome
flutter build web --release --base-href /mobile/ --no-web-resources-cdn --no-pub
npm run test:package
npm run package:web
npm run check:deploy
npm run dev:web -- --port 8890
```

`http://127.0.0.1:8890/mobile/`で表示を確認します。本番で必要なHTTPS認証・保存の受入れは、ローカルHTTPの確認とは別に行ってください。`check:deploy`はdry-runで、本番へは配備しません。

`web/_headers`のパスはリクエストURL基準です。配信元の直下へコピーし、`/mobile/*`だけにCSP、nosniff、Referrer-Policy、`private, max-age=0, must-revalidate`を付けます。CSPでは同梱のCanvasKitに必要なWebAssembly、FlutterのインラインCSS、描画用のblob workerを許可します。同じoriginのAPIへ接続し、別originへの通信許可やService Workerの登録は追加しません。ホスト全体のHSTSは既存設定を維持します。

配備用スクリプトはbase・manifest・参照ファイル・ヘッダーを検査し、未使用の`flutter_service_worker.js`とFlutterの`.last_build_id`を除外します。独自bootstrapにはService Worker登録がありません。ローカル設定、symlink、想定外のパス、25 MiBを超えるファイル、20,000件を超える成果物は拒否します。`_release.json`にsource SHAと全配備ファイルのSHA-256を保存します。ビルド時のdefineへPATやスモーク設定を渡さないでください。ファイル名の検査だけで、任意のファイルに埋め込まれた秘密を検出できるわけではありません。

### 配備前の準備と記録

運用担当はGitHub Environment **`plane-mobile-production`**を作り、配備を承認するreviewerとmain限定のdeployment branchを設定してください。利用しているGitHubプランでEnvironmentの保護を設定できることも確認します。設定できない場合は配備を止め、承認方法を決めてから進めてください。

このEnvironmentだけにsecret **`CLOUDFLARE_API_TOKEN`**とvariable **`CLOUDFLARE_ACCOUNT_ID`**を登録します。tokenの権限は対象アカウントのWorkers Scripts編集、`itpit.net`のWorkers Routes編集・Zone読取りに限定します。値は運用担当が登録し、コード・チャット・ログへ貼りません。PR用のWeb checksにはEnvironmentも配備secretも渡しません。

本番配備前に、次の結果と日時を[CORE-53（PWA親項目）](https://plane.itpit.net/imagepit/browse/CORE-53/)のコメントへ残します。

1. `plane.itpit.net`のDNSがproxiedで、既存Tunnelへの向き先を維持している。
2. Accessの許可policyと対象host/pathを確認し、`/mobile/`と`/api/v1/`が本人限定の保護範囲に含まれる。より具体的なpathのBypass、別policy、サービス認証の例外も確認する。
3. 現在の経路で未認証・本人以外による`/mobile/`と`/api/v1/`の取得が拒否される。実際の別本人の認証を試せない場合は未確認とし、成功扱いにしない。
4. 既存Workers Routeとの競合がなく、最小権限と成果物の容量上限を満たす。
5. mainへmergeされ、そのSHAのWeb checksが成功している。Environmentの承認と配備認証の登録が済んでいる。

記録が揃うまで本番Routeの追加・配備を実行しません。Route追加前の拒否確認は、追加後の静的ファイル保護を証明するものではありません。配備直後にもHTML・JS・manifest・アイコンとAPIについて未認証・本人以外の取得拒否を確認します。取得できてしまう場合は新規Routeを外して既存経路へ戻し、配信成功にせず親コメントへ記録します。初回配備には過去のWorker versionがないため、この退避手順を使います。Accessを緩めて復旧しないでください。

Access設定を追加・変更する前に、既存のpublic APIクライアントを確認してください。本人用のブラウザー認証とAPIクライアントの認証を混同せず、影響を確認できるまで変更を止めます。既存RunnerはTailscale内のprivate gatewayからNodePortへ接続する経路を維持します。通常のRoute管理はWranglerに任せます。緊急退避でRouteを外した後は配備を停止し、原因の修復と配備前確認・人の承認が揃った場合だけ再配備してください。

### 検査済み成果物の手動配備・更新

`Web checks`はPRとmainのpushで検査し、成功時だけ`pwa-<40桁SHA>`を保存します。artifactの保持期間は90日です。PRの成果物は配備に使いません。

GitHub Actionsの**Deploy Web manually**をmainから実行し、次を入力します。

- `sha`: 配備したい、Web checks成功済みのmainの40桁SHA
- `preflight_record`: CORE-53に保存した配備前確認コメントのURL
- `preflight_confirmed`: 上記の確認がすべて済んだ場合だけtrue

確認欄とURLは運用担当による申告です。workflowはPlaneコメント本文を自動で検証しません。Environmentの承認者は記録を読んでから承認してください。

workflowは指定SHAをcheckoutし、main履歴への所属と、そのSHAのmain push検査成功を確認します。そのrunのartifact ID・名前・SHA・archive digestを照合し、展開後も`_release.json`と全ファイルのhashを検査します。一つでも一致しない、成果物が期限切れ、欠落している場合は配備を止めます。対象SHAの配備設定とnpm lockを使用し、再ビルドはしません。配備secretを使うのは最後のWrangler配備ステップだけです。

更新は新しい検査済みmain SHAで同じ操作を行います。開いたままの画面は現在のコードで動くため、作業内容を保存してからSafariで再読み込みしてください。配備前後のSHA、Web checks run、artifact IDとdigest、Cloudflare version ID、HTTPヘッダー、画面、既存デスクトップ/API/Runnerの結果をCORE-55へ記録します。

配備直後に本番のCSP・nosniff・Referrer-Policy・cacheの実応答を照合し、未適用なら配信成功にせず退避・rollbackしてください。配備workflowは一つずつ実行し、実行中の配備は新しい依頼で取り消しません。

### ロールバック

通常は、保存期間内の以前の検査済みmain SHAを**Deploy Web manually**へ指定し、同じ成果物を再配備します。以前の`wrangler.jsonc`も使用するので、Route・配備設定の差分を先に確認してください。期限切れや削除済みのartifactは再ビルドして代用しません。

緊急時は、配備記録でSHAと対応を確認したCloudflare version IDを使い、運用担当が以下を実行します。現在版と戻し先を必ず明示し、直前版へ暗黙に戻す運用は避けてください。

```bash
npm run versions:web
npm run rollback:web -- <確認したversion-id> --message 'CORE-55 rollback'
```

Cloudflare側で保持されているversionだけが対象です。rollbackは現在のRouteや外部のAccess設定を復元しません。認証の問題なら新規Routeを外す退避が必要です。戻した後も再読み込み、SHA・画面・Access拒否・既存経路を確認し、更新とrollbackの結果をCORE-55へ残します。iPhoneのホーム画面起動と長期保存の受入れはCORE-56で行います。

仕様の根拠: [サブディレクトリ配信](https://developers.cloudflare.com/workers/static-assets/routing/advanced/serving-a-subdirectory/)、[配信ヘッダー](https://developers.cloudflare.com/workers/static-assets/headers/)、[AccessとWorkers](https://developers.cloudflare.com/workers/configuration/cloudflare-access/)、[rollback](https://developers.cloudflare.com/workers/versions-and-deployments/rollbacks/)、[Static Assetsの容量上限](https://developers.cloudflare.com/workers/platform/limits/#static-assets)。

## ライセンス

MIT
