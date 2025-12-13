import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/models/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isLoggedIn = authState.isAuthenticated;
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 20,
                20,
                30,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: isLoggedIn
                  ? _buildLoggedInHeader(context, user, l10n)
                  : _buildGuestHeader(context, l10n),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isLoggedIn && user?.role == UserRole.projectOwner) ...[
                  _buildMenuSection(
                    context,
                    l10n.tr('myProject'),
                    [
                      _MenuItem(
                        icon: Icons.storefront_rounded,
                        label: l10n.tr('manageProject'),
                        onTap: () => context.push(Routes.myProject),
                      ),
                      _MenuItem(
                        icon: Icons.inventory_2_rounded,
                        label: l10n.tr('products'),
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.analytics_rounded,
                        label: l10n.tr('profile.statistics'),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                _buildMenuSection(
                  context,
                  l10n.tr('settings'),
                  [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: l10n.tr('editProfile'),
                      onTap: () => context.push('/edit-profile'),
                      visible: isLoggedIn,
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: l10n.tr('notifications'),
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.language_rounded,
                      label: l10n.tr('language'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentLocale.languageCode == 'ar'
                              ? l10n.tr('arabic')
                              : l10n.tr('english'),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                      onTap: () => _showLanguageSheet(context, ref),
                    ),
                    _MenuItem(
                      icon: Icons.dark_mode_outlined,
                      label: l10n.tr('appearance'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.tr('lightMode'),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildMenuSection(
                  context,
                  l10n.tr('support.title'),
                  [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: l10n.tr('helpCenter'),
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: l10n.tr('contactUs'),
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.policy_outlined,
                      label: l10n.tr('privacyPolicy'),
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      label: l10n.tr('termsOfService'),
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (isLoggedIn)
                  _buildLogoutButton(context, ref, l10n)
                else
                  _buildLoginButton(context, l10n),

                const SizedBox(height: 24),

                // App version
                Center(
                  child: Text(
                    '${l10n.tr('version')} 1.0.0',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInHeader(
      BuildContext context, user, AppLocalizations l10n) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          user?.fullName ?? l10n.tr('guest'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 4),

        Text(
          user?.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),

        if (user?.role == UserRole.projectOwner) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.tr('auth.projectOwner'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuestHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 48,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tr('guest'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tr('guestMessage'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
  ) {
    final visibleItems = items.where((item) => item.visible).toList();
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: visibleItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildMenuItem(context, item),
                  if (index < visibleItems.length - 1)
                    const Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.icon,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
      title: Text(
        item.label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: item.trailing ??
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textTertiary,
          ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => _showLogoutConfirmation(context, ref, l10n),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.error,
            size: 22,
          ),
        ),
        title: Text(
          l10n.tr('logout'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AppLocalizations l10n) {
    final isRtl = context.isRtl;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => context.push(Routes.login),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.login_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          l10n.tr('login'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
        ),
        trailing: Icon(
          isRtl
              ? Icons.arrow_back_ios_rounded
              : Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.white70,
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.tr('chooseLanguage'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                context,
                ref,
                'العربية',
                'ar',
                flag: '🇸🇦',
                isSelected: ref.watch(localeProvider).languageCode == 'ar',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                ref,
                'English',
                'en',
                flag: '🇺🇸',
                isSelected: ref.watch(localeProvider).languageCode == 'en',
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    String code, {
    required bool isSelected,
    String? flag,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (flag != null) ...[
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.tr('logout')),
        content: Text(l10n.tr('auth.logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.tr('logout')),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool visible;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.visible = true,
  });
}
