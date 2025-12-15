/// Conversation model for chat
class Conversation {
  final int id;
  final int customerId;
  final int projectId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final ConversationUser? customer;
  final ConversationProject? project;
  final LastMessage? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.customerId,
    required this.projectId,
    this.lastMessageAt,
    required this.createdAt,
    this.customer,
    this.project,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int? ?? 0,
      customerId:
          json['customerId'] as int? ?? json['customer_id'] as int? ?? 0,
      projectId: json['projectId'] as int? ?? json['project_id'] as int? ?? 0,
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
      customer: json['customer'] != null
          ? ConversationUser.fromJson(json['customer'] as Map<String, dynamic>)
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
    if (customerId == currentUserId) {
      // User is customer, show project name
      return project?.getLocalizedName(locale) ?? 'Unknown';
    } else {
      // User is project owner, show customer name
      return customer?.fullName ?? 'Unknown';
    }
  }

  /// Get avatar URL based on user role
  String? getAvatarUrl(int currentUserId) {
    if (customerId == currentUserId) {
      return project?.logoUrl;
    } else {
      return customer?.avatarUrl;
    }
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

  /// Get localized preview
  String getLocalizedPreview(String locale) {
    if (messageType == 'image') {
      return locale == 'ar' ? '📷 صورة' : '📷 Image';
    }
    if (messageType == 'inquiry') {
      return locale == 'ar' ? '📋 استفسار' : '📋 Inquiry';
    }
    if (messageType == 'transaction') {
      return locale == 'ar' ? '⭐ طلب تقييم' : '⭐ Rating Request';
    }
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }
}
