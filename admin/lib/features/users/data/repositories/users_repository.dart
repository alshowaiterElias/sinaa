import 'package:dio/dio.dart';
import '../../../../data/models/admin_user.dart';

class UsersRepository {
  final Dio _dio;

  UsersRepository(this._dio);

  Future<UsersResponse> getUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role != 'all') 'role': role,
        if (status != null && status != 'all') 'status': status,
      };

      final response = await _dio.get(
        '/admin/users',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> usersJson = data['users'];
      final users = usersJson.map((json) => AdminUser.fromJson(json)).toList();

      return UsersResponse(
        users: users,
        total: data['total'],
        totalPages: data['totalPages'],
        currentPage: data['page'],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleUserBan(int userId) async {
    try {
      await _dio.put('/admin/users/$userId/ban');
    } catch (e) {
      rethrow;
    }
  }
}

class UsersResponse {
  final List<AdminUser> users;
  final int total;
  final int totalPages;
  final int currentPage;

  UsersResponse({
    required this.users,
    required this.total,
    required this.totalPages,
    required this.currentPage,
  });
}
