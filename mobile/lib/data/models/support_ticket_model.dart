import 'package:flutter/material.dart';

/// Ticket type enum
enum TicketType {
  general,
  dispute,
  report,
  feedback,
}

/// Extension for TicketType
extension TicketTypeExtension on TicketType {
  String get value {
    switch (this) {
      case TicketType.general:
        return 'general';
      case TicketType.dispute:
        return 'dispute';
      case TicketType.report:
        return 'report';
      case TicketType.feedback:
        return 'feedback';
    }
  }

  String get label {
    switch (this) {
      case TicketType.general:
        return 'General Inquiry';
      case TicketType.dispute:
        return 'Dispute';
      case TicketType.report:
        return 'Report Issue';
      case TicketType.feedback:
        return 'Feedback';
    }
  }

  String get labelAr {
    switch (this) {
      case TicketType.general:
        return 'استفسار عام';
      case TicketType.dispute:
        return 'نزاع';
      case TicketType.report:
        return 'إبلاغ عن مشكلة';
      case TicketType.feedback:
        return 'ملاحظات';
    }
  }

  IconData get icon {
    switch (this) {
      case TicketType.general:
        return Icons.help_outline;
      case TicketType.dispute:
        return Icons.gavel;
      case TicketType.report:
        return Icons.report_problem_outlined;
      case TicketType.feedback:
        return Icons.feedback_outlined;
    }
  }

  static TicketType fromString(String value) {
    switch (value) {
      case 'general':
        return TicketType.general;
      case 'dispute':
        return TicketType.dispute;
      case 'report':
        return TicketType.report;
      case 'feedback':
        return TicketType.feedback;
      default:
        return TicketType.general;
    }
  }
}

/// Ticket status enum
enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed,
}

/// Extension for TicketStatus
extension TicketStatusExtension on TicketStatus {
  String get value {
    switch (this) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String get labelAr {
    switch (this) {
      case TicketStatus.open:
        return 'مفتوحة';
      case TicketStatus.inProgress:
        return 'قيد المعالجة';
      case TicketStatus.resolved:
        return 'تم الحل';
      case TicketStatus.closed:
        return 'مغلقة';
    }
  }

  Color get color {
    switch (this) {
      case TicketStatus.open:
        return Colors.orange;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  static TicketStatus fromString(String value) {
    switch (value) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }
}

/// User info for ticket assignee
class TicketUser {
  final int id;
  final String fullName;
  final String? avatarUrl;
  final String? email;

  const TicketUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.email,
  });

  factory TicketUser.fromJson(Map<String, dynamic> json) {
    return TicketUser(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Support ticket model
class SupportTicket {
  final int id;
  final int userId;
  final TicketType type;
  final String subject;
  final String description;
  final int? relatedId;
  final String? relatedType;
  final TicketStatus status;
  final int? assignedTo;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TicketUser? user;
  final TicketUser? assignee;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.description,
    this.relatedId,
    this.relatedType,
    required this.status,
    this.assignedTo,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.assignee,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? json['user_id'] as int? ?? 0,
      type:
          TicketTypeExtension.fromString(json['type'] as String? ?? 'general'),
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      relatedId: json['relatedId'] as int? ?? json['related_id'] as int?,
      relatedType:
          json['relatedType'] as String? ?? json['related_type'] as String?,
      status:
          TicketStatusExtension.fromString(json['status'] as String? ?? 'open'),
      assignedTo: json['assignedTo'] as int? ?? json['assigned_to'] as int?,
      resolution: json['resolution'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
      user: json['user'] != null
          ? TicketUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] != null
          ? TicketUser.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Check if ticket is open
  bool get isOpen =>
      status == TicketStatus.open || status == TicketStatus.inProgress;

  /// Check if ticket is closed
  bool get isClosed =>
      status == TicketStatus.resolved || status == TicketStatus.closed;

  /// Get localized type label
  String getLocalizedTypeLabel(String locale) {
    return locale == 'ar' ? type.labelAr : type.label;
  }

  /// Get localized status label
  String getLocalizedStatusLabel(String locale) {
    return locale == 'ar' ? status.labelAr : status.label;
  }
}
