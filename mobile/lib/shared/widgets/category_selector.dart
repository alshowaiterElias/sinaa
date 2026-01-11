import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../data/models/category.dart';
import '../../data/providers/categories_provider.dart';
import '../../core/localization/app_localizations.dart';

/// Category Selector Widget - For selecting category in forms
class CategorySelector extends ConsumerStatefulWidget {
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final Function(Category? category, Category? subcategory) onChanged;
  final bool required;
  final String? errorText;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    this.selectedSubcategory,
    required this.onChanged,
    this.required = false,
    this.errorText,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  @override
  void initState() {
    super.initState();
    // Load categories if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesStateProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesStateProvider);
    final categories = categoriesState.parentCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Parent category dropdown
        _buildDropdown(
          label:
              '${context.l10n.tr('mainCategory')}${widget.required ? ' *' : ''}',
          hint: context.l10n.tr('selectCategory'),
          value: widget.selectedCategory,
          items: categories,
          onChanged: (category) {
            widget.onChanged(category, null);
          },
          isLoading: categoriesState.isLoading,
        ),

        // Subcategory dropdown (only show if parent is selected and has children)
        if (widget.selectedCategory != null &&
            widget.selectedCategory!.hasChildren) ...[
          const SizedBox(height: 16),
          _buildDropdown(
            label:
                '${context.l10n.tr('subCategory')}${widget.required ? ' *' : ''}',
            hint: context.l10n.tr('selectSubCategory'),
            value: widget.selectedSubcategory,
            items: widget.selectedCategory!.children,
            onChanged: (subcategory) {
              widget.onChanged(widget.selectedCategory, subcategory);
            },
          ),
        ],

        // Error text
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required Category? value,
    required List<Category> items,
    required Function(Category?) onChanged,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.error
                  : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Category?>(
                    value: value,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        hint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                    items: [
                      // Optional clear option
                      if (value != null)
                        DropdownMenuItem<Category?>(
                          value: null,
                          child: Text(
                            context.l10n.tr('clearSelection'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      // Category items
                      ...items.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category.iconName),
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.displayName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (category.hasChildren)
                                Text(
                                  '(${category.children.length})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: onChanged,
                  ),
                ),
        ),
      ],
    );
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
    };
    return iconMap[iconName] ?? Icons.category_rounded;
  }
}

/// Category Filter Widget - For filtering products/search
class CategoryFilter extends ConsumerWidget {
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final Function(Category? category) onCategoryChanged;
  final Function(Category? subcategory) onSubcategoryChanged;
  final VoidCallback? onClear;

  const CategoryFilter({
    super.key,
    this.selectedCategory,
    this.selectedSubcategory,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesStateProvider);

    if (!categoriesState.isInitialized && !categoriesState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(categoriesStateProvider.notifier).loadCategories();
      });
    }

    final categories = categoriesState.parentCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with clear button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.tr('filterByCategory'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (selectedCategory != null || selectedSubcategory != null)
              TextButton.icon(
                onPressed: () {
                  onCategoryChanged(null);
                  onSubcategoryChanged(null);
                  onClear?.call();
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: Text(context.l10n.tr('clear')),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Parent categories - horizontal chips
        SizedBox(
          height: 40,
          child: categoriesState.isLoading
              ? _buildChipsShimmer()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" chip
                      final isSelected = selectedCategory == null;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(context.l10n.tr('all')),
                        onSelected: (_) => onCategoryChanged(null),
                        backgroundColor: AppColors.surfaceVariant,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      );
                    }

                    final category = categories[index - 1];
                    final isSelected = selectedCategory?.id == category.id;

                    return FilterChip(
                      selected: isSelected,
                      label: Text(category.displayName),
                      onSelected: (_) => onCategoryChanged(category),
                      backgroundColor: AppColors.surfaceVariant,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                      avatar: isSelected
                          ? null
                          : Icon(
                              _getCategoryIcon(category.iconName),
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    );
                  },
                ),
        ),

        // Subcategories (if parent is selected and has children)
        if (selectedCategory != null && selectedCategory!.hasChildren) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedCategory!.children.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "All subcategories" chip
                  final isSelected = selectedSubcategory == null;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(context.l10n.tr('allSubCategories')),
                    onSelected: (_) => onSubcategoryChanged(null),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.secondary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  );
                }

                final subcategory = selectedCategory!.children[index - 1];
                final isSelected = selectedSubcategory?.id == subcategory.id;

                return ChoiceChip(
                  selected: isSelected,
                  label: Text(subcategory.displayName),
                  onSelected: (_) => onSubcategoryChanged(subcategory),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.secondary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChipsShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Container(
          width: 80,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
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
    };
    return iconMap[iconName] ?? Icons.category_rounded;
  }
}

/// Bottom sheet for category selection
class CategoryPickerBottomSheet extends ConsumerWidget {
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final Function(Category? category, Category? subcategory) onSelected;

  const CategoryPickerBottomSheet({
    super.key,
    this.selectedCategory,
    this.selectedSubcategory,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    Category? selectedCategory,
    Category? selectedSubcategory,
    required Function(Category? category, Category? subcategory) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerBottomSheet(
        selectedCategory: selectedCategory,
        selectedSubcategory: selectedSubcategory,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesStateProvider);
    final categories = categoriesState.parentCategories;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.tr('selectCategory'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (selectedCategory != null)
                      TextButton(
                        onPressed: () {
                          onSelected(null, null);
                          Navigator.pop(context);
                        },
                        child: Text(context.l10n.tr('clear')),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Categories list
              Expanded(
                child: categoriesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              selectedCategory?.id == category.id;

                          return ExpansionTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getCategoryIcon(category.iconName),
                                size: 20,
                                color: isSelected
                                    ? AppColors.textOnPrimary
                                    : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              category.displayName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            trailing: category.hasChildren
                                ? null
                                : (isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: AppColors.primary)
                                    : null),
                            children: category.hasChildren
                                ? [
                                    // Select parent only option
                                    ListTile(
                                      leading: const SizedBox(width: 40),
                                      title: Text(
                                        '${context.l10n.tr('all')} ${category.displayName}',
                                        style: TextStyle(
                                          color: isSelected &&
                                                  selectedSubcategory == null
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      trailing: isSelected &&
                                              selectedSubcategory == null
                                          ? const Icon(Icons.check_rounded,
                                              color: AppColors.primary)
                                          : null,
                                      onTap: () {
                                        onSelected(category, null);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    // Subcategories
                                    ...category.children.map((sub) {
                                      final isSubSelected =
                                          selectedSubcategory?.id == sub.id;
                                      return ListTile(
                                        leading: const SizedBox(width: 40),
                                        title: Text(
                                          sub.displayName,
                                          style: TextStyle(
                                            color: isSubSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        trailing: isSubSelected
                                            ? const Icon(Icons.check_rounded,
                                                color: AppColors.primary)
                                            : null,
                                        onTap: () {
                                          onSelected(category, sub);
                                          Navigator.pop(context);
                                        },
                                      );
                                    }),
                                  ]
                                : [],
                            onExpansionChanged: category.hasChildren
                                ? null
                                : (expanded) {
                                    onSelected(category, null);
                                    Navigator.pop(context);
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
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
    };
    return iconMap[iconName] ?? Icons.category_rounded;
  }
}
