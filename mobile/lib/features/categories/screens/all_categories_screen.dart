import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/category.dart';
import '../../../data/providers/categories_provider.dart';

class AllCategoriesScreen extends ConsumerStatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  ConsumerState<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends ConsumerState<AllCategoriesScreen>
    with SingleTickerProviderStateMixin {
  int? _expandedCategoryId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesStateProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesStateProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful gradient app bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, 
                    color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A5653),
                      Color(0xFF2D8C87),
                      Color(0xFF1A5653),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr('allCategories'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tr('exploreCategories'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats bar
          if (categoriesState.isInitialized && !categoriesState.isLoading)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        categoriesState.parentCategories.length.toString(),
                        l10n.tr('mainCategories'),
                        Icons.category_rounded,
                        AppColors.primary,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.divider,
                      ),
                      _buildStatItem(
                        context,
                        categoriesState.flatCategories
                            .where((c) => c.isSubcategory)
                            .length
                            .toString(),
                        l10n.tr('subCategories'),
                        Icons.subdirectory_arrow_right_rounded,
                        AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading state
          if (categoriesState.isLoading && categoriesState.categories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.tr('loading')),
                  ],
                ),
              ),
            ),

          // Error state
          if (categoriesState.error != null && categoriesState.categories.isEmpty)
            SliverFillRemaining(
              child: _buildErrorState(context),
            ),

          // Categories grid
          if (categoriesState.categories.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categoriesState.parentCategories[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCategoryCard(context, category, index),
                    );
                  },
                  childCount: categoriesState.parentCategories.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('loadCategoriesFailed'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              ref.read(categoriesStateProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category, int index) {
    final isExpanded = _expandedCategoryId == category.id;
    final color = _getCategoryColor(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isExpanded 
                ? color.withOpacity(0.2) 
                : AppColors.shadow.withOpacity(0.08),
            blurRadius: isExpanded ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isExpanded 
            ? Border.all(color: color.withOpacity(0.3), width: 2) 
            : null,
      ),
      child: Column(
        children: [
          // Category header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedCategoryId = isExpanded ? null : category.id;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon container with gradient
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _getCategoryIcon(category.iconName),
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayName,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          if (category.hasChildren) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${category.children.length} ${context.l10n.tr('subCategory')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Expand/collapse button
                    if (category.hasChildren)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: color,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: color,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Subcategories (animated)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSubcategories(context, category, color),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategories(
      BuildContext context, Category category, Color parentColor) {
    if (!category.hasChildren) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: category.children.asMap().entries.map((entry) {
              final index = entry.key;
              final sub = entry.value;
              final subColor = _getSubCategoryColor(index, parentColor);

              return GestureDetector(
                onTap: () {
                  // Navigate to category products
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${context.l10n.tr('browsing')} ${sub.displayName}'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: subColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: subColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: subColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        sub.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFFE57373), // Red
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFFFB74D), // Orange
      const Color(0xFF81C784), // Green
      const Color(0xFFBA68C8), // Purple
      const Color(0xFF4DD0E1), // Cyan
      const Color(0xFFFFD54F), // Yellow
      const Color(0xFFA1887F), // Brown
    ];
    return colors[index % colors.length];
  }

  Color _getSubCategoryColor(int index, Color parentColor) {
    // Create variations of the parent color
    final hsl = HSLColor.fromColor(parentColor);
    final newHue = (hsl.hue + (index * 30)) % 360;
    return HSLColor.fromAHSL(1, newHue, hsl.saturation * 0.8, hsl.lightness).toColor();
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant_rounded,
      'checkroom': Icons.checkroom_rounded,
      'handyman': Icons.handyman_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'watch': Icons.watch_rounded,
      'spa': Icons.spa_rounded,
      'home': Icons.home_rounded,
      'child_care': Icons.child_care_rounded,
      'category': Icons.category_rounded,
      'local_dining': Icons.local_dining_rounded,
      'cake': Icons.cake_rounded,
      'local_cafe': Icons.local_cafe_rounded,
      'eco': Icons.eco_rounded,
    };
    return iconMap[iconName] ?? Icons.category_rounded;
  }
}

