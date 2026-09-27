import 'package:hive/hive.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';

/// 非機密設定（接続先URL・テーマ・前回の選択）の保存。
///
/// API token の保存先は [CredentialStore]（Keychain / Android Keystore）で、
/// このクラスは Hive に平文で残さない。公開APIは変えず、token の保管だけを
/// [CredentialStore] へ委譲する。
class LocalStorage {
  LocalStorage({required CredentialStore credentialStore})
      : _credentialStore = credentialStore;

  late Box _box;
  final CredentialStore _credentialStore;

  static const _keySelfHostedUrl = 'self_hosted_url';
  static const _keyApiToken = 'api_token';
  static const _keyWorkspaceSlug = 'workspace_slug';
  static const _keyLastWorkspaceSlug = 'last_workspace_slug';
  static const _keyLastProjectId = 'last_project_id';
  static const _keyThemeMode = 'theme_mode';

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.hiveBoxName);
    await _migrateLegacyApiToken();
  }

  /// 旧版が Hive に平文で置いていた `api_token` を [CredentialStore] へ移してから
  /// 削除する（移行）。移行後は平文が Hive に残らない。
  Future<void> _migrateLegacyApiToken() async {
    final legacy = _box.get(_keyApiToken) as String?;
    if (legacy == null || legacy.isEmpty) return;
    await _credentialStore.saveToken(legacy);
    await _box.delete(_keyApiToken);
  }

  bool get isConfigured {
    final url = selfHostedUrl;
    final token = apiToken;
    return url != null && url.isNotEmpty && token != null && token.isNotEmpty;
  }

  String? get selfHostedUrl => _box.get(_keySelfHostedUrl) as String?;

  /// 設定済みの Workspace slug（PAT では列挙できないため手入力で持つ）。
  String? get workspaceSlug => _box.get(_keyWorkspaceSlug) as String?;
  set workspaceSlug(String? value) => _box.put(_keyWorkspaceSlug, value);

  String? get apiToken => _credentialStore.apiToken;

  /// 互換のため残す同期セッター。メモリキャッシュだけを更新し、Hive にも
  /// Secure Storage にも書かない。永続化は [saveConfig] /
  /// `CredentialStore.saveToken` 経路のみを使う。
  set apiToken(String? value) {
    _credentialStore.apiToken = value;
  }

  String? get lastWorkspaceSlug => _box.get(_keyLastWorkspaceSlug) as String?;
  set lastWorkspaceSlug(String? value) =>
      _box.put(_keyLastWorkspaceSlug, value);
  String? get lastProjectId => _box.get(_keyLastProjectId) as String?;
  set lastProjectId(String? value) => _box.put(_keyLastProjectId, value);
  String get themeMode => _box.get(_keyThemeMode) as String? ?? 'system';

  set themeMode(String value) => _box.put(_keyThemeMode, value);

  /// 接続先URLと Workspace slug を Hive に、API token を [CredentialStore] に保存する。
  /// `workspaceSlug` は追加引数（未指定なら空として保存する）。
  Future<void> saveConfig({
    required String selfHostedUrl,
    String? workspaceSlug,
    required String apiToken,
  }) async {
    await _credentialStore.saveToken(apiToken);
    await _box.put(_keySelfHostedUrl, selfHostedUrl);
    await _box.put(_keyWorkspaceSlug, workspaceSlug);
  }

  /// 接続設定を消す。API token は [CredentialStore]（Keychain / Android
  /// Keystore）と Hive の両方から消す。
  Future<void> clearConfig() async {
    await _credentialStore.clearToken();
    await _box.deleteAll([
      _keySelfHostedUrl,
      _keyApiToken,
      _keyWorkspaceSlug,
      _keyLastWorkspaceSlug,
      _keyLastProjectId,
    ]);
  }
}
