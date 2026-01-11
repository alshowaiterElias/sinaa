import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/categories_provider.dart';
import '../../../data/providers/search_provider.dart';
import '../../projects/widgets/project_card.dart';
import '../../projects/widgets/product_card.dart';
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

  // Debounce timer could be added here

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Ensure categories are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesStateProvider.notifier).loadCategories();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {}); // Rebuild to update filter sheet context
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.read(searchProvider.notifier);

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
                    onClear: _searchController.text.isNotEmpty
                        ? () {
                            _searchController.clear();
                            searchNotifier.setQuery('');
                            searchNotifier.searchAll();
                            setState(() {}); // Update to hide clear button
                          }
                        : null,
                    onChanged: (value) {
                      setState(() {}); // Update clear button visibility
                      searchNotifier.setQuery(value);
                      // Optional: Trigger search on debounce
                    },
                    onSubmitted: (value) {
                      searchNotifier.searchAll();
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
                  _buildProductsTab(context, searchState),
                  _buildProjectsTab(context, searchState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context, SearchState state) {
    final l10n = context.l10n;

    // If no query and no category selected, show categories
    if (state.query.isEmpty &&
        state.selectedCategory == null &&
        state.products.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed categories grid as per request
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tr('searchPlaceholder'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.isProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.productsError != null) {
      return Center(child: Text(state.productsError!));
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              l10n.tr('noResultsFound'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        return ProductCard(
          product: product,
          onTap: () {
            context.push('/product/${product.id}');
          },
        );
      },
    );
  }

  Widget _buildProjectsTab(BuildContext context, SearchState state) {
    final l10n = context.l10n;

    if (state.isProjectsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.projectsError != null) {
      return Center(child: Text(state.projectsError!));
    }

    if (state.projects.isEmpty) {
      // If empty query, show placeholder
      if (state.query.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded,
                  size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                l10n.tr('searchPlaceholder'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              l10n.tr('noResultsFound'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final project = state.projects[index];
        return ProjectCard(project: project);
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = context.l10n;
    final searchState = ref.read(searchProvider);
    final isProjectsTab = _tabController.index == 1;

    // Local state for the sheet
    double distanceRadius = searchState.distanceRadius;
    String sortBy = searchState.sortBy;
    String? city = searchState.selectedCity;
    double? minRating = searchState.minRating;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Fix overlap issue
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          distanceRadius = 50;
                          sortBy = 'rating';
                          city = null;
                          minRating = null;
                        });
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
                      // Sort by
                      Text(
                        l10n.tr('sortBy'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (isProjectsTab)
                            _buildSortChip(
                              context: context,
                              label: l10n.tr('location.sortByDistance'),
                              value: 'distance',
                              selected: sortBy == 'distance',
                              icon: Icons.near_me_outlined,
                              onTap: () =>
                                  setSheetState(() => sortBy = 'distance'),
                            ),
                          _buildSortChip(
                            context: context,
                            label: l10n.tr('rating'),
                            value: 'rating',
                            selected: sortBy == 'rating',
                            icon: Icons.star_rounded,
                            onTap: () => setSheetState(() => sortBy = 'rating'),
                          ),
                          _buildSortChip(
                            context: context,
                            label: l10n.tr('location.sortByNewest'),
                            value: 'newest',
                            selected: sortBy == 'newest',
                            icon: Icons.schedule_rounded,
                            onTap: () => setSheetState(() => sortBy = 'newest'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Distance filter (Only for Projects)
                      if (isProjectsTab) ...[
                        Row(
                          children: [
                            Text(
                              l10n.tr('location.distanceFilter'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${distanceRadius.toInt()} ${l10n.tr('km')}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tr('location.distanceFilterHint'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: distanceRadius,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: '${distanceRadius.toInt()} km',
                          onChanged: (value) {
                            setSheetState(() {
                              distanceRadius = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '5 ${l10n.tr('km')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                            Text(
                              '100 ${l10n.tr('km')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Rating Filter (Detailed)
                      Text(
                        l10n.tr('rating'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [4, 3, 2, 1].map((rating) {
                          return RadioListTile<double>(
                            value: rating.toDouble(),
                            groupValue: minRating,
                            onChanged: (value) {
                              setSheetState(() {
                                minRating = value;
                              });
                            },
                            title: Row(
                              children: [
                                Text('$rating+ '),
                                const Icon(Icons.star_rounded,
                                    color: AppColors.warning, size: 16),
                              ],
                            ),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // City filter (Only for Projects)
                      if (isProjectsTab) ...[
                        Text(
                          l10n.tr('city'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة']
                                  .map((c) => FilterChip(
                                        label: Text(c),
                                        selected: city == c,
                                        onSelected: (selected) {
                                          setSheetState(() {
                                            city = selected ? c : null;
                                          });
                                        },
                                      ))
                                  .toList(),
                        ),
                        const SizedBox(height: 40),
                      ],
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
                    onPressed: () {
                      ref.read(searchProvider.notifier).applyFilters(
                            distanceRadius: distanceRadius,
                            sortBy: sortBy,
                            city: city,
                            minRating: minRating,
                          );
                      Navigator.pop(context);
                    },
                    child: Text(l10n.tr('apply')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required BuildContext context,
    required String label,
    required String value,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
