class AppConstants {
  AppConstants._();

  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const String socketUrl = 'http://localhost:3000';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Settings
  static const int maxProductImages = 4;
  static const int maxImageSizeKb = 5120; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Cache Duration
  static const Duration categoriesCacheDuration = Duration(hours: 24);
  static const Duration productsCacheDuration = Duration(minutes: 15);

  // Search
  static const int searchDebounceMs = 500;
  static const double defaultSearchRadiusKm = 50.0;
}

class UserRoles {
  UserRoles._();

  static const String customer = 'customer';
  static const String projectOwner = 'project_owner';
  static const String admin = 'admin';
}

class ProjectStatus {
  ProjectStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class ProductStatus {
  ProductStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class TransactionStatus {
  TransactionStatus._();

  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String disputed = 'disputed';
  static const String cancelled = 'cancelled';
}
