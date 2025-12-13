import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ProjectsListScreen extends StatelessWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إدارة المشاريع',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Tabs
          DefaultTabController(
            length: 3,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    labelColor: AdminColors.primary,
                    unselectedLabelColor: AdminColors.textSecondary,
                    indicatorColor: AdminColors.primary,
                    tabs: const [
                      Tab(text: 'الكل'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('في الانتظار'),
                            SizedBox(width: 8),
                            Badge(
                              backgroundColor: AdminColors.warning,
                              label: Text('3'),
                            ),
                          ],
                        ),
                      ),
                      Tab(text: 'المعتمدة'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildProjectsList(context, 'all'),
                        _buildProjectsList(context, 'pending'),
                        _buildProjectsList(context, 'approved'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(BuildContext context, String filter) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('المشروع')),
            DataColumn(label: Text('المالك')),
            DataColumn(label: Text('المدينة')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('الإجراءات')),
          ],
          rows: List.generate(5, (index) {
            final status = index % 3;
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: AdminColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('مشروع ${index + 1}'),
                      Text(
                        'Project ${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              )),
              DataCell(Text('صاحب المشروع ${index + 1}')),
              const DataCell(Text('الرياض')),
              DataCell(_buildStatusBadge(status)),
              const DataCell(Text('2024/01/15')),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {},
                    tooltip: 'عرض',
                  ),
                  if (status == 0) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AdminColors.success),
                      onPressed: () {},
                      tooltip: 'موافقة',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AdminColors.error),
                      onPressed: () {},
                      tooltip: 'رفض',
                    ),
                  ],
                ],
              )),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    final statuses = ['قيد المراجعة', 'معتمد', 'مرفوض'];
    final bgColors = [AdminColors.pendingBg, AdminColors.approvedBg, AdminColors.rejectedBg];
    final textColors = [AdminColors.pendingText, AdminColors.approvedText, AdminColors.rejectedText];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColors[status],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statuses[status],
        style: TextStyle(
          color: textColors[status],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

