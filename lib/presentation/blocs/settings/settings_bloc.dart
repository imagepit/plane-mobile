import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LocalStorage _localStorage;
  final DioClient _dioClient;

  SettingsBloc({
    required LocalStorage localStorage,
    required DioClient dioClient,
  })  : _localStorage = localStorage,
        _dioClient = dioClient,
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
    on<TestConnection>(_onTestConnection);
    on<ResetSettings>(_onResetSettings);
    on<ChangeTheme>(_onChangeTheme);
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    if (_localStorage.isConfigured) {
      final url = _localStorage.selfHostedUrl!;
      final token = _localStorage.apiToken!;
      _dioClient.updateConfig(baseUrl: url, apiToken: token);
      emit(SettingsConfigured(url: url, apiToken: token));
    } else {
      emit(SettingsUnconfigured(
        lastUrl: _localStorage.selfHostedUrl,
        lastSlug: _localStorage.workspaceSlug,
      ));
    }
  }

  Future<void> _onSaveSettings(
      SaveSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    await _localStorage.saveConfig(
      selfHostedUrl: event.url,
      workspaceSlug: event.workspaceSlug,
      apiToken: event.apiToken,
    );
    _dioClient.updateConfig(baseUrl: event.url, apiToken: event.apiToken);
    emit(SettingsConfigured(url: event.url, apiToken: event.apiToken));
  }

  Future<void> _onTestConnection(
      TestConnection event, Emitter<SettingsState> emit) async {
    emit(SettingsTestingConnection(
      url: event.url,
      workspaceSlug: event.workspaceSlug,
      apiToken: event.apiToken,
    ));
    try {
      final tempDio = Dio();
      tempDio.options.headers['X-Api-Key'] = event.apiToken;
      tempDio.options.headers['Content-Type'] = 'application/json';
      // PAT（X-API-Key）が通るのは /api/v1 のみ（旧 /api/ は 401。2026-09-27 実測）
      final url = '${event.url}/api/v1/users/me/';
      final response = await tempDio.get(url);
      final name = response.data?['first_name'] ?? response.data?['email'] ?? 'User';
      emit(SettingsConnectionSuccess(
        url: event.url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
        userName: name.toString(),
      ));
    } on DioException catch (e) {
      final error = e.response?.statusCode == 401
          ? 'Invalid API token'
          : 'Could not connect to server';
      emit(SettingsConnectionFailure(
        url: event.url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
        error: error,
      ));
    } catch (e) {
      emit(SettingsConnectionFailure(
        url: event.url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
        error: 'Connection failed: $e',
      ));
    }
  }

  Future<void> _onResetSettings(
      ResetSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    await _localStorage.clearConfig();
    _dioClient.updateConfig(baseUrl: '', apiToken: '');
    emit(SettingsUnconfigured());
  }

  Future<void> _onChangeTheme(
      ChangeTheme event, Emitter<SettingsState> emit) async {
    _localStorage.themeMode = event.themeMode;
  }
}