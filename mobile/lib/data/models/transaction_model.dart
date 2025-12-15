import 'package:flutter/material.dart';

/// Transaction status enum
enum TransactionStatus {
  pending,
  confirmed,
  disputed,
  cancelled;

  static TransactionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'confirmed':
        return TransactionStatus.confirmed;
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
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.confirmed:
        return 'confirmed';
      case TransactionStatus.disputed:
        return 'disputed';
      case TransactionStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.disputed:
        return 'Disputed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelAr {
    switch (this) {
      case TransactionStatus.pending:
        return 'قيد الانتظار';
      case TransactionStatus.confirmed:
        return 'مؤكد';
      case TransactionStatus.disputed:
        return 'متنازع عليه';
      case TransactionStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.confirmed:
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

  TransactionProduct({
    required this.id,
    required this.name,
    this.price,
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
    return TransactionProduct(
      id: json['id'] as int,
      name: json['name'] ?? '',
      price: parsedPrice,
    );
  }
}

/// Transaction model
class Transaction {
  final int id;
  final int conversationId;
  final int? productId;
  final int initiatedBy;
  final bool customerConfirmed;
  final bool sellerConfirmed;
  final DateTime? customerConfirmedAt;
  final DateTime? sellerConfirmedAt;
  final TransactionStatus status;
  final DateTime autoConfirmAt;
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
    required this.customerConfirmed,
    required this.sellerConfirmed,
    this.customerConfirmedAt,
    this.sellerConfirmedAt,
    required this.status,
    required this.autoConfirmAt,
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
      customerConfirmed:
          json['customerConfirmed'] ?? json['customer_confirmed'] ?? false,
      sellerConfirmed:
          json['sellerConfirmed'] ?? json['seller_confirmed'] ?? false,
      customerConfirmedAt: json['customerConfirmedAt'] != null ||
              json['customer_confirmed_at'] != null
          ? DateTime.parse(
              json['customerConfirmedAt'] ?? json['customer_confirmed_at'])
          : null,
      sellerConfirmedAt: json['sellerConfirmedAt'] != null ||
              json['seller_confirmed_at'] != null
          ? DateTime.parse(
              json['sellerConfirmedAt'] ?? json['seller_confirmed_at'])
          : null,
      status: TransactionStatus.fromString(json['status']),
      autoConfirmAt:
          DateTime.parse(json['autoConfirmAt'] ?? json['auto_confirm_at']),
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
  bool get isConfirmed => status == TransactionStatus.confirmed;

  /// Check if rating is available (confirmed or auto-confirm passed)
  bool get canRate =>
      status == TransactionStatus.confirmed ||
      (status == TransactionStatus.pending &&
          DateTime.now().isAfter(autoConfirmAt));

  /// Check if given user can submit a review (must be the customer, not seller)
  bool canSubmitReview(int userId) {
    if (!canRate) return false;
    if (productId == null) return false;
    // Only the customer can submit reviews, not the seller/product owner
    if (customerId != null) {
      return userId == customerId;
    }
    // Fallback: if customerId is null, allow rating (old transactions)
    return true;
  }

  /// Days until auto-confirm
  int get daysUntilAutoConfirm {
    if (status != TransactionStatus.pending) return 0;
    final diff = autoConfirmAt.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
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
