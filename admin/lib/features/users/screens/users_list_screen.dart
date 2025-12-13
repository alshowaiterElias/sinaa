import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إدارة المستخدمين',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('إضافة مستخدم'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'بحث عن مستخدم...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    hint: const Text('الدور'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'customer', child: Text('عميل')),
                      DropdownMenuItem(value: 'project_owner', child: Text('صاحب مشروع')),
                      DropdownMenuItem(value: 'admin', child: Text('مدير')),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    hint: const Text('الحالة'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'active', child: Text('نشط')),
                      DropdownMenuItem(value: 'banned', child: Text('محظور')),
                    ],
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data table
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('المستخدم')),
                    DataColumn(label: Text('البريد الإلكتروني')),
                    DataColumn(label: Text('الدور')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('تاريخ التسجيل')),
                    DataColumn(label: Text('الإجراءات')),
                  ],
                  rows: List.generate(10, (index) {
                    return DataRow(cells: [
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AdminColors.primary.withOpacity(0.1),
                            child: Text(
                              'أ',
                              style: TextStyle(
                                color: AdminColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('مستخدم ${index + 1}'),
                        ],
                      )),
                      DataCell(Text('user${index + 1}@example.com')),
                      DataCell(_buildRoleBadge(index % 3)),
                      DataCell(_buildStatusBadge(index % 2 == 0)),
                      const DataCell(Text('2024/01/15')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {},
                            tooltip: 'عرض',
                          ),
                          IconButton(
                            icon: Icon(
                              index % 2 == 0 ? Icons.block : Icons.check_circle,
                              color: index % 2 == 0 ? AdminColors.error : AdminColors.success,
                            ),
                            onPressed: () {},
                            tooltip: index % 2 == 0 ? 'حظر' : 'إلغاء الحظر',
                          ),
                        ],
                      )),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(int roleIndex) {
    final roles = ['عميل', 'صاحب مشروع', 'مدير'];
    final colors = [AdminColors.info, AdminColors.success, AdminColors.primary];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[roleIndex].withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        roles[roleIndex],
        style: TextStyle(
          color: colors[roleIndex],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AdminColors.approvedBg : AdminColors.rejectedBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'نشط' : 'محظور',
        style: TextStyle(
          color: isActive ? AdminColors.approvedText : AdminColors.rejectedText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

