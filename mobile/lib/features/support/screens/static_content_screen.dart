import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';

class StaticContentScreen extends ConsumerWidget {
  final String title;
  final String contentKey;

  const StaticContentScreen({
    super.key,
    required this.title,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient.scale(0.1),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: _buildContent(context, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (contentKey == 'contact_us') {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildContactCard(
            context,
            icon: Icons.email_rounded,
            title: l10n.tr('email'),
            subtitle: 'support@sinaa.com',
            onTap: () => _launchUrl('mailto:support@sinaa.com'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.phone_rounded,
            title: l10n.tr('phone'),
            subtitle: '+966 50 000 0000',
            onTap: () => _launchUrl('tel:+966500000000'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.chat_bubble_rounded,
            title: 'WhatsApp',
            subtitle: '+966 50 000 0000',
            onTap: () => _launchUrl('https://wa.me/966500000000'),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.tr('followUs'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(Icons.facebook, () {}),
              _buildSocialButton(Icons.camera_alt, () {}), // Instagram
              _buildSocialButton(Icons.alternate_email, () {}), // Twitter/X
            ],
          ),
        ]),
      );
    }

    // Default content for Privacy/Terms
    String content = '';
    if (contentKey == 'privacy_policy') {
      content = l10n.tr('privacyPolicyContent');
      if (content == 'privacyPolicyContent') {
        content =
            '## 1. Data Collection\nWe collect data to improve your experience. This includes basic profile information and usage data.\n\n'
            '## 2. Data Usage\nYour data is used for order processing, app functionality, and improving our services.\n\n'
            '## 3. Data Protection\nWe implement robust security measures to protect your information from unauthorized access.\n\n'
            '## 4. Third Parties\nWe do not sell your data to third parties. We may share data with trusted partners for service delivery.';
      }
    } else if (contentKey == 'terms_of_service') {
      content = l10n.tr('termsOfServiceContent');
      if (content == 'termsOfServiceContent') {
        content =
            '## 1. Acceptance of Terms\nBy using this app, you agree to these terms and conditions.\n\n'
            '## 2. User Conduct\nYou agree to use the app responsibly and not for any illegal activities.\n\n'
            '## 3. Liability\nWe are not liable for any damages arising from the use or inability to use our services.\n\n'
            '## 4. Modifications\nWe reserve the right to modify these terms at any time. Continued use implies acceptance.';
      }
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
