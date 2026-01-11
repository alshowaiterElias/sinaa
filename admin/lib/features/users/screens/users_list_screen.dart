import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../data/models/admin_user.dart';
import '../data/providers/users_provider.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(usersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersProvider);

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
              // Add User button removed or can be kept if needed
              // ElevatedButton.icon(
              //   onPressed: () {},
              //   icon: const Icon(Icons.add),
              //   label: const Text('إضافة مستخدم'),
              // ),
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
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'بحث عن مستخدم...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (value) {
                        ref.read(usersProvider.notifier).setSearch(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      ref
                          .read(usersProvider.notifier)
                          .setSearch(_searchController.text);
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: state.roleFilter,
                    hint: const Text('الدور'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'customer', child: Text('عميل')),
                      DropdownMenuItem(
                        value: 'project_owner',
                        child: Text('صاحب مشروع'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('مدير')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(usersProvider.notifier).setRoleFilter(value);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: state.statusFilter,
                    hint: const Text('الحالة'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'active', child: Text('نشط')),
                      DropdownMenuItem(value: 'banned', child: Text('محظور')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(usersProvider.notifier).setStatusFilter(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Error Message
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Data table
          Expanded(
            child: Card(
              child: state.users.isEmpty && !state.isLoading
                  ? const Center(child: Text('لا يوجد مستخدمين'))
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('المستخدم')),
                              DataColumn(label: Text('البريد الإلكتروني')),
                              DataColumn(label: Text('الدور')),
                              DataColumn(label: Text('الحالة')),
                              DataColumn(label: Text('تاريخ التسجيل')),
                              DataColumn(label: Text('الإجراءات')),
                            ],
                            rows: state.users.map((user) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage:
                                              user.avatarUrl != null
                                              ? NetworkImage(user.avatarUrl!)
                                              : null,
                                          backgroundColor: AdminColors.primary
                                              .withOpacity(0.1),
                                          child: user.avatarUrl == null
                                              ? Text(
                                                  user.initials,
                                                  style: TextStyle(
                                                    color: AdminColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(user.fullName),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(user.email)),
                                  DataCell(_buildRoleBadge(user.role)),
                                  DataCell(_buildStatusBadge(user.isActive)),
                                  DataCell(
                                    Text(
                                      DateFormat(
                                        'yyyy/MM/dd',
                                      ).format(user.createdAt),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        // IconButton(
                                        //   icon: const Icon(Icons.visibility),
                                        //   onPressed: () {},
                                        //   tooltip: 'عرض',
                                        // ),
                                        IconButton(
                                          icon: Icon(
                                            user.isActive
                                                ? Icons.block
                                                : Icons.check_circle,
                                            color: user.isActive
                                                ? AdminColors.error
                                                : AdminColors.success,
                                          ),
                                          onPressed: () {
                                            _confirmToggleBan(context, user);
                                          },
                                          tooltip: user.isActive
                                              ? 'حظر'
                                              : 'إلغاء الحظر',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          if (state.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = AdminColors.primary;
        label = 'مدير';
        break;
      case 'project_owner':
        color = AdminColors.success;
        label = 'صاحب مشروع';
        break;
      case 'customer':
      default:
        color = AdminColors.info;
        label = 'عميل';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
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

  void _confirmToggleBan(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'حظر المستخدم' : 'إلغاء حظر المستخدم'),
        content: Text(
          user.isActive
              ? 'هل أنت متأكد من رغبتك في حظر ${user.fullName}؟'
              : 'هل أنت متأكد من رغبتك في إلغاء حظر ${user.fullName}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(usersProvider.notifier).toggleUserBan(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'حظر' : 'إلغاء الحظر'),
          ),
        ],
      ),
    );
  }
}
