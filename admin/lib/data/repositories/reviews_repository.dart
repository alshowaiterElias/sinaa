import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/review.dart';

class ReviewsRepository {
  final Dio _dio;

  ReviewsRepository(this._dio);

  /// Get all reviews with filters and pagination
  Future<ReviewsResponse> getReviews({
    int page = 1,
    int limit = 20,
    String? status,
    int? productId,
    int? userId,
    String? sort,
    String? search,
    String? searchField,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (productId != null) queryParams['productId'] = productId;
      if (userId != null) queryParams['userId'] = userId;
      if (sort != null) queryParams['sort'] = sort;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (searchField != null && searchField != 'all')
        queryParams['searchField'] = searchField;

      final response = await _dio.get(
        ApiEndpoints.reviews,
        queryParameters: queryParams,
      );

      return ReviewsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get single review by ID
  Future<Review> getReviewById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.review(id));
      return Review.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Approve a review
  Future<Review> approveReview(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.reviewApprove(id));
      return Review.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Reject a review
  Future<Review> rejectReview(int id, {String? reason}) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.reviewReject(id),
        data: reason != null ? {'reason': reason} : null,
      );
      return Review.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for reviews repository
final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(adminDioProvider));
});
