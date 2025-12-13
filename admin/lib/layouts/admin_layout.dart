import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../data/providers/auth_provider.dart';

class AdminLayout extends ConsumerStatefulWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentAdminProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 260 : 70,
            decoration: const BoxDecoration(
              color: AdminColors.sidebarBg,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AdminColors.sidebarActive,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'صنعة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'لوحة التحكم',
                        path: AdminRoutes.dashboard,
                        isSelected: currentPath == AdminRoutes.dashboard,
                      ),
                      _buildNavItem(
                        icon: Icons.people_rounded,
                        label: 'المستخدمين',
                        path: AdminRoutes.users,
                        isSelected: currentPath == AdminRoutes.users,
                      ),
                      _buildNavItem(
                        icon: Icons.storefront_rounded,
                        label: 'المشاريع',
                        path: AdminRoutes.projects,
                        isSelected: currentPath == AdminRoutes.projects,
                        badge: 3,
                      ),
                      _buildNavItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'المنتجات',
                        path: AdminRoutes.products,
                        isSelected: currentPath == AdminRoutes.products,
                        badge: 5,
                      ),
                      _buildNavItem(
                        icon: Icons.category_rounded,
                        label: 'التصنيفات',
                        path: AdminRoutes.categories,
                        isSelected: currentPath == AdminRoutes.categories,
                      ),
                      _buildNavItem(
                        icon: Icons.star_rounded,
                        label: 'التقييمات',
                        path: AdminRoutes.reviews,
                        isSelected: currentPath == AdminRoutes.reviews,
                      ),
                      _buildNavItem(
                        icon: Icons.support_agent_rounded,
                        label: 'تذاكر الدعم',
                        path: AdminRoutes.tickets,
                        isSelected: currentPath == AdminRoutes.tickets,
                      ),
                      const Divider(color: Colors.white12),
                      _buildNavItem(
                        icon: Icons.settings_rounded,
                        label: 'الإعدادات',
                        path: AdminRoutes.settings,
                        isSelected: currentPath == AdminRoutes.settings,
                      ),
                    ],
                  ),
                ),

                // User section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AdminColors.sidebarActive,
                        child: Text(
                          admin?.initials ?? 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                admin?.fullName ?? 'Admin',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                admin?.email ?? '',
                                style: const TextStyle(
                                  color: AdminColors.textTertiary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _handleLogout,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          tooltip: 'تسجيل الخروج',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AdminColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AdminColors.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Toggle sidebar button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        icon: Icon(
                          _isExpanded
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          color: AdminColors.textSecondary,
                        ),
                      ),

                      const Spacer(),

                      // Notifications
                      IconButton(
                        onPressed: () {},
                        icon: Badge(
                          label: const Text('3'),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Profile menu
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _handleLogout();
                          } else if (value == 'settings') {
                            context.go(AdminRoutes.settings);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 20),
                                const SizedBox(width: 12),
                                const Text('الملف الشخصي'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                const Icon(Icons.settings_outlined, size: 20),
                                const SizedBox(width: 12),
                                const Text('الإعدادات'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    size: 20, color: AdminColors.error),
                                const SizedBox(width: 12),
                                Text('تسجيل الخروج',
                                    style: TextStyle(color: AdminColors.error)),
                              ],
                            ),
                          ),
                        ],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AdminColors.primary,
                              child: Text(
                                admin?.initials ?? 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              admin?.fullName ?? 'Admin',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String path,
    required bool isSelected,
    int? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AdminColors.sidebarActive.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AdminColors.sidebarActive
                      : AdminColors.sidebarText.withOpacity(0.7),
                  size: 22,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AdminColors.sidebarText.withOpacity(0.8),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminAuthStateProvider.notifier).logout();
    }
  }
}
