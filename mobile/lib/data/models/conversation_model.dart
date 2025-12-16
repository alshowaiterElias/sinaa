import 'dart:convert';

/// Conversation model for chat
class Conversation {
  final int id;
  final int? user1Id;
  final int? user2Id;
  final int? projectId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final ConversationUser? user1;
  final ConversationUser? user2;
  final ConversationUser? otherUser;
  final ConversationProject? project;
  final LastMessage? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.id,
    this.user1Id,
    this.user2Id,
    this.projectId,
    this.lastMessageAt,
    required this.createdAt,
    this.user1,
    this.user2,
    this.otherUser,
    this.project,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int? ?? 0,
      user1Id: json['user1Id'] as int? ?? json['user1_id'] as int?,
      user2Id: json['user2Id'] as int? ?? json['user2_id'] as int?,
      projectId: json['projectId'] as int? ?? json['project_id'] as int?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : json['last_message_at'] != null
              ? DateTime.parse(json['last_message_at'] as String)
              : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      user1: json['user1'] != null
          ? ConversationUser.fromJson(json['user1'] as Map<String, dynamic>)
          : null,
      user2: json['user2'] != null
          ? ConversationUser.fromJson(json['user2'] as Map<String, dynamic>)
          : null,
      otherUser: json['otherUser'] != null
          ? ConversationUser.fromJson(json['otherUser'] as Map<String, dynamic>)
          : null,
      project: json['project'] != null
          ? ConversationProject.fromJson(
              json['project'] as Map<String, dynamic>)
          : null,
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  /// Get display name based on user role
  String getDisplayName(int currentUserId, String locale) {
    // Use otherUser if available (new schema)
    if (otherUser != null) {
      return otherUser!.fullName;
    }
    // Fallback to project name if available
    return project?.getLocalizedName(locale) ?? 'Unknown';
  }

  /// Get avatar URL based on user role
  String? getAvatarUrl(int currentUserId) {
    // Use otherUser if available (new schema)
    if (otherUser != null) {
      return otherUser!.avatarUrl;
    }
    // Fallback to project logo
    return project?.logoUrl;
  }
}

/// User info in conversation
class ConversationUser {
  final int id;
  final String fullName;
  final String? avatarUrl;

  const ConversationUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id'] as int? ?? 0,
      fullName:
          json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }
}

/// Project info in conversation
class ConversationProject {
  final int id;
  final String name;
  final String nameAr;
  final String? logoUrl;
  final int? userId;
  final ConversationUser? owner;

  const ConversationProject({
    required this.id,
    required this.name,
    required this.nameAr,
    this.logoUrl,
    this.userId,
    this.owner,
  });

  factory ConversationProject.fromJson(Map<String, dynamic> json) {
    return ConversationProject(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      userId: json['userId'] as int? ?? json['user_id'] as int?,
      owner: json['owner'] != null
          ? ConversationUser.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }

  String getLocalizedName(String locale) {
    return locale == 'ar' ? nameAr : name;
  }
}

/// Last message preview
class LastMessage {
  final int id;
  final String content;
  final String messageType;
  final int senderId;
  final String? senderName;
  final DateTime createdAt;

  const LastMessage({
    required this.id,
    required this.content,
    required this.messageType,
    required this.senderId,
    this.senderName,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ??
          json['message_type'] as String? ??
          'text',
      senderId: json['senderId'] as int? ?? json['sender_id'] as int? ?? 0,
      senderName:
          json['senderName'] as String? ?? json['sender_name'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  String get preview {
    if (messageType == 'image') return '📷 Image';
    if (messageType == 'inquiry') return '📋 Inquiry';
    if (messageType == 'transaction') return '⭐ Rating Request';
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  /// Get localized preview with product name for transaction messages
  String getLocalizedPreview(String locale) {
    if (messageType == 'image') {
      return locale == 'ar' ? '📷 صورة' : '📷 Image';
    }
    if (messageType == 'inquiry') {
      return locale == 'ar' ? '📋 استفسار' : '📋 Inquiry';
    }
    if (messageType == 'transaction') {
      // Try to parse JSON content for product name
      try {
        final data = jsonDecode(content) as Map<String, dynamic>;
        final productName = locale == 'ar'
            ? (data['productNameAr'] as String? ??
                data['productName'] as String?)
            : (data['productName'] as String?);
        if (productName != null && productName.isNotEmpty) {
          return locale == 'ar'
              ? '⭐ طلب تقييم: $productName'
              : '⭐ Rating: $productName';
        }
      } catch (_) {
        // JSON parsing failed, use default
      }
      return locale == 'ar' ? '⭐ طلب تقييم' : '⭐ Rating Request';
    }
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }
}
