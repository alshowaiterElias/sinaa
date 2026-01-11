import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/product_model.dart';
import 'categories_repository.dart'; // For PaginationInfo

/// Products Repository - handles all product API calls
class ProductsRepository {
  final Dio _dio;

  ProductsRepository(this._dio);

  /// Get all products with pagination and filters
  Future<ProductsResponse> getProducts({
    int page = 1,
    int limit = 20,
    int? categoryId,
    int? projectId,
    String? search,
    String? status,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sort,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (projectId != null) queryParams['projectId'] = projectId;
      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minRating != null) queryParams['minRating'] = minRating;
      if (sort != null) queryParams['sort'] = sort;

      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      final productsList = data['products'] as List? ?? [];

      return ProductsResponse(
        products: productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList(),
        pagination:
            PaginationInfo.fromJson(data['pagination'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get a single product by ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.productDetail(id),
      );

      final data = response.data['data'];
      return Product.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a new product with image file
  Future<Product> createProduct({
    required Map<String, dynamic> productData,
    required List<int> imageBytes,
    required String imageFilename,
    List<int>? tagIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': productData['name'],
        'nameAr': productData['nameAr'],
        'description': productData['description'] ?? '',
        'descriptionAr': productData['descriptionAr'] ?? '',
        'basePrice': productData['basePrice'],
        'quantity': productData['quantity'],
        'categoryId': productData['categoryId'],
        'isAvailable': productData['isAvailable'] ?? true,
        'posterImage': MultipartFile.fromBytes(
          imageBytes,
          filename: imageFilename,
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.products,
        data: formData,
      );

      final data = response.data['data'];
      final product = Product.fromJson(data as Map<String, dynamic>);

      // Add tags if provided
      if (tagIds != null && tagIds.isNotEmpty) {
        for (final tagId in tagIds) {
          await addProductTag(product.id, tagId);
        }
      }

      return product;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update product details
  Future<Product> updateProduct(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.productDetail(id),
        data: updates,
      );

      final data = response.data['data'];
      return Product.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update product poster image
  Future<Product> updateProductPoster(
    int productId,
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final formData = FormData.fromMap({
        'posterImage': MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
        ),
      });

      final response = await _dio.put(
        '${ApiEndpoints.productDetail(productId)}/poster',
        data: formData,
      );

      final data = response.data['data'];
      return Product.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Promote an existing product image to be the new poster
  Future<Product> promoteImageAsPoster(int productId, int imageId) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.productDetail(productId)}/promote-image/$imageId',
      );

      final data = response.data['data'];
      return Product.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete a product
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete(ApiEndpoints.productDetail(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Add image to product
  Future<ProductImage> addProductImage(
      int productId, List<int> imageBytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
        ),
      });

      final response = await _dio.post(
        '${ApiEndpoints.productDetail(productId)}/images',
        data: formData,
      );

      final data = response.data['data'];
      return ProductImage.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete product image
  Future<void> deleteProductImage(int productId, int imageId) async {
    try {
      await _dio
          .delete('${ApiEndpoints.productDetail(productId)}/images/$imageId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get product variants
  Future<List<ProductVariant>> getProductVariants(int productId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.productDetail(productId)}/variants',
      );

      final data = response.data['data'];
      return (data as List)
          .map((json) => ProductVariant.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Add product variant
  Future<ProductVariant> addProductVariant(
      int productId, Map<String, dynamic> variantData) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.productDetail(productId)}/variants',
        data: variantData,
      );

      final data = response.data['data'];
      return ProductVariant.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update product variant
  Future<ProductVariant> updateProductVariant(
      int variantId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.products}/variants/$variantId',
        data: updates,
      );

      final data = response.data['data'];
      return ProductVariant.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete product variant
  Future<void> deleteProductVariant(int variantId) async {
    try {
      await _dio.delete('${ApiEndpoints.products}/variants/$variantId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Add tag to product
  Future<void> addProductTag(int productId, int tagId) async {
    try {
      await _dio.post(
        '${ApiEndpoints.productDetail(productId)}/tags',
        data: {'tagId': tagId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Remove tag from product
  Future<void> removeProductTag(int productId, int tagId) async {
    try {
      await _dio.delete('${ApiEndpoints.productDetail(productId)}/tags/$tagId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get all tags
  Future<List<ProductTag>> getTags() async {
    try {
      final response = await _dio.get('/tags');

      final data = response.data['data'];
      return (data as List)
          .map((json) => ProductTag.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Find or create a tag by name
  Future<ProductTag> findOrCreateTag(String tagName) async {
    try {
      final response = await _dio.post(
        '/tags/find-or-create',
        data: {'name': tagName, 'nameAr': tagName},
      );

      final data = response.data['data'];
      return ProductTag.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Add custom tags to a product (creates tags if needed)
  Future<void> addCustomTagsToProduct(
      int productId, List<String> tagNames) async {
    for (final tagName in tagNames) {
      try {
        // First find or create the tag
        final tag = await findOrCreateTag(tagName);
        // Then link it to the product
        await addProductTag(productId, tag.id);
      } catch (e) {
        // Continue with other tags even if one fails
        print('Failed to add tag "$tagName": $e');
      }
    }
  }
}

/// Response for products list endpoint
class ProductsResponse {
  final List<Product> products;
  final PaginationInfo pagination;

  ProductsResponse({
    required this.products,
    required this.pagination,
  });
}

/// Products repository provider
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProductsRepository(dio);
});
