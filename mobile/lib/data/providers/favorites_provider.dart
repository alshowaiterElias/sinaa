import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/favorite.dart';
import '../repositories/favorites_repository.dart';

/// Provider for the favorites list
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Favorite>>>((ref) {
  return FavoritesNotifier(ref.read(favoritesRepositoryProvider));
});

/// Provider for checking if a specific project is favorited
final isFavoriteProvider =
    FutureProvider.family<bool, int>((ref, projectId) async {
  final repository = ref.read(favoritesRepositoryProvider);
  return repository.checkFavorite(projectId);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Favorite>>> {
  final FavoritesRepository _repository;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  FavoritesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  bool get canLoadMore => _currentPage < _totalPages && !_isLoadingMore;

  Future<void> loadFavorites() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.getFavorites(page: 1);
      _currentPage = response.page;
      _totalPages = response.totalPages;
      state = AsyncValue.data(response.favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    _isLoadingMore = true;

    try {
      final response = await _repository.getFavorites(page: _currentPage + 1);
      _currentPage = response.page;
      _totalPages = response.totalPages;

      state.whenData((currentFavorites) {
        state = AsyncValue.data([...currentFavorites, ...response.favorites]);
      });
    } catch (e) {
      // Silently fail on load more
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> toggleFavorite(int projectId) async {
    try {
      final isFavorite = await _repository.toggleFavorite(projectId);

      state.whenData((favorites) {
        if (isFavorite) {
          // Refresh to get the new favorite with project data
          loadFavorites();
        } else {
          // Remove from list
          state = AsyncValue.data(
            favorites.where((f) => f.project.id != projectId).toList(),
          );
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFavorite(int projectId) async {
    try {
      await _repository.removeFavorite(projectId);

      state.whenData((favorites) {
        state = AsyncValue.data(
          favorites.where((f) => f.project.id != projectId).toList(),
        );
      });
    } catch (e) {
      rethrow;
    }
  }
}
