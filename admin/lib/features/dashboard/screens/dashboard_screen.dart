import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../config/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'لوحة التحكم',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'مرحباً بك في لوحة إدارة صنعة',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Stats cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final crossAxisCount = isWide ? 4 : 2;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 1.5 : 1.3,
                children: const [
                  _StatCard(
                    title: 'المستخدمين',
                    value: '1,234',
                    change: '+12%',
                    isPositive: true,
                    icon: Icons.people,
                    color: AdminColors.info,
                  ),
                  _StatCard(
                    title: 'المشاريع',
                    value: '156',
                    change: '+8%',
                    isPositive: true,
                    icon: Icons.store,
                    color: AdminColors.success,
                  ),
                  _StatCard(
                    title: 'المنتجات',
                    value: '2,847',
                    change: '+23%',
                    isPositive: true,
                    icon: Icons.inventory_2,
                    color: AdminColors.accent,
                  ),
                  _StatCard(
                    title: 'تذاكر مفتوحة',
                    value: '12',
                    change: '-5%',
                    isPositive: true,
                    icon: Icons.support_agent,
                    color: AdminColors.warning,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Charts row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildUserGrowthChart(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCategoryDistribution(context)),
                  ],
                );
              }

              return Column(
                children: [
                  _buildUserGrowthChart(context),
                  const SizedBox(height: 16),
                  _buildCategoryDistribution(context),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Pending approvals and recent activity
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPendingApprovals(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRecentActivity(context)),
                  ],
                );
              }

              return Column(
                children: [
                  _buildPendingApprovals(context),
                  const SizedBox(height: 16),
                  _buildRecentActivity(context),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نمو المستخدمين',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: AdminColors.divider, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AdminColors.textTertiary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'يناير',
                            'فبراير',
                            'مارس',
                            'أبريل',
                            'مايو',
                            'يونيو',
                          ];
                          if (value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(
                                color: AdminColors.textTertiary,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 30),
                        FlSpot(1, 45),
                        FlSpot(2, 55),
                        FlSpot(3, 70),
                        FlSpot(4, 85),
                        FlSpot(5, 100),
                      ],
                      isCurved: true,
                      color: AdminColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AdminColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistribution(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'توزيع التصنيفات',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: 35,
                      title: '35%',
                      color: AdminColors.primary,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: '25%',
                      color: AdminColors.accent,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: AdminColors.success,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: AdminColors.info,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('طعام', AdminColors.primary),
                _buildLegendItem('حرف يدوية', AdminColors.accent),
                _buildLegendItem('ملابس', AdminColors.success),
                _buildLegendItem('أخرى', AdminColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'في انتظار الموافقة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(onPressed: () {}, child: const Text('عرض الكل')),
              ],
            ),
            const SizedBox(height: 16),
            _buildPendingItem(
              context,
              type: 'مشروع',
              name: 'مطبخ أم محمد',
              time: 'منذ ساعتين',
              color: AdminColors.success,
            ),
            _buildPendingItem(
              context,
              type: 'منتج',
              name: 'كيكة الشوكولاتة',
              time: 'منذ 3 ساعات',
              color: AdminColors.accent,
            ),
            _buildPendingItem(
              context,
              type: 'تقييم',
              name: 'تقييم على منتج #234',
              time: 'منذ 5 ساعات',
              color: AdminColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItem(
    BuildContext context, {
    required String type,
    required String name,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '$type • $time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('مراجعة')),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النشاط الأخير',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              context,
              icon: Icons.person_add,
              iconColor: AdminColors.info,
              title: 'مستخدم جديد',
              subtitle: 'أحمد محمد سجل حساب جديد',
              time: 'منذ 5 دقائق',
            ),
            _buildActivityItem(
              context,
              icon: Icons.check_circle,
              iconColor: AdminColors.success,
              title: 'موافقة على مشروع',
              subtitle: 'تمت الموافقة على مشروع "حلويات نورة"',
              time: 'منذ 20 دقيقة',
            ),
            _buildActivityItem(
              context,
              icon: Icons.shopping_bag,
              iconColor: AdminColors.accent,
              title: 'منتج جديد',
              subtitle: 'تم إضافة منتج جديد في قسم الطعام',
              time: 'منذ ساعة',
            ),
            _buildActivityItem(
              context,
              icon: Icons.star,
              iconColor: AdminColors.warning,
              title: 'تقييم جديد',
              subtitle: 'أحمد قيّم منتج بـ 5 نجوم',
              time: 'منذ ساعتين',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AdminColors.success.withOpacity(0.1)
                        : AdminColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: isPositive
                          ? AdminColors.success
                          : AdminColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
