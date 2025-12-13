import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage keys
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'admin_access_token';
  static const String refreshToken = 'admin_refresh_token';
  static const String userData = 'admin_user_data';
  static const String themeMode = 'admin_theme_mode';
  static const String language = 'admin_language';
}

/// Admin Local Storage for web
class AdminLocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Token management
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.accessToken, accessToken);
    await prefs.setString(StorageKeys.refreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.accessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await _preferences;
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.refreshToken);
  }

  // User data management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.userData, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _preferences;
    final data = prefs.getString(StorageKeys.userData);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearUserData() async {
    final prefs = await _preferences;
    await prefs.remove(StorageKeys.userData);
  }

  // Theme management
  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.themeMode, themeMode);
  }

  Future<String> getThemeMode() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.themeMode) ?? 'light';
  }

  // Language management
  Future<void> saveLanguage(String languageCode) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.language, languageCode);
  }

  Future<String> getLanguage() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.language) ?? 'ar';
  }

  // Clear all data
  Future<void> clearAll() async {
    await clearTokens();
    await clearUserData();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

/// Admin storage provider
final adminStorageProvider = Provider<AdminLocalStorage>((ref) {
  return AdminLocalStorage();
});

