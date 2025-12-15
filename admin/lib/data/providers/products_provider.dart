import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/products_repository.dart';

/// Filter state for products list
class ProductsFilter {
  final String status;
  final String? search;
  final int? categoryId;
  final int? projectId;
  final int? ownerId;
  final String sort;

  const ProductsFilter({
    this.status = 'all',
    this.search,
    this.categoryId,
    this.projectId,
    this.ownerId,
    this.sort = 'pending_first',
  });

  ProductsFilter copyWith({
    String? status,
    String? search,
    int? categoryId,
    int? projectId,
    int? ownerId,
    String? sort,
  }) {
    return ProductsFilter(
      status: status ?? this.status,
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      sort: sort ?? this.sort,
    );
  }

  /// Clear specific filter
  ProductsFilter clearSearch() => copyWith(search: '');
  ProductsFilter clearCategory() =>
      ProductsFilter(status: status, search: search, sort: sort);
  ProductsFilter clearProject() =>
      ProductsFilter(status: status, search: search, sort: sort);
}

/// Products list state
class ProductsListState {
  final List<Product> products;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ProductsFilter filter;

  const ProductsListState({
    this.products = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filter = const ProductsFilter(),
  });

  bool get hasMore => page < totalPages;

  /// Get pending products count
  int get pendingCount =>
      products.where((p) => p.status == ProductStatus.pending).length;

  ProductsListState copyWith({
    List<Product>? products,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    ProductsFilter? filter,
  }) {
    return ProductsListState(
      products: products ?? this.products,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

/// Products list notifier
class ProductsListNotifier extends Notifier<ProductsListState> {
  late ProductsRepository _repository;

  @override
  ProductsListState build() {
    _repository = ref.watch(productsRepositoryProvider);
    return const ProductsListState();
  }

  /// Load products with current filters
  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      page: refresh ? 1 : state.page,
    );

    try {
      final response = await _repository.getProducts(
        page: refresh ? 1 : state.page,
        status: state.filter.status,
        search: state.filter.search,
        categoryId: state.filter.categoryId,
        projectId: state.filter.projectId,
        ownerId: state.filter.ownerId,
        sort: state.filter.sort,
      );

      state = state.copyWith(
        products: response.products,
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _repository.getProducts(
        page: state.page + 1,
        status: state.filter.status,
        search: state.filter.search,
        categoryId: state.filter.categoryId,
        projectId: state.filter.projectId,
        ownerId: state.filter.ownerId,
        sort: state.filter.sort,
      );

      state = state.copyWith(
        products: [...state.products, ...response.products],
        page: response.page,
        totalPages: response.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Update filter and reload
  Future<void> setFilter(ProductsFilter filter) async {
    state = state.copyWith(filter: filter, page: 1);
    await loadProducts(refresh: true);
  }

  /// Set status filter
  Future<void> setStatusFilter(String status) async {
    await setFilter(state.filter.copyWith(status: status));
  }

  /// Set search query
  Future<void> setSearch(String query) async {
    await setFilter(state.filter.copyWith(search: query));
  }

  /// Approve a product
  Future<bool> approveProduct(int id) async {
    try {
      final product = await _repository.approveProduct(id);
      _updateProductInList(product);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reject a product
  Future<bool> rejectProduct(int id, String reason) async {
    try {
      final product = await _repository.rejectProduct(id, reason);
      _updateProductInList(product);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Disable a product
  Future<bool> disableProduct(int id, String reason) async {
    try {
      final product = await _repository.disableProduct(id, reason);
      _updateProductInList(product);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Enable a product
  Future<bool> enableProduct(int id) async {
    try {
      final product = await _repository.enableProduct(id);
      _updateProductInList(product);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update product in list
  void _updateProductInList(Product updated) {
    final index = state.products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      final newList = List<Product>.from(state.products);
      newList[index] = updated;
      state = state.copyWith(products: newList);
    }
  }
}

/// Selected product detail state
class ProductDetailState {
  final Product? product;
  final bool isLoading;
  final String? error;

  const ProductDetailState({
    this.product,
    this.isLoading = false,
    this.error,
  });

  ProductDetailState copyWith({
    Product? product,
    bool? isLoading,
    String? error,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============ Providers ============

/// Products list provider
final productsListProvider =
    NotifierProvider<ProductsListNotifier, ProductsListState>(() {
  return ProductsListNotifier();
});

/// Product detail provider (family) - using FutureProvider.family for simpler pattern
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, int>((ref, id) async {
  final repository = ref.watch(productsRepositoryProvider);
  return await repository.getProductById(id);
});

/// Pending products count
final pendingProductsCountProvider = Provider<int>((ref) {
  return ref.watch(productsListProvider).pendingCount;
});

/// Products filter provider
final productsFilterProvider = Provider<ProductsFilter>((ref) {
  return ref.watch(productsListProvider).filter;
});
