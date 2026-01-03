import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../repositories/categories_repository.dart';

// Repository provider
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(adminDioProvider));
});

/// Categories state for admin
class AdminCategoriesState {
  final List<Category> categories;
  final List<Category> requests;
  final CategoriesStats? stats;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AdminCategoriesState({
    this.categories = const [],
    this.requests = const [],
    this.stats,
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

  AdminCategoriesState copyWith({
    List<Category>? categories,
    List<Category>? requests,
    CategoriesStats? stats,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AdminCategoriesState(
      categories: categories ?? this.categories,
      requests: requests ?? this.requests,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// Admin categories notifier
class AdminCategoriesNotifier extends Notifier<AdminCategoriesState> {
  late CategoriesRepository _repository;

  @override
  AdminCategoriesState build() {
    _repository = ref.watch(categoriesRepositoryProvider);
    return const AdminCategoriesState();
  }

  /// Load all categories
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (state.isInitialized && !forceRefresh && state.categories.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getCategories();

      state = state.copyWith(
        categories: response.categories,
        stats: response.stats,
        isLoading: false,
        isInitialized: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.message,
      );
    }
  }

  /// Load category requests
  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requests = await _repository.getCategoryRequests();
      state = state.copyWith(requests: requests, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Refresh categories and requests
  Future<void> refresh() async {
    await Future.wait([
      loadCategories(forceRefresh: true),
      loadRequests(),
    ]);
  }

  /// Create a new category
  Future<Category?> createCategory({
    required String name,
    required String nameAr,
    String? icon,
    int? parentId,
    int? sortOrder,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final category = await _repository.createCategory({
        'name': name,
        'nameAr': nameAr,
        if (icon != null) 'icon': icon,
        if (parentId != null) 'parentId': parentId,
        if (sortOrder != null) 'sortOrder': sortOrder,
        'isActive': isActive,
      });

      await refresh();
      return category;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Update a category
  Future<Category?> updateCategory({
    required int id,
    String? name,
    String? nameAr,
    String? icon,
    int? parentId,
    int? sortOrder,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final category = await _repository.updateCategory(id, {
        if (name != null) 'name': name,
        if (nameAr != null) 'nameAr': nameAr,
        if (icon != null) 'icon': icon,
        if (parentId != null) 'parentId': parentId,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (isActive != null) 'isActive': isActive,
      });

      await refresh();
      return category;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deleteCategory(id);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Toggle category active status
  Future<Category?> toggleCategory(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final category = await _repository.toggleCategory(id);
      await refresh();
      return category;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Reorder categories
  Future<bool> reorderCategories(List<Map<String, dynamic>> orders) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.reorderCategories(orders);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Approve category request
  Future<void> approveRequest(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.approveCategory(id);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Reject category request
  Future<void> rejectRequest(int id, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.rejectCategory(id, reason);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }
}

// Providers
final adminCategoriesStateProvider =
    NotifierProvider<AdminCategoriesNotifier, AdminCategoriesState>(() {
  return AdminCategoriesNotifier();
});

final adminParentCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(adminCategoriesStateProvider).parentCategories;
});

final adminCategoriesStatsProvider = Provider<CategoriesStats?>((ref) {
  return ref.watch(adminCategoriesStateProvider).stats;
});

final categoryRequestsProvider = Provider<List<Category>>((ref) {
  return ref.watch(adminCategoriesStateProvider).requests;
});
