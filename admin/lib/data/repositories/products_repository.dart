import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/product.dart';

class ProductsRepository {
  final Dio _dio;

  ProductsRepository(this._dio);

  /// Get all products with filters and pagination
  Future<ProductsResponse> getProducts({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    int? categoryId,
    int? projectId,
    int? ownerId,
    String? sort,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (projectId != null) queryParams['projectId'] = projectId;
      if (ownerId != null) queryParams['ownerId'] = ownerId;
      if (sort != null) queryParams['sort'] = sort;

      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final List<dynamic> productsData = response.data['data'] as List<dynamic>;
      final Map<String, dynamic> paginationData =
          response.data['pagination'] as Map<String, dynamic>;

      return ProductsResponse(
        products: productsData
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList(),
        total: paginationData['total'] as int,
        page: paginationData['page'] as int,
        totalPages: paginationData['totalPages'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get single product by ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.product(id));
      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Approve a pending product
  Future<Product> approveProduct(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.productApprove(id));
      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Reject a product with reason
  Future<Product> rejectProduct(int id, String reason) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.productReject(id),
        data: {'reason': reason},
      );
      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Disable an approved product
  Future<Product> disableProduct(int id, String reason) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.productDisable(id),
        data: {'reason': reason},
      );
      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Enable a disabled product
  Future<Product> enableProduct(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.productEnable(id));
      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Response wrapper for paginated products
class ProductsResponse {
  final List<Product> products;
  final int total;
  final int page;
  final int totalPages;

  ProductsResponse({
    required this.products,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

/// Provider for products repository
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(adminDioProvider));
});
