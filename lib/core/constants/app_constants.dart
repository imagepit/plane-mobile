class AppConstants {
  AppConstants._();

  static const String appName = 'Plane';
  static const String appVersion = '1.0.0';
  static const String defaultBaseUrl = 'https://api.plane.so';
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const String hiveBoxName = 'plane_mobile';
  static const String webHiveBoxName = 'plane_mobile_pwa_settings_v1';
  static const String webCredentialNamespace =
      'plane_mobile_pwa_credentials_v1';
  static const String webApiTokenKey = 'plane_mobile_pwa_api_token_v1';
  static const String webTokenActivationKey =
      'plane_mobile_pwa_token_activation_v1';
  static const String webPath = '/mobile/';
}
