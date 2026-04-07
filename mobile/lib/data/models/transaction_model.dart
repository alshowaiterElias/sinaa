import 'package:flutter/material.dart';

/// Transaction status enum
enum TransactionStatus {
  all,
  pending,
  preparing,
  readyToDeliver,
  delivered,
  disputed,
  cancelled;

  static TransactionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'preparing':
        return TransactionStatus.preparing;
      case 'ready_to_deliver':
        return TransactionStatus.readyToDeliver;
      case 'delivered':
        return TransactionStatus.delivered;
      case 'disputed':
        return TransactionStatus.disputed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case TransactionStatus.all:
        return 'all';
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.preparing:
        return 'preparing';
      case TransactionStatus.readyToDeliver:
        return 'ready_to_deliver';
      case TransactionStatus.delivered:
        return 'delivered';
      case TransactionStatus.disputed:
        return 'disputed';
      case TransactionStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case TransactionStatus.all:
        return 'All';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.preparing:
        return 'Preparing';
      case TransactionStatus.readyToDeliver:
        return 'Ready to Deliver';
      case TransactionStatus.delivered:
        return 'Delivered';
      case TransactionStatus.disputed:
        return 'Disputed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelAr {
    switch (this) {
      case TransactionStatus.all:
        return 'الكل';
      case TransactionStatus.pending:
        return 'قيد الانتظار';
      case TransactionStatus.preparing:
        return 'قيد التجهيز';
      case TransactionStatus.readyToDeliver:
        return 'جاهز للتسليم';
      case TransactionStatus.delivered:
        return 'تم التسليم';
      case TransactionStatus.disputed:
        return 'متنازع عليه';
      case TransactionStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.all:
        return Colors.grey;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.preparing:
        return Colors.blue;
      case TransactionStatus.readyToDeliver:
        return Colors.teal;
      case TransactionStatus.delivered:
        return Colors.green;
      case TransactionStatus.disputed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}

/// Transaction user model
class TransactionUser {
  final int id;
  final String fullName;
  final String? avatarUrl;

  TransactionUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory TransactionUser.fromJson(Map<String, dynamic> json) {
    return TransactionUser(
      id: json['id'] as int,
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }
}

/// Transaction product model
class TransactionProduct {
  final int id;
  final String name;
  final double? price;
  final int? ownerId; // Product owner (from project.ownerId)

  TransactionProduct({
    required this.id,
    required this.name,
    this.price,
    this.ownerId,
  });

  factory TransactionProduct.fromJson(Map<String, dynamic> json) {
    // Backend returns 'basePrice', which may be a num or String (DECIMAL from MySQL)
    final priceValue = json['basePrice'] ?? json['base_price'] ?? json['price'];
    double? parsedPrice;
    if (priceValue != null) {
      if (priceValue is num) {
        parsedPrice = priceValue.toDouble();
      } else if (priceValue is String) {
        parsedPrice = double.tryParse(priceValue);
      }
    }

    // Extract ownerId from nested project
    int? ownerId;
    if (json['project'] != null) {
      final project = json['project'] as Map<String, dynamic>;
      ownerId = project['ownerId'] ?? project['owner_id'];
    }

    return TransactionProduct(
      id: json['id'] as int,
      name: json['name'] ?? '',
      price: parsedPrice,
      ownerId: ownerId,
    );
  }
}

/// Transaction model
class Transaction {
  final int id;
  final int conversationId;
  final int? productId;
  final int initiatedBy;
  final TransactionStatus status;
  final DateTime createdAt;
  final TransactionUser? initiator;
  final TransactionProduct? product;

  /// The customer ID from the conversation (who should submit reviews)
  final int? customerId;

  Transaction({
    required this.id,
    required this.conversationId,
    this.productId,
    required this.initiatedBy,
    required this.status,
    required this.createdAt,
    this.initiator,
    this.product,
    this.customerId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Extract customerId from nested conversation if available
    int? customerId;
    if (json['conversation'] != null) {
      final conversation = json['conversation'] as Map<String, dynamic>;
      customerId = conversation['customerId'] ?? conversation['customer_id'];
    }

    return Transaction(
      id: json['id'] as int,
      conversationId: json['conversationId'] ?? json['conversation_id'] as int,
      productId: json['productId'] ?? json['product_id'],
      initiatedBy: json['initiatedBy'] ?? json['initiated_by'] as int,
      status: TransactionStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      initiator: json['initiator'] != null
          ? TransactionUser.fromJson(json['initiator'])
          : null,
      product: json['product'] != null
          ? TransactionProduct.fromJson(json['product'])
          : null,
      customerId: customerId,
    );
  }

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Check if transaction is confirmed
  bool get isPreparing => status == TransactionStatus.preparing;

  bool get isReadyToDeliver => status == TransactionStatus.readyToDeliver;

  bool get isDelivered => status == TransactionStatus.delivered;

  /// Check if rating is available (delivered)
  bool get canRate => status == TransactionStatus.delivered;

  /// Check if given user can submit a review (must NOT be the product owner)
  bool canSubmitReview(int userId) {
    if (!canRate) return false;
    if (productId == null) return false;
    if (product == null) return false;

    // Only non-owners can submit reviews (customers, not sellers)
    final ownerId = product!.ownerId;
    if (ownerId != null) {
      // User is the product owner = cannot review
      return userId != ownerId;
    }
    // Fallback: if ownerId is null, disallow rating for safety
    return false;
  }

}

/// Response model for paginated transactions
class TransactionsResponse {
  final List<Transaction> transactions;
  final int total;
  final int page;
  final int totalPages;

  TransactionsResponse({
    required this.transactions,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return TransactionsResponse(
      transactions: data.map((e) => Transaction.fromJson(e)).toList(),
      total: pagination['total'] ?? 0,
      page: pagination['page'] ?? 1,
      totalPages: pagination['totalPages'] ?? 1,
    );
  }
}
