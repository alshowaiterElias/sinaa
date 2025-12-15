import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../repositories/products_repository.dart';
import '../repositories/categories_repository.dart';

/// Products State
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final PaginationInfo? pagination;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.pagination,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    PaginationInfo? pagination,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }

  bool get hasMore => pagination?.hasMore ?? false;
}

/// Featured Products State
class FeaturedProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  FeaturedProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  FeaturedProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
  }) {
    return FeaturedProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Featured Products Notifier - loads featured/approved products for home screen
class FeaturedProductsNotifier extends Notifier<FeaturedProductsState> {
  @override
  FeaturedProductsState build() {
    return FeaturedProductsState();
  }

  Future<void> loadFeaturedProducts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.getProducts(
        page: 1,
        limit: 10,
        status: 'approved',
      );

      state = state.copyWith(
        products: response.products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = FeaturedProductsState();
    await loadFeaturedProducts();
  }
}

// Providers
final featuredProductsProvider =
    NotifierProvider<FeaturedProductsNotifier, FeaturedProductsState>(() {
  return FeaturedProductsNotifier();
});

/// Provider to get a single product by ID
final productByIdProvider =
    FutureProvider.family<Product, int>((ref, id) async {
  final repository = ref.read(productsRepositoryProvider);
  return repository.getProductById(id);
});
