/// Notification types
enum NotificationType {
  message,
  transaction,
  review,
  projectApproval,
  productApproval,
  inquiry,
}

/// Extension to parse notification type from string
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.message:
        return 'message';
      case NotificationType.transaction:
        return 'transaction';
      case NotificationType.review:
        return 'review';
      case NotificationType.projectApproval:
        return 'project_approval';
      case NotificationType.productApproval:
        return 'product_approval';
      case NotificationType.inquiry:
        return 'inquiry';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'message':
        return NotificationType.message;
      case 'transaction':
        return NotificationType.transaction;
      case 'review':
        return NotificationType.review;
      case 'project_approval':
        return NotificationType.projectApproval;
      case 'product_approval':
        return NotificationType.productApproval;
      case 'inquiry':
        return NotificationType.inquiry;
      default:
        return NotificationType.message;
    }
  }
}

/// Notification data (additional info)
class NotificationData {
  final int? conversationId;
  final int? projectId;
  final int? productId;
  final int? transactionId;
  final int? reviewId;
  final int? messageId;
  final int? senderId;
  final String? senderName;
  final int? rating;

  const NotificationData({
    this.conversationId,
    this.projectId,
    this.productId,
    this.transactionId,
    this.reviewId,
    this.messageId,
    this.senderId,
    this.senderName,
    this.rating,
  });

  factory NotificationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationData();
    return NotificationData(
      conversationId: json['conversationId'] as int?,
      projectId: json['projectId'] as int?,
      productId: json['productId'] as int?,
      transactionId: json['transactionId'] as int?,
      reviewId: json['reviewId'] as int?,
      messageId: json['messageId'] as int?,
      senderId: json['senderId'] as int?,
      senderName: json['senderName'] as String?,
      rating: json['rating'] as int?,
    );
  }
}

/// Notification model
class AppNotification {
  final int id;
  final int userId;
  final NotificationType type;
  final String title;
  final String titleAr;
  final String? body;
  final String? bodyAr;
  final NotificationData? data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.titleAr,
    this.body,
    this.bodyAr,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? json['user_id'] as int? ?? 0,
      type: NotificationTypeExtension.fromString(
          json['type'] as String? ?? 'message'),
      title: json['title'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? json['title_ar'] as String? ?? '',
      body: json['body'] as String?,
      bodyAr: json['bodyAr'] as String? ?? json['body_ar'] as String?,
      data: json['data'] != null
          ? NotificationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  /// Get localized title
  String getLocalizedTitle(String locale) {
    return locale == 'ar' ? titleAr : title;
  }

  /// Get localized body
  String? getLocalizedBody(String locale) {
    return locale == 'ar' ? bodyAr : body;
  }

  /// Get icon for notification type
  String get iconName {
    switch (type) {
      case NotificationType.message:
      case NotificationType.inquiry:
        return 'chat_bubble';
      case NotificationType.transaction:
        return 'receipt_long';
      case NotificationType.review:
        return 'star';
      case NotificationType.projectApproval:
        return 'store';
      case NotificationType.productApproval:
        return 'inventory_2';
    }
  }

  /// Copy with isRead updated
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      titleAr: titleAr,
      body: body,
      bodyAr: bodyAr,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
