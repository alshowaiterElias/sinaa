import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/cart_item_model.dart';

/// Repository for cart operations
class CartRepository {
  final Dio _dio;

  CartRepository(this._dio);

  /// Get user's cart with items grouped by project
  Future<CartResponse> getCart() async {
    try {
      final response = await _dio.get(ApiEndpoints.cart);
      final data = response.data['data'] as Map<String, dynamic>;
      return CartResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Add product to cart
  Future<CartItem> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.cart,
        data: {
          'productId': productId,
          if (variantId != null) 'variantId': variantId,
          'quantity': quantity,
          if (note != null) 'note': note,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return CartItem.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update cart item quantity or note
  Future<CartItem> updateCartItem({
    required int itemId,
    int? quantity,
    String? note,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.cartItem(itemId),
        data: {
          if (quantity != null) 'quantity': quantity,
          if (note != null) 'note': note,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return CartItem.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(int itemId) async {
    try {
      await _dio.delete(ApiEndpoints.cartItem(itemId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiEndpoints.cart);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get cart items count
  Future<int> getCartCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.cartCount);
      final data = response.data['data'] as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Send inquiries to all projects in cart
  Future<SendInquiriesResponse> sendInquiries({String? generalNote}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.cartSendInquiries,
        data: {
          if (generalNote != null) 'generalNote': generalNote,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return SendInquiriesResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for cart repository
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CartRepository(dio);
});
