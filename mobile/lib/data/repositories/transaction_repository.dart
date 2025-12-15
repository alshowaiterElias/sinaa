import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/transaction_model.dart';

/// Repository for transaction-related API calls
class TransactionRepository {
  final Dio _dio;

  TransactionRepository(this._dio);

  /// Initiate a new transaction (rating request)
  Future<Transaction> initiateTransaction({
    required int conversationId,
    int? productId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.transactions,
        data: {
          'conversationId': conversationId,
          if (productId != null) 'productId': productId,
        },
      );

      if (response.data['success'] == true) {
        return Transaction.fromJson(response.data['data']);
      }
      throw ApiException(
        message: response.data['error']?['message'] ??
            'Failed to initiate transaction',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user's transactions
  Future<TransactionsResponse> getTransactions({
    TransactionStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: {
          if (status != null) 'status': status.value,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        return TransactionsResponse.fromJson(response.data);
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ?? 'Failed to get transactions',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get transaction by ID
  Future<Transaction> getTransactionById(int id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.transactions}/$id');

      if (response.data['success'] == true) {
        return Transaction.fromJson(response.data['data']);
      }
      throw ApiException(
        message: response.data['error']?['message'] ?? 'Transaction not found',
        code: response.data['error']?['code'] ?? 'NOT_FOUND',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Confirm transaction
  Future<Transaction> confirmTransaction(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.transactionConfirm(id));

      if (response.data['success'] == true) {
        return Transaction.fromJson(response.data['data']);
      }
      throw ApiException(
        message: response.data['error']?['message'] ??
            'Failed to confirm transaction',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Deny transaction
  Future<Map<String, dynamic>> denyTransaction(int id) async {
    try {
      final response = await _dio.put('${ApiEndpoints.transactions}/$id/deny');

      if (response.data['success'] == true) {
        return {
          'message': response.data['message'],
          'autoConfirmAt': response.data['data']?['autoConfirmAt'],
        };
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ?? 'Failed to deny transaction',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Cancel transaction
  Future<void> cancelTransaction(int id) async {
    try {
      final response =
          await _dio.put('${ApiEndpoints.transactions}/$id/cancel');

      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['error']?['message'] ??
              'Failed to cancel transaction',
          code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Open dispute for transaction
  Future<Map<String, dynamic>> openDispute({
    required int transactionId,
    required String reason,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.transactionDispute(transactionId),
        data: {
          'reason': reason,
          'description': description,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw ApiException(
        message: response.data['error']?['message'] ?? 'Failed to open dispute',
        code: response.data['error']?['code'] ?? 'UNKNOWN_ERROR',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionRepository(dio);
});
