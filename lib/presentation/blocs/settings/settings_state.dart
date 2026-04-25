part of 'settings_bloc.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsUnconfigured extends SettingsState {
  final String? lastUrl;
  SettingsUnconfigured({this.lastUrl});
}

class SettingsConfigured extends SettingsState {
  final String url;
  final String apiToken;
  SettingsConfigured({required this.url, required this.apiToken});
}

class SettingsTestingConnection extends SettingsState {
  final String url;
  final String apiToken;
  SettingsTestingConnection({required this.url, required this.apiToken});
}

class SettingsConnectionSuccess extends SettingsState {
  final String url;
  final String apiToken;
  final String userName;
  SettingsConnectionSuccess({
    required this.url,
    required this.apiToken,
    required this.userName,
  });
}

class SettingsConnectionFailure extends SettingsState {
  final String url;
  final String apiToken;
  final String error;
  SettingsConnectionFailure({
    required this.url,
    required this.apiToken,
    required this.error,
  });
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError({required this.message});
}