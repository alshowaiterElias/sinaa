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

/// Auth Interceptor - handles token injection and refresh
class AuthInterceptor extends Interceptor {
  final LocalStorage _storage;
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for public endpoints
    final publicEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.registerProjectOwner,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.resetPassword,
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
    // Handle 401 - try to refresh token
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          // Try to refresh the token
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

            // Retry the original request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
            
            final retryResponse = await _dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed, clear tokens
          await _storage.clearTokens();
        }
      }
    }

    handler.next(err);
  }
}

/// Dio provider with configuration
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(localStorageProvider);
  
  // Print API configuration on initialization
  ApiEndpoints.printConfig();
  
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

  // Add interceptors
  dio.interceptors.add(AuthInterceptor(storage, dio));
  
  // Add detailed logging interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      print('');
      print('┌───────────────────────────────────────────────────────────');
      print('│ 🚀 REQUEST: ${options.method} ${options.uri}');
      print('├───────────────────────────────────────────────────────────');
      print('│ Headers: ${options.headers}');
      if (options.data != null) {
        print('│ Body: ${options.data}');
      }
      print('└───────────────────────────────────────────────────────────');
      handler.next(options);
    },
    onResponse: (response, handler) {
      print('');
      print('┌───────────────────────────────────────────────────────────');
      print('│ ✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('├───────────────────────────────────────────────────────────');
      print('│ Data: ${response.data}');
      print('└───────────────────────────────────────────────────────────');
      handler.next(response);
    },
    onError: (error, handler) {
      print('');
      print('┌───────────────────────────────────────────────────────────');
      print('│ ❌ ERROR: ${error.type}');
      print('├───────────────────────────────────────────────────────────');
      print('│ URL: ${error.requestOptions.uri}');
      print('│ Message: ${error.message}');
      if (error.response != null) {
        print('│ Status: ${error.response?.statusCode}');
        print('│ Data: ${error.response?.data}');
      }
      print('│');
      print('│ 💡 TROUBLESHOOTING:');
      print('│ 1. Is backend running? (npm run dev)');
      print('│ 2. Is phone on same WiFi as computer?');
      print('│ 3. Is firewall blocking port 3000?');
      print('│ 4. Try: curl ${error.requestOptions.uri}');
      print('└───────────────────────────────────────────────────────────');
      handler.next(error);
    },
  ));

  return dio;
});
