import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../repositories/notifications_repository.dart';
import '../services/socket_service.dart';

/// State for notifications
class NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifications notifier
class NotificationsNotifier extends Notifier<NotificationsState> {
  StreamSubscription? _notificationSubscription;

  @override
  NotificationsState build() {
    // Listen for real-time notifications
    final socketService = ref.watch(socketServiceProvider);
    _notificationSubscription?.cancel();
    _notificationSubscription =
        socketService.notificationStream.listen((notification) {
      _addNotification(notification);
    });

    ref.onDispose(() {
      _notificationSubscription?.cancel();
    });

    return const NotificationsState();
  }

  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  /// Load notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load unread count only
  Future<void> loadUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silently fail for badge count
    }
  }

  /// Mark single as read
  Future<void> markAsRead(int id) async {
    try {
      await _repository.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnread = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
      state = state.copyWith(notifications: updated, unreadCount: newUnread);
    } catch (e) {
      // Handle error
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      // Handle error
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int id) async {
    try {
      await _repository.deleteNotification(id);
      final wasUnread = state.notifications.any((n) => n.id == id && !n.isRead);
      final updated = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: wasUnread && state.unreadCount > 0
            ? state.unreadCount - 1
            : state.unreadCount,
      );
    } catch (e) {
      // Handle error
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      await _repository.deleteAll();
      state = state.copyWith(notifications: [], unreadCount: 0);
    } catch (e) {
      // Handle error
    }
  }

  void _addNotification(AppNotification notification) {
    // Add to beginning of list
    final updated = [notification, ...state.notifications];
    state = state.copyWith(
      notifications: updated,
      unreadCount: state.unreadCount + 1,
    );
  }
}

/// Provider for notifications
final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

/// Provider for unread count (for badge)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider.select((s) => s.unreadCount));
});

/// Initialize notifications listener when socket is connected
/// Watch this in home_screen to ensure real-time notifications work
final notificationInitProvider = Provider<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final isConnected = socketService.isConnected;

  if (isConnected) {
    // Force the notifier to build, which sets up the stream listener
    ref.watch(notificationsProvider);
    // Load unread count
    ref.read(notificationsProvider.notifier).loadUnreadCount();
  }
});
