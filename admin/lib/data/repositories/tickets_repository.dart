import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/support_ticket.dart';

class TicketsRepository {
  final Dio _dio;

  TicketsRepository(this._dio);

  /// Get all support tickets
  Future<TicketsResponse> getTickets({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? assignedTo,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (type != null && type != 'all') queryParams['type'] = type;
      if (assignedTo != null) queryParams['assignedTo'] = assignedTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        ApiEndpoints.tickets,
        queryParameters: queryParams,
      );

      final List<dynamic> ticketsData = response.data['data'] as List<dynamic>;
      final Map<String, dynamic> paginationData =
          response.data['pagination'] as Map<String, dynamic>;

      return TicketsResponse(
        tickets: ticketsData
            .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
            .toList(),
        total: paginationData['total'] as int,
        page: paginationData['page'] as int,
        totalPages: paginationData['totalPages'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get ticket by ID
  Future<SupportTicket> getTicketById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.ticket(id));
      return SupportTicket.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update ticket status
  Future<SupportTicket> updateTicketStatus(int id, String status) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.ticketStatus(id),
        data: {'status': status},
      );
      return SupportTicket.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Assign ticket to admin
  Future<SupportTicket> assignTicket(int id, {int? adminId}) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.ticketAssign(id),
        data: adminId != null ? {'adminId': adminId} : {},
      );
      return SupportTicket.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Resolve ticket with resolution notes
  Future<SupportTicket> resolveTicket(int id, String resolution) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.ticketResolve(id),
        data: {'resolution': resolution},
      );
      return SupportTicket.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for tickets repository
final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  final dio = ref.watch(adminDioProvider);
  return TicketsRepository(dio);
});
