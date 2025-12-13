import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إعدادات النظام',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // General settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإعدادات العامة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSettingRow(
                    context,
                    'فترة التأكيد التلقائي',
                    'عدد الأيام قبل تأكيد المعاملة تلقائياً',
                    child: SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: '7',
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          suffixText: 'يوم',
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  
                  _buildSettingRow(
                    context,
                    'نطاق البحث الافتراضي',
                    'المسافة الافتراضية للبحث عن المنتجات القريبة',
                    child: SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: '50',
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          suffixText: 'كم',
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  
                  _buildSettingRow(
                    context,
                    'حد حجم الصورة',
                    'الحد الأقصى لحجم الصور المرفوعة',
                    child: SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: '5',
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          suffixText: 'MB',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Content policies
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سياسات المحتوى',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSwitchRow(
                    context,
                    'مراجعة المشاريع الجديدة',
                    'طلب موافقة المدير على المشاريع الجديدة',
                    true,
                  ),
                  const Divider(height: 16),
                  
                  _buildSwitchRow(
                    context,
                    'مراجعة المنتجات الجديدة',
                    'طلب موافقة المدير على المنتجات الجديدة',
                    true,
                  ),
                  const Divider(height: 16),
                  
                  _buildSwitchRow(
                    context,
                    'مراجعة التقييمات',
                    'طلب موافقة المدير على التقييمات قبل نشرها',
                    false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إشعارات المدير',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSwitchRow(
                    context,
                    'مشروع جديد في الانتظار',
                    'إرسال إشعار عند تسجيل مشروع جديد',
                    true,
                  ),
                  const Divider(height: 16),
                  
                  _buildSwitchRow(
                    context,
                    'تذكرة دعم جديدة',
                    'إرسال إشعار عند فتح تذكرة دعم جديدة',
                    true,
                  ),
                  const Divider(height: 16),
                  
                  _buildSwitchRow(
                    context,
                    'نزاع جديد',
                    'إرسال إشعار عند فتح نزاع على معاملة',
                    true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save),
              label: const Text('حفظ الإعدادات'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String title,
    String subtitle, {
    required Widget child,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildSwitchRow(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) {},
          activeColor: AdminColors.primary,
        ),
      ],
    );
  }
}

