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
        title: Text(isRtl ? 'تفاصيل الطلب' : 'Request Details'),
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

  Future<void> _confirmTransaction() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(transactionsProvider.notifier)
        .confirmTransaction(widget.transaction.id);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (widget.isRtl ? 'تم التأكيد بنجاح' : 'Confirmed successfully')
                : (ref.read(transactionsProvider).error ??
                    (widget.isRtl ? 'حدث خطأ' : 'An error occurred')),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        // Invalidate provider to refresh data when coming back
        ref.invalidate(transactionDetailProvider(widget.transaction.id));
        context.pop();
      }
    }
  }

  Future<void> _denyTransaction() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(transactionsProvider.notifier)
        .denyTransaction(widget.transaction.id);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (widget.isRtl ? 'تم الرفض' : 'Denied successfully')
                : (ref.read(transactionsProvider).error ??
                    (widget.isRtl ? 'حدث خطأ' : 'An error occurred')),
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
      if (success) {
        ref.invalidate(transactionDetailProvider(widget.transaction.id));
        context.pop();
      }
    }
  }

  Future<void> _cancelTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isRtl ? 'إلغاء الطلب' : 'Cancel Request'),
        content: Text(
          widget.isRtl
              ? 'هل أنت متأكد من إلغاء طلب التقييم؟'
              : 'Are you sure you want to cancel this rating request?',
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
      setState(() => _isLoading = true);
      final success = await ref
          .read(transactionsProvider.notifier)
          .cancelTransaction(widget.transaction.id);
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (widget.isRtl ? 'تم الإلغاء' : 'Cancelled successfully')
                  : (ref.read(transactionsProvider).error ??
                      (widget.isRtl ? 'حدث خطأ' : 'An error occurred')),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          ref.invalidate(transactionDetailProvider(widget.transaction.id));
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat =
        DateFormat('yyyy/MM/dd HH:mm', widget.isRtl ? 'ar' : 'en');

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

          // Confirmation status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isRtl ? 'حالة التأكيد' : 'Confirmation Status',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmationRow(
                    icon: Icons.person,
                    label: widget.isRtl ? 'العميل' : 'Customer',
                    confirmed: widget.transaction.customerConfirmed,
                  ),
                  const SizedBox(height: 8),
                  _buildConfirmationRow(
                    icon: Icons.store,
                    label: widget.isRtl ? 'البائع' : 'Seller',
                    confirmed: widget.transaction.sellerConfirmed,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-confirm info
          if (widget.transaction.isPending) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isRtl ? 'تأكيد تلقائي' : 'Auto-Confirm',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isRtl
                                ? 'سيتم التأكيد تلقائياً في ${dateFormat.format(widget.transaction.autoConfirmAt)}'
                                : 'Will auto-confirm on ${dateFormat.format(widget.transaction.autoConfirmAt)}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Product info
          if (widget.transaction.product != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(widget.transaction.product!.name),
                subtitle: widget.transaction.product!.price != null
                    ? Text(
                        '${widget.transaction.product!.price!.toStringAsFixed(2)} SAR')
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions for pending transactions
          if (widget.transaction.isPending) ...[
            const SizedBox(height: 8),
            // Confirm/Deny only shown for receiver (not the initiator)
            if (widget.currentUserId != widget.transaction.initiatedBy) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _confirmTransaction,
                      icon: const Icon(Icons.check),
                      label: Text(widget.isRtl ? 'تأكيد' : 'Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _denyTransaction,
                      icon: const Icon(Icons.close),
                      label: Text(widget.isRtl ? 'رفض' : 'Deny'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Cancel button only shown for initiator (the one who sent it)
            if (widget.currentUserId == widget.transaction.initiatedBy) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _cancelTransaction,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(widget.isRtl ? 'إلغاء الطلب' : 'Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
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

  Widget _buildConfirmationRow({
    required IconData icon,
    required String label,
    required bool confirmed,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Icon(
          confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: confirmed ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          confirmed
              ? (widget.isRtl ? 'مؤكد' : 'Confirmed')
              : (widget.isRtl ? 'بانتظار' : 'Pending'),
          style: TextStyle(
            color: confirmed ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.disputed:
        return Icons.warning;
      case TransactionStatus.cancelled:
        return Icons.cancel;
    }
  }
}
