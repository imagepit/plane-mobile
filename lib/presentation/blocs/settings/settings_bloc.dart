import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LocalStorage _localStorage;
  final DioClient _dioClient;
  final DioClient Function()? _connectionClientFactory;

  SettingsBloc({
    required LocalStorage localStorage,
    required DioClient dioClient,
    DioClient Function()? connectionClientFactory,
  })  : _localStorage = localStorage,
        _dioClient = dioClient,
        _connectionClientFactory = connectionClientFactory,
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
    if (_localStorage.isConfigured && !event.edit) {
      final url = _dioClient.resolveBaseUrl(_localStorage.selfHostedUrl!);
      final token = _localStorage.apiToken!;
      _dioClient.updateConfig(baseUrl: url, apiToken: token);
      emit(SettingsConfigured(url: url, apiToken: token));
    } else {
      if (_localStorage.recoveryMessage != null) {
        emit(SettingsError(message: _localStorage.recoveryMessage!));
        return;
      }
      emit(SettingsUnconfigured(
        lastUrl: _localStorage.selfHostedUrl,
        lastSlug: _localStorage.workspaceSlug,
      ));
    }
  }

  Future<void> _onSaveSettings(
      SaveSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    final url = _dioClient.resolveBaseUrl(event.url);
    try {
      if (_dioClient.isWeb &&
          !_dioClient.permitsRequest(Uri.parse('$url/api/v1/users/me/'))) {
        throw StateError('HTTPS required');
      }
      await _localStorage.saveConfig(
        selfHostedUrl: url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
      );
      _dioClient.updateConfig(baseUrl: url, apiToken: event.apiToken);
      emit(SettingsConfigured(url: url, apiToken: event.apiToken));
    } catch (_) {
      if (_dioClient.isWeb) _dioClient.updateConfig(apiToken: '');
      emit(SettingsConnectionFailure(
          url: url,
          workspaceSlug: event.workspaceSlug,
          apiToken: event.apiToken,
          error: _dioClient.isWeb
              ? 'Could not save settings. Use HTTPS, allow website storage, and try again.'
              : 'Could not save settings. Please try again.'));
    }
  }

  Future<void> _onTestConnection(
      TestConnection event, Emitter<SettingsState> emit) async {
    final url = _dioClient.resolveBaseUrl(event.url);
    emit(SettingsTestingConnection(
      url: url,
      workspaceSlug: event.workspaceSlug,
      apiToken: event.apiToken,
    ));
    final client =
        _connectionClientFactory?.call() ?? _dioClient.connectionTestClient();
    try {
      client.updateConfig(baseUrl: url, apiToken: event.apiToken);
      // PAT（X-API-Key）が通るのは /api/v1 のみ（旧 /api/ は 401。2026-09-27 実測）
      final response = await client.get('/api/v1/users/me/');
      if (response.data is! Map) {
        throw const FormatException('Expected API object');
      }
      final name =
          response.data['first_name'] ?? response.data['email'] ?? 'User';
      emit(SettingsConnectionSuccess(
        url: url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
        userName: name.toString(),
      ));
    } on DioException catch (e) {
      final error = _dioClient.isWeb
          ? (e.message ?? 'Could not connect to server')
          : e.response?.statusCode == 401 || e.error is UnauthorizedException
              ? 'Invalid API token'
              : 'Could not connect to server';
      emit(SettingsConnectionFailure(
        url: url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
        error: error,
      ));
    } catch (_) {
      emit(SettingsConnectionFailure(
        url: url,
        workspaceSlug: event.workspaceSlug,
        apiToken: event.apiToken,
        error:
            'Could not read a Plane API response. Check your settings and website sign-in.',
      ));
    } finally {
      client.close();
    }
  }

  Future<void> _onResetSettings(
      ResetSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    _dioClient.updateConfig(baseUrl: '', apiToken: '');
    try {
      await _localStorage.clearConfig();
      emit(SettingsUnconfigured());
    } catch (_) {
      emit(SettingsError(
          message: 'Could not fully clear saved settings. '
              'Allow website storage or clear this website’s data before reconnecting.'));
    }
  }

  Future<void> _onChangeTheme(
      ChangeTheme event, Emitter<SettingsState> emit) async {
    _localStorage.themeMode = event.themeMode;
  }
}
