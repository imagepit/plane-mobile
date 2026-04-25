import 'package:hive/hive.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';

class LocalStorage {
  late Box _box;

  static const _keySelfHostedUrl = 'self_hosted_url';
  static const _keyApiToken = 'api_token';
  static const _keyLastWorkspaceSlug = 'last_workspace_slug';
  static const _keyLastProjectId = 'last_project_id';
  static const _keyThemeMode = 'theme_mode';

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.hiveBoxName);
  }

  bool get isConfigured {
    final url = selfHostedUrl;
    final token = apiToken;
    return url != null && url.isNotEmpty && token != null && token.isNotEmpty;
  }

  String? get selfHostedUrl => _box.get(_keySelfHostedUrl) as String?;
  String? get apiToken => _box.get(_keyApiToken) as String?;
  String? get lastWorkspaceSlug => _box.get(_keyLastWorkspaceSlug) as String?;
  String? get lastProjectId => _box.get(_keyLastProjectId) as String?;
  String get themeMode => _box.get(_keyThemeMode) as String? ?? 'system';

  set selfHostedUrl(String? value) => _box.put(_keySelfHostedUrl, value);
  set apiToken(String? value) => _box.put(_keyApiToken, value);
  set lastWorkspaceSlug(String? value) =>
      _box.put(_keyLastWorkspaceSlug, value);
  set lastProjectId(String? value) => _box.put(_keyLastProjectId, value);
  set themeMode(String value) => _box.put(_keyThemeMode, value);

  Future<void> saveConfig({
    required String selfHostedUrl,
    required String apiToken,
  }) async {
    await _box.putAll({
      _keySelfHostedUrl: selfHostedUrl,
      _keyApiToken: apiToken,
    });
  }

  Future<void> clearConfig() async {
    await _box.deleteAll([
      _keySelfHostedUrl,
      _keyApiToken,
      _keyLastWorkspaceSlug,
      _keyLastProjectId,
    ]);
  }
}