import 'package:equatable/equatable.dart';
import 'project_model.dart';

/// Represents a user's favorite project
class Favorite extends Equatable {
  final int id;
  final Project project;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.project,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as int,
      project: Project.fromJson(json['project'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': project.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, project, createdAt];
}

/// Response model for favorites list
class FavoritesResponse {
  final List<Favorite> favorites;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const FavoritesResponse({
    required this.favorites,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>;
    final favoritesJson = data['favorites'] as List<dynamic>;

    return FavoritesResponse(
      favorites: favoritesJson
          .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }
}
