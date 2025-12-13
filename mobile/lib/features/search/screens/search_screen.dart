import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/category.dart';
import '../../../data/providers/categories_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  Category? _selectedCategory;

  final _recentSearches = [
    'حلويات منزلية',
    'ملابس أطفال',
    'عطور',
    'مخبوزات',
  ];

  final _popularSearches = [
    'أطعمة صحية',
    'هدايا',
    'إكسسوارات يدوية',
    'عسل طبيعي',
    'ملابس نسائية',
    'قهوة مختصة',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Ensure categories are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesStateProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('search'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SearchTextField(
                    controller: _searchController,
                    hint: l10n.tr('searchPlaceholder'),
                    autofocus: false,
                    onFilterTap: () => _showFilterSheet(context),
                    onChanged: (value) {
                      // TODO: Implement search
                    },
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                dividerHeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: l10n.tr('products')),
                  Tab(text: l10n.tr('projects')),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchContent(context),
                  _buildSearchContent(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    final l10n = context.l10n;
    // Show recent/popular if no search
    if (_searchController.text.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tr('recentSearches'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _recentSearches.clear());
                    },
                    child: Text(l10n.tr('clearAll')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _recentSearches
                    .map((search) => _buildSearchChip(
                          context,
                          search,
                          isRecent: true,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Popular searches
            Text(
              l10n.tr('mostSearched'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _popularSearches
                  .map((search) => _buildSearchChip(context, search))
                  .toList(),
            ),

            const SizedBox(height: 32),

            // Categories
            Text(
              l10n.tr('browseByCategory'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildCategoriesGrid(context),
          ],
        ),
      );
    }

    // Show search results
    return _buildSearchResults(context);
  }

  Widget _buildSearchChip(
    BuildContext context,
    String text, {
    bool isRecent = false,
  }) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        // TODO: Trigger search
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecent) ...[
              Icon(
                Icons.history_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final l10n = context.l10n;
    final categoriesState = ref.watch(categoriesStateProvider);

    // Show loading shimmer
    if (categoriesState.isLoading && categoriesState.categories.isEmpty) {
      return _buildCategoriesGridShimmer();
    }

    // Show error
    if (categoriesState.error != null && categoriesState.categories.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: () => ref.read(categoriesStateProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.tr('reloadCategories')),
        ),
      );
    }

    final categories = categoriesState.parentCategories;

    if (categories.isEmpty) {
      return Center(
        child: Text(
          l10n.tr('noCategoriesFound'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryGridItem(context, category, index);
      },
    );
  }

  Widget _buildCategoriesGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }

  // Category colors based on index
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

  // Map icon name to IconData
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

  Widget _buildCategoryGridItem(
      BuildContext context, Category category, int index) {
    final color = _getCategoryColor(index);
    final icon = _getCategoryIcon(category.iconName);
    final isSelected = _selectedCategory?.id == category.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category;
        });
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSelected
                ? 'تم إلغاء تصفية ${category.displayName}'
                : 'تصفية حسب ${category.displayName}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadow,
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final l10n = context.l10n;
    // TODO: Replace with actual search results
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('searchingText'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tr('filterResults'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Reset filters
                    },
                    child: Text(l10n.tr('reset')),
                  ),
                ],
              ),
            ),

            // Filter content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('city'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة']
                          .map((city) => FilterChip(
                                label: Text(city),
                                selected: false,
                                onSelected: (selected) {},
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.tr('rating'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['4+ ⭐', '3+ ⭐', '2+ ⭐']
                          .map((rating) => FilterChip(
                                label: Text(rating),
                                selected: false,
                                onSelected: (selected) {},
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.tr('apply')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
