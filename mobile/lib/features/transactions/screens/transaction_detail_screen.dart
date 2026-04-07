import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sinaa_mobile/config/theme.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync =
        ref.watch(transactionDetailProvider(transactionId));
    final isRtl = context.isRtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'تفاصيل الطلب' : 'Order Details'),
      ),
      body: transactionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                isRtl ? 'خطأ في تحميل البيانات' : 'Error loading data',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(transactionDetailProvider(transactionId)),
                child: Text(isRtl ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
        data: (transaction) {
          if (transaction == null) {
            return Center(
              child: Text(isRtl ? 'الطلب غير موجود' : 'Transaction not found'),
            );
          }
          final currentUserId = ref.watch(currentUserProvider)?.id;
          return _TransactionDetailBody(
            transaction: transaction,
            isRtl: isRtl,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }
}

class _TransactionDetailBody extends ConsumerStatefulWidget {
  final Transaction transaction;
  final bool isRtl;
  final int? currentUserId;

  const _TransactionDetailBody({
    required this.transaction,
    required this.isRtl,
    this.currentUserId,
  });

  @override
  ConsumerState<_TransactionDetailBody> createState() =>
      _TransactionDetailBodyState();
}

class _TransactionDetailBodyState
    extends ConsumerState<_TransactionDetailBody> {
  bool _isLoading = false;

  Future<void> _handleAction(Future<bool> Function(int) action, String successMsgEn, String successMsgAr) async {
    setState(() => _isLoading = true);
    final success = await action(widget.transaction.id);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (widget.isRtl ? successMsgAr : successMsgEn)
                : (ref.read(transactionsProvider).error ??
                    (widget.isRtl ? 'حدث خطأ' : 'An error occurred')),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        ref.invalidate(transactionDetailProvider(widget.transaction.id));
        ref.read(transactionsProvider.notifier).loadTransactions(refresh: true);
        context.pop();
      }
    }
  }

  Future<void> _acceptOrder() async {
    await _handleAction(ref.read(transactionsProvider.notifier).acceptOrder, 'Order Accepted', 'تم قبول الطلب');
  }

  Future<void> _markDeliverable() async {
    await _handleAction(ref.read(transactionsProvider.notifier).markDeliverable, 'Marked Deliverable', 'متوفر للتسليم');
  }

  Future<void> _receiveOrder() async {
    await _handleAction(ref.read(transactionsProvider.notifier).receiveOrder, 'Order Received', 'تم استلام الطلب');
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isRtl ? 'إلغاء الطلب' : 'Cancel Request'),
        content: Text(
          widget.isRtl
              ? 'هل أنت متأكد من إلغاء الطلب؟'
              : 'Are you sure you want to cancel this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.isRtl ? 'لا' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.isRtl ? 'نعم، إلغاء' : 'Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleAction(ref.read(transactionsProvider.notifier).cancelTransaction, 'Order Cancelled', 'تم الإلغاء');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat =
        DateFormat('yyyy/MM/dd HH:mm', widget.isRtl ? 'ar' : 'en');
        
    final isCustomer = widget.currentUserId == widget.transaction.initiatedBy;
    final isSeller = widget.currentUserId != null && widget.currentUserId != widget.transaction.initiatedBy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.transaction.status.color
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: widget.transaction.status.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isRtl
                              ? widget.transaction.status.labelAr
                              : widget.transaction.status.label,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.transaction.status.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(widget.transaction.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Product info
          if (widget.transaction.product != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(widget.transaction.product!.name),
                subtitle: widget.transaction.product!.price != null
                    ? Text(
                        '${widget.transaction.product!.price!.toStringAsFixed(2)} YER')
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Go to Chat button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/chat/${widget.transaction.conversationId}'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(widget.isRtl ? 'الذهاب للمحادثة' : 'Go to Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          if (widget.transaction.isPending && isSeller) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _acceptOrder,
                icon: const Icon(Icons.check),
                label: Text(widget.isRtl ? 'قبول الطلب' : 'Accept Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
            
          if (widget.transaction.isPending && (isCustomer || isSeller)) ...[
             SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _cancelOrder,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(widget.isRtl ? 'إلغاء الطلب' : 'Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
          ],

          if (widget.transaction.isPreparing && isSeller) ...[
             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _markDeliverable,
                icon: const Icon(Icons.local_shipping),
                label: Text(widget.isRtl ? 'جاهز للتسليم' : 'Mark Deliverable'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (widget.transaction.isReadyToDeliver && isCustomer) ...[
             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _receiveOrder,
                icon: const Icon(Icons.done_all),
                label: Text(widget.isRtl ? 'استلام الطلب' : 'Receive Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Rate button for confirmed transactions (only for customer, not product owner)
          if (widget.currentUserId != null &&
              widget.transaction.canSubmitReview(widget.currentUserId!)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                      '/transactions/${widget.transaction.id}/review?productId=${widget.transaction.productId}');
                },
                icon: const Icon(Icons.star),
                label: Text(widget.isRtl ? 'أضف تقييماً' : 'Add Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case TransactionStatus.all:
        return Icons.all_inclusive;
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.preparing:
        return Icons.precision_manufacturing;
      case TransactionStatus.readyToDeliver:
        return Icons.local_shipping;
      case TransactionStatus.delivered:
        return Icons.done_all;
      case TransactionStatus.disputed:
        return Icons.warning;
      case TransactionStatus.cancelled:
        return Icons.cancel;
    }
  }
}
