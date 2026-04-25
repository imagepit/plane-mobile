import 'package:dio/dio.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';

class ApiInterceptor extends Interceptor {
  final DioClient _dioClient;

  ApiInterceptor(this._dioClient);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _dioClient.apiToken;
    if (token.isNotEmpty) {
      options.headers['X-Api-Key'] = token;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
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