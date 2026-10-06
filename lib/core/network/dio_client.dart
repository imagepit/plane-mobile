import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';
import 'package:plane_mobile/core/network/api_interceptor.dart';
import 'web_transport_stub.dart'
    if (dart.library.js_interop) 'web_transport.dart';

class DioClient {
  late Dio _dio;
  String _baseUrl = AppConstants.defaultBaseUrl;
  String _apiToken = '';

  DioClient({bool? isWeb, Uri? origin, Dio? dio})
      : isWeb = isWeb ?? kIsWeb,
        origin = origin ?? Uri.base {
    if (this.isWeb) _baseUrl = this.origin.origin;
    _dio = dio ??
        Dio(
          BaseOptions(
            connectTimeout: AppConstants.connectionTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
    if (this.isWeb && dio == null) {
      _dio.httpClientAdapter = createWebTransport();
    }
    _dio.interceptors.add(ApiInterceptor(this));
  }

  final bool isWeb;
  final Uri origin;
  String resolveBaseUrl(String requested) =>
      isWeb ? origin.origin : requested.replaceAll(RegExp(r'/+$'), '');

  bool permitsRequest(Uri uri) =>
      !isWeb ||
      (origin.scheme == 'https' &&
          uri.scheme == 'https' &&
          uri.origin == origin.origin &&
          uri.userInfo.isEmpty &&
          uri.path.startsWith('/api/v1/'));

  DioClient connectionTestClient() => DioClient(isWeb: isWeb, origin: origin);
  void close() => _dio.close();

  String get baseUrl => _baseUrl;
  String get apiToken => _apiToken;

  String _resolveUrl(String path) {
    if (isWeb && (!path.startsWith('/api/v1/') || path.startsWith('//'))) {
      throw ArgumentError('Web API requests must use /api/v1/');
    }
    return '$_baseUrl$path';
  }

  void updateConfig({String? baseUrl, String? apiToken}) {
    if (baseUrl != null) {
      _baseUrl = resolveBaseUrl(baseUrl);
    }
    if (apiToken != null) {
      _apiToken = apiToken;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        _resolveUrl(path),
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        _resolveUrl(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        _resolveUrl(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        _resolveUrl(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }
}
