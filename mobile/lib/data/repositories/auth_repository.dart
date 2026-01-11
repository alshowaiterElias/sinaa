import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/user.dart';

/// Auth Repository - handles all authentication API calls
class AuthRepository {
  final Dio _dio;
  final LocalStorage _storage;

  AuthRepository(this._dio, this._storage);

  /// Register a new customer
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String language = 'ar',
    String? city,
    double? latitude,
    double? longitude,
    bool locationSharingEnabled = true,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.register, data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phone != null) 'phone': phone,
        'language': language,
        if (city != null) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'locationSharingEnabled': locationSharingEnabled,
      });

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Register a new project owner
  Future<AuthResponse> registerProjectOwner({
    required String email,
    required String password,
    required String fullName,
    required String projectName,
    required String projectNameAr,
    required String city,
    String? phone,
    String language = 'ar',
    String? description,
    String? descriptionAr,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? workingHours,
    Map<String, dynamic>? socialLinks,
    // User location fields
    String? userCity,
    double? userLatitude,
    double? userLongitude,
    File? coverImage,
    bool locationSharingEnabled = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'email': email,
        'password': password,
        'fullName': fullName,
        'projectName': projectName,
        'projectNameAr': projectNameAr,
        'city': city,
        if (phone != null) 'phone': phone,
        'language': language,
        if (description != null) 'description': description,
        if (descriptionAr != null) 'descriptionAr': descriptionAr,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (workingHours != null) 'workingHours': workingHours,
        if (socialLinks != null) 'socialLinks': socialLinks,
        if (userCity != null) 'userCity': userCity,
        if (userLatitude != null) 'userLatitude': userLatitude,
        if (userLongitude != null) 'userLongitude': userLongitude,
        'locationSharingEnabled': locationSharingEnabled,
      });

      if (coverImage != null) {
        formData.files.add(MapEntry(
          'coverImage',
          await MultipartFile.fromFile(coverImage.path),
        ));
      }

      final response = await _dio.post(
        ApiEndpoints.registerProjectOwner,
        data: formData,
      );

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _storage.clearAll();
    }
  }

  /// Get current user profile
  Future<AuthResponse> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return _handleAuthResponse(response, saveTokens: false);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? language,
    String? city,
    double? latitude,
    double? longitude,
    bool? locationSharingEnabled,
    bool? notificationsEnabled,
  }) async {
    try {
      final response = await _dio.put(ApiEndpoints.me, data: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (language != null) 'language': language,
        if (city != null) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationSharingEnabled != null)
          'locationSharingEnabled': locationSharingEnabled,
        if (notificationsEnabled != null)
          'notificationsEnabled': notificationsEnabled,
      });

      final data = response.data['data'];
      return User.fromJson(data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Change password
  Future<AuthTokens> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(ApiEndpoints.changePassword, data: {
        'currentPassword': currentPassword,
        'password': newPassword,
      });

      final data = response.data['data'];
      final tokens = AuthTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);
      return tokens;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: {
        'token': token,
        'password': password,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Refresh access token
  Future<AuthTokens> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw ApiException(
          message: 'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
        );
      }

      final response = await _dio.post(ApiEndpoints.refreshToken, data: {
        'refreshToken': refreshToken,
      });

      final data = response.data['data'];
      final tokens = AuthTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);
      return tokens;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Handle auth response and save tokens
  Future<AuthResponse> _handleAuthResponse(
    Response response, {
    bool saveTokens = true,
  }) async {
    final data = response.data['data'];

    final user = User.fromJson(data['user']);

    Project? project;
    if (data['project'] != null) {
      project = Project.fromJson(data['project']);
    }

    if (saveTokens && data['accessToken'] != null) {
      await _storage.saveTokens(
        data['accessToken'],
        data['refreshToken'],
      );
      await _storage.saveUserData(user.toJson());
    }

    return AuthResponse(
      user: user,
      project: project,
      tokens: saveTokens && data['accessToken'] != null
          ? AuthTokens(
              accessToken: data['accessToken'],
              refreshToken: data['refreshToken'],
            )
          : null,
    );
  }
}

/// Auth response model
class AuthResponse {
  final User user;
  final Project? project;
  final AuthTokens? tokens;

  AuthResponse({
    required this.user,
    this.project,
    this.tokens,
  });
}

/// Auth tokens model
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(localStorageProvider);
  return AuthRepository(dio, storage);
});
