import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/core/network/api_interceptor.dart';
import 'package:plane_mobile/core/network/dio_client.dart';

class RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  String contentType = 'application/json';
  String body = '{"first_name":"Dummy user"}';
  bool failConnection = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (failConnection) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    return ResponseBody.fromBytes(utf8.encode(body), status, headers: {
      'content-type': [contentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late RecordingAdapter adapter;
  late Dio dio;
  late DioClient client;
  setUp(() {
    adapter = RecordingAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    client = DioClient(
        isWeb: true,
        origin: Uri.parse('https://plane.example.com/mobile/'),
        dio: dio);
    client.updateConfig(apiToken: 'dummy-pat');
  });
  tearDown(() => client.close());

  test('restored, submitted and test URLs always use the HTTPS origin API',
      () async {
    for (final requested in [
      'http://other.example',
      'https://other.example',
      'https://plane.example.com/mobile/'
    ]) {
      client.updateConfig(baseUrl: requested);
      await client.get('/api/v1/users/me/');
    }
    expect(adapter.requests.length, 3);
    for (final request in adapter.requests) {
      expect(
          request.uri.toString(), 'https://plane.example.com/api/v1/users/me/');
      expect(request.headers['X-Api-Key'], 'dummy-pat');
    }
  });

  test(
      'request guard rejects off-origin requests before attaching or transmitting a token',
      () async {
    for (final url in [
      'https://other.example/api/v1/users/me/',
      'https://plane.example.com.evil.example/api/v1/users/me/',
      'https://evil-plane.example.com/api/v1/users/me/',
      'https://plane.example.com:8443/api/v1/users/me/',
      'https://plane.example.com/mobile/api/v1/users/me/'
    ]) {
      await expectLater(dio.get(url), throwsA(isA<DioException>()));
    }
    expect(adapter.requests, isEmpty);
  });

  test(
      'HTTP origin refuses even same-origin API traffic before sending a token',
      () async {
    final httpAdapter = RecordingAdapter();
    final http = DioClient(
        isWeb: true,
        origin: Uri.parse('http://plane.example.com/mobile/'),
        dio: Dio()..httpClientAdapter = httpAdapter);
    http.updateConfig(apiToken: 'dummy-http');
    await expectLater(
        http.get('/api/v1/users/me/'), throwsA(isA<DioException>()));
    expect(httpAdapter.requests, isEmpty);
    http.close();
  });

  test(
      'absolute API paths, scheme-relative paths and non-API routes are rejected',
      () async {
    for (final path in [
      'https://other.example/api/v1/',
      '//other.example/api/v1/',
      '/mobile/',
      '/api/v1/../../mobile/'
    ]) {
      await expectLater(client.get(path),
          throwsA(anyOf(isA<ArgumentError>(), isA<DioException>())));
    }
    expect(adapter.requests, isEmpty);
  });

  for (final status in [200, 403]) {
    test(
        'HTML $status is sign-in failure rather than API success or PAT failure',
        () async {
      adapter.status = status;
      adapter.contentType = 'text/html';
      adapter.body = '<!doctype html><html><body>Sign in</body></html>';
      await expectLater(
          client.get('/api/v1/users/me/'),
          throwsA(isA<DioException>().having(
              (e) => e.message, 'message', ApiInterceptor.webLoginMessage)));
    });
  }
  for (final status in [401, 403]) {
    test('JSON $status gives the corresponding token error', () async {
      adapter.status = status;
      adapter.body = '{"detail":"denied"}';
      await expectLater(
          client.get('/api/v1/users/me/'),
          throwsA(isA<DioException>().having((e) => e.message, 'message',
              contains(status == 401 ? 'expired API token' : 'permissions'))));
    });
  }
  test(
      'unreadable network failure is not asserted to be Access expiry and POST is not retried',
      () async {
    adapter.failConnection = true;
    await expectLater(
        client.post('/api/v1/workspaces/example/projects/',
            data: {'name': 'dummy'}),
        throwsA(isA<DioException>().having(
            (e) => e.message, 'message', ApiInterceptor.webNetworkMessage)));
    expect(adapter.requests.length, 1);
  });
  test('native retains configured URL support', () async {
    final native =
        DioClient(isWeb: false, dio: Dio()..httpClientAdapter = adapter);
    native.updateConfig(
        baseUrl: 'http://native.example:8080/', apiToken: 'dummy-native');
    await native.get('/api/v1/users/me/');
    expect(adapter.requests.single.uri.toString(),
        'http://native.example:8080/api/v1/users/me/');
    native.close();
  });
}
