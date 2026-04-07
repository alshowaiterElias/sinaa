import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/transaction_provider.dart';

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
    if (message.isTransactionMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: _TransactionBubbleContent(
            message: message,
            isMe: isMe,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: isMe ? 60 : 0,
        end: isMe ? 0 : 60,
        bottom: 8,
      ),
      child: Align(
        alignment: isMe
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(18),
                  topEnd: const Radius.circular(18),
                  bottomStart: Radius.circular(isMe ? 18 : 4),
                  bottomEnd: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                  _formatTime(message.createdAt.add(const Duration(hours: 3))),
                  style: const TextStyle(
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
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                    ? Colors.white.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
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
            color: isMe ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
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

class _TransactionBubbleContent extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;

  const _TransactionBubbleContent({
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<_TransactionBubbleContent> createState() => _TransactionBubbleContentState();
}

class _TransactionBubbleContentState extends ConsumerState<_TransactionBubbleContent> {
  int? transactionId;
  String? productName;
  String? productNameAr;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _parseMessage();
  }

  void _parseMessage() {
    try {
      if (widget.message.content.startsWith('{')) {
        final data = jsonDecode(widget.message.content) as Map<String, dynamic>;
        transactionId = data['transactionId'] as int?;
        productName = data['productName'] as String?;
        productNameAr = data['productNameAr'] as String?;
      }
    } catch (_) {}
  }

  void _navigateToTransaction(BuildContext context) {
    if (transactionId != null) {
      context.push('/transactions/$transactionId');
    } else {
      context.push('/transactions');
    }
  }

  Widget _buildStages(Transaction transaction, bool isRtl, int currentUserId) {
    final stages = [
      {'key': TransactionStatus.pending, 'en': 'Pending', 'ar': 'الانتظار'},
      {'key': TransactionStatus.preparing, 'en': 'Preparing', 'ar': 'التجهيز'},
      {'key': TransactionStatus.readyToDeliver, 'en': 'Ready', 'ar': 'جاهز'},
      {'key': TransactionStatus.delivered, 'en': 'Delivered', 'ar': 'التسليم'},
    ];

    if (transaction.status == TransactionStatus.cancelled || transaction.status == TransactionStatus.disputed) {
        return Center(
          child: Text(
            isRtl ? transaction.status.labelAr : transaction.status.label,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        );
    }

    int currentIndex = -1;
    if (transaction.status == TransactionStatus.pending) currentIndex = 0;
    else if (transaction.status == TransactionStatus.preparing) currentIndex = 1;
    else if (transaction.status == TransactionStatus.readyToDeliver) currentIndex = 2;
    else if (transaction.status == TransactionStatus.delivered) currentIndex = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.grey.shade300,
                  border: isCurrent ? Border.all(color: Colors.green.shade800, width: 2) : null,
                ),
                child: isActive ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(height: 4),
              Text(
                isRtl ? stages[index]['ar'] as String : stages[index]['en'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.black87 : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActions(Transaction transaction, int currentUserId, bool isRtl) {
    final isCustomer = currentUserId == transaction.initiatedBy;
    final isSeller = currentUserId != transaction.initiatedBy;

    Future<void> _handleAction(Future<bool> Function(int) action) async {
      setState(() => _isLoading = true);
      final success = await action(transaction.id);
      if (mounted) {
        if (success) {
          ref.invalidate(transactionDetailProvider(transaction.id));
        } else {
          final error = ref.read(transactionsProvider).error;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          }
        }
        setState(() => _isLoading = false);
      }
    }

    if (transaction.status == TransactionStatus.pending && isSeller) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 36)),
        onPressed: _isLoading ? null : () => _handleAction(ref.read(transactionsProvider.notifier).acceptOrder),
        child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isRtl ? 'قبول الطلب' : 'Accept Order'),
      );
    } else if (transaction.status == TransactionStatus.preparing && isSeller) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 36)),
        onPressed: _isLoading ? null : () => _handleAction(ref.read(transactionsProvider.notifier).markDeliverable),
        child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isRtl ? 'تحديد كجاهز للتسليم' : 'Mark Deliverable'),
      );
    } else if (transaction.status == TransactionStatus.readyToDeliver && isCustomer) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 36)),
        onPressed: _isLoading ? null : () => _handleAction(ref.read(transactionsProvider.notifier).receiveOrder),
        child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isRtl ? 'استلام الطلب' : 'Receive Order'),
      );
    } else if (transaction.status == TransactionStatus.delivered && isCustomer) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
        onPressed: () {
          context.push('/transactions/${transaction.id}/review?productId=${transaction.productId}');
        },
        child: Text(isRtl ? 'إضافة تقييم' : 'Add Review'),
      );
    }

    // Nothing actionable at this state for this user using minimal buttons
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final name = isRtl ? (productNameAr ?? productName) : productName;
    final currentUserId = ref.watch(currentUserProvider)?.id;

    final Color bgColor = widget.isMe ? Colors.green.shade50 : Colors.blue.shade50;
    final Color borderColor = widget.isMe ? Colors.green.shade200 : Colors.blue.shade200;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: transactionId == null
          ? const Text("Invalid Data")
          : ref.watch(transactionDetailProvider(transactionId!)).when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => const Text("Error loading order"),
              data: (transaction) {
                if (transaction == null) return const Text("Order not found");
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name ?? (isRtl ? 'طلب منتج' : 'Product Order'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStages(transaction, isRtl, currentUserId ?? 0),
                    const SizedBox(height: 16),
                    if (currentUserId != null) _buildActions(transaction, currentUserId, isRtl),
                    Align(
                      alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _navigateToTransaction(context),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(isRtl ? 'عرض التفاصيل' : 'View Details', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
