import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/project_model.dart';
import '../models/category.dart';
import '../repositories/products_repository.dart';
import '../repositories/project_repository.dart';
import 'auth_provider.dart';

class SearchState {
  final String query;
  final Category? selectedCategory;
  final double distanceRadius;
  final String sortBy; // 'rating', 'distance', 'newest'
  final String? selectedCity;
  final double? minRating;

  // Results
  final List<Product> products;
  final List<Project> projects;
  final bool isProductsLoading;
  final bool isProjectsLoading;
  final String? productsError;
  final String? projectsError;

  SearchState({
    this.query = '',
    this.selectedCategory,
    this.distanceRadius = 50,
    this.sortBy = 'rating',
    this.selectedCity,
    this.minRating,
    this.products = const [],
    this.projects = const [],
    this.isProductsLoading = false,
    this.isProjectsLoading = false,
    this.productsError,
    this.projectsError,
  });

  SearchState copyWith({
    String? query,
    Category? selectedCategory,
    double? distanceRadius,
    String? sortBy,
    String? selectedCity,
    double? minRating,
    List<Product>? products,
    List<Project>? projects,
    bool? isProductsLoading,
    bool? isProjectsLoading,
    String? productsError,
    String? projectsError,
    // Helper to clear nullable fields
    bool clearCategory = false,
    bool clearCity = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      distanceRadius: distanceRadius ?? this.distanceRadius,
      sortBy: sortBy ?? this.sortBy,
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      minRating: minRating ?? this.minRating,
      products: products ?? this.products,
      projects: projects ?? this.projects,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
      isProjectsLoading: isProjectsLoading ?? this.isProjectsLoading,
      productsError: productsError ?? this.productsError,
      projectsError: projectsError ?? this.projectsError,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    // Debounce logic could go here, but for now we'll trigger search manually or on submit
  }

  void setCategory(Category? category) {
    if (state.selectedCategory?.id == category?.id) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
    searchProducts(); // Category mainly affects products
  }

  void applyFilters({
    required double distanceRadius,
    required String sortBy,
    String? city,
    double? minRating,
  }) {
    state = state.copyWith(
      distanceRadius: distanceRadius,
      sortBy: sortBy,
      selectedCity: city,
      clearCity: city == null,
      minRating: minRating,
    );
    // Trigger re-search
    searchProducts();
    searchProjects();
  }

  void setFilters({
    double? distanceRadius,
    String? sortBy,
    String? city,
    double? minRating,
  }) {
    state = state.copyWith(
      distanceRadius: distanceRadius,
      sortBy: sortBy,
      selectedCity: city,
      minRating: minRating,
    );
    // Trigger re-search
    searchProducts();
    searchProjects();
  }

  void clearFilters() {
    state = state.copyWith(
      distanceRadius: 50,
      sortBy: 'rating',
      clearCity: true,
      minRating: 0,
    );
  }

  Future<void> searchProducts() async {
    if (state.query.isEmpty && state.selectedCategory == null) {
      // Clear products if no query and no category
      state = state.copyWith(
        products: [],
        isProductsLoading: false,
        productsError: null,
      );
      return;
    }

    state = state.copyWith(isProductsLoading: true, productsError: null);

    try {
      final repository = ref.read(productsRepositoryProvider);

      // Map sort by to backend params if needed, currently backend supports basic filters
      // We might need to handle sorting client side if backend doesn't support it fully for products

      final response = await repository.getProducts(
        search: state.query.isEmpty ? null : state.query,
        categoryId: state.selectedCategory?.id,
        limit: 20,
      );

      // Client-side filtering for things backend might not support yet
      var filteredProducts = response.products;

      if (state.minRating != null) {
        filteredProducts = filteredProducts
            .where((p) => p.averageRating >= state.minRating!)
            .toList();
      }

      state = state.copyWith(
        products: filteredProducts,
        isProductsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProductsLoading: false,
        productsError: e.toString(),
      );
    }
  }

  Future<void> searchProjects() async {
    // If query is empty and no filters are set (default sort is rating, default radius is 50)
    // We should probably clear results unless we want to show "All Projects" by default?
    // The user expectation for "Clear" is likely to reset to empty state.
    // However, for Projects, we might want to show "Nearby" if location is available?
    // Let's stick to clearing for now to match User request "resetting... results".

    // Check if any filter is active
    bool hasFilters = state.selectedCity != null ||
        state.sortBy != 'rating' || // 'rating' is default
        state.distanceRadius != 50; // 50 is default

    if (state.query.isEmpty && !hasFilters) {
      state = state.copyWith(
        projects: [],
        isProjectsLoading: false,
        projectsError: null,
      );
      return;
    }

    state = state.copyWith(isProjectsLoading: true, projectsError: null);

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final user = ref.read(authStateProvider).user;

      double? lat;
      double? lon;

      // Always send location if available so distance can be calculated
      if (user != null && user.hasLocation) {
        lat = user.latitude;
        lon = user.longitude;
      }

      final response = await repository.getProjects(
        search: state.query.isEmpty ? null : state.query,
        city: state.selectedCity,
        lat: lat,
        lon: lon,
        radius: state.distanceRadius,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        projects: response.projects,
        isProjectsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProjectsLoading: false,
        projectsError: e.toString(),
      );
    }
  }

  Future<void> searchAll() async {
    await Future.wait([
      searchProducts(),
      searchProjects(),
    ]);
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});
