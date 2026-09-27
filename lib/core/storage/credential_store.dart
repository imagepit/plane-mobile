import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API token の保存先。
///
/// 機密は iOS Keychain / Android Keystore（[FlutterSecureStorage]）にだけ置き、
/// Hive など平文ストレージには残さない。永続化は await 可能な [saveToken] /
/// [clearToken] 経路だけとし、同期の `set apiToken` はメモリキャッシュ更新のみ
/// にとどめる。
class CredentialStore {
  CredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Secure Storage 内のキー名。
  static const String apiTokenKey = 'api_token';

  final FlutterSecureStorage _storage;
  String? _apiToken;

  /// Secure Storage からメモリキャッシュへ読み込む。
  ///
  /// `LocalStorage.init()` より先に完了させること（保存直後の `isConfigured`
  /// 判定がキャッシュを読むため）。
  Future<void> init() async {
    _apiToken = await _storage.read(key: apiTokenKey);
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
    await _storage.write(key: apiTokenKey, value: token);
    _apiToken = token;
  }

  /// Secure Storage とメモリキャッシュの両方からトークンを消す。
  Future<void> clearToken() async {
    await _storage.delete(key: apiTokenKey);
    _apiToken = null;
  }
}
