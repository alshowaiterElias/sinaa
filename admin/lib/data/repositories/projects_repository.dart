import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/project.dart';

class ProjectsRepository {
  final Dio _dio;

  ProjectsRepository(this._dio);

  Future<ProjectsResponse> getProjects({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        ApiEndpoints.projects,
        queryParameters: queryParams,
      );

      final List<dynamic> projectsData = response.data['data'] as List<dynamic>;
      final Map<String, dynamic> paginationData =
          response.data['pagination'] as Map<String, dynamic>;

      return ProjectsResponse(
        projects: projectsData
            .map((json) => Project.fromJson(json as Map<String, dynamic>))
            .toList(),
        total: paginationData['total'] as int,
        page: paginationData['page'] as int,
        totalPages: paginationData['totalPages'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> getProjectById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.project(id));
      return Project.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> approveProject(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.projectApprove(id));
      return Project.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> rejectProject(int id, String reason) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.projectReject(id),
        data: {'reason': reason},
      );
      return Project.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> disableProject(int id, String reason) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.projectDisable(id),
        data: {'reason': reason},
      );
      return Project.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> enableProject(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.projectEnable(id));
      return Project.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class ProjectsResponse {
  final List<Project> projects;
  final int total;
  final int page;
  final int totalPages;

  ProjectsResponse({
    required this.projects,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(adminDioProvider));
});
