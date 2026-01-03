import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/categories_provider.dart';
import '../../../data/providers/projects_provider.dart';
import '../../../data/providers/products_provider.dart';
import '../../../data/providers/notifications_provider.dart';
import '../../../data/providers/chat_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../projects/widgets/project_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load categories, projects, products, and notification count when the home screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesStateProvider.notifier).loadCategories();
      ref.read(projectsStateProvider.notifier).loadProjects();
      ref.read(featuredProductsProvider.notifier).loadFeaturedProducts();
      ref.read(notificationsProvider.notifier).loadUnreadCount();
      debugPrint(
          '[HOME] Loaded categories, projects, featured products, and notification count');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final categoriesState = ref.watch(categoriesStateProvider);
    final projectsState = ref.watch(projectsStateProvider);
    final l10n = context.l10n;

    // Initialize socket and notification listeners when logged in
    ref.watch(socketInitProvider);
    ref.watch(notificationInitProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.background, AppColors.background],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null
                                      ? '${l10n.tr('greetings.welcome')}, ${user.fullName.split(' ').first}'
                                      : l10n.tr('greetings.welcome'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.tr('greetings.whatLooking'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            _buildNotificationButton(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildSearchBar(context),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Categories section
                _buildSectionHeader(context, l10n.tr('categories'),
                    onSeeAll: () {
                  context.push(Routes.allCategories);
                }),
                const SizedBox(height: 16),
                _buildCategoriesSection(context, categoriesState),

                const SizedBox(height: 32),

                // Featured products
                _buildSectionHeader(context, l10n.tr('featuredProducts'),
                    onSeeAll: () {}),
                const SizedBox(height: 16),
                _buildFeaturedProducts(context),

                const SizedBox(height: 32),

                // Nearby projects
                _buildSectionHeader(context, l10n.tr('nearbyProjects'),
                    onSeeAll: () {}),
                const SizedBox(height: 16),
                _buildNearbyProjects(context, projectsState),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.softShadow,
      ),
      child: IconButton(
        onPressed: () => context.push('/notifications'),
        icon: Badge(
          label: unreadCount > 0
              ? Text(unreadCount > 99 ? '99+' : '$unreadCount')
              : null,
          isLabelVisible: unreadCount > 0,
          backgroundColor: AppColors.primary,
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => context.go(Routes.search),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              l10n.tr('searchPlaceholder'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    final l10n = context.l10n;
    final isRtl = context.isRtl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(
                children: [
                  Text(l10n.tr('seeAll')),
                  const SizedBox(width: 4),
                  Icon(
                    isRtl
                        ? Icons.arrow_back_ios_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
      BuildContext context, CategoriesState categoriesState) {
    // Show shimmer while loading
    if (categoriesState.isLoading && categoriesState.categories.isEmpty) {
      return _buildCategoriesShimmer();
    }

    // Show error state
    if (categoriesState.error != null && categoriesState.categories.isEmpty) {
      return _buildCategoriesError(context);
    }

    final categories = categoriesState.parentCategories;

    // If no categories, show empty state
    if (categories.isEmpty) {
      return _buildCategoriesEmpty(context);
    }

    // Limit to 5 categories + "More" button
    final displayCategories = categories.take(5).toList();
    final hasMore = categories.length > 5;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayCategories.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // "More" button at the end
          if (hasMore && index == displayCategories.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildMoreCategoriesItem(context),
            );
          }

          final category = displayCategories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildCategoryItem(context, category, index),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesShimmer() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 50,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesError(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('loadCategoriesFailed'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            TextButton(
              onPressed: () {
                ref.read(categoriesStateProvider.notifier).refresh();
              },
              child: Text(l10n.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesEmpty(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          l10n.tr('noCategoriesFound'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ),
    );
  }

  // Category colors based on index for visual variety
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
    };
    return iconMap[iconName] ?? Icons.category_rounded;
  }

  Widget _buildCategoryItem(
      BuildContext context, Category category, int index) {
    final color = _getCategoryColor(index);
    final icon = _getCategoryIcon(category.iconName);
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(
          Routes.categoryProducts.replaceFirst(
            ':categoryId',
            category.id.toString(),
          ),
        );
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withAlpha(38), // 0.15
                    color.withAlpha(13), // 0.05
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withAlpha(51), // 0.2
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.getLocalizedName(l10n.locale.languageCode),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreCategoriesItem(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () {
        context.push(Routes.allCategories);
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.textTertiary.withAlpha(38), // 0.15
                    AppColors.textTertiary.withAlpha(13), // 0.05
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.textTertiary.withAlpha(51), // 0.2
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textTertiary,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tr('more'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(BuildContext context) {
    final featuredProducts = ref.watch(featuredProductsProvider);
    final l10n = context.l10n;
    final isRtl = context.isRtl;

    if (featuredProducts.isLoading && featuredProducts.products.isEmpty) {
      return SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      );
    }

    if (featuredProducts.products.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.tr('noProductsFound'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featuredProducts.products.length,
        itemBuilder: (context, index) {
          final product = featuredProducts.products[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildProductCard(context, product, isRtl),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, bool isRtl) {
    return GestureDetector(
      onTap: () {
        context.push(
          Routes.productDetail.replaceFirst(
            ':productId',
            product.id.toString(),
          ),
        );
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: ApiEndpoints.imageUrl(product.posterImageUrl),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? product.nameAr : product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (product.averageRating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                product.averageRating.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${product.basePrice.toStringAsFixed(0)} ${isRtl ? 'ر.س' : 'SAR'}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyProjects(BuildContext context, projectsState) {
    debugPrint(
        '[HOME] Projects state: isLoading=${projectsState.isLoading}, count=${projectsState.projects.length}, error=${projectsState.error}');
    if (projectsState.isLoading && projectsState.projects.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (projectsState.projects.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            context.l10n.tr('project.noProjectsFound'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ),
      );
    }

    final projects = projectsState.projects.take(5).toList();

    return SizedBox(
      height: 300, // Increased height to fix overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 280, // Fixed width for horizontal card
              child: ProjectCard(
                project: projects[index],
                onTap: () => context.push(
                  Routes.projectDetail.replaceFirst(
                    ':projectId',
                    projects[index].id.toString(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
