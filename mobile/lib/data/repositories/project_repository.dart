import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/project_model.dart';
import '../models/product_model.dart';
import 'categories_repository.dart'; // For PaginationInfo

/// Projects Repository - handles all project API calls
class ProjectsRepository {
  final Dio _dio;

  ProjectsRepository(this._dio);

  /// Get all approved projects with pagination and filters
  Future<ProjectsResponse> getProjects({
    int page = 1,
    int limit = 20,
    String? city,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (city != null) queryParams['city'] = city;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        ApiEndpoints.projects,
        queryParameters: queryParams,
      );

      final data = response.data['data'];

      // API returns data as array directly with pagination at root level
      final List projectsList = data is List ? data : data['rows'] as List;
      final paginationData = data is List
          ? response.data['pagination'] as Map<String, dynamic>
          : data['pagination'] as Map<String, dynamic>;

      return ProjectsResponse(
        projects: projectsList
            .map((json) => Project.fromJson(json as Map<String, dynamic>))
            .toList(),
        pagination: PaginationInfo.fromJson(paginationData),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get a single project by ID
  Future<Project> getProjectById(int id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.projectDetail(id),
      );

      final data = response.data['data'];
      return Project.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get products in a project
  Future<ProjectProductsResponse> getProjectProducts(
    int projectId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.projectProducts(projectId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'];

      // Handle both possible response structures
      final List productsList;
      final Map<String, dynamic> paginationData;

      if (data is List) {
        productsList = data;
        paginationData = response.data['pagination'] as Map<String, dynamic>;
      } else {
        productsList = data['rows'] as List;
        paginationData = data['pagination'] as Map<String, dynamic>;
      }

      return ProjectProductsResponse(
        products: productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList(),
        pagination: PaginationInfo.fromJson(paginationData),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get current user's project (for project owners)
  Future<Project> getMyProject() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.myProject,
      );

      final data = response.data['data'];
      return Project.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a new project
  Future<Project> createProject(Map<String, dynamic> projectData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.projects,
        data: projectData,
      );

      final data = response.data['data'];
      return Project.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update project details
  Future<Project> updateProject(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.projectDetail(id),
        data: updates,
      );

      final data = response.data['data'];
      return Project.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Response for projects list endpoint
class ProjectsResponse {
  final List<Project> projects;
  final PaginationInfo pagination;

  ProjectsResponse({
    required this.projects,
    required this.pagination,
  });
}

/// Response for project products endpoint
class ProjectProductsResponse {
  final List<Product> products;
  final PaginationInfo pagination;

  ProjectProductsResponse({
    required this.products,
    required this.pagination,
  });
}

/// Projects repository provider
final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProjectsRepository(dio);
});
