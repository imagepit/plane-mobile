import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';

/// 端末の Keychain / Android Keystore に触れないための偽物。
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late CredentialStore store;

  setUp(() {
    storage = MockFlutterSecureStorage();
    store = CredentialStore(storage: storage);
  });

  group('CredentialStore', () {
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
      when(() => storage.write(key: CredentialStore.apiTokenKey, value: 'token-b'))
          .thenAnswer((_) async {});

      await store.saveToken('token-b');

      verify(() =>
              storage.write(key: CredentialStore.apiTokenKey, value: 'token-b'))
          .called(1);
      expect(store.apiToken, 'token-b');
    });

    test('clearToken は Secure Storage とキャッシュの両方から消す', () async {
      when(() => storage.write(key: CredentialStore.apiTokenKey, value: 'token-c'))
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
      verifyNever(
          () => storage.write(key: any(named: 'key'), value: any(named: 'value')));
    });
  });
}
