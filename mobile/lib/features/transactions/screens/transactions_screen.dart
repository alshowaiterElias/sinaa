import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sinaa_mobile/config/theme.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    // Load transactions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsProvider.notifier).loadTransactions(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isRtl = context.isRtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'طلبات التقييم' : 'Rating Requests'),
        actions: [
          PopupMenuButton<TransactionStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              ref.read(transactionsProvider.notifier).setStatusFilter(status);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(isRtl ? 'الكل' : 'All'),
              ),
              PopupMenuItem(
                value: TransactionStatus.pending,
                child: Text(isRtl ? 'قيد الانتظار' : 'Pending'),
              ),
              PopupMenuItem(
                value: TransactionStatus.confirmed,
                child: Text(isRtl ? 'مؤكد' : 'Confirmed'),
              ),
              PopupMenuItem(
                value: TransactionStatus.disputed,
                child: Text(isRtl ? 'متنازع' : 'Disputed'),
              ),
              PopupMenuItem(
                value: TransactionStatus.cancelled,
                child: Text(isRtl ? 'ملغي' : 'Cancelled'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(transactionsProvider.notifier)
              .loadTransactions(refresh: true);
        },
        child: state.isLoading && state.transactions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.transactions.isEmpty
                ? _buildEmptyState(isRtl)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = state.transactions[index];
                      return _TransactionCard(
                        transaction: transaction,
                        isRtl: isRtl,
                        currentUserId: currentUserId,
                        onTap: () {
                          context.push('/transactions/${transaction.id}');
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isRtl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isRtl ? 'لا توجد طلبات تقييم' : 'No rating requests',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'سيظهر هنا طلبات التقييم من المحادثات'
                : 'Rating requests from conversations will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final bool isRtl;
  final VoidCallback onTap;
  final int? currentUserId;

  const _TransactionCard({
    required this.transaction,
    required this.isRtl,
    required this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', isRtl ? 'ar' : 'en');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: transaction.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isRtl
                          ? transaction.status.labelAr
                          : transaction.status.label,
                      style: TextStyle(
                        color: transaction.status.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(transaction.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Product info if available
              if (transaction.product != null) ...[
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.product!.name,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Initiator info
              if (transaction.initiator != null)
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      isRtl
                          ? 'بواسطة: ${transaction.initiator!.fullName}'
                          : 'By: ${transaction.initiator!.fullName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

              // Auto-confirm info if pending
              if (transaction.isPending &&
                  transaction.daysUntilAutoConfirm > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      isRtl
                          ? 'تأكيد تلقائي بعد ${transaction.daysUntilAutoConfirm} أيام'
                          : 'Auto-confirm in ${transaction.daysUntilAutoConfirm} days',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],

              // Can rate indicator (only for customers who can review, not product owners)
              if (currentUserId != null &&
                  transaction.canSubmitReview(currentUserId!)) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        isRtl ? 'يمكنك التقييم الآن' : 'Ready to rate',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
