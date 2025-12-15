import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/support_ticket_model.dart';

/// Support tickets repository
class SupportRepository {
  final Dio _dio;

  SupportRepository(this._dio);

  /// Get user's support tickets
  Future<List<SupportTicket>> getMyTickets({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.supportTickets,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get ticket by ID
  Future<SupportTicket> getTicketById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.supportTicket(id));
      return SupportTicket.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a new ticket
  Future<SupportTicket> createTicket({
    required TicketType type,
    required String subject,
    required String description,
    int? relatedId,
    String? relatedType,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.supportTickets,
        data: {
          'type': type.value,
          'subject': subject,
          'description': description,
          if (relatedId != null) 'relatedId': relatedId,
          if (relatedType != null) 'relatedType': relatedType,
        },
      );

      return SupportTicket.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for support repository
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SupportRepository(dio);
});
