import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Repository for chat operations (REST API)
class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  /// Get user's conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get(ApiEndpoints.conversations);
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get single conversation with messages
  Future<ConversationDetailResponse> getConversation(
    int conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.conversation(conversationId),
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ConversationDetailResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Start a new conversation with a project
  Future<Conversation> createConversation(int projectId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversations,
        data: {'projectId': projectId},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Conversation.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Send message (REST fallback)
  Future<Message> sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversationMessages(conversationId),
        data: {
          'content': content,
          'messageType': messageType,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Message.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _dio.put(ApiEndpoints.conversationRead(conversationId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for chat repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatRepository(dio);
});
