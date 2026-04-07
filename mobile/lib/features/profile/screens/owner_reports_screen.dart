import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/repositories/project_repository.dart';

/// Riverpod provider for owner reports — autoDispose ensures fresh data on each visit
final ownerReportsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(projectsRepositoryProvider);
  return repo.getOwnerReports();
});

class OwnerReportsScreen extends ConsumerStatefulWidget {
  const OwnerReportsScreen({super.key});

  @override
  ConsumerState<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends ConsumerState<OwnerReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Force a fresh fetch every time the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(ownerReportsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(ownerReportsProvider);
    final isRtl = context.isRtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ownerReportsProvider),
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(isRtl
                        ? 'فشل تحميل التقارير'
                        : 'Failed to load reports'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(ownerReportsProvider),
                      child: Text(isRtl ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (data) => _ReportsBody(
            data: data,
            isRtl: isRtl,
            onRefresh: () async => ref.invalidate(ownerReportsProvider),
          ),
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRtl;
  final Future<void> Function() onRefresh;

  const _ReportsBody(
      {required this.data, required this.isRtl, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final project = data['project'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as Map<String, dynamic>? ?? {};
    final orders = data['orders'] as Map<String, dynamic>? ?? {};
    final topProducts = (data['topProducts'] as List?) ?? [];
    final recentOrders = (data['recentOrders'] as List?) ?? [];
    final mostOrdered = data['mostOrderedProduct'] as Map<String, dynamic>?;

    final projectName = isRtl
        ? (project['nameAr'] ?? project['name'] ?? '')
        : (project['name'] ?? '');
    final avgRating = (data['averageRating'] ?? 0).toDouble();
    final totalReviews = data['totalReviews'] ?? 0;
    final activeConversations = data['activeConversations'] ?? 0;
    final totalOrders = orders['total'] ?? 0;
    final deliveredOrders = orders['delivered'] ?? 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isRtl ? 'لوحة التقارير' : 'Reports Dashboard',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Project name
                  Text(
                    projectName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Orders + Rating row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl ? 'الطلبات المكتملة' : 'Completed Orders',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$deliveredOrders',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' / $totalOrders',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.accent, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($totalReviews)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Body content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats Row
                _buildQuickStats(
                    context, products, orders, activeConversations),
                const SizedBox(height: 24),

                // Most Ordered Product
                if (mostOrdered != null) ...[
                  _buildSectionTitle(
                      isRtl ? 'المنتج الأكثر طلباً' : 'Most Ordered Product'),
                  const SizedBox(height: 12),
                  _buildMostOrderedCard(context, mostOrdered),
                  const SizedBox(height: 24),
                ],

                // Order Status Breakdown
                _buildSectionTitle(
                    isRtl ? 'حالة الطلبات' : 'Order Status Breakdown'),
                const SizedBox(height: 12),
                _buildOrderStatusBreakdown(context, orders),
                const SizedBox(height: 24),

                // Top Products
                if (topProducts.isNotEmpty) ...[
                  _buildSectionTitle(
                      isRtl ? 'أكثر المنتجات طلباً' : 'Top Products by Orders'),
                  const SizedBox(height: 12),
                  _buildTopProductsList(context, topProducts),
                  const SizedBox(height: 24),
                ],

                // Recent Orders
                if (recentOrders.isNotEmpty) ...[
                  _buildSectionTitle(isRtl ? 'آخر الطلبات' : 'Recent Orders'),
                  const SizedBox(height: 12),
                  _buildRecentOrdersList(context, recentOrders),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    Map<String, dynamic> products,
    Map<String, dynamic> orders,
    int activeConversations,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2_rounded,
            label: isRtl ? 'المنتجات' : 'Products',
            value: '${products['total'] ?? 0}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_rounded,
            label: isRtl ? 'الطلبات' : 'Orders',
            value: '${orders['total'] ?? 0}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: isRtl ? 'مكتملة' : 'Fulfilled',
            value: '${orders['delivered'] ?? 0}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.chat_rounded,
            label: isRtl ? 'المحادثات' : 'Chats',
            value: '$activeConversations',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildMostOrderedCard(
      BuildContext context, Map<String, dynamic> product) {
    final name =
        isRtl ? (product['nameAr'] ?? product['name']) : product['name'];
    final orderCount = product['orderCount'] ?? 0;
    final price = (product['basePrice'] ?? 0).toDouble();
    final rating = (product['averageRating'] ?? 0).toDouble();
    final imageUrl = product['posterImageUrl'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFEFC5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          // Product image or icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      ApiEndpoints.imageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.accent,
                          size: 32),
                    ),
                  )
                : const Icon(Icons.emoji_events_rounded,
                    color: AppColors.accent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.shopping_cart,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      isRtl ? '$orderCount طلب' : '$orderCount orders',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    if (rating > 0) ...[
                      const Icon(Icons.star, size: 14, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${price.toStringAsFixed(0)} YER',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBreakdown(
      BuildContext context, Map<String, dynamic> orders) {
    final total = (orders['total'] ?? 0) as int;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Center(
          child: Text(
            isRtl ? 'لا توجد طلبات بعد' : 'No orders yet',
            style: const TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final statuses = [
      {
        'key': 'pending',
        'en': 'Pending',
        'ar': 'انتظار',
        'color': Colors.orange
      },
      {
        'key': 'preparing',
        'en': 'Preparing',
        'ar': 'تجهيز',
        'color': Colors.blue
      },
      {
        'key': 'ready_to_deliver',
        'en': 'Ready',
        'ar': 'جاهز',
        'color': Colors.teal
      },
      {
        'key': 'delivered',
        'en': 'Delivered',
        'ar': 'مسلّم',
        'color': Colors.green
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Horizontal stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: statuses.map((s) {
                  final count = (orders[s['key']] ?? 0) as int;
                  if (count == 0) return const SizedBox.shrink();
                  return Expanded(
                    flex: count,
                    child: Container(color: s['color'] as Color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: statuses.map((s) {
              final count = (orders[s['key']] ?? 0) as int;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s['color'] as Color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isRtl ? s['ar'] : s['en']}: $count',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsList(BuildContext context, List topProducts) {
    final maxCount = topProducts.isNotEmpty
        ? (topProducts[0]['orderCount'] as int? ?? 1)
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: topProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value as Map<String, dynamic>;
          final name =
              isRtl ? (product['nameAr'] ?? product['name']) : product['name'];
          final count = product['orderCount'] as int? ?? 0;

          return Padding(
            padding: EdgeInsets.only(
                bottom: index < topProducts.length - 1 ? 12 : 0),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppColors.accent
                        : index == 1
                            ? AppColors.textTertiary
                            : AppColors.divider,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index < 2 ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxCount > 0 ? count / maxCount : 0,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(
                            index == 0
                                ? AppColors.primary
                                : AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentOrdersList(BuildContext context, List recentOrders) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: recentOrders.asMap().entries.map((entry) {
          final index = entry.key;
          final order = entry.value as Map<String, dynamic>;
          final productName = isRtl
              ? (order['productNameAr'] ?? order['productName'] ?? '')
              : (order['productName'] ?? '');
          final status = order['status'] ?? 'pending';
          final customerName = order['customerName'] ?? '';
          final price = order['productPrice'];

          final statusInfo = _getStatusInfo(status);

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        (statusInfo['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusInfo['icon'] as IconData,
                    color: statusInfo['color'] as Color,
                    size: 20,
                  ),
                ),
                title: Text(
                  productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  customerName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (statusInfo['color'] as Color)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRtl
                            ? statusInfo['ar'] as String
                            : statusInfo['en'] as String,
                        style: TextStyle(
                          color: statusInfo['color'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(price as num).toStringAsFixed(0)} YER',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              if (index < recentOrders.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'en': 'Pending',
          'ar': 'انتظار',
          'color': Colors.orange,
          'icon': Icons.schedule
        };
      case 'preparing':
        return {
          'en': 'Preparing',
          'ar': 'تجهيز',
          'color': Colors.blue,
          'icon': Icons.autorenew
        };
      case 'ready_to_deliver':
        return {
          'en': 'Ready',
          'ar': 'جاهز',
          'color': Colors.teal,
          'icon': Icons.local_shipping
        };
      case 'delivered':
        return {
          'en': 'Delivered',
          'ar': 'مسلّم',
          'color': Colors.green,
          'icon': Icons.check_circle
        };
      default:
        return {
          'en': status,
          'ar': status,
          'color': Colors.grey,
          'icon': Icons.info
        };
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
