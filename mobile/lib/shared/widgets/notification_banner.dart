import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_model.dart';
import '../../data/services/socket_service.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../core/localization/app_localizations.dart';

/// Global navigator key for navigation from outside router context
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// A wrapper widget that shows in-app notification banners when new notifications arrive
class NotificationBannerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationBannerWrapper({super.key, required this.child});

  @override
  ConsumerState<NotificationBannerWrapper> createState() =>
      _NotificationBannerWrapperState();
}

class _NotificationBannerWrapperState
    extends ConsumerState<NotificationBannerWrapper> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    final socketService = ref.read(socketServiceProvider);
    socketService.notificationStream.listen((notification) {
      if (mounted) {
        _showNotificationBanner(notification);
      }
    });
  }

  void _navigateToNotifications() {
    // Hide the banner first
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    // Use the router from ref instead of context
    final router = ref.read(routerProvider);
    router.push(Routes.notifications);
  }

  void _showNotificationBanner(AppNotification notification) {
    final l10n = context.l10n;
    final isArabic = l10n.locale.languageCode == 'ar';

    final title = isArabic ? notification.titleAr : notification.title;
    final body =
        isArabic ? (notification.bodyAr ?? '') : (notification.body ?? '');

    // Show material banner from top
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.surface,
        elevation: 4,
        padding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIconForType(notification.type),
            color: AppColors.primary,
            size: 24,
          ),
        ),
        content: GestureDetector(
          onTap: _navigateToNotifications,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text(
              isArabic ? 'إغلاق' : 'Dismiss',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: _navigateToNotifications,
            child: Text(
              isArabic ? 'عرض' : 'View',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.inquiry:
        return Icons.help_outline;
      case NotificationType.transaction:
        return Icons.payment;
      case NotificationType.review:
        return Icons.star_outline;
      case NotificationType.projectApproval:
        return Icons.business_center_outlined;
      case NotificationType.productApproval:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
