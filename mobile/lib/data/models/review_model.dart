import 'package:flutter/material.dart';

/// Review status enum
enum ReviewStatus {
  pending,
  approved,
  rejected;

  static ReviewStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return ReviewStatus.pending;
      case 'approved':
        return ReviewStatus.approved;
      case 'rejected':
        return ReviewStatus.rejected;
      default:
        return ReviewStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case ReviewStatus.pending:
        return 'pending';
      case ReviewStatus.approved:
        return 'approved';
      case ReviewStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }

  String get labelAr {
    switch (this) {
      case ReviewStatus.pending:
        return 'قيد المراجعة';
      case ReviewStatus.approved:
        return 'معتمد';
      case ReviewStatus.rejected:
        return 'مرفوض';
    }
  }

  Color get color {
    switch (this) {
      case ReviewStatus.pending:
        return Colors.orange;
      case ReviewStatus.approved:
        return Colors.green;
      case ReviewStatus.rejected:
        return Colors.red;
    }
  }
}

/// Review user model
class ReviewUser {
  final int id;
  final String fullName;
  final String? avatarUrl;

  ReviewUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'] as int,
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }
}

/// Review product model
class ReviewProduct {
  final int id;
  final String name;
  final double? price;

  ReviewProduct({
    required this.id,
    required this.name,
    this.price,
  });

  factory ReviewProduct.fromJson(Map<String, dynamic> json) {
    return ReviewProduct(
      id: json['id'] as int,
      name: json['name'] ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }
}

/// Review model
class Review {
  final int id;
  final int productId;
  final int userId;
  final int transactionId;
  final int rating;
  final String? comment;
  final ReviewStatus status;
  final DateTime createdAt;
  final ReviewUser? user;
  final ReviewProduct? product;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.transactionId,
    required this.rating,
    this.comment,
    required this.status,
    required this.createdAt,
    this.user,
    this.product,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      productId: json['productId'] ?? json['product_id'] as int,
      userId: json['userId'] ?? json['user_id'] as int,
      transactionId: json['transactionId'] ?? json['transaction_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'],
      status: ReviewStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      user: json['user'] != null ? ReviewUser.fromJson(json['user']) : null,
      product: json['product'] != null
          ? ReviewProduct.fromJson(json['product'])
          : null,
    );
  }

  /// Is the review approved
  bool get isApproved => status == ReviewStatus.approved;

  /// Is the review pending
  bool get isPending => status == ReviewStatus.pending;
}

/// Response model for paginated reviews
class ReviewsResponse {
  final List<Review> reviews;
  final int total;
  final int page;
  final int totalPages;
  final double averageRating;
  final int totalReviews;

  ReviewsResponse({
    required this.reviews,
    required this.total,
    required this.page,
    required this.totalPages,
    this.averageRating = 0,
    this.totalReviews = 0,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    return ReviewsResponse(
      reviews: data.map((e) => Review.fromJson(e)).toList(),
      total: pagination['total'] ?? 0,
      page: pagination['page'] ?? 1,
      totalPages: pagination['totalPages'] ?? 1,
      averageRating:
          double.tryParse(stats['averageRating']?.toString() ?? '0') ?? 0,
      totalReviews: stats['totalReviews'] ?? 0,
    );
  }
}
