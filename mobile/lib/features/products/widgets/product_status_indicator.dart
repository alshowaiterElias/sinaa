import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

/// Product Status Indicator - shows pending/rejected/approved status
class ProductStatusIndicator extends StatelessWidget {
  final String status;
  final String? rejectionReason;
  final bool showBadge;

  const ProductStatusIndicator({
    super.key,
    required this.status,
    this.rejectionReason,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.access_time;
        label = isRtl ? 'قيد المراجعة' : 'Pending Review';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        label = isRtl ? 'مرفوض' : 'Rejected';
        break;
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        label = isRtl ? 'موافق عليه' : 'Approved';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
        label = status;
    }

    if (showBadge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Full banner for rejected products
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (status == 'rejected' && rejectionReason != null) ...[
            const SizedBox(height: 12),
            Text(
              isRtl ? 'سبب الرفض:' : 'Rejection reason:',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rejectionReason!,
              style: TextStyle(color: textColor),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 8),
            Text(
              isRtl
                  ? 'منتجك قيد المراجعة من قبل الإدارة. سيتم إشعارك فور الموافقة عليه.'
                  : 'Your product is under review by the admin team. You will be notified once approved.',
              style: TextStyle(color: textColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pending Products Banner - shows at top of owner's product list
class PendingProductsBanner extends StatelessWidget {
  final int pendingCount;

  const PendingProductsBanner({
    super.key,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    if (pendingCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl
                      ? '$pendingCount منتج قيد المراجعة'
                      : '$pendingCount product(s) pending review',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRtl
                      ? 'ستظهر المنتجات للجميع بعد الموافقة'
                      : 'Products will be visible after approval',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
