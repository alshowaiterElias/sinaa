import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/favorite.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.read(dioProvider));
});

class FavoritesRepository {
  final Dio _dio;

  FavoritesRepository(this._dio);

  /// Get user's favorite projects
  Future<FavoritesResponse> getFavorites({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.favorites,
        queryParameters: {'page': page, 'limit': limit},
      );
      return FavoritesResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Add a project to favorites
  Future<void> addFavorite(int projectId) async {
    try {
      await _dio.post('${ApiEndpoints.favorites}/$projectId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Remove a project from favorites
  Future<void> removeFavorite(int projectId) async {
    try {
      await _dio.delete('${ApiEndpoints.favorites}/$projectId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Check if a project is in favorites
  Future<bool> checkFavorite(int projectId) async {
    try {
      final response =
          await _dio.get('${ApiEndpoints.favorites}/$projectId/check');
      final data = response.data as Map<String, dynamic>;
      return data['data']['isFavorite'] as bool;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(int projectId) async {
    try {
      final response =
          await _dio.post('${ApiEndpoints.favorites}/$projectId/toggle');
      final data = response.data as Map<String, dynamic>;
      return data['data']['isFavorite'] as bool;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
