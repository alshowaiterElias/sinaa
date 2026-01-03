import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../data/models/review.dart';
import '../../../data/providers/reviews_provider.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewsListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مراجعة التقييمات',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'إجمالي: ${state.total}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search and filters row
          Row(
            children: [
              // Search field selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.searchField,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('بحث في الكل')),
                      DropdownMenuItem(
                          value: 'comment', child: Text('التعليق')),
                      DropdownMenuItem(
                          value: 'userName', child: Text('اسم المستخدم')),
                      DropdownMenuItem(
                          value: 'productName', child: Text('اسم المنتج')),
                      DropdownMenuItem(
                          value: 'projectOwner', child: Text('اسم المتجر')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(reviewsListProvider.notifier)
                            .setSearchField(value);
                      }
                    },
                  ),
                ),
              ),
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(reviewsListProvider.notifier)
                                  .clearSearch();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(8)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (value) {
                    ref.read(reviewsListProvider.notifier).setSearch(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Status filter
              DropdownButton<String>(
                value: state.statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(
                      value: 'pending', child: Text('قيد المراجعة')),
                  DropdownMenuItem(value: 'approved', child: Text('معتمد')),
                  DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(reviewsListProvider.notifier)
                        .setStatusFilter(value);
                  }
                },
              ),
              const SizedBox(width: 16),
              // Sort by
              DropdownButton<String>(
                value: state.sortBy,
                items: const [
                  DropdownMenuItem(
                      value: 'pending_first',
                      child: Text('قيد المراجعة أولاً')),
                  DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                  DropdownMenuItem(value: 'oldest', child: Text('الأقدم')),
                  DropdownMenuItem(
                      value: 'rating_high', child: Text('الأعلى تقييماً')),
                  DropdownMenuItem(
                      value: 'rating_low', child: Text('الأقل تقييماً')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(reviewsListProvider.notifier).setSortBy(value);
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref
                    .read(reviewsListProvider.notifier)
                    .loadReviews(refresh: true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('حدث خطأ: ${state.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(reviewsListProvider.notifier)
                          .loadReviews(refresh: true),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.reviews.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد تقييمات',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.reviews.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final review = state.reviews[index];
                    return _buildReviewItem(context, review);
                  },
                ),
              ),
            ),

          // Pagination
          if (state.totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.page > 1
                        ? () => ref
                            .read(reviewsListProvider.notifier)
                            .loadReviews(page: state.page - 1)
                        : null,
                  ),
                  Text('صفحة ${state.page} من ${state.totalPages}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.page < state.totalPages
                        ? () => ref
                            .read(reviewsListProvider.notifier)
                            .loadReviews(page: state.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AdminColors.primary.withOpacity(0.1),
            backgroundImage: review.user?.avatarUrl != null
                ? NetworkImage(review.user!.avatarUrl!)
                : null,
            child: review.user?.avatarUrl == null
                ? Text(
                    review.user?.fullName.isNotEmpty == true
                        ? review.user!.fullName[0].toUpperCase()
                        : '؟',
                    style: TextStyle(
                        color: AdminColors.primary,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name and status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.user?.fullName ?? 'مستخدم غير معروف',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (review.user?.email != null)
                            Text(
                              review.user!.email!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(review.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Product info
                if (review.product != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (review.product!.posterImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              review.product!.posterImageUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image, size: 20),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.product!.nameAr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (review.product!.project != null)
                                Text(
                                  review.product!.project!.nameAr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // Rating stars
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 18,
                        color: AdminColors.warning,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${review.rating}/5',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                // Comment
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      review.comment!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Date and actions
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(review.createdAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Spacer(),
                    // Actions for pending reviews
                    if (review.status == ReviewStatus.pending) ...[
                      TextButton.icon(
                        onPressed: () => _approveReview(review.id),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('موافقة'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.success,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showRejectDialog(review),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('رفض'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.error,
                        ),
                      ),
                    ],
                    // Actions for approved/rejected reviews
                    if (review.status == ReviewStatus.approved)
                      TextButton.icon(
                        onPressed: () => _showRejectDialog(review),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('إلغاء الموافقة'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.error,
                        ),
                      ),
                    if (review.status == ReviewStatus.rejected)
                      TextButton.icon(
                        onPressed: () => _approveReview(review.id),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('استعادة'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.success,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReviewStatus status) {
    final bgColors = {
      ReviewStatus.pending: AdminColors.pendingBg,
      ReviewStatus.approved: AdminColors.approvedBg,
      ReviewStatus.rejected: AdminColors.rejectedBg,
    };
    final textColors = {
      ReviewStatus.pending: AdminColors.pendingText,
      ReviewStatus.approved: AdminColors.approvedText,
      ReviewStatus.rejected: AdminColors.rejectedText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColors[status],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(
          color: textColors[status],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _approveReview(int reviewId) async {
    final success =
        await ref.read(reviewsListProvider.notifier).approveReview(reviewId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تمت الموافقة على التقييم' : 'حدث خطأ'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(Review review) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض التقييم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من رفض هذا التقييم؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ref.read(reviewsListProvider.notifier).rejectReview(
                        review.id,
                        reason: reasonController.text.isNotEmpty
                            ? reasonController.text
                            : null,
                      );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم رفض التقييم' : 'حدث خطأ'),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
