import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';

/// 端末の Keychain / Android Keystore に触れないための偽物。
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockBox extends Mock implements Box {}

void main() {
  Directory? tempDir;
  late MockFlutterSecureStorage secureStorage;
  late CredentialStore credentialStore;
  late Box box;

  setUp(() async {
    if (!kIsWeb) {
      tempDir =
          await Directory.systemTemp.createTemp('plane_mobile_local_storage');
    }
    Hive.init(tempDir?.path ?? 'browser-tests');
    box = await Hive.openBox(AppConstants.hiveBoxName);
    if (kIsWeb) {
      await box.clear();
      await (await Hive.openBox(AppConstants.webHiveBoxName)).clear();
    }
    secureStorage = MockFlutterSecureStorage();
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'))).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
    credentialStore = CredentialStore(storage: secureStorage, isWeb: false);
    await credentialStore.init();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir?.delete(recursive: true);
  });

  group('LocalStorage の api_token 保管', () {
    test('saveConfig 後も Hive の box に api_token が残らず、Secure Storage にだけ保存される',
        () async {
      final localStorage =
          LocalStorage(credentialStore: credentialStore, isWeb: false);
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

    test('set apiToken 後も Hive に残らず、Secure Storage へも書かない（永続化しない）', () async {
      final localStorage =
          LocalStorage(credentialStore: credentialStore, isWeb: false);
      await localStorage.init();

      localStorage.apiToken = 'token-2';

      expect(localStorage.apiToken, 'token-2');
      expect(box.containsKey('api_token'), isFalse);
      verifyNever(() => secureStorage.write(
          key: any(named: 'key'), value: any(named: 'value')));
    });

    test('既存の平文 api_token は CredentialStore へ移って Hive から消える（移行）', () async {
      await box.put('api_token', 'legacy-token');

      final localStorage =
          LocalStorage(credentialStore: credentialStore, isWeb: false);
      await localStorage.init();

      expect(box.containsKey('api_token'), isFalse);
      verify(() => secureStorage.write(key: 'api_token', value: 'legacy-token'))
          .called(1);
      expect(localStorage.apiToken, 'legacy-token');
      expect(localStorage.isConfigured, isFalse); // URL が無いため未設定のまま
    });

    test('clearConfig は Hive の設定と Secure Storage のトークンの両方を消す', () async {
      await box.put('api_token', 'legacy-token');
      final localStorage =
          LocalStorage(credentialStore: credentialStore, isWeb: false);
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

  group('Web settings', () {
    test(
        'failed final verification and failed cleanup stay inactive on restart',
        () async {
      final persisted = <String, String>{};
      when(() => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((call) async {
        persisted[call.namedArguments[#key] as String] =
            call.namedArguments[#value] as String;
      });
      when(() => secureStorage.read(key: any(named: 'key')))
          .thenAnswer((call) async => persisted[call.namedArguments[#key]]);
      when(() => secureStorage.delete(key: any(named: 'key')))
          .thenThrow(StateError('cleanup denied'));
      final webStore = CredentialStore(storage: secureStorage, isWeb: true);
      await webStore.init();
      var checkpoints = 0;
      final local = LocalStorage(
          credentialStore: webStore,
          isWeb: true,
          commitVerifier: (_) async {
            if (++checkpoints == 2) throw StateError('readback denied');
          });
      await local.init();
      await expectLater(
          local.saveConfig(
              selfHostedUrl: 'https://plane.example.com',
              workspaceSlug: 'example',
              apiToken: 'dummy-inactive-candidate'),
          throwsStateError);
      expect(Hive.box(AppConstants.webHiveBoxName).get('config_save_pending'),
          isFalse);
      expect(persisted[AppConstants.webTokenActivationKey], 'pending');
      expect(
          persisted[AppConstants.webApiTokenKey], 'dummy-inactive-candidate');
      expect(local.isConfigured, isFalse);
      final restored = CredentialStore(storage: secureStorage, isWeb: true);
      await restored.init();
      final restarted = LocalStorage(credentialStore: restored, isWeb: true);
      await restarted.init();
      expect(restarted.apiToken, isNull);
      expect(restarted.isConfigured, isFalse);
      expect(restarted.recoveryMessage, isNotNull);
      verifyNever(() => secureStorage.read(key: AppConstants.webApiTokenKey));
    });

    test('failed final settings transaction remains incomplete after restart',
        () async {
      final settings = <String, Object?>{
        'self_hosted_url': 'https://plane.example.com',
        'workspace_slug': 'old-workspace',
      };
      final failingBox = MockBox();
      when(() => failingBox.get(any()))
          .thenAnswer((call) => settings[call.positionalArguments.single]);
      when(() => failingBox.delete('api_token')).thenAnswer((_) async {});
      when(() => failingBox.put('config_save_pending', true))
          .thenAnswer((_) async {
        settings['config_save_pending'] = true;
      });
      when(() => failingBox.putAll(any()))
          .thenThrow(StateError('Hive transaction denied'));
      String? encryptedDummy;
      when(() => secureStorage.write(
          key: AppConstants.webApiTokenKey,
          value: 'dummy-partial')).thenAnswer((_) async {
        encryptedDummy = 'dummy-partial';
      });
      when(() => secureStorage.read(key: AppConstants.webApiTokenKey))
          .thenAnswer((_) async => encryptedDummy);
      when(() => secureStorage.delete(key: AppConstants.webApiTokenKey))
          .thenAnswer((_) async {
        encryptedDummy = null;
      });
      final webStore = CredentialStore(storage: secureStorage, isWeb: true);
      await webStore.init();
      final local = LocalStorage(
          credentialStore: webStore,
          isWeb: true,
          box: failingBox,
          commitVerifier: (_) async {});
      await local.init();
      await expectLater(
          local.saveConfig(
              selfHostedUrl: 'https://plane.example.com',
              workspaceSlug: 'new-workspace',
              apiToken: 'dummy-partial'),
          throwsStateError);
      expect(local.apiToken, isNull);
      expect(encryptedDummy, isNull);
      final restored = CredentialStore(storage: secureStorage, isWeb: true);
      await restored.init();
      final restarted = LocalStorage(
          credentialStore: restored,
          isWeb: true,
          box: failingBox,
          commitVerifier: (_) async {});
      await restarted.init();
      expect(restarted.isConfigured, isFalse);
      expect(restarted.recoveryMessage, isNotNull);
      expect(settings['workspace_slug'], 'old-workspace');
      expect(settings['config_save_pending'], isTrue);
    });

    for (final failureAt in [1, 2]) {
      test('commit verification failure $failureAt is never saved/configured',
          () async {
        final webStore = CredentialStore(storage: secureStorage, isWeb: true);
        await webStore.init();
        var checkpoints = 0;
        final local = LocalStorage(
            credentialStore: webStore,
            isWeb: true,
            commitVerifier: (_) async {
              if (++checkpoints == failureAt)
                throw StateError('late transaction abort');
            });
        await local.init();
        await expectLater(
            local.saveConfig(
                selfHostedUrl: 'https://plane.example.com',
                workspaceSlug: 'example',
                apiToken: 'dummy-commit-failure'),
            throwsStateError);
        expect(local.isConfigured, isFalse);
        expect(local.apiToken, isNull);
        if (failureAt == 1) {
          verifyNever(() => secureStorage.write(
              key: AppConstants.webApiTokenKey, value: 'dummy-commit-failure'));
        } else {
          verify(() => secureStorage.delete(key: AppConstants.webApiTokenKey))
              .called(1);
        }
      });
    }

    test('uses its own non-secret box and never migrates a native credential',
        () async {
      await box.put('api_token', 'dummy-native-legacy');
      final webStore = CredentialStore(storage: secureStorage, isWeb: true);
      await webStore.init();
      final local = LocalStorage(credentialStore: webStore, isWeb: true);
      await local.init();
      final webBox = Hive.box(AppConstants.webHiveBoxName);
      await local.saveConfig(
          selfHostedUrl: 'https://plane.example.com',
          workspaceSlug: 'example',
          apiToken: 'dummy-web');
      expect(webBox.get('workspace_slug'), 'example');
      expect(webBox.containsKey('api_token'), isFalse);
      expect(webBox.values, isNot(contains('dummy-web')));
      expect(box.get('api_token'), 'dummy-native-legacy');
      verifyNever(() =>
          secureStorage.write(key: 'api_token', value: 'dummy-native-legacy'));
      await local.clearConfig();
      expect(local.isConfigured, isFalse);
      expect(webBox.get('self_hosted_url'), isNull);
      expect(box.get('api_token'), 'dummy-native-legacy');
    });

    test('save denial cannot be reported as configured', () async {
      final webStore = CredentialStore(storage: secureStorage, isWeb: true);
      await webStore.init();
      final local = LocalStorage(credentialStore: webStore, isWeb: true);
      await local.init();
      when(() => secureStorage.write(
          key: AppConstants.webApiTokenKey,
          value: 'dummy-denied')).thenThrow(StateError('denied'));
      await expectLater(
          local.saveConfig(
              selfHostedUrl: 'https://plane.example.com',
              apiToken: 'dummy-denied'),
          throwsStateError);
      expect(local.isConfigured, isFalse);
      expect(local.recoveryMessage, isNotNull);
      expect(Hive.box(AppConstants.webHiveBoxName).containsKey('api_token'),
          isFalse);
    });
  });
}
