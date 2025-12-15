import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product.dart';
import '../../../data/providers/products_provider.dart';
import '../widgets/reject_dialog.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final _statusTabs = ['all', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load products on init
    Future.microtask(() {
      ref.read(productsListProvider.notifier).loadProducts(refresh: true);
    });

    // Pagination listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _statusTabs[_tabController.index];
    ref.read(productsListProvider.notifier).setStatusFilter(status);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productsListProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(productsListProvider.notifier).setSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'إدارة المنتجات',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              // Stats
              _buildStatBadge('الإجمالي', state.total, AdminColors.primary),
              const SizedBox(width: 12),
              _buildStatBadge(
                  'في الانتظار', state.pendingCount, AdminColors.warning),
            ],
          ),
          const SizedBox(height: 24),

          // Search and filters row
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عن منتج...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _onSearch,
                ),
              ),
              const SizedBox(width: 16),
              // Refresh button
              IconButton.outlined(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref
                      .read(productsListProvider.notifier)
                      .loadProducts(refresh: true);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AdminColors.primary,
            unselectedLabelColor: AdminColors.textSecondary,
            indicatorColor: AdminColors.primary,
            tabs: [
              const Tab(text: 'الكل'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('في الانتظار'),
                    if (state.pendingCount > 0) ...[
                      const SizedBox(width: 8),
                      Badge(
                        backgroundColor: AdminColors.warning,
                        label: Text('${state.pendingCount}'),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'المعتمدة'),
              const Tab(text: 'المرفوضة'),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: state.isLoading && state.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.products.isEmpty
                    ? _buildErrorState(state.error!)
                    : state.products.isEmpty
                        ? _buildEmptyState()
                        : _buildProductsTable(state),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AdminColors.error),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(productsListProvider.notifier)
                  .loadProducts(refresh: true);
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AdminColors.textTertiary),
          SizedBox(height: 16),
          Text('لا توجد منتجات',
              style: TextStyle(color: AdminColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProductsTable(ProductsListState state) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Table
          Container(
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AdminColors.surfaceVariant),
                columns: const [
                  DataColumn(label: Text('المنتج')),
                  DataColumn(label: Text('المشروع')),
                  DataColumn(label: Text('الفئة')),
                  DataColumn(label: Text('السعر')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('الإجراءات')),
                ],
                rows: state.products.map((product) {
                  return DataRow(
                    cells: [
                      // Product info
                      DataCell(_buildProductCell(product)),
                      // Project
                      DataCell(Text(product.project?.nameAr ?? '-')),
                      // Category
                      DataCell(Text(product.category?.nameAr ?? '-')),
                      // Price
                      DataCell(
                          Text('${product.basePrice.toStringAsFixed(2)} ر.س')),
                      // Status
                      DataCell(_buildStatusBadge(product)),
                      // Actions
                      DataCell(_buildActions(product)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // Loading more indicator
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCell(Product product) {
    final imageUrl = product.posterImageUrl.isNotEmpty
        ? '${ApiEndpoints.baseUrl.replaceFirst('/api/v1', '')}${product.posterImageUrl}'
        : null;

    return Row(
      children: [
        // Thumbnail
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AdminColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? const Icon(Icons.image, color: AdminColors.textTertiary)
              : null,
        ),
        const SizedBox(width: 12),
        // Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.nameAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActions(Product product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick approve for pending
        if (product.status == ProductStatus.pending) ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: AdminColors.success),
            tooltip: 'اعتماد',
            onPressed: () => _approveProduct(product),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AdminColors.error),
            tooltip: 'رفض',
            onPressed: () => _rejectProduct(product),
          ),
        ],

        // Disable for approved
        if (product.status == ProductStatus.approved && !product.isDisabled)
          IconButton(
            icon: const Icon(Icons.block, color: AdminColors.warning),
            tooltip: 'تعطيل',
            onPressed: () => _disableProduct(product),
          ),

        // Enable for disabled
        if (product.isDisabled)
          IconButton(
            icon: const Icon(Icons.check, color: AdminColors.success),
            tooltip: 'تفعيل',
            onPressed: () => _enableProduct(product),
          ),

        // View details
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: 'عرض التفاصيل',
          onPressed: () => context.push('/products/${product.id}'),
        ),
      ],
    );
  }

  Future<void> _approveProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاعتماد'),
        content: Text('هل تريد اعتماد منتج "${product.nameAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(productsListProvider.notifier)
          .approveProduct(product.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم اعتماد المنتج بنجاح'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    }
  }

  Future<void> _rejectProduct(Product product) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => RejectDialog(
        title: 'رفض المنتج',
        itemName: product.nameAr,
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      final success = await ref
          .read(productsListProvider.notifier)
          .rejectProduct(product.id, reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض المنتج'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    }
  }

  Future<void> _disableProduct(Product product) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => RejectDialog(
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
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعطيل المنتج'),
            backgroundColor: AdminColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _enableProduct(Product product) async {
    final success =
        await ref.read(productsListProvider.notifier).enableProduct(product.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل المنتج'),
          backgroundColor: AdminColors.success,
        ),
      );
    }
  }
}
