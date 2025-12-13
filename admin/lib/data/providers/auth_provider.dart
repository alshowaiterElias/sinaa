import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/admin_user.dart';

/// Admin auth state
class AdminAuthState {
  final AdminUser? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AdminAuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AdminAuthState copyWith({
    AdminUser? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearUser = false,
  }) {
    return AdminAuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// Admin auth notifier
class AdminAuthNotifier extends Notifier<AdminAuthState> {
  late Dio _dio;
  late AdminLocalStorage _storage;

  @override
  AdminAuthState build() {
    _dio = ref.watch(adminDioProvider);
    _storage = ref.watch(adminStorageProvider);
    return const AdminAuthState();
  }

  /// Initialize auth state
  Future<void> initAuth() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true);

    try {
      final isLoggedIn = await _storage.isLoggedIn();
      if (isLoggedIn) {
        try {
          final response = await _dio.get(ApiEndpoints.me);
          final data = response.data['data'];
          final user = AdminUser.fromJson(data['user']);

          if (!user.isAdmin) {
            await _storage.clearAll();
            state = state.copyWith(isLoading: false, isInitialized: true);
            return;
          }

          state = state.copyWith(
            user: user,
            isLoading: false,
            isInitialized: true,
          );
          return;
        } catch (_) {
          await _storage.clearAll();
        }
      }
    } catch (_) {
      // Continue as logged out
    }

    state = state.copyWith(isLoading: false, isInitialized: true);
  }

  /// Admin login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(ApiEndpoints.adminLogin, data: {
        'email': email,
        'password': password,
      });

      final data = response.data['data'];
      final user = AdminUser.fromJson(data['user']);

      if (!user.isAdmin) {
        state = state.copyWith(
          isLoading: false,
          error: 'Access denied. Admin credentials required.',
        );
        return;
      }

      await _storage.saveTokens(
        data['accessToken'],
        data['refreshToken'],
      );
      await _storage.saveUserData(user.toJson());

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore logout errors
    }

    await _storage.clearAll();
    state = const AdminAuthState(isInitialized: true);
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.put(ApiEndpoints.changePassword, data: {
        'currentPassword': currentPassword,
        'password': newPassword,
      });

      final data = response.data['data'];
      await _storage.saveTokens(
        data['accessToken'],
        data['refreshToken'],
      );

      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
      rethrow;
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final data = response.data['data'];
      final user = AdminUser.fromJson(data['user']);
      state = state.copyWith(user: user);
    } catch (_) {
      // Ignore refresh errors
    }
  }
}

// Providers
final adminAuthStateProvider =
    NotifierProvider<AdminAuthNotifier, AdminAuthState>(() {
  return AdminAuthNotifier();
});

final isAdminAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthStateProvider).isAuthenticated;
});

final currentAdminProvider = Provider<AdminUser?>((ref) {
  return ref.watch(adminAuthStateProvider).user;
});

