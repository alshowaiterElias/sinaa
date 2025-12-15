import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/review_model.dart';

/// Repository for review-related API calls
class ReviewRepository {
  final Dio _dio;

  ReviewRepository(this._dio);

  /// Create a new review
  Future<Review> createReview({
    required int transactionId,
    required int productId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.reviews,
        data: {
          'transactionId': transactionId,
          'productId': productId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );

      if (response.data['success'] == true) {
        return Review.fromJson(response.data['data']);
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ?? 'Failed to create review',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get reviews for a product
  Future<ReviewsResponse> getProductReviews(
    int productId, {
    ReviewStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.reviews}/product/$productId',
        queryParameters: {
          if (status != null) 'status': status.value,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        return ReviewsResponse.fromJson(response.data);
      }
      throw ApiException(
        message: response.data['error']?['message'] ?? 'Failed to get reviews',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user's reviews
  Future<ReviewsResponse> getMyReviews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.reviews}/my',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        return ReviewsResponse.fromJson(response.data);
      }
      throw ApiException(
        message: response.data['error']?['message'] ?? 'Failed to get reviews',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update a review
  Future<Review> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.review(reviewId),
        data: {
          if (rating != null) 'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );

      if (response.data['success'] == true) {
        return Review.fromJson(response.data['data']);
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ?? 'Failed to update review',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete a review
  Future<void> deleteReview(int reviewId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.review(reviewId));

      if (response.data['success'] != true) {
        throw ApiException(
          message:
              response.data['error']?['message'] ?? 'Failed to delete review',
          code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewRepository(dio);
});
