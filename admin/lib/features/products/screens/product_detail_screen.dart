import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product.dart';
import '../../../data/providers/products_provider.dart';
import '../widgets/reject_dialog.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProduct = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productDetailProvider(productId)),
          ),
        ],
      ),
      body: asyncProduct.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error.toString()),
        data: (product) => _buildContent(context, ref, product),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AdminColors.error),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(productDetailProvider(productId)),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Product product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Images
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildImageSection(context, product),
                const SizedBox(height: 24),
                _buildVariantsSection(context, product),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column - Details
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(context, product),
                const SizedBox(height: 24),
                _buildDetailsCard(context, product),
                const SizedBox(height: 24),
                _buildProjectSection(context, product),
                const SizedBox(height: 24),
                _buildTagsSection(context, product),
                const SizedBox(height: 24),
                _buildActionsSection(context, ref, product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, Product product) {
    final allImages = [
      if (product.posterImageUrl.isNotEmpty) product.posterImageUrl,
      ...product.images.map((i) => i.imageUrl),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الصور', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (allImages.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AdminColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      size: 48, color: AdminColors.textTertiary),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  final imageUrl =
                      '${ApiEndpoints.baseUrl.replaceFirst('/api/v1', '')}${allImages[index]}';
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: index == 0
                          ? Border.all(color: AdminColors.primary, width: 2)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AdminColors.surfaceVariant,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                          if (index == 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'رئيسية',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsSection(BuildContext context, Product product) {
    if (product.variants.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المتغيرات (${product.variants.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...product.variants.map((variant) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(variant.nameAr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(variant.name,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(
                        '${variant.priceModifier >= 0 ? '+' : ''}${variant.priceModifier.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          color: variant.priceModifier >= 0
                              ? AdminColors.success
                              : AdminColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: variant.isAvailable
                              ? AdminColors.approvedBg
                              : AdminColors.rejectedBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'الكمية: ${variant.quantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: variant.isAvailable
                                ? AdminColors.approvedText
                                : AdminColors.rejectedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nameAr,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AdminColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(product),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${product.basePrice.toStringAsFixed(2)} ر.س',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AdminColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('${product.averageRating.toStringAsFixed(1)}'),
                    Text(' (${product.totalReviews} تقييم)',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.visibility,
                        size: 20, color: AdminColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${product.viewCount}'),
                  ],
                ),
              ],
            ),
            if (product.rejectionReason != null &&
                product.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: product.isDisabled
                      ? AdminColors.warning.withOpacity(0.1)
                      : AdminColors.rejectedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      product.isDisabled ? Icons.block : Icons.info_outline,
                      color: product.isDisabled
                          ? AdminColors.warning
                          : AdminColors.rejectedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.isDisabled
                            ? 'سبب التعطيل: ${product.disableReason}'
                            : 'سبب الرفض: ${product.rejectionReason}',
                        style: TextStyle(
                          color: product.isDisabled
                              ? AdminColors.warning
                              : AdminColors.rejectedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Product product) {
    Color bgColor;
    Color textColor;
    String label;

    if (product.isDisabled) {
      bgColor = AdminColors.textTertiary.withOpacity(0.2);
      textColor = AdminColors.textSecondary;
      label = 'معطل';
    } else {
      switch (product.status) {
        case ProductStatus.pending:
          bgColor = AdminColors.pendingBg;
          textColor = AdminColors.pendingText;
          label = 'قيد المراجعة';
          break;
        case ProductStatus.approved:
          bgColor = AdminColors.approvedBg;
          textColor = AdminColors.approvedText;
          label = 'معتمد';
          break;
        case ProductStatus.rejected:
          bgColor = AdminColors.rejectedBg;
          textColor = AdminColors.rejectedText;
          label = 'مرفوض';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوصف', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (product.descriptionAr != null &&
                product.descriptionAr!.isNotEmpty) ...[
              Text(product.descriptionAr!,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              Text(
                product.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AdminColors.textSecondary),
              ),
            ],
            if ((product.description == null || product.description!.isEmpty) &&
                (product.descriptionAr == null ||
                    product.descriptionAr!.isEmpty))
              Text(
                'لا يوجد وصف',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow('الكمية المتوفرة', '${product.quantity}'),
            _buildDetailRow('متوفر',
                product.isAvailable && !product.isDisabled ? 'نعم' : 'لا'),
            _buildDetailRow('تاريخ الإنشاء',
                '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AdminColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProjectSection(BuildContext context, Product product) {
    if (product.project == null) return const SizedBox.shrink();
    final project = product.project!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المشروع', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: AdminColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.nameAr,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(project.city,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (project.owner != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(project.owner!.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(project.owner!.email,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, Product product) {
    if (product.tags.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوسوم', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.tags
                  .map((tag) => Chip(
                        label: Text(tag.nameAr),
                        backgroundColor: AdminColors.surfaceVariant,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, WidgetRef ref, Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإجراءات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                if (product.status == ProductStatus.pending)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('اعتماد'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.success),
                      onPressed: () => _approveProduct(context, ref, product),
                    ),
                  ),
                if (product.status == ProductStatus.pending)
                  const SizedBox(width: 12),
                if (product.status == ProductStatus.pending)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.error),
                      onPressed: () => _rejectProduct(context, ref, product),
                    ),
                  ),
                if (product.status == ProductStatus.approved &&
                    !product.isDisabled)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.block),
                      label: const Text('تعطيل'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.warning),
                      onPressed: () => _disableProduct(context, ref, product),
                    ),
                  ),
                if (product.isDisabled)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('تفعيل'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.success),
                      onPressed: () => _enableProduct(context, ref, product),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveProduct(
      BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاعتماد'),
        content: Text('هل تريد اعتماد منتج "${product.nameAr}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('اعتماد')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(productsListProvider.notifier)
          .approveProduct(product.id);
      if (success) {
        ref.invalidate(productDetailProvider(productId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم اعتماد المنتج بنجاح'),
            backgroundColor: AdminColors.success,
          ));
        }
      }
    }
  }

  Future<void> _rejectProduct(
      BuildContext context, WidgetRef ref, Product product) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) =>
          RejectDialog(title: 'رفض المنتج', itemName: product.nameAr),
    );

    if (reason != null && reason.isNotEmpty) {
      final success = await ref
          .read(productsListProvider.notifier)
          .rejectProduct(product.id, reason);
      if (success) {
        ref.invalidate(productDetailProvider(productId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم رفض المنتج'),
            backgroundColor: AdminColors.error,
          ));
        }
      }
    }
  }

  Future<void> _disableProduct(
      BuildContext context, WidgetRef ref, Product product) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => RejectDialog(
        title: 'تعطيل المنتج',
        itemName: product.nameAr,
        reasonLabel: 'سبب التعطيل',
        confirmLabel: 'تعطيل',
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      final success = await ref
          .read(productsListProvider.notifier)
          .disableProduct(product.id, reason);
      if (success) {
        ref.invalidate(productDetailProvider(productId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تعطيل المنتج'),
            backgroundColor: AdminColors.warning,
          ));
        }
      }
    }
  }

  Future<void> _enableProduct(
      BuildContext context, WidgetRef ref, Product product) async {
    final success =
        await ref.read(productsListProvider.notifier).enableProduct(product.id);
    if (success) {
      ref.invalidate(productDetailProvider(productId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تفعيل المنتج'),
          backgroundColor: AdminColors.success,
        ));
      }
    }
  }
}
