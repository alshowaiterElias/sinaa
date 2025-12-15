import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/transaction_provider.dart';
import 'product_form_screen.dart';
import 'package:go_router/go_router.dart';

/// Product Detail Screen - displays product information
/// Shows different UI for owners vs customers
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  final bool isOwner;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isOwner = false,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _error;
  int _selectedVariantIndex = -1;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(productsRepositoryProvider);
      final product = await repository.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    final baseUrl = ApiEndpoints.baseUrl.replaceFirst('/api/v1', '');
    return '$baseUrl$imageUrl';
  }

  double get _totalPrice {
    if (_product == null) return 0;
    double price = _product!.basePrice;
    if (_selectedVariantIndex >= 0 &&
        _selectedVariantIndex < _product!.variants.length) {
      price += _product!.variants[_selectedVariantIndex].priceModifier;
    }
    return price;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? context.tr('error')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    // Show different UI for owner vs customer
    return widget.isOwner ? _buildOwnerView() : _buildCustomerView();
  }

  // ============ OWNER VIEW ============
  Widget _buildOwnerView() {
    final product = _product!;
    final isRtl = context.isRtl;
    final allImages = [
      product.posterImageUrl,
      ...product.images.map((img) => img.imageUrl),
    ].where((url) => url.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Compact App Bar with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (allImages.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _getImageUrl(allImages[0]),
                      fit: BoxFit.cover,
                    ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(100),
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                  // Product name and status at bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(product),
                        const SizedBox(height: 8),
                        Text(
                          isRtl ? product.nameAr : product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => _navigateToEdit(),
              ),
            ],
          ),

          // Analytics Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rejection Banner (if rejected)
                  if (product.isRejected && product.rejectionReason != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade50,
                            Colors.red.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'سبب الرفض' : 'Rejection Reason',
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.rejectionReason!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Analytics Section Title
                  Text(
                    isRtl ? 'إحصائيات المنتج' : 'Product Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Analytics Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          icon: Icons.visibility_rounded,
                          iconColor: Colors.blue,
                          value: '${product.viewCount}',
                          label: isRtl ? 'المشاهدات' : 'Views',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                          value: product.averageRating.toStringAsFixed(1),
                          label: isRtl ? 'التقييم' : 'Rating',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          icon: Icons.reviews_rounded,
                          iconColor: Colors.purple,
                          value: '${product.totalReviews}',
                          label: isRtl ? 'التقييمات' : 'Reviews',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          icon: Icons.inventory_2_rounded,
                          iconColor: product.quantity > 5
                              ? Colors.green
                              : product.quantity > 0
                                  ? Colors.orange
                                  : Colors.red,
                          value: '${product.quantity}',
                          label: isRtl ? 'المخزون' : 'In Stock',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Product Details Section
                  Text(
                    isRtl ? 'تفاصيل المنتج' : 'Product Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Price Card
                  _buildDetailCard(
                    children: [
                      _buildDetailRow(
                        icon: Icons.payments_rounded,
                        label: isRtl ? 'السعر الأساسي' : 'Base Price',
                        value: '${product.basePrice.toStringAsFixed(2)} SAR',
                        valueColor: AppColors.primary,
                      ),
                      if (product.variants.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.style_rounded,
                          label: isRtl ? 'المتغيرات' : 'Variants',
                          value: '${product.variants.length}',
                        ),
                      ],
                      if (product.tags.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.tag_rounded,
                          label: isRtl ? 'الوسوم' : 'Tags',
                          value: product.tags
                              .map((t) => isRtl ? t.nameAr : t.name)
                              .join(', '),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description Card
                  if (product.description?.isNotEmpty == true ||
                      product.descriptionAr?.isNotEmpty == true)
                    _buildDetailCard(
                      children: [
                        Text(
                          isRtl ? 'الوصف' : 'Description',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRtl
                              ? (product.descriptionAr ??
                                  product.description ??
                                  '')
                              : (product.description ?? ''),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    isRtl ? 'إجراءات سريعة' : 'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.edit_rounded,
                          label: isRtl ? 'تعديل' : 'Edit',
                          color: Colors.teal,
                          onTap: _navigateToEdit,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Product product) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;
    final isRtl = context.isRtl;

    if (product.isRejected) {
      bgColor = Colors.red;
      textColor = Colors.white;
      icon = Icons.cancel_rounded;
      text = isRtl ? 'مرفوض' : 'Rejected';
    } else if (product.isPending) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      icon = Icons.schedule_rounded;
      text = isRtl ? 'قيد المراجعة' : 'Pending';
    } else {
      bgColor = Colors.green;
      textColor = Colors.white;
      icon = Icons.check_circle_rounded;
      text = isRtl ? 'معتمد' : 'Approved';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
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

  Widget _buildDetailCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit() async {
    final product = _product!;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          projectId: product.projectId,
          product: product,
        ),
      ),
    );
    if (result == true) {
      _loadProduct();
    }
  }

  // ============ CUSTOMER VIEW ============
  Widget _buildCustomerView() {
    final product = _product!;
    final isRtl = context.isRtl;
    final allImages = [
      product.posterImageUrl,
      ...product.images.map((img) => img.imageUrl),
    ].where((url) => url.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            slivers: [
              // Hero Image with Gradient
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image PageView
                      PageView.builder(
                        itemCount: allImages.isNotEmpty ? allImages.length : 1,
                        onPageChanged: (index) {
                          setState(() => _selectedImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          if (allImages.isEmpty) {
                            return Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.shopping_bag, size: 64),
                            );
                          }
                          return CachedNetworkImage(
                            imageUrl: _getImageUrl(allImages[index]),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        },
                      ),
                      // Bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 150,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(120),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Page Indicators
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(allImages.length, (index) {
                              final isSelected = _selectedImageIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: isSelected ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withAlpha(100),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -24, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        // Category & Rating Row
                        Row(
                          children: [
                            if (product.category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isRtl
                                      ? product.category!.nameAr
                                      : product.category!.name,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (product.totalReviews > 0)
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    final rating = product.averageRating;
                                    if (index < rating.floor()) {
                                      return const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    } else if (index < rating) {
                                      return const Icon(
                                        Icons.star_half_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    } else {
                                      return Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber.withAlpha(60),
                                        size: 18,
                                      );
                                    }
                                  }),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${product.totalReviews})',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Product Name
                        Text(
                          isRtl ? product.nameAr : product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'SAR',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tags
                        if (product.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: product.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border.withAlpha(50),
                                  ),
                                ),
                                child: Text(
                                  isRtl ? tag.nameAr : tag.name,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Description
                        Text(
                          isRtl ? 'الوصف' : 'Description',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRtl
                              ? (product.descriptionAr ??
                                  product.description ??
                                  '')
                              : (product.description ?? ''),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Variants
                        if (product.variants.isNotEmpty) ...[
                          Text(
                            isRtl ? 'اختر النوع' : 'Select Variant',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                List.generate(product.variants.length, (index) {
                              final variant = product.variants[index];
                              final isSelected = _selectedVariantIndex == index;
                              return GestureDetector(
                                onTap: variant.isAvailable
                                    ? () {
                                        setState(() {
                                          _selectedVariantIndex =
                                              isSelected ? -1 : index;
                                        });
                                      }
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withAlpha(60),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        isRtl ? variant.nameAr : variant.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (variant.priceModifier != 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${variant.priceModifier > 0 ? '+' : ''}${variant.priceModifier.toStringAsFixed(0)} SAR',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white.withAlpha(200)
                                                : AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Seller Info
                        if (product.project != null) ...[
                          Text(
                            isRtl ? 'البائع' : 'Seller',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              context.push(
                                Routes.projectDetail.replaceFirst(
                                  ':projectId',
                                  product.project!.id.toString(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withAlpha(100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border.withAlpha(30),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRtl
                                              ? product.project!.nameAr
                                              : product.project!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (product.project!.city.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                size: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                product.project!.city,
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Availability Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? Colors.green.withAlpha(20)
                            : Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: product.isAvailable
                              ? Colors.green.withAlpha(50)
                              : Colors.red.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.isAvailable
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color:
                                product.isAvailable ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${product.quantity}',
                            style: TextStyle(
                              color: product.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Request Rating Button
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _requestRating(product),
                          borderRadius: BorderRadius.circular(14),
                          child: const Icon(
                            Icons.star_rate_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add to Cart Button
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: product.isAvailable
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [Colors.grey.shade400, Colors.grey.shade500],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: product.isAvailable
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(100),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: product.isAvailable
                                ? () async {
                                    final variantId = _selectedVariantIndex >= 0
                                        ? product
                                            .variants[_selectedVariantIndex].id
                                        : null;
                                    final success = await ref
                                        .read(cartProvider.notifier)
                                        .addToCart(
                                          productId: product.id,
                                          variantId: variantId,
                                          quantity: 1,
                                        );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? context.tr('addedToCart')
                                                : context
                                                    .tr('errorAddingToCart'),
                                          ),
                                          backgroundColor: success
                                              ? AppColors.success
                                              : AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr('addToCart'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Request rating - creates conversation and initiates transaction with selected product
  Future<void> _requestRating(Product product) async {
    final isRtl = context.isRtl;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'طلب تقييم' : 'Request Rating'),
        content: Text(
          isRtl
              ? 'سيتم بدء محادثة مع البائع وإرسال طلب تقييم لهذا المنتج:\n\n${product.nameAr}'
              : 'A conversation will be started with the seller and a rating request will be sent for this product:\n\n${product.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRtl ? 'طلب التقييم' : 'Request Rating'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(isRtl ? 'جاري الإرسال...' : 'Sending...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Create or get conversation with the project
      final chatRepository = ref.read(chatRepositoryProvider);
      final conversation =
          await chatRepository.createConversation(product.projectId);

      // 2. Initiate transaction with the product
      final transaction =
          await ref.read(transactionsProvider.notifier).initiateTransaction(
                conversationId: conversation.id,
                productId: product.id,
              );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (transaction != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl
                  ? 'تم إرسال طلب التقييم بنجاح'
                  : 'Rating request sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to the conversation
          context.push('/chat/${conversation.id}');
        } else {
          // Get specific error from provider
          final error = ref.read(transactionsProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ??
                  (isRtl ? 'حدث خطأ أثناء الإرسال' : 'Error sending request')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl ? 'حدث خطأ: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
