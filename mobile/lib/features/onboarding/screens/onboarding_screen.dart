import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/local_storage.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingItem> _getItems(AppLocalizations l10n) => [
    OnboardingItem(
      icon: Icons.storefront_rounded,
      iconGradient: AppColors.primaryGradient,
      title: l10n.tr('onboarding1Title'),
      subtitle: l10n.tr('onboarding1Subtitle'),
      decorationColor: AppColors.primary,
    ),
    OnboardingItem(
      icon: Icons.chat_bubble_rounded,
      iconGradient: AppColors.secondaryGradient,
      title: l10n.tr('onboarding2Title'),
      subtitle: l10n.tr('onboarding2Subtitle'),
      decorationColor: AppColors.secondary,
    ),
    OnboardingItem(
      icon: Icons.shopping_bag_rounded,
      iconGradient: AppColors.goldGradient,
      title: l10n.tr('onboarding3Title'),
      subtitle: l10n.tr('onboarding3Subtitle'),
      decorationColor: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final storage = ref.read(localStorageProvider);
    await storage.setHasSeenOnboarding(true);
    if (mounted) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = context.l10n;
    final items = _getItems(l10n);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.warmGradient,
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.3,
              child: _buildDecorativeBlob(
                size.width * 0.8,
                items[_currentPage].decorationColor.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.2,
              left: -size.width * 0.2,
              child: _buildDecorativeBlob(
                size.width * 0.6,
                items[_currentPage].decorationColor.withOpacity(0.05),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          l10n.tr('skip'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                      ),
                    ),
                  ),

                  // Page view
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: items.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildPage(items[index]);
                      },
                    ),
                  ),

                  // Bottom section
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            items.length,
                            (index) => _buildIndicator(index),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Buttons
                        if (_currentPage == items.length - 1)
                          _buildStartButton(l10n)
                        else
                          _buildNextButton(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: item.iconGradient,
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: item.decorationColor.withOpacity(0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  Icon(
                    item.icon,
                    size: 80,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Subtitle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              item.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.8,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 32 : 10,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.divider,
      ),
    );
  }

  Widget _buildNextButton(AppLocalizations l10n) {
    final isRtl = l10n.isRtl;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _completeOnboarding,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AppColors.divider, width: 2),
            ),
            child: Text(l10n.tr('browse')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.tr('next')),
                  const SizedBox(width: 8),
                  Icon(
                    isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, 
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(AppLocalizations l10n) {
    final isRtl = l10n.isRtl;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _completeOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.tr('start'),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 12),
            Icon(
              isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, 
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final LinearGradient iconGradient;
  final String title;
  final String subtitle;
  final Color decorationColor;

  OnboardingItem({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.decorationColor,
  });
}

