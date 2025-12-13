import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../repositories/categories_repository.dart';

/// Categories state
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  /// Get parent categories only
  List<Category> get parentCategories =>
      categories.where((c) => c.isParentCategory).toList();

  /// Get all categories flattened
  List<Category> get flatCategories {
    final flat = <Category>[];
    for (final parent in categories) {
      flat.add(parent);
      flat.addAll(parent.children);
    }
    return flat;
  }

  /// Find category by ID
  Category? findById(int id) {
    for (final parent in categories) {
      if (parent.id == id) return parent;
      for (final child in parent.children) {
        if (child.id == id) return child;
      }
    }
    return null;
  }

  /// Get subcategories for a parent
  List<Category> getSubcategories(int parentId) {
    for (final parent in categories) {
      if (parent.id == parentId) {
        return parent.children;
      }
    }
    return [];
  }

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// Categories notifier
class CategoriesNotifier extends Notifier<CategoriesState> {
  late CategoriesRepository _repository;

  @override
  CategoriesState build() {
    _repository = ref.watch(categoriesRepositoryProvider);
    return const CategoriesState();
  }

  /// Load all categories
  Future<void> loadCategories({bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (state.isInitialized && !forceRefresh && state.categories.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(
        categories: categories,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.toString(),
      );
    }
  }

  /// Refresh categories
  Future<void> refresh() async {
    await loadCategories(forceRefresh: true);
  }

  /// Get category by ID (fetches from API if not cached)
  Future<Category?> getCategoryById(int id) async {
    // First check local cache
    final cached = state.findById(id);
    if (cached != null) return cached;

    // Fetch from API
    try {
      return await _repository.getCategoryById(id);
    } catch (_) {
      return null;
    }
  }
}

// Providers
final categoriesStateProvider =
    NotifierProvider<CategoriesNotifier, CategoriesState>(() {
  return CategoriesNotifier();
});

/// Provider for parent categories only
final parentCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesStateProvider).parentCategories;
});

/// Provider for flat category list
final flatCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesStateProvider).flatCategories;
});

/// Provider for getting subcategories of a parent
final subcategoriesProvider =
    Provider.family<List<Category>, int>((ref, parentId) {
  return ref.watch(categoriesStateProvider).getSubcategories(parentId);
});

/// Provider for checking if categories are loading
final categoriesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoriesStateProvider).isLoading;
});

/// Selected category notifier (for filtering)
class SelectedCategoryNotifier extends Notifier<Category?> {
  @override
  Category? build() => null;

  void select(Category? category) => state = category;
  void clear() => state = null;
}

/// Selected subcategory notifier (for filtering)
class SelectedSubcategoryNotifier extends Notifier<Category?> {
  @override
  Category? build() => null;

  void select(Category? subcategory) => state = subcategory;
  void clear() => state = null;
}

/// Provider for selected category (for filtering)
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, Category?>(() {
  return SelectedCategoryNotifier();
});

/// Provider for selected subcategory (for filtering)
final selectedSubcategoryProvider =
    NotifierProvider<SelectedSubcategoryNotifier, Category?>(() {
  return SelectedSubcategoryNotifier();
});
