import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../data/models/category.dart';
import '../../data/providers/categories_provider.dart';
import '../../core/localization/app_localizations.dart';

/// Category Grid Widget - Displays categories in a grid layout
class CategoryGrid extends ConsumerWidget {
  final Function(Category category)? onCategoryTap;
  final int crossAxisCount;
  final double spacing;
  final bool showAll;
  final int? maxItems;

  const CategoryGrid({
    super.key,
    this.onCategoryTap,
    this.crossAxisCount = 4,
    this.spacing = 12,
    this.showAll = true,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesStateProvider);

    // Load categories if not loaded
    if (!categoriesState.isInitialized && !categoriesState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(categoriesStateProvider.notifier).loadCategories();
      });
    }

    if (categoriesState.isLoading && categoriesState.categories.isEmpty) {
      return _buildShimmer(context);
    }

    if (categoriesState.error != null && categoriesState.categories.isEmpty) {
      return _buildError(context, ref, categoriesState.error!);
    }

    final categories = categoriesState.parentCategories;
    final displayCategories =
        maxItems != null ? categories.take(maxItems!).toList() : categories;

    if (displayCategories.isEmpty) {
      return _buildEmpty(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.85,
      ),
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        return CategoryCard(
          category: displayCategories[index],
          onTap: onCategoryTap,
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr('failedToLoadCategories'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              ref.read(categoriesStateProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr('noCategories'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Category Card Widget - Individual category display
class CategoryCard extends StatelessWidget {
  final Category category;
  final Function(Category category)? onTap;
  final bool isSelected;
  final bool showSubCount;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.isSelected = false,
    this.showSubCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(category) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category.iconName),
                  size: 24,
                  color:
                      isSelected ? AppColors.textOnPrimary : AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  category.displayName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Subcategory count
              if (showSubCount && category.hasChildren) ...[
                const SizedBox(height: 4),
                Text(
                  '${category.children.length} ${context.l10n.tr('subCategories')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    // Map icon names to Material icons
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
      'woman': Icons.woman_rounded,
      'man': Icons.man_rounded,
      'child_friendly': Icons.child_friendly_rounded,
      'style': Icons.style_rounded,
      'brush': Icons.brush_rounded,
      'palette': Icons.palette_rounded,
      'carpenter': Icons.carpenter_rounded,
      'texture': Icons.texture_rounded,
      'face': Icons.face_rounded,
      'sanitizer': Icons.sanitizer_rounded,
      'air_freshener': Icons.air_rounded,
    };

    return iconMap[iconName] ?? Icons.category_rounded;
  }
}

/// Horizontal Category List - For compact display
class CategoryHorizontalList extends ConsumerWidget {
  final Function(Category category)? onCategoryTap;
  final Category? selectedCategory;
  final double itemWidth;
  final double height;

  const CategoryHorizontalList({
    super.key,
    this.onCategoryTap,
    this.selectedCategory,
    this.itemWidth = 80,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesStateProvider);

    if (!categoriesState.isInitialized && !categoriesState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(categoriesStateProvider.notifier).loadCategories();
      });
    }

    if (categoriesState.isLoading && categoriesState.categories.isEmpty) {
      return _buildShimmer();
    }

    final categories = categoriesState.parentCategories;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory?.id == category.id;

          return SizedBox(
            width: itemWidth,
            child: CategoryCard(
              category: category,
              onTap: onCategoryTap,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: itemWidth,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}
