import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// Auth state
class AuthState {
  final User? user;
  final Project? project;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.user,
    this.project,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isProjectOwner => user?.isProjectOwner ?? false;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    User? user,
    Project? project,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearUser = false,
    bool clearProject = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      project: clearProject ? null : (project ?? this.project),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// Auth notifier using Riverpod 3.x Notifier
class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _authRepository;
  late LocalStorage _storage;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(localStorageProvider);
    return const AuthState();
  }

  /// Initialize auth state from stored data
  Future<void> initAuth() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true);

    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        // Try to get user data from API
        try {
          final response = await _authRepository.getMe();
          state = state.copyWith(
            user: response.user,
            project: response.project,
            isLoading: false,
            isInitialized: true,
          );
          return;
        } catch (_) {
          // Token invalid, clear storage
          await _storage.clearAll();
        }
      }
    } catch (_) {
      // Error loading auth, continue as guest
    }

    state = state.copyWith(isLoading: false, isInitialized: true);
  }

  /// Register customer
  Future<void> register({
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        language: language,
        city: city,
        latitude: latitude,
        longitude: longitude,
        locationSharingEnabled: locationSharingEnabled,
      );

      state = state.copyWith(
        user: response.user,
        project: response.project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Register project owner
  Future<void> registerProjectOwner({
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.registerProjectOwner(
        email: email,
        password: password,
        fullName: fullName,
        projectName: projectName,
        projectNameAr: projectNameAr,
        city: city,
        phone: phone,
        language: language,
        description: description,
        descriptionAr: descriptionAr,
        latitude: latitude,
        longitude: longitude,
        workingHours: workingHours,
        socialLinks: socialLinks,
        userCity: userCity,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        coverImage: coverImage,
        locationSharingEnabled: locationSharingEnabled,
      );

      state = state.copyWith(
        user: response.user,
        project: response.project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );

      state = state.copyWith(
        user: response.user,
        project: response.project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.logout();
    } catch (_) {
      // Ignore logout errors
    }

    state = const AuthState(isInitialized: true);
  }

  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? language,
    String? city,
    double? latitude,
    double? longitude,
    bool? locationSharingEnabled,
    bool? notificationsEnabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.updateProfile(
        fullName: fullName,
        phone: phone,
        language: language,
        city: city,
        latitude: latitude,
        longitude: longitude,
        locationSharingEnabled: locationSharingEnabled,
        notificationsEnabled: notificationsEnabled,
      );

      await _storage.saveUserData(user.toJson());
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final response = await _authRepository.getMe();
      state = state.copyWith(
        user: response.user,
        project: response.project,
      );
    } catch (_) {
      // Ignore refresh errors
    }
  }
}

// Providers
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final currentProjectProvider = Provider<Project?>((ref) {
  return ref.watch(authStateProvider).project;
});

final isProjectOwnerProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isProjectOwner;
});
