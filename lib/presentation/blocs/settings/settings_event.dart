part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {
  final bool edit;
  LoadSettings({this.edit = false});
}

class SaveSettings extends SettingsEvent {
  final String url;
  final String workspaceSlug;
  final String apiToken;
  SaveSettings({
    required this.url,
    required this.workspaceSlug,
    required this.apiToken,
  });
}

class TestConnection extends SettingsEvent {
  final String url;
  final String workspaceSlug;
  final String apiToken;
  TestConnection({
    required this.url,
    required this.workspaceSlug,
    required this.apiToken,
  });
}

class ResetSettings extends SettingsEvent {}

class ChangeTheme extends SettingsEvent {
  final String themeMode;
  ChangeTheme({required this.themeMode});
}
