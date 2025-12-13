import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تذاكر الدعم الفني',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('الموضوع')),
                  DataColumn(label: Text('المستخدم')),
                  DataColumn(label: Text('النوع')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('الإجراءات')),
                ],
                rows: List.generate(8, (index) {
                  final status = index % 4;
                  final type = index % 4;
                  
                  return DataRow(cells: [
                    DataCell(Text('#${1000 + index}')),
                    DataCell(Text('مشكلة في الطلب رقم ${index + 100}')),
                    DataCell(Text('مستخدم ${index + 1}')),
                    DataCell(_buildTypeBadge(type)),
                    DataCell(_buildStatusBadge(status)),
                    const DataCell(Text('2024/01/15')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.reply),
                          onPressed: () {},
                        ),
                      ],
                    )),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(int type) {
    final types = ['عام', 'نزاع', 'بلاغ', 'اقتراح'];
    final colors = [AdminColors.info, AdminColors.error, AdminColors.warning, AdminColors.success];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[type].withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        types[type],
        style: TextStyle(
          color: colors[type],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    final statuses = ['مفتوح', 'قيد المعالجة', 'تم الحل', 'مغلق'];
    final bgColors = [
      AdminColors.error.withOpacity(0.1),
      AdminColors.warning.withOpacity(0.1),
      AdminColors.success.withOpacity(0.1),
      AdminColors.textTertiary.withOpacity(0.1),
    ];
    final textColors = [
      AdminColors.error,
      AdminColors.warning,
      AdminColors.success,
      AdminColors.textTertiary,
    ];
    
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

