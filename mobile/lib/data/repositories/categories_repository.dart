import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/category.dart';

/// Categories Repository - handles all category API calls
class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository(this._dio);

  /// Get all categories with subcategories (hierarchical)
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);

      final data = response.data['data'];
      final categoriesJson = data['categories'] as List;

      return categoriesJson
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get a single category by ID
  Future<Category> getCategoryById(int id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.categoryById(id),
      );

      final data = response.data['data'];
      return Category.fromJson(data['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get products in a category
  /// Returns a map with 'category', 'products', and 'pagination'
  Future<CategoryProductsResponse> getCategoryProducts(
    int categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.categoryProducts(categoryId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'];

      return CategoryProductsResponse(
        category:
            CategorySummary.fromJson(data['category'] as Map<String, dynamic>),
        products: (data['products'] as List)
            .map((p) => p as Map<String, dynamic>)
            .toList(), // Will be converted to Product model when created
        pagination:
            PaginationInfo.fromJson(data['pagination'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get all parent categories (for filters)
  Future<List<Category>> getParentCategories() async {
    final categories = await getCategories();
    return categories.where((c) => c.isParentCategory).toList();
  }

  /// Get subcategories for a parent
  Future<List<Category>> getSubcategories(int parentId) async {
    final parent = await getCategoryById(parentId);
    return parent.children;
  }

  /// Flatten categories into a single list (for search/selection)
  Future<List<Category>> getFlatCategories() async {
    final categories = await getCategories();
    final flat = <Category>[];

    for (final parent in categories) {
      flat.add(parent);
      flat.addAll(parent.children);
    }

    return flat;
  }

  /// Request a new category
  Future<Category> requestCategory({
    required String name,
    required String nameAr,
    String? icon,
    int? parentId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.categories}/request',
        data: {
          'name': name,
          'nameAr': nameAr,
          if (icon != null) 'icon': icon,
          if (parentId != null) 'parentId': parentId,
        },
      );

      final data = response.data['data'];
      return Category.fromJson(data['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get my requested categories
  Future<List<Category>> getMyRequests() async {
    try {
      final response = await _dio.get('${ApiEndpoints.categories}/my-requests');
      final data = response.data['data']['categories'] as List;
      return data.map((e) => Category.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Category summary for product listing
class CategorySummary {
  final int id;
  final String name;
  final String nameAr;

  CategorySummary({
    required this.id,
    required this.name,
    required this.nameAr,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
    );
  }

  String get displayName => nameAr;
}

/// Pagination info
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: (json['currentPage'] ?? json['page']) as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 0,
      totalItems: (json['totalItems'] ?? json['total']) as int? ?? 0,
      itemsPerPage: json['itemsPerPage'] as int? ?? 20,
    );
  }

  bool get hasMore => currentPage < totalPages;
  bool get isEmpty => totalItems == 0;
}

/// Response for category products endpoint
class CategoryProductsResponse {
  final CategorySummary category;
  final List<Map<String, dynamic>>
      products; // Will be List<Product> when model is created
  final PaginationInfo pagination;

  CategoryProductsResponse({
    required this.category,
    required this.products,
    required this.pagination,
  });
}

/// Categories repository provider
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CategoriesRepository(dio);
});
