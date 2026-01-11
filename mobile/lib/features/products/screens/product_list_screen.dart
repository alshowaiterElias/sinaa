import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/providers/categories_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

/// Product List Screen - displays all products with filtering
class ProductListScreen extends ConsumerStatefulWidget {
  final int? categoryId;
  final int? projectId;
  final String? searchQuery;
  final bool isOwner;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.projectId,
    this.searchQuery,
    this.isOwner = false,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Category filtering state
  Category? _parentCategory;
  List<Category> _subcategories = [];
  int? _selectedSubcategoryId;

  // Search and Filter state
  late TextEditingController _searchController;
  String _sortBy = 'newest';
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchQuery = widget.searchQuery ?? '';
    _loadProducts();
    _scrollController.addListener(_onScroll);

    // Load category info if we have a categoryId
    if (widget.categoryId != null) {
      _loadCategoryInfo();
    }
  }

  @override
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCategoryInfo() async {
    final categoriesState = ref.read(categoriesStateProvider);

    // Find the category by ID
    Category? findCategory(List<Category> categories, int id) {
      for (final cat in categories) {
        if (cat.id == id) return cat;
        if (cat.hasChildren) {
          final found = findCategory(cat.children, id);
          if (found != null) return found;
        }
      }
      return null;
    }

    final category =
        findCategory(categoriesState.categories, widget.categoryId!);

    if (category != null) {
      setState(() {
        if (category.isParentCategory) {
          // This is a parent category - show its subcategories
          _parentCategory = category;
          _subcategories = category.children;
        } else {
          // This is a subcategory - find parent
          final parent = findCategory(
            categoriesState.categories,
            category.parentId!,
          );
          _parentCategory = parent;
          _subcategories = parent?.children ?? [];
          _selectedSubcategoryId = category.id;
        }
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.getProducts(
        page: 1,
        limit: 20,
        categoryId: _selectedSubcategoryId ?? widget.categoryId,
        projectId: widget.projectId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: widget.isOwner ? 'all' : 'approved',
        sort: _sortBy,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
      );
      setState(() {
        _products = response.products;
        _hasMore = response.pagination.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.getProducts(
        page: _currentPage,
        limit: 20,
        categoryId: _selectedSubcategoryId ?? widget.categoryId,
        projectId: widget.projectId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: widget.isOwner ? 'all' : 'approved',
        sort: _sortBy,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
      );
      setState(() {
        _products.addAll(response.products);
        _hasMore = response.pagination.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  void _selectSubcategory(int? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
    _loadProducts();
  }

  Future<void> _navigateToAddProduct() async {
    if (widget.projectId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          projectId: widget.projectId!,
        ),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  void _navigateToProductDetail(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          productId: product.id,
          isOwner: widget.isOwner,
        ),
      ),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRtl = context.isRtl;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: _parentCategory != null ? 160 : 100,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list_rounded,
                      color: Colors.white, size: 18),
                ),
                onPressed: _showFilterSheet,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SearchTextField(
                  controller: _searchController,
                  hint: l10n.tr('searchPlaceholder'),
                  onChanged: (value) {
                    _searchQuery = value;
                    // Debounce could be added here
                  },
                  onSubmitted: (value) {
                    _searchQuery = value;
                    _loadProducts();
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadProducts();
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A5653),
                      Color(0xFF2D8C87),
                      Color(0xFF1A5653),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _parentCategory != null
                              ? _parentCategory!
                                  .getLocalizedName(l10n.locale.languageCode)
                              : l10n.tr('products'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_parentCategory != null &&
                            _parentCategory!.hasChildren)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_subcategories.length} ${l10n.tr('subCategories')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Subcategory chips
          if (_subcategories.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _subcategories.length + 1, // +1 for "All" chip
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // "All" chip
                            final isSelected = _selectedSubcategoryId == null;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: isRtl ? 0 : 10,
                                left: isRtl ? 10 : 0,
                              ),
                              child: FilterChip(
                                label: Text(l10n.tr('all')),
                                selected: isSelected,
                                onSelected: (_) => _selectSubcategory(null),
                                backgroundColor: AppColors.surfaceVariant,
                                selectedColor:
                                    AppColors.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            );
                          }

                          final subcategory = _subcategories[index - 1];
                          final isSelected =
                              _selectedSubcategoryId == subcategory.id;

                          return Padding(
                            padding: EdgeInsets.only(
                              right: isRtl ? 0 : 10,
                              left: isRtl ? 10 : 0,
                            ),
                            child: FilterChip(
                              label: Text(
                                subcategory
                                    .getLocalizedName(l10n.locale.languageCode),
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  _selectSubcategory(subcategory.id),
                              backgroundColor: AppColors.surfaceVariant,
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),

          // Products grid
          _buildProductsSliver(),
        ],
      ),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddProduct,
              label: Text(l10n.tr('addProduct')),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildProductsSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('error'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppColors.textTertiary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.isRtl ? 'لا توجد منتجات' : 'No products found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (widget.isOwner) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToAddProduct,
                  icon: const Icon(Icons.add),
                  label: Text(context.isRtl ? 'إضافة منتج' : 'Add Product'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _products.length) {
              // Loading indicator at the end
              return _isLoadingMore
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox();
            }

            final product = _products[index];
            return _buildProductCard(context, product);
          },
          childCount: _products.length + (_hasMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isRtl = context.isRtl;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with status badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: product.posterImageUrl.isNotEmpty
                          ? Image.network(
                              ApiEndpoints.imageUrl(product.posterImageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Icon(Icons.image,
                                    color: AppColors.textTertiary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image,
                                  color: AppColors.textTertiary),
                            ),
                    ),
                  ),
                  // Status badge for owner view
                  if (widget.isOwner && product.status != 'approved')
                    Positioned(
                      top: 8,
                      left: isRtl ? null : 8,
                      right: isRtl ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(product.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(product.status, isRtl),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product info - fixed height to avoid overflow
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRtl ? product.nameAr : product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${product.basePrice.toStringAsFixed(0)} ${isRtl ? 'ر.س' : 'SAR'}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.averageRating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.averageRating.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'approved':
        return AppColors.success;
      default:
        return AppColors.textTertiary;
    }
  }

  String _getStatusLabel(String status, bool isRtl) {
    switch (status) {
      case 'pending':
        return isRtl ? 'قيد المراجعة' : 'Pending';
      case 'rejected':
        return isRtl ? 'مرفوض' : 'Rejected';
      case 'approved':
        return isRtl ? 'موافق عليه' : 'Approved';
      default:
        return status;
    }
  }

  void _showFilterSheet() {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.tr('filterResults'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _sortBy = 'newest';
                          _minPrice = null;
                          _maxPrice = null;
                          _minRating = null;
                        });
                      },
                      child: Text(l10n.tr('reset')),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort By
                      Text(
                        l10n.tr('sortBy'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildSortChip(
                            context,
                            l10n.tr('location.sortByNewest'),
                            'newest',
                            Icons.schedule_rounded,
                            setSheetState,
                          ),
                          _buildSortChip(
                            context,
                            l10n.tr('priceLowToHigh'), // Add to l10n later
                            'price_asc',
                            Icons.arrow_upward_rounded,
                            setSheetState,
                          ),
                          _buildSortChip(
                            context,
                            l10n.tr('priceHighToLow'), // Add to l10n later
                            'price_desc',
                            Icons.arrow_downward_rounded,
                            setSheetState,
                          ),
                          _buildSortChip(
                            context,
                            l10n.tr('rating'),
                            'rating',
                            Icons.star_rounded,
                            setSheetState,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Price Range
                      Text(
                        l10n.tr('price'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: l10n.tr('min'),
                                prefixText: 'SAR ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) =>
                                  _minPrice = double.tryParse(val),
                              controller: TextEditingController(
                                  text: _minPrice?.toStringAsFixed(0) ?? ''),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: l10n.tr('max'),
                                prefixText: 'SAR ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) =>
                                  _maxPrice = double.tryParse(val),
                              controller: TextEditingController(
                                  text: _maxPrice?.toStringAsFixed(0) ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      Text(
                        l10n.tr('rating'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [4, 3, 2, 1].map((rating) {
                          return RadioListTile<double>(
                            value: rating.toDouble(),
                            groupValue: _minRating,
                            onChanged: (value) {
                              setSheetState(() {
                                _minRating = value;
                              });
                            },
                            title: Row(
                              children: [
                                Text('$rating+ '),
                                const Icon(Icons.star_rounded,
                                    color: AppColors.warning, size: 16),
                              ],
                            ),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Apply Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadProducts();
                    },
                    child: Text(l10n.tr('apply')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    StateSetter setSheetState,
  ) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
