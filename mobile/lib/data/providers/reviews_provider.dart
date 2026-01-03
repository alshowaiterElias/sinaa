import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';

/// Provider for fetching product reviews
final productReviewsProvider = FutureProvider.autoDispose
    .family<ReviewsResponse, int>((ref, productId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getProductReviews(productId);
});
