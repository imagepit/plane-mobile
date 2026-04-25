part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class SaveSettings extends SettingsEvent {
  final String url;
  final String apiToken;
  SaveSettings({required this.url, required this.apiToken});
}

class TestConnection extends SettingsEvent {
  final String url;
  final String apiToken;
  TestConnection({required this.url, required this.apiToken});
}

class ResetSettings extends SettingsEvent {}

class ChangeTheme extends SettingsEvent {
  final String themeMode;
  ChangeTheme({required this.themeMode});
}