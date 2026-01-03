import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../repositories/reviews_repository.dart';

/// Reviews list state
class ReviewsListState {
  final List<Review> reviews;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String statusFilter;
  final String sortBy;
  final String search;
  final String searchField;

  const ReviewsListState({
    this.reviews = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.statusFilter = 'all',
    this.sortBy = 'pending_first',
    this.search = '',
    this.searchField = 'all',
  });

  bool get hasMore => page < totalPages;

  ReviewsListState copyWith({
    List<Review>? reviews,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? sortBy,
    String? search,
    String? searchField,
  }) {
    return ReviewsListState(
      reviews: reviews ?? this.reviews,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      sortBy: sortBy ?? this.sortBy,
      search: search ?? this.search,
      searchField: searchField ?? this.searchField,
    );
  }
}

/// Reviews list notifier
class ReviewsListNotifier extends Notifier<ReviewsListState> {
  late ReviewsRepository _repository;

  @override
  ReviewsListState build() {
    _repository = ref.watch(reviewsRepositoryProvider);
    // Load reviews on init
    Future.microtask(() => loadReviews(refresh: true));
    return const ReviewsListState(isLoading: true);
  }

  /// Load reviews with current filters
  Future<void> loadReviews({bool refresh = false, int? page}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final targetPage = page ?? (refresh ? 1 : state.page);
      final response = await _repository.getReviews(
        page: targetPage,
        limit: 20,
        status: state.statusFilter,
        sort: state.sortBy,
        search: state.search.isNotEmpty ? state.search : null,
        searchField: state.searchField,
      );

      state = state.copyWith(
        reviews: response.reviews,
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set status filter
  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadReviews(refresh: true);
  }

  /// Set sort order
  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
    loadReviews(refresh: true);
  }

  /// Set search query and field
  void setSearch(String query, {String? field}) {
    state = state.copyWith(
      search: query,
      searchField: field ?? state.searchField,
    );
    loadReviews(refresh: true);
  }

  /// Set search field only
  void setSearchField(String field) {
    state = state.copyWith(searchField: field);
    if (state.search.isNotEmpty) {
      loadReviews(refresh: true);
    }
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(search: '', searchField: 'all');
    loadReviews(refresh: true);
  }

  /// Approve a review
  Future<bool> approveReview(int reviewId) async {
    try {
      final updatedReview = await _repository.approveReview(reviewId);
      state = state.copyWith(
        reviews: state.reviews.map((r) {
          return r.id == reviewId ? updatedReview : r;
        }).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject a review
  Future<bool> rejectReview(int reviewId, {String? reason}) async {
    try {
      final updatedReview =
          await _repository.rejectReview(reviewId, reason: reason);
      state = state.copyWith(
        reviews: state.reviews.map((r) {
          return r.id == reviewId ? updatedReview : r;
        }).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ============ Providers ============

/// Reviews list provider
final reviewsListProvider =
    NotifierProvider<ReviewsListNotifier, ReviewsListState>(() {
  return ReviewsListNotifier();
});
