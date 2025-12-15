import 'conversation_model.dart';

/// Message model for chat
class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final ConversationUser? sender;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ??
          json['conversation_id'] as int? ??
          0,
      senderId: json['senderId'] as int? ?? json['sender_id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ??
          json['message_type'] as String? ??
          'text',
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      sender: json['sender'] != null
          ? ConversationUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isTextMessage => messageType == 'text';
  bool get isImageMessage => messageType == 'image';
  bool get isInquiryMessage => messageType == 'inquiry';
  bool get isTransactionMessage => messageType == 'transaction';

  /// Check if this message is from the current user
  bool isFromUser(int currentUserId) => senderId == currentUserId;
}

/// Response for GET /conversations/:id
class ConversationDetailResponse {
  final ConversationDetail conversation;
  final List<Message> messages;

  const ConversationDetailResponse({
    required this.conversation,
    required this.messages,
  });

  factory ConversationDetailResponse.fromJson(Map<String, dynamic> json) {
    return ConversationDetailResponse(
      conversation: ConversationDetail.fromJson(
        json['conversation'] as Map<String, dynamic>,
      ),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Simplified conversation for detail view
class ConversationDetail {
  final int id;
  final int customerId;
  final int projectId;
  final ConversationUser? customer;
  final ConversationProject? project;

  const ConversationDetail({
    required this.id,
    required this.customerId,
    required this.projectId,
    this.customer,
    this.project,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'] as int? ?? 0,
      customerId:
          json['customerId'] as int? ?? json['customer_id'] as int? ?? 0,
      projectId: json['projectId'] as int? ?? json['project_id'] as int? ?? 0,
      customer: json['customer'] != null
          ? ConversationUser.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      project: json['project'] != null
          ? ConversationProject.fromJson(
              json['project'] as Map<String, dynamic>)
          : null,
    );
  }
}
