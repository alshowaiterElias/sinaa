import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/category.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository(this._dio);

  Future<CategoriesResponse> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);
      final data = response.data['data'];

      return CategoriesResponse(
        categories: (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList(),
        stats: CategoriesStats.fromJson(data['stats']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Category>> getCategoryRequests() async {
    try {
      final response = await _dio.get('${ApiEndpoints.categories}/requests');
      final data = response.data['data']['requests'] as List;
      return data.map((e) => Category.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.categories, data: data);
      return Category.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.category(id), data: data);
      return Category.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete(ApiEndpoints.category(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> toggleCategory(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.categoryToggle(id));
      return Category.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> orders) async {
    try {
      await _dio.put(
        ApiEndpoints.categoriesReorder,
        data: {'orders': orders},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> approveCategory(int id) async {
    try {
      final response = await _dio.put('${ApiEndpoints.categories}/$id/approve');
      return Category.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> rejectCategory(int id, String reason) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.categories}/$id/reject',
        data: {'reason': reason},
      );
      return Category.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class CategoriesResponse {
  final List<Category> categories;
  final CategoriesStats stats;

  CategoriesResponse({required this.categories, required this.stats});
}
