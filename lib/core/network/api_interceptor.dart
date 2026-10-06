import 'package:dio/dio.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';

class ApiInterceptor extends Interceptor {
  final DioClient _dioClient;

  ApiInterceptor(this._dioClient);

  static const webLoginMessage =
      'Website sign-in is required. Open /mobile/ again and sign in, then retry.';
  static const webNetworkMessage =
      'Could not reach Plane. Check your connection, or open /mobile/ again '
      'to sign in. If a write failed, check its result before retrying.';

  bool _isHtml(Response? response) =>
      response?.headers
              .value('content-type')
              ?.toLowerCase()
              .contains('text/html') ==
          true ||
      (response?.data is String &&
          RegExp(r'^\s*(<!doctype\s+html|<html)', caseSensitive: false)
              .hasMatch(response!.data as String));

  DioException _webError(RequestOptions request, String message,
          {Response? response}) =>
      DioException(
          requestOptions: request,
          response: response,
          message: message,
          error: ConnectionException(message));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_dioClient.permitsRequest(options.uri)) {
      options.headers.removeWhere((key, _) => key.toLowerCase() == 'x-api-key');
      handler.reject(_webError(options,
          'Plane Web requires HTTPS and the current website API origin.'));
      return;
    }
    final token = _dioClient.apiToken;
    if (token.isNotEmpty) {
      options.headers['X-Api-Key'] = token;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_dioClient.isWeb && _isHtml(response)) {
      handler.reject(_webError(response.requestOptions, webLoginMessage,
          response: response));
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_dioClient.isWeb) {
      final status = err.response?.statusCode;
      final message = _isHtml(err.response)
          ? webLoginMessage
          : status == 401
              ? 'Invalid or expired API token. Enter a valid Plane API token.'
              : status == 403
                  ? 'Plane API access was denied. Check your token permissions.'
                  : (err.type == DioExceptionType.connectionError ||
                          err.type == DioExceptionType.connectionTimeout ||
                          err.type == DioExceptionType.sendTimeout ||
                          err.type == DioExceptionType.receiveTimeout)
                      ? webNetworkMessage
                      : null;
      if (message != null) {
        handler.reject(
            _webError(err.requestOptions, message, response: err.response));
        return;
      }
      // Preserve rejected policy/HTML responses and never retry writes.
      if (err.error is ConnectionException) {
        handler.next(err);
        return;
      }
    }
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ConnectionException('Connection timed out'),
          ),
        );
        break;
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ConnectionException('No internet connection'),
          ),
        );
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: UnauthorizedException(),
            ),
          );
        } else if (statusCode == 403) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ForbiddenException(),
            ),
          );
        } else if (statusCode == 404) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: NotFoundException(),
            ),
          );
        } else {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerException(
                err.response?.statusMessage ?? 'Server error',
                statusCode: statusCode,
              ),
            ),
          );
        }
        break;
      default:
        handler.next(err);
    }
  }
}
