import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboardStats);
      return DashboardStats.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: e.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
