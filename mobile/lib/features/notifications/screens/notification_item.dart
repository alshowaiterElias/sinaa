import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../data/models/notification_model.dart';

/// Notification item widget
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final bool isRtl;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isRtl,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final locale = isRtl ? 'ar' : 'en';
    final title = notification.getLocalizedTitle(locale);
    final body = notification.getLocalizedBody(locale);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primary.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(color: AppColors.primary.withAlpha(51)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        if (body != null && body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.createdAt, isRtl),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case NotificationType.message:
      case NotificationType.inquiry:
        iconData = Icons.chat_bubble_rounded;
        color = AppColors.secondary;
        break;
      case NotificationType.transaction:
        iconData = Icons.receipt_long_rounded;
        color = AppColors.success;
        break;
      case NotificationType.review:
        iconData = Icons.star_rounded;
        color = Colors.amber;
        break;
      case NotificationType.projectApproval:
        iconData = Icons.storefront_rounded;
        color = AppColors.primary;
        break;
      case NotificationType.productApproval:
        iconData = Icons.inventory_2_rounded;
        color = AppColors.primary;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _formatTime(DateTime date, bool isRtl) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return isRtl ? 'الآن' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return isRtl ? 'منذ $mins دقيقة' : '$mins min ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return isRtl ? 'منذ $hours ساعة' : '$hours hr ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return isRtl ? 'منذ $days يوم' : '$days days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
