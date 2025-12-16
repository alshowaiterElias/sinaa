import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../data/models/message_model.dart';

/// Message bubble widget for chat
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // Transaction messages are centered and styled differently
    if (message.isTransactionMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => _navigateToTransaction(context),
            child: _buildTransactionContent(context),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildContent(context),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isTransactionMessage) {
      return _buildTransactionContent(context);
    }

    if (message.isInquiryMessage) {
      return _buildInquiryContent(context);
    }

    if (message.isImageMessage) {
      return _buildImageContent();
    }

    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  /// Parse transaction ID from message content
  int? _getTransactionId() {
    try {
      if (message.content.startsWith('{')) {
        final data = jsonDecode(message.content) as Map<String, dynamic>;
        return data['transactionId'] as int?;
      }
    } catch (_) {}
    return null;
  }

  /// Navigate to transaction details
  void _navigateToTransaction(BuildContext context) {
    final transactionId = _getTransactionId();
    if (transactionId != null) {
      context.push('/transactions/$transactionId');
    } else {
      // Fallback: go to transactions list
      context.push('/transactions');
    }
  }

  Widget _buildTransactionContent(BuildContext context) {
    // Parse product name from JSON content
    String? productName;
    try {
      if (message.content.startsWith('{')) {
        final data = jsonDecode(message.content) as Map<String, dynamic>;
        final locale = Localizations.localeOf(context).languageCode;
        productName = locale == 'ar'
            ? (data['productNameAr'] as String? ??
                data['productName'] as String?)
            : (data['productName'] as String?);
      }
    } catch (_) {}

    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    // Different theme based on who sent the request
    // Sender (isMe = true): green tones - "You sent a rating request"
    // Receiver (isMe = false): amber tones - "You received a rating request"
    final Color bgColor = isMe ? Colors.green.shade50 : Colors.amber.shade50;
    final Color borderColor =
        isMe ? Colors.green.shade200 : Colors.amber.shade200;
    final Color iconBgColor =
        isMe ? Colors.green.shade100 : Colors.amber.shade100;
    final Color iconColor =
        isMe ? Colors.green.shade700 : Colors.amber.shade700;
    final Color titleColor =
        isMe ? Colors.green.shade900 : Colors.amber.shade900;
    final Color subtitleColor =
        isMe ? Colors.green.shade800 : Colors.amber.shade800;
    final Color hintColor =
        isMe ? Colors.green.shade700 : Colors.amber.shade700;

    final String title = isMe
        ? (isRtl ? 'طلب تقييم مُرسل' : 'Rating Request Sent')
        : (isRtl ? 'طلب تقييم وارد' : 'Rating Request Received');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isMe ? Icons.send_rounded : Icons.star_rate_rounded,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: titleColor,
                      ),
                    ),
                    if (productName != null && productName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      isRtl ? 'اضغط للتفاصيل' : 'Tap for details',
                      style: TextStyle(
                        fontSize: 12,
                        color: hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: iconColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withAlpha(30)
                    : AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_long,
                size: 16,
                color: isMe ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Inquiry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white.withAlpha(230) : AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        message.content,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 100,
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(Icons.broken_image, color: AppColors.textTertiary),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
