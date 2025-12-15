import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/providers/notifications_provider.dart';
import '../../../data/providers/auth_provider.dart';
import 'notification_item.dart';

/// Notifications screen
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    final l10n = context.l10n;
    final isRtl = context.isRtl;

    if (!isLoggedIn) {
      return _buildLoginPrompt(context, l10n);
    }

    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('notifications.title')),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: Text(l10n.tr('markAllRead')),
            ),
          IconButton(
            onPressed: () => ref
                .read(notificationsProvider.notifier)
                .loadNotifications(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(state, isRtl, l10n),
    );
  }

  Widget _buildBody(
      NotificationsState state, bool isRtl, AppLocalizations l10n) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(notificationsProvider.notifier)
                  .loadNotifications(refresh: true),
              child: Text(l10n.tr('retry')),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(notificationsProvider.notifier)
          .loadNotifications(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return NotificationItem(
            notification: notification,
            isRtl: isRtl,
            onTap: () => _handleNotificationTap(notification),
            onDelete: () => ref
                .read(notificationsProvider.notifier)
                .deleteNotification(notification.id),
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.tr('notifications.title'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withAlpha(38),
                      AppColors.primary.withAlpha(13),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 70,
                  color: AppColors.primary.withAlpha(128),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.tr('loginForNotifications'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tr('loginForNotificationsMessage'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(38),
                    AppColors.primary.withAlpha(13),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 70,
                color: AppColors.primary.withAlpha(128),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.tr('noNotifications'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tr('noNotificationsMessage'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(dynamic notification) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on notification type
    final data = notification.data as NotificationData?;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.message:
      case NotificationType.inquiry:
        if (data.conversationId != null) {
          context.push('/chat/${data.conversationId}');
        }
        break;
      case NotificationType.productApproval:
        if (data.productId != null) {
          context.push('/product/${data.productId}');
        } else {
          // Go to my project screen to see products
          context.push(Routes.myProject);
        }
        break;
      case NotificationType.projectApproval:
        // Navigate to my project screen
        context.push(Routes.myProject);
        break;
      case NotificationType.transaction:
        // TODO: Navigate to transaction details when implemented
        break;
      case NotificationType.review:
        // Navigate to my project to see reviews
        context.push(Routes.myProject);
        break;
    }
  }
}
