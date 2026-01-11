import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../data/models/review_model.dart';
import '../../../data/providers/reviews_provider.dart';

/// Widget to display product reviews section
class ProductReviewsSection extends ConsumerWidget {
  final int productId;
  final bool isRtl;
  final bool isOwner;
  final Function(Review)? onReportComment;

  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.isRtl,
    this.isOwner = false,
    this.onReportComment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.reviews_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isRtl ? 'التقييمات والمراجعات' : 'Reviews & Ratings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reviews Content
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isRtl ? 'خطأ في تحميل التقييمات' : 'Error loading reviews',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(productReviewsProvider(productId)),
                  child: Text(isRtl ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
          data: (response) {
            if (response.reviews.isEmpty) {
              return _buildNoReviews(context, response);
            }
            return Column(
              children: [
                // Rating Summary Card
                _buildRatingSummary(response),
                const SizedBox(height: 16),
                // Reviews List
                ...response.reviews.take(5).map((review) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReviewCard(review),
                    )),
                if (response.reviews.length > 5)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all reviews screen
                    },
                    child: Text(
                      isRtl
                          ? 'عرض جميع التقييمات (${response.totalReviews})'
                          : 'View all reviews (${response.totalReviews})',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoReviews(BuildContext context, ReviewsResponse response) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'لا توجد تقييمات بعد' : 'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRtl
                ? 'كن أول من يقيم هذا المنتج!'
                : 'Be the first to review this product!',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(ReviewsResponse response) {
    final rating = response.averageRating;
    final count = response.totalReviews;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return Icon(
                    starValue <= rating
                        ? Icons.star_rounded
                        : starValue - rating < 1
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Review count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'بناءً على' : 'Based on',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isRtl ? '$count تقييم' : '$count reviews',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final dateFormat = DateFormat('yyyy/MM/dd', isRtl ? 'ar' : 'en');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withAlpha(50),
                backgroundImage: review.user?.avatarUrl != null
                    ? NetworkImage(review.user!.avatarUrl!)
                    : null,
                child: review.user?.avatarUrl == null
                    ? Text(
                        review.user?.fullName.isNotEmpty == true
                            ? review.user!.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user?.fullName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dateFormat.format(review.createdAt),
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${review.rating}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          if (isOwner && onReportComment != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => onReportComment!(review),
                icon: const Icon(Icons.flag_outlined,
                    size: 18, color: Colors.red),
                label: Text(
                  isRtl ? 'إبلاغ عن تعليق' : 'Report Comment',
                  style: const TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
