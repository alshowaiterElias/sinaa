import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

/// Repository for notifications
class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  /// Get user's notifications (paginated)
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (unreadOnly) 'unread': 'true',
        },
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data['data'] as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(int id) async {
    try {
      await _dio.put(ApiEndpoints.notificationRead(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dio.put(ApiEndpoints.notificationsReadAll);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int id) async {
    try {
      await _dio.delete(ApiEndpoints.notification(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for notifications repository
final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationsRepository(dio);
});
