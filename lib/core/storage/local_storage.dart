import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';
import 'web_commit_stub.dart' if (dart.library.js_interop) 'web_commit.dart';

/// 非機密設定（接続先URL・テーマ・前回の選択）の保存。
///
/// API token の保存先は [CredentialStore]（native secure store / WebCrypto）で、
/// このクラスは Hive に平文で残さない。公開APIは変えず、token の保管だけを
/// [CredentialStore] へ委譲する。
class LocalStorage {
  LocalStorage(
      {required CredentialStore credentialStore,
      bool? isWeb,
      Box? box,
      Future<void> Function(Map<String, Object?>)? commitVerifier})
      : _credentialStore = credentialStore,
        _commitVerifier = commitVerifier ?? verifyWebCommit,
        _box = box,
        isWeb = isWeb ?? kIsWeb;

  Box? _box;
  final CredentialStore _credentialStore;
  final bool isWeb;
  final Future<void> Function(Map<String, Object?>) _commitVerifier;
  bool _saveFailed = false;
  String? get recoveryMessage => isWeb &&
          (_box == null || _credentialStore.restoreFailed || _saveFailed)
      ? 'Browser storage could not be restored or saved. Re-enter your settings. '
          'If saving fails, allow website storage and try again.'
      : null;

  static const _keySelfHostedUrl = 'self_hosted_url';
  static const _keyApiToken = 'api_token';
  static const _keyWorkspaceSlug = 'workspace_slug';
  static const _keyLastWorkspaceSlug = 'last_workspace_slug';
  static const _keyLastProjectId = 'last_project_id';
  static const _keyThemeMode = 'theme_mode';
  static const _keyConfigPending = 'config_save_pending';

  Future<void> init() async {
    try {
      _box ??= await Hive.openBox(
        isWeb ? AppConstants.webHiveBoxName : AppConstants.hiveBoxName,
      );
      if (isWeb) {
        // Web never imports credentials from the native/legacy box.
        await _box!.delete(_keyApiToken);
        _saveFailed = _box!.get(_keyConfigPending) == true;
        if (_saveFailed) {
          // An incomplete save must never restore a credential into API use.
          try {
            await _credentialStore.clearToken();
          } catch (_) {
            _credentialStore.apiToken = null;
          }
        }
      } else {
        await _migrateLegacyApiToken();
      }
    } catch (_) {
      if (!isWeb) rethrow;
      _box = null;
    }
  }

  /// 旧版が Hive に平文で置いていた `api_token` を [CredentialStore] へ移してから
  /// 削除する（移行）。移行後は平文が Hive に残らない。
  Future<void> _migrateLegacyApiToken() async {
    final legacy = _box!.get(_keyApiToken) as String?;
    if (legacy == null || legacy.isEmpty) return;
    await _credentialStore.saveToken(legacy);
    await _box!.delete(_keyApiToken);
  }

  bool get isConfigured {
    if (recoveryMessage != null) return false;
    final url = selfHostedUrl;
    final token = apiToken;
    return url != null && url.isNotEmpty && token != null && token.isNotEmpty;
  }

  String? get selfHostedUrl => _box?.get(_keySelfHostedUrl) as String?;

  /// 設定済みの Workspace slug（PAT では列挙できないため手入力で持つ）。
  String? get workspaceSlug => _box?.get(_keyWorkspaceSlug) as String?;
  set workspaceSlug(String? value) => _box?.put(_keyWorkspaceSlug, value);

  String? get apiToken => _credentialStore.apiToken;

  /// 互換のため残す同期セッター。メモリキャッシュだけを更新し、Hive にも
  /// Secure Storage にも書かない。永続化は [saveConfig] /
  /// `CredentialStore.saveToken` 経路のみを使う。
  set apiToken(String? value) {
    _credentialStore.apiToken = value;
  }

  String? get lastWorkspaceSlug => _box?.get(_keyLastWorkspaceSlug) as String?;
  set lastWorkspaceSlug(String? value) =>
      _box?.put(_keyLastWorkspaceSlug, value);
  String? get lastProjectId => _box?.get(_keyLastProjectId) as String?;
  set lastProjectId(String? value) => _box?.put(_keyLastProjectId, value);
  String get themeMode => _box?.get(_keyThemeMode) as String? ?? 'system';

  set themeMode(String value) => _box?.put(_keyThemeMode, value);

  /// 接続先URLと Workspace slug を Hive に、API token を [CredentialStore] に保存する。
  /// `workspaceSlug` は追加引数（未指定なら空として保存する）。
  Future<void> saveConfig({
    required String selfHostedUrl,
    String? workspaceSlug,
    required String apiToken,
  }) async {
    var tokenSaved = false;
    try {
      if (_box == null) await init();
      final box = _box;
      if (box == null) throw StateError('Browser settings storage unavailable');
      // Persist the incomplete state before touching the credential. If the
      // final Hive transaction fails, startup must not use mixed settings.
      if (isWeb) {
        await box.put(_keyConfigPending, true);
        await _commitVerifier({_keyConfigPending: true});
      }
      if (isWeb) {
        await _credentialStore.stageToken(apiToken);
      } else {
        await _credentialStore.saveToken(apiToken);
      }
      tokenSaved = true;
      await box.putAll({
        _keySelfHostedUrl: selfHostedUrl,
        _keyWorkspaceSlug: workspaceSlug,
        if (isWeb) _keyConfigPending: false,
      });
      if (isWeb) {
        await _commitVerifier({
          _keySelfHostedUrl: selfHostedUrl,
          _keyWorkspaceSlug: workspaceSlug,
          _keyConfigPending: false,
        });
        await _credentialStore.activateToken();
      }
      _saveFailed = false;
    } catch (_) {
      _saveFailed = true;
      if (isWeb) {
        _credentialStore.apiToken = null;
        if (tokenSaved) {
          try {
            await _credentialStore.clearToken();
          } catch (_) {
            // Failure remains visible and startup with a pending marker also
            // invalidates the credential. Do not use or log the stored value.
          }
        }
      }
      rethrow;
    }
  }

  /// 接続設定を消す。API token は [CredentialStore]（Keychain / Android
  /// Keystore）と Hive の両方から消す。
  Future<void> clearConfig() async {
    try {
      await _credentialStore.clearToken();
    } finally {
      await _box?.deleteAll([
        _keySelfHostedUrl,
        _keyApiToken,
        _keyWorkspaceSlug,
        _keyLastWorkspaceSlug,
        _keyLastProjectId,
        _keyConfigPending,
      ]);
      if (isWeb && _box != null) {
        await _commitVerifier({
          _keySelfHostedUrl: null,
          _keyWorkspaceSlug: null,
          _keyConfigPending: null,
          _keyLastWorkspaceSlug: null,
          _keyLastProjectId: null,
          _keyApiToken: null,
        });
      }
      _saveFailed = false;
    }
  }
}
