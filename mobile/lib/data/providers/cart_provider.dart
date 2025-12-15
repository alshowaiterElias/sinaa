import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';

/// State for the cart
class CartState {
  final List<CartGroup> groups;
  final int totalItems;
  final bool isLoading;
  final String? error;
  final bool isSending;

  const CartState({
    this.groups = const [],
    this.totalItems = 0,
    this.isLoading = false,
    this.error,
    this.isSending = false,
  });

  bool get isEmpty => groups.isEmpty;
  int get projectCount => groups.length;

  CartState copyWith({
    List<CartGroup>? groups,
    int? totalItems,
    bool? isLoading,
    String? error,
    bool? isSending,
  }) {
    return CartState(
      groups: groups ?? this.groups,
      totalItems: totalItems ?? this.totalItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// Cart notifier for managing cart state
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  CartRepository get _repository => ref.read(cartRepositoryProvider);

  /// Load cart from server
  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getCart();
      state = state.copyWith(
        groups: response.groups,
        totalItems: response.totalItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add product to cart
  Future<bool> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
    String? note,
  }) async {
    try {
      await _repository.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        note: note,
      );
      await loadCart(); // Refresh cart
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update cart item
  Future<bool> updateCartItem({
    required int itemId,
    int? quantity,
    String? note,
  }) async {
    try {
      await _repository.updateCartItem(
        itemId: itemId,
        quantity: quantity,
        note: note,
      );
      await loadCart(); // Refresh cart
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(int itemId) async {
    try {
      await _repository.removeFromCart(itemId);
      await loadCart(); // Refresh cart
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart() async {
    try {
      await _repository.clearCart();
      state = const CartState();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send inquiries to all projects
  Future<SendInquiriesResponse?> sendInquiries({String? generalNote}) async {
    state = state.copyWith(isSending: true);
    try {
      final response =
          await _repository.sendInquiries(generalNote: generalNote);
      state = const CartState(); // Clear cart after success
      return response;
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      return null;
    }
  }
}

/// Provider for cart state
final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Provider for cart count (for badge display)
final cartCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(cartRepositoryProvider);
  return repository.getCartCount();
});
