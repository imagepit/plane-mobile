import 'package:dio/dio.dart';
import 'package:plane_mobile/core/constants/app_constants.dart';
import 'package:plane_mobile/core/network/api_interceptor.dart';

class DioClient {
  late Dio _dio;
  String _baseUrl = AppConstants.defaultBaseUrl;
  String _apiToken = '';

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(ApiInterceptor(this));
  }

  String get baseUrl => _baseUrl;
  String get apiToken => _apiToken;

  String _resolveUrl(String path) {
    return '$_baseUrl$path';
  }

  void updateConfig({String? baseUrl, String? apiToken}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
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