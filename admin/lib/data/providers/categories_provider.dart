import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/category.dart';

/// Categories state for admin
class AdminCategoriesState {
  final List<Category> categories;
  final CategoriesStats? stats;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AdminCategoriesState({
    this.categories = const [],
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
    CategoriesStats? stats,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AdminCategoriesState(
      categories: categories ?? this.categories,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// Admin categories notifier
class AdminCategoriesNotifier extends Notifier<AdminCategoriesState> {
  late Dio _dio;

  @override
  AdminCategoriesState build() {
    _dio = ref.watch(adminDioProvider);
    return const AdminCategoriesState();
  }

  /// Load all categories
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (state.isInitialized && !forceRefresh && state.categories.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(ApiEndpoints.categories);
      final data = response.data['data'];

      final categoriesJson = data['categories'] as List;
      final categories = categoriesJson
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      final stats = data['stats'] != null
          ? CategoriesStats.fromJson(data['stats'] as Map<String, dynamic>)
          : null;

      state = state.copyWith(
        categories: categories,
        stats: stats,
        isLoading: false,
        isInitialized: true,
      );
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: error.message,
      );
    }
  }

  /// Refresh categories
  Future<void> refresh() async {
    await loadCategories(forceRefresh: true);
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
      final response = await _dio.post(ApiEndpoints.categories, data: {
        'name': name,
        'nameAr': nameAr,
        if (icon != null) 'icon': icon,
        if (parentId != null) 'parentId': parentId,
        if (sortOrder != null) 'sortOrder': sortOrder,
        'isActive': isActive,
      });

      final data = response.data['data'];
      final category = Category.fromJson(data['category'] as Map<String, dynamic>);

      // Refresh the list
      await refresh();

      return category;
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
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
      final response = await _dio.put(ApiEndpoints.category(id), data: {
        if (name != null) 'name': name,
        if (nameAr != null) 'nameAr': nameAr,
        if (icon != null) 'icon': icon,
        if (parentId != null) 'parentId': parentId,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (isActive != null) 'isActive': isActive,
      });

      final data = response.data['data'];
      final category = Category.fromJson(data['category'] as Map<String, dynamic>);

      // Refresh the list
      await refresh();

      return category;
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
      rethrow;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dio.delete(ApiEndpoints.category(id));

      // Refresh the list
      await refresh();

      return true;
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
      return false;
    }
  }

  /// Toggle category active status
  Future<Category?> toggleCategory(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.put('${ApiEndpoints.category(id)}/toggle');

      final data = response.data['data'];
      final category = Category.fromJson(data['category'] as Map<String, dynamic>);

      // Refresh the list
      await refresh();

      return category;
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
      rethrow;
    }
  }

  /// Reorder categories
  Future<bool> reorderCategories(List<Map<String, int>> orders) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dio.put('${ApiEndpoints.categories}/reorder', data: {
        'orders': orders,
      });

      // Refresh the list
      await refresh();

      return true;
    } on DioException catch (e) {
      final error = ApiException.fromDioError(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
      return false;
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

