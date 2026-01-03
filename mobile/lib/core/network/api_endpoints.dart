import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// API Endpoints for Sina'a
class ApiEndpoints {
  ApiEndpoints._();

  // ============================================================
  // BASE URL CONFIGURATION
  // ============================================================
  //
  // For PHYSICAL DEVICE testing: Use your computer's IP address
  // Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)
  // Make sure your phone and computer are on the SAME WiFi network!
  //
  // Current LAN IP: 192.168.43.148 (update if changed)
  // ============================================================

  static const String _lanIp = '192.168.43.148'; // <-- UPDATE THIS with your IP
  static const String _port = '3000';
  static const String _apiPath = '/api/v1';

  /// Automatically detect the correct base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web: use localhost
      return 'http://localhost:$_port$_apiPath';
    }

    if (kDebugMode) {
      // Debug mode on mobile
      if (Platform.isAndroid) {
        // For Android: Use LAN IP for physical device
        // 10.0.2.2 is for emulator only!
        return 'http://$_lanIp:$_port$_apiPath';
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost, physical device needs LAN IP
        return 'http://$_lanIp:$_port$_apiPath';
      }
    }

    // Production
    return 'https://api.sinaa.sa$_apiPath';
  }

  /// Server base URL for images and uploads (without /api/v1)
  static String get serverBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }

    if (kDebugMode) {
      return 'http://$_lanIp:$_port';
    }

    return 'https://api.sinaa.sa';
  }

  /// Get full image URL from relative path
  static String imageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    // Already a full URL
    if (relativePath.startsWith('http')) {
      return relativePath;
    }
    return '$serverBaseUrl$relativePath';
  }

  /// For debugging: print the current base URL
  static void printConfig() {
    print('═══════════════════════════════════════════════════════════');
    print('📡 API CONFIGURATION');
    print('═══════════════════════════════════════════════════════════');
    print('Base URL: $baseUrl');
    print('Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    print('Debug Mode: $kDebugMode');
    print('LAN IP: $_lanIp');
    print('═══════════════════════════════════════════════════════════');
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String registerProjectOwner = '/auth/register/project-owner';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Categories endpoints
  static const String categories = '/categories';
  static String categoryById(int id) => '/categories/$id';
  static String categoryProducts(int id) => '/categories/$id/products';

  // Products endpoints
  static const String products = '/products';
  static String productDetail(int id) => '/products/$id';
  static const String productsSearch = '/products/search';
  static const String productsNearby = '/products/nearby';
  static String productReviews(int id) => '/products/$id/reviews';

  // Projects endpoints
  static const String projects = '/projects';
  static String projectDetail(int id) => '/projects/$id';
  static String projectProducts(int id) => '/projects/$id/products';
  static const String myProject = '/projects/my-project';

  // Cart endpoints
  static const String cart = '/cart';
  static String cartItem(int id) => '/cart/$id';
  static const String cartCount = '/cart/count';
  static const String cartSendInquiries = '/cart/send-inquiries';

  // Conversations endpoints
  static const String conversations = '/conversations';
  static String conversation(int id) => '/conversations/$id';
  static String conversationMessages(int id) => '/conversations/$id/messages';
  static String conversationRead(int id) => '/conversations/$id/read';

  // Transactions endpoints
  static const String transactions = '/transactions';
  static String transactionConfirm(int id) => '/transactions/$id/confirm';
  static String transactionDispute(int id) => '/transactions/$id/dispute';

  // Reviews endpoints
  static const String reviews = '/reviews';
  static String review(int id) => '/reviews/$id';

  // Support endpoints
  static const String supportTickets = '/support/tickets';
  static String supportTicket(int id) => '/support/tickets/$id';

  // Notifications endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notification(int id) => '/notifications/$id';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Favorites endpoints
  static const String favorites = '/favorites';

  // Health check
  static const String health = '/health';
}
