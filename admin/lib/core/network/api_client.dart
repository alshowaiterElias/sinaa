import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';
import 'api_endpoints.dart';

/// API Exception class
class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    required this.code,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'An unexpected error occurred';
    String code = 'UNKNOWN_ERROR';
    int? statusCode = error.response?.statusCode;

    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response?.data as Map;
      if (data['error'] != null) {
        message = data['error']['message'] ?? message;
        code = data['error']['code'] ?? code;
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timeout. Please check your internet connection.';
          code = 'TIMEOUT';
          break;
        case DioExceptionType.badResponse:
          message = 'Server error. Please try again later.';
          code = 'SERVER_ERROR';
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled';
          code = 'CANCELLED';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection. Please check your network.';
          code = 'NO_NETWORK';
          break;
        default:
          message = 'Something went wrong. Please try again.';
      }
    }

    return ApiException(
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}

/// Auth Interceptor for admin panel
class AdminAuthInterceptor extends Interceptor {
  final AdminLocalStorage _storage;
  final Dio _dio;

  AdminAuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final publicEndpoints = [
      ApiEndpoints.adminLogin,
      ApiEndpoints.refreshToken,
    ];

    if (!publicEndpoints.contains(options.path)) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final data = response.data['data'];
            await _storage.saveTokens(
              data['accessToken'],
              data['refreshToken'],
            );

            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
            
            final retryResponse = await _dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          await _storage.clearAll();
        }
      }
    }

    handler.next(err);
  }
}

/// Dio provider for admin panel
final adminDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(adminStorageProvider);
  
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AdminAuthInterceptor(storage, dio));
  
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print('[ADMIN DIO] $obj'),
  ));

  return dio;
});

