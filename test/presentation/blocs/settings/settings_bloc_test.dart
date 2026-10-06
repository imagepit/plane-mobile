import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/presentation/blocs/settings/settings_bloc.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/presentation/pages/settings/server_config_page.dart';
import '../../../core/network/web_origin_test.dart' show RecordingAdapter;

class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late MockLocalStorage storage;
  late RecordingAdapter adapter;
  late DioClient client;
  late SettingsBloc bloc;
  setUp(() {
    storage = MockLocalStorage();
    adapter = RecordingAdapter();
    client = DioClient(
        isWeb: true, origin: Uri.parse('https://plane.example.com/mobile/'));
    bloc = SettingsBloc(
        localStorage: storage,
        dioClient: client,
        connectionClientFactory: () => DioClient(
            isWeb: true,
            origin: client.origin,
            dio: Dio()..httpClientAdapter = adapter));
  });
  tearDown(() async {
    await bloc.close();
    client.close();
  });

  TestConnection connection() => TestConnection(
      url: 'https://malicious.example',
      workspaceSlug: 'example',
      apiToken: 'dummy-settings-token');

  test('connection test uses same-origin policy and valid JSON API response',
      () async {
    final result =
        bloc.stream.firstWhere((state) => state is SettingsConnectionSuccess);
    bloc.add(connection());
    final state = await result as SettingsConnectionSuccess;
    expect(state.url, 'https://plane.example.com');
    expect(state.userName, 'Dummy user');
    expect(adapter.requests.single.uri.toString(),
        'https://plane.example.com/api/v1/users/me/');
  });

  test('Access HTML response never becomes configured or success', () async {
    adapter.contentType = 'text/html';
    adapter.body = '<html>Sign in</html>';
    final result =
        bloc.stream.firstWhere((state) => state is SettingsConnectionFailure);
    bloc.add(connection());
    final state = await result as SettingsConnectionFailure;
    expect(state.error, contains('sign-in'));
    expect(state.apiToken, 'dummy-settings-token');
  });

  test(
      'storage failure returns editable inputs and does not configure live client',
      () async {
    when(() => storage.saveConfig(
        selfHostedUrl: any(named: 'selfHostedUrl'),
        workspaceSlug: any(named: 'workspaceSlug'),
        apiToken: any(named: 'apiToken'))).thenThrow(StateError('denied'));
    final result =
        bloc.stream.firstWhere((state) => state is SettingsConnectionFailure);
    bloc.add(SaveSettings(
        url: 'https://malicious.example',
        workspaceSlug: 'example',
        apiToken: 'dummy-save-token'));
    final state = await result as SettingsConnectionFailure;
    expect(state.error, contains('Could not save'));
    expect(state.url, 'https://plane.example.com');
    expect(client.apiToken, isEmpty);
  });

  test('save writes the current origin and updates client only after success',
      () async {
    when(() => storage.saveConfig(
        selfHostedUrl: any(named: 'selfHostedUrl'),
        workspaceSlug: any(named: 'workspaceSlug'),
        apiToken: any(named: 'apiToken'))).thenAnswer((_) async {});
    final result =
        bloc.stream.firstWhere((state) => state is SettingsConfigured);
    bloc.add(SaveSettings(
        url: 'http://malicious.example',
        workspaceSlug: 'example',
        apiToken: 'dummy-save-token'));
    await result;
    verify(() => storage.saveConfig(
        selfHostedUrl: 'https://plane.example.com',
        workspaceSlug: 'example',
        apiToken: 'dummy-save-token')).called(1);
    expect(client.baseUrl, 'https://plane.example.com');
    expect(client.apiToken, 'dummy-save-token');
  });

  test('credential restoration failure opens recoverable settings', () async {
    when(() => storage.isConfigured).thenReturn(false);
    when(() => storage.recoveryMessage)
        .thenReturn('Browser storage could not be restored.');
    final result = bloc.stream.firstWhere((state) => state is SettingsError);
    bloc.add(LoadSettings());
    expect((await result as SettingsError).message, contains('restored'));
  });

  test('editing existing Web settings stays on the editable form state',
      () async {
    when(() => storage.isConfigured).thenReturn(true);
    when(() => storage.selfHostedUrl).thenReturn('https://plane.example.com');
    when(() => storage.workspaceSlug).thenReturn('example');
    final result =
        bloc.stream.firstWhere((state) => state is SettingsUnconfigured);
    bloc.add(LoadSettings(edit: true));
    expect((await result as SettingsUnconfigured).lastSlug, 'example');
  });

  testWidgets('configured Web user can reach and use Clear saved settings',
      (tester) async {
    when(() => storage.isConfigured).thenReturn(true);
    when(() => storage.selfHostedUrl).thenReturn('https://plane.example.com');
    when(() => storage.workspaceSlug).thenReturn('example');
    when(() => storage.clearConfig()).thenAnswer((_) async {});
    await sl.reset();
    sl.registerSingleton<LocalStorage>(storage);
    sl.registerSingleton<DioClient>(client);
    try {
      await tester.pumpWidget(const MaterialApp(home: ServerConfigPage()));
      await tester.pumpAndSettle();
      final clear = find.text('Clear saved settings');
      expect(clear, findsOneWidget);
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      verify(() => storage.clearConfig()).called(1);
      expect(find.text('Save & Connect'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      await sl.reset();
    }
  }, skip: !kIsWeb);

  test('reset invalidates live client even when browser deletion fails',
      () async {
    client.updateConfig(apiToken: 'dummy-old');
    when(() => storage.clearConfig()).thenThrow(StateError('denied'));
    final result = bloc.stream.firstWhere((state) => state is SettingsError);
    bloc.add(ResetSettings());
    await result;
    expect(client.apiToken, isEmpty);
  });

  test('native connection test still accepts the input host', () async {
    await bloc.close();
    final native = DioClient(isWeb: false);
    bloc = SettingsBloc(
        localStorage: storage,
        dioClient: native,
        connectionClientFactory: () =>
            DioClient(isWeb: false, dio: Dio()..httpClientAdapter = adapter));
    final result =
        bloc.stream.firstWhere((state) => state is SettingsConnectionSuccess);
    bloc.add(TestConnection(
        url: 'http://native.example:8080/',
        workspaceSlug: 'example',
        apiToken: 'dummy-native'));
    await result;
    expect(adapter.requests.single.uri.toString(),
        'http://native.example:8080/api/v1/users/me/');
    native.close();
  });
}
