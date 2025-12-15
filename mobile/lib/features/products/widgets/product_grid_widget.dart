import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product_model.dart';

/// Product Grid Widget - displays products in a stunning grid layout
class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final Function(Product)? onProductTap;
  final int crossAxisCount;
  final double childAspectRatio;

  const ProductGridWidget({
    super.key,
    required this.products,
    this.scrollController,
    this.isLoadingMore = false,
    this.onProductTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.68,
  });

  String _getImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    final baseUrl = ApiEndpoints.baseUrl.replaceFirst('/api/v1', '');
    return '$baseUrl$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return _ProductGridCard(
                  product: product,
                  onTap: () => onProductTap?.call(product),
                  isRtl: isRtl,
                  getImageUrl: _getImageUrl,
                );
              },
              childCount: products.length,
            ),
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool isRtl;
  final String Function(String) getImageUrl;

  const _ProductGridCard({
    required this.product,
    this.onTap,
    required this.isRtl,
    required this.getImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Gradient Overlay
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Product Image
                      if (product.posterImageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: getImageUrl(product.posterImageUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withAlpha(30),
                                  AppColors.primaryDark.withAlpha(30),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.surfaceVariant,
                                  AppColors.surfaceVariant.withAlpha(200),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: AppColors.textTertiary.withAlpha(100),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withAlpha(20),
                                AppColors.primaryDark.withAlpha(40),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: AppColors.primary.withAlpha(100),
                            ),
                          ),
                        ),

                      // Gradient overlay at bottom for text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(60),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Price Badge
                      Positioned(
                        bottom: 8,
                        left: isRtl ? null : 8,
                        right: isRtl ? 8 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${product.basePrice.toStringAsFixed(0)} SAR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Rating Badge (if has reviews)
                      if (product.totalReviews > 0)
                        Positioned(
                          top: 8,
                          right: isRtl ? null : 8,
                          left: isRtl ? 8 : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  product.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Status badge (pending or rejected) - for owners
                      if (product.isPending || product.isRejected)
                        Positioned(
                          top: 8,
                          left: isRtl ? null : 8,
                          right: isRtl ? 8 : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: product.isRejected
                                    ? [Colors.red.shade600, Colors.red.shade800]
                                    : [
                                        Colors.orange.shade500,
                                        Colors.orange.shade700
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (product.isRejected
                                          ? Colors.red
                                          : Colors.orange)
                                      .withAlpha(80),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.isRejected
                                      ? Icons.cancel_rounded
                                      : Icons.schedule_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.isRejected
                                      ? (isRtl ? 'مرفوض' : 'Rejected')
                                      : (isRtl ? 'قيد المراجعة' : 'Pending'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Out of stock overlay
                      if (!product.isAvailable)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRtl ? 'غير متوفر' : 'Sold Out',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Info Section
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withAlpha(50),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          isRtl ? product.nameAr : product.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Seller/Project info
                        if (product.project != null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isRtl
                                      ? product.project!.nameAr
                                      : product.project!.name,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
