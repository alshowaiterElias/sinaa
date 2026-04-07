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
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id;
    final isOwner = ref.watch(isProjectOwnerProvider);
    final isRtl = context.isRtl;

    // Project owners get a tabbed view (Incoming / Outgoing)
    if (isOwner) {
      return _OwnerTabbedView(
        state: state,
        currentUserId: currentUserId,
        isRtl: isRtl,
        onRefresh: () async {
          await ref
              .read(transactionsProvider.notifier)
              .loadTransactions(refresh: true);
        },
        onFilter: (status) {
          ref.read(transactionsProvider.notifier).setStatusFilter(status);
        },
      );
    }

    // Regular customer — flat list
    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الطلبات' : 'Orders'),
        actions: [_buildFilterButton(isRtl)],
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

  Widget _buildFilterButton(bool isRtl) {
    return PopupMenuButton<TransactionStatus?>(
      icon: const Icon(Icons.filter_list),
      onSelected: (status) {
        ref.read(transactionsProvider.notifier).setStatusFilter(status);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TransactionStatus.all,
          child: Text(isRtl ? 'الكل' : 'All'),
        ),
        PopupMenuItem(
          value: TransactionStatus.pending,
          child: Text(isRtl ? 'قيد الانتظار' : 'Pending'),
        ),
        PopupMenuItem(
          value: TransactionStatus.preparing,
          child: Text(isRtl ? 'قيد التجهيز' : 'Preparing'),
        ),
        PopupMenuItem(
          value: TransactionStatus.readyToDeliver,
          child: Text(isRtl ? 'جاهز للتسليم' : 'Ready to Deliver'),
        ),
        PopupMenuItem(
          value: TransactionStatus.delivered,
          child: Text(isRtl ? 'تم التسليم' : 'Delivered'),
        ),
        PopupMenuItem(
          value: TransactionStatus.cancelled,
          child: Text(isRtl ? 'ملغي' : 'Cancelled'),
        ),
      ],
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
            isRtl ? 'لا توجد طلبات' : 'No orders',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'ستظهر هنا الطلبات من المحادثات'
                : 'Orders from conversations will appear here',
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

/// Tabbed view for project owners: Incoming (seller) / Outgoing (customer)
class _OwnerTabbedView extends StatelessWidget {
  final TransactionsState state;
  final int? currentUserId;
  final bool isRtl;
  final Future<void> Function() onRefresh;
  final void Function(TransactionStatus?) onFilter;

  const _OwnerTabbedView({
    required this.state,
    required this.currentUserId,
    required this.isRtl,
    required this.onRefresh,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    // Split transactions: incoming = user is seller, outgoing = user initiated
    final incoming = <Transaction>[];
    final outgoing = <Transaction>[];

    for (final t in state.transactions) {
      final isInitiator = t.initiatedBy == currentUserId;
      if (isInitiator) {
        outgoing.add(t);
      } else {
        incoming.add(t);
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRtl ? 'الطلبات' : 'Orders'),
          actions: [
            PopupMenuButton<TransactionStatus?>(
              icon: const Icon(Icons.filter_list),
              onSelected: onFilter,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: TransactionStatus.all,
                  child: Text(isRtl ? 'الكل' : 'All'),
                ),
                PopupMenuItem(
                  value: TransactionStatus.pending,
                  child: Text(isRtl ? 'قيد الانتظار' : 'Pending'),
                ),
                PopupMenuItem(
                  value: TransactionStatus.preparing,
                  child: Text(isRtl ? 'قيد التجهيز' : 'Preparing'),
                ),
                PopupMenuItem(
                  value: TransactionStatus.readyToDeliver,
                  child: Text(isRtl ? 'جاهز للتسليم' : 'Ready to Deliver'),
                ),
                PopupMenuItem(
                  value: TransactionStatus.delivered,
                  child: Text(isRtl ? 'تم التسليم' : 'Delivered'),
                ),
                PopupMenuItem(
                  value: TransactionStatus.cancelled,
                  child: Text(isRtl ? 'ملغي' : 'Cancelled'),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: const Icon(Icons.call_received_rounded, size: 20),
                text: isRtl
                    ? 'واردة (${incoming.length})'
                    : 'Incoming (${incoming.length})',
              ),
              Tab(
                icon: const Icon(Icons.call_made_rounded, size: 20),
                text: isRtl
                    ? 'صادرة (${outgoing.length})'
                    : 'Outgoing (${outgoing.length})',
              ),
            ],
          ),
        ),
        body: state.isLoading && state.transactions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Incoming tab
                  _TransactionList(
                    transactions: incoming,
                    isRtl: isRtl,
                    currentUserId: currentUserId,
                    onRefresh: onRefresh,
                    emptyIcon: Icons.call_received_rounded,
                    emptyTitle:
                        isRtl ? 'لا توجد طلبات واردة' : 'No incoming orders',
                    emptySubtitle: isRtl
                        ? 'الطلبات التي يرسلها العملاء ستظهر هنا'
                        : 'Orders from customers will appear here',
                  ),
                  // Outgoing tab
                  _TransactionList(
                    transactions: outgoing,
                    isRtl: isRtl,
                    currentUserId: currentUserId,
                    onRefresh: onRefresh,
                    emptyIcon: Icons.call_made_rounded,
                    emptyTitle:
                        isRtl ? 'لا توجد طلبات صادرة' : 'No outgoing orders',
                    emptySubtitle: isRtl
                        ? 'الطلبات التي ترسلها كعميل ستظهر هنا'
                        : 'Orders you place as a customer will appear here',
                  ),
                ],
              ),
      ),
    );
  }
}

/// Reusable transaction list with pull-to-refresh and empty state
class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isRtl;
  final int? currentUserId;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _TransactionList({
    required this.transactions,
    required this.isRtl,
    required this.currentUserId,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(emptyIcon, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      emptySubtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
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
