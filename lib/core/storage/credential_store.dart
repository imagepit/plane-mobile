import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';

/// API token の保存先。
///
/// native は Keychain / Keystore、Web は専用 WebCrypto 保存へ置き、
/// Hive には残さない。永続化は await 可能な [saveToken] /
/// [clearToken] 経路だけとし、同期の `set apiToken` はメモリキャッシュ更新のみ
/// にとどめる。
class CredentialStore {
  CredentialStore({FlutterSecureStorage? storage, bool? isWeb})
      : isWeb = isWeb ?? kIsWeb,
        _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: AppConstants.webCredentialNamespace,
                publicKey: AppConstants.webCredentialNamespace,
              ),
            );

  final bool isWeb;
  bool restoreFailed = false;
  String get tokenKey => isWeb ? AppConstants.webApiTokenKey : apiTokenKey;

  /// Secure Storage 内のキー名。
  static const String apiTokenKey = 'api_token';

  final FlutterSecureStorage _storage;
  String? _apiToken;
  String? _pendingToken;

  /// Secure Storage からメモリキャッシュへ読み込む。
  ///
  /// `LocalStorage.init()` より先に完了させること（保存直後の `isConfigured`
  /// 判定がキャッシュを読むため）。
  Future<void> init() async {
    try {
      if (isWeb) {
        final activation =
            await _storage.read(key: AppConstants.webTokenActivationKey);
        if (activation != 'ready') {
          _apiToken = null;
          restoreFailed = activation == 'pending';
          return;
        }
      }
      _apiToken = await _storage.read(key: tokenKey);
    } catch (_) {
      if (!isWeb) rethrow;
      // A denied store or lost WebCrypto key must not prevent opening settings.
      _apiToken = null;
      restoreFailed = true;
    }
  }

  /// メモリキャッシュ上のトークン。
  String? get apiToken => _apiToken;

  /// 互換のため残す同期セッター。メモリキャッシュだけを更新し、
  /// Secure Storage へは書かない（永続化しない）。
  set apiToken(String? value) {
    _apiToken = value;
  }

  /// トークンを Secure Storage へ保存し、成功後にキャッシュを更新する。
  Future<void> saveToken(String token) async {
    if (isWeb) {
      await stageToken(token);
      await activateToken();
      return;
    }
    await _storage.write(key: tokenKey, value: token);
    _apiToken = token;
    restoreFailed = false;
  }

  /// Persist an inactive Web candidate before changing the non-secret config.
  Future<void> stageToken(String token) async {
    if (!isWeb) throw StateError('Web staging is not a native operation');
    _apiToken = null;
    _pendingToken = null;
    await _storage.write(
        key: AppConstants.webTokenActivationKey, value: 'pending');
    await _storage.write(key: tokenKey, value: token);
    _pendingToken = token;
  }

  /// WebCrypto writes the activation marker only after config commit checks.
  Future<void> activateToken() async {
    final token = _pendingToken;
    if (!isWeb || token == null) throw StateError('No staged Web credential');
    await _storage.write(
        key: AppConstants.webTokenActivationKey, value: 'ready');
    _apiToken = token;
    _pendingToken = null;
    restoreFailed = false;
  }

  /// Secure Storage とメモリキャッシュの両方からトークンを消す。
  Future<void> clearToken() async {
    _apiToken = null;
    _pendingToken = null;
    if (isWeb) {
      try {
        await _storage.delete(key: AppConstants.webTokenActivationKey);
      } finally {
        await _storage.delete(key: tokenKey);
      }
    } else {
      await _storage.delete(key: tokenKey);
    }
    restoreFailed = false;
  }
}
