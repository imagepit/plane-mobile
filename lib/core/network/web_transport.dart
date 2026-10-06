import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/dio.dart';

@JS('fetch')
external JSPromise<_FetchResponse> _fetch(JSString url, JSObject init);

extension type _FetchResponse._(JSObject _) implements JSObject {
  external int get status;
  external _FetchHeaders get headers;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

extension type _FetchHeaders._(JSObject _) implements JSObject {
  external void forEach(JSFunction callback);
}

@JS('AbortController')
extension type _AbortController._(JSObject _) implements JSObject {
  external factory _AbortController();
  external JSObject get signal;
  external void abort();
}

HttpClientAdapter createWebTransport() => _WebTransport();

/// XHR follows redirects with X-Api-Key. Fetch rejects all redirects before
/// forwarding the token, and same-origin mode also disallows external targets.
class _WebTransport implements HttpClientAdapter {
  final _active = <_AbortController>{};
  bool _closed = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (_closed) throw StateError('Transport closed');
    final controller = _AbortController();
    _active.add(controller);
    var cancelled = false;
    cancelFuture?.then((_) {
      cancelled = true;
      controller.abort();
    });
    Future<T> timed<T>(
            Future<T> future, Duration? timeout, DioExceptionType type) =>
        timeout == null || timeout == Duration.zero
            ? future
            : future.timeout(timeout, onTimeout: () {
                controller.abort();
                throw DioException(requestOptions: options, type: type);
              });
    try {
      Uint8List? body;
      if (requestStream != null) {
        final builder = BytesBuilder();
        await timed(requestStream.forEach(builder.add), options.sendTimeout,
            DioExceptionType.sendTimeout);
        body = builder.takeBytes();
      }
      final init = <String, Object?>{
        'method': options.method,
        'headers': options.headers
            .map((key, value) => MapEntry(key, value.toString())),
        'credentials': 'same-origin',
        'mode': 'same-origin',
        'redirect': 'error',
        'signal': controller.signal,
        if (body != null) 'body': body.toJS,
      }.jsify() as JSObject;
      final response = await timed(
          _fetch(options.uri.toString().toJS, init).toDart,
          options.connectTimeout,
          DioExceptionType.connectionTimeout);
      final bytes = await timed(response.arrayBuffer().toDart,
          options.receiveTimeout, DioExceptionType.receiveTimeout);
      final headers = <String, List<String>>{};
      response.headers.forEach(((JSString value, JSString key) {
        headers[key.toDart] = [value.toDart];
      }).toJS);
      return ResponseBody.fromBytes(bytes.toDart.asUint8List(), response.status,
          headers: headers);
    } on DioException {
      rethrow;
    } catch (_) {
      // Avoid exposing a browser exception which can include request details.
      throw DioException(
          requestOptions: options,
          type: cancelled
              ? DioExceptionType.cancel
              : DioExceptionType.connectionError);
    } finally {
      _active.remove(controller);
    }
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    if (force) {
      for (final controller in _active) {
        controller.abort();
      }
    }
  }
}
