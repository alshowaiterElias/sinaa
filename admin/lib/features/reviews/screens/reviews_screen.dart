import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة التقييمات',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 10,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildReviewItem(context, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, int index) {
    final status = index % 3;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AdminColors.primary.withOpacity(0.1),
            child: Text(
              'أ',
              style: TextStyle(color: AdminColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'مستخدم ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < 4 ? Icons.star : Icons.star_border,
                        size: 16,
                        color: AdminColors.warning,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      'على منتج ${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'هذا المنتج رائع جداً وأنصح به بشدة. الجودة ممتازة والتوصيل كان سريع.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'منذ 3 ساعات',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (status == 0) ...[
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('موافقة'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.success,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('رفض'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    final statuses = ['قيد المراجعة', 'معتمد', 'مرفوض'];
    final bgColors = [AdminColors.pendingBg, AdminColors.approvedBg, AdminColors.rejectedBg];
    final textColors = [AdminColors.pendingText, AdminColors.approvedText, AdminColors.rejectedText];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColors[status],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statuses[status],
        style: TextStyle(
          color: textColors[status],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

