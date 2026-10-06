import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';

/// 端末の Keychain / Android Keystore に触れないための偽物。
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late CredentialStore store;

  setUp(() {
    storage = MockFlutterSecureStorage();
    store = CredentialStore(storage: storage, isWeb: false);
  });

  group('CredentialStore', () {
    test('native mock roundtrip uses only the native key', () async {
      String? stored;
      when(() => storage.write(
          key: CredentialStore.apiTokenKey,
          value: 'dummy-native-roundtrip')).thenAnswer((_) async {
        stored = 'dummy-native-roundtrip';
      });
      when(() => storage.read(key: CredentialStore.apiTokenKey))
          .thenAnswer((_) async => stored);
      when(() => storage.delete(key: CredentialStore.apiTokenKey))
          .thenAnswer((_) async {
        stored = null;
      });
      await store.saveToken('dummy-native-roundtrip');
      final restored = CredentialStore(storage: storage, isWeb: false);
      await restored.init();
      expect(restored.apiToken, 'dummy-native-roundtrip');
      await store.clearToken();
      await restored.init();
      expect(restored.apiToken, isNull);
      verifyNever(() => storage.read(key: AppConstants.webApiTokenKey));
    });
    test('init は Secure Storage の api_token をメモリキャッシュへ読む', () async {
      when(() => storage.read(key: CredentialStore.apiTokenKey))
          .thenAnswer((_) async => 'token-a');

      await store.init();

      expect(store.apiToken, 'token-a');
    });

    test('init は Secure Storage に api_token が無ければ null', () async {
      when(() => storage.read(key: CredentialStore.apiTokenKey))
          .thenAnswer((_) async => null);

      await store.init();

      expect(store.apiToken, isNull);
    });

    test('saveToken は Secure Storage に書いてからキャッシュを更新する', () async {
      when(() =>
              storage.write(key: CredentialStore.apiTokenKey, value: 'token-b'))
          .thenAnswer((_) async {});

      await store.saveToken('token-b');

      verify(() =>
              storage.write(key: CredentialStore.apiTokenKey, value: 'token-b'))
          .called(1);
      expect(store.apiToken, 'token-b');
    });

    test('clearToken は Secure Storage とキャッシュの両方から消す', () async {
      when(() =>
              storage.write(key: CredentialStore.apiTokenKey, value: 'token-c'))
          .thenAnswer((_) async {});
      when(() => storage.delete(key: CredentialStore.apiTokenKey))
          .thenAnswer((_) async {});

      await store.saveToken('token-c');
      await store.clearToken();

      verify(() => storage.delete(key: CredentialStore.apiTokenKey)).called(1);
      expect(store.apiToken, isNull);
    });

    test('set apiToken はメモリキャッシュのみで Secure Storage へ書かない', () {
      store.apiToken = 'token-d';

      expect(store.apiToken, 'token-d');
      verifyNever(() =>
          storage.write(key: any(named: 'key'), value: any(named: 'value')));
    });
  });

  group('Web credentials', () {
    setUp(() {
      store = CredentialStore(storage: storage, isWeb: true);
      when(() => storage.write(
          key: AppConstants.webTokenActivationKey,
          value: any(named: 'value'))).thenAnswer((_) async {});
      when(() => storage.read(key: AppConstants.webTokenActivationKey))
          .thenAnswer((_) async => 'ready');
      when(() => storage.delete(key: AppConstants.webTokenActivationKey))
          .thenAnswer((_) async {});
    });

    test('dedicated key, persistence, restore and reset', () async {
      when(() => storage.write(
          key: AppConstants.webApiTokenKey,
          value: 'dummy-web')).thenAnswer((_) async {});
      when(() => storage.read(key: AppConstants.webApiTokenKey))
          .thenAnswer((_) async => 'dummy-web');
      when(() => storage.delete(key: AppConstants.webApiTokenKey))
          .thenAnswer((_) async {});
      await store.saveToken('dummy-web');
      await store.init();
      expect(store.apiToken, 'dummy-web');
      await store.clearToken();
      expect(store.apiToken, isNull);
      verifyNever(() => storage.read(key: CredentialStore.apiTokenKey));
      verify(() => storage.delete(key: AppConstants.webApiTokenKey)).called(1);
    });

    test('read failure permits settings recovery without a token', () async {
      when(() => storage.read(key: AppConstants.webApiTokenKey))
          .thenThrow(StateError('denied or corrupt'));
      await store.init();
      expect(store.restoreFailed, isTrue);
      expect(store.apiToken, isNull);
      when(() => storage.write(
          key: AppConstants.webApiTokenKey,
          value: 'dummy-recovered')).thenAnswer((_) async {});
      await store.saveToken('dummy-recovered');
      expect(store.restoreFailed, isFalse);
    });

    test('write denial invalidates cache and propagates failure', () async {
      store.apiToken = 'dummy-old';
      when(() => storage.write(
          key: AppConstants.webApiTokenKey,
          value: 'dummy-new')).thenThrow(StateError('denied'));
      await expectLater(store.saveToken('dummy-new'), throwsStateError);
      expect(store.apiToken, isNull);
    });

    test('failed activation keeps the candidate unread after restart',
        () async {
      var marker = 'ready';
      when(() => storage.write(
          key: AppConstants.webTokenActivationKey,
          value: 'pending')).thenAnswer((_) async {
        marker = 'pending';
      });
      when(() => storage.write(
          key: AppConstants.webApiTokenKey,
          value: 'dummy-staged')).thenAnswer((_) async {});
      when(() => storage.write(
          key: AppConstants.webTokenActivationKey,
          value: 'ready')).thenThrow(StateError('activation denied'));
      when(() => storage.read(key: AppConstants.webTokenActivationKey))
          .thenAnswer((_) async => marker);
      await expectLater(store.saveToken('dummy-staged'), throwsStateError);
      expect(store.apiToken, isNull);
      final restored = CredentialStore(storage: storage, isWeb: true);
      await restored.init();
      expect(restored.apiToken, isNull);
      expect(restored.restoreFailed, isTrue);
      verifyNever(() => storage.read(key: AppConstants.webApiTokenKey));
    });

    test('delete denial invalidates in-memory credential and reports failure',
        () async {
      store.apiToken = 'dummy-old';
      when(() => storage.delete(key: AppConstants.webApiTokenKey))
          .thenThrow(StateError('denied'));
      await expectLater(store.clearToken(), throwsStateError);
      expect(store.apiToken, isNull);
    });
  });
}
