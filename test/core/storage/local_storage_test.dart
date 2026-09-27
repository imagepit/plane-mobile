import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';

/// 端末の Keychain / Android Keystore に触れないための偽物。
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late Directory tempDir;
  late MockFlutterSecureStorage secureStorage;
  late CredentialStore credentialStore;
  late Box box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('plane_mobile_local_storage');
    Hive.init(tempDir.path);
    box = await Hive.openBox(AppConstants.hiveBoxName);
    secureStorage = MockFlutterSecureStorage();
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => secureStorage.write(
        key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
    credentialStore = CredentialStore(storage: secureStorage);
    await credentialStore.init();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('LocalStorage の api_token 保管', () {
    test('saveConfig 後も Hive の box に api_token が残らず、Secure Storage にだけ保存される',
        () async {
      final localStorage = LocalStorage(credentialStore: credentialStore);
      await localStorage.init();

      await localStorage.saveConfig(
        selfHostedUrl: 'https://plane.example.com',
        apiToken: 'token-1',
      );

      expect(box.containsKey('api_token'), isFalse);
      expect(box.get('self_hosted_url'), 'https://plane.example.com');
      verify(() => secureStorage.write(key: 'api_token', value: 'token-1'))
          .called(1);
      expect(localStorage.apiToken, 'token-1');
      expect(localStorage.isConfigured, isTrue);
    });

    test('set apiToken 後も Hive に残らず、Secure Storage へも書かない（永続化しない）',
        () async {
      final localStorage = LocalStorage(credentialStore: credentialStore);
      await localStorage.init();

      localStorage.apiToken = 'token-2';

      expect(localStorage.apiToken, 'token-2');
      expect(box.containsKey('api_token'), isFalse);
      verifyNever(
          () => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('既存の平文 api_token は CredentialStore へ移って Hive から消える（移行）',
        () async {
      await box.put('api_token', 'legacy-token');

      final localStorage = LocalStorage(credentialStore: credentialStore);
      await localStorage.init();

      expect(box.containsKey('api_token'), isFalse);
      verify(() => secureStorage.write(key: 'api_token', value: 'legacy-token'))
          .called(1);
      expect(localStorage.apiToken, 'legacy-token');
      expect(localStorage.isConfigured, isFalse); // URL が無いため未設定のまま
    });

    test('clearConfig は Hive の設定と Secure Storage のトークンの両方を消す', () async {
      await box.put('api_token', 'legacy-token');
      final localStorage = LocalStorage(credentialStore: credentialStore);
      await localStorage.init();
      await localStorage.saveConfig(
        selfHostedUrl: 'https://plane.example.com',
        apiToken: 'token-3',
      );

      await localStorage.clearConfig();

      expect(box.containsKey('api_token'), isFalse);
      expect(box.containsKey('self_hosted_url'), isFalse);
      verify(() => secureStorage.delete(key: 'api_token')).called(1);
      expect(localStorage.apiToken, isNull);
      expect(localStorage.selfHostedUrl, isNull);
      expect(localStorage.isConfigured, isFalse);
    });
  });
}
