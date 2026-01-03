import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';

import '../../../config/routes.dart';
import '../../../data/providers/projects_provider.dart';
import '../../../data/providers/favorites_provider.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../widgets/product_card.dart';
import 'package:go_router/go_router.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final productsAsync = ref.watch(projectProductsProvider(projectId));
    final isRtl = context.isRtl;

    return Scaffold(
      body: projectAsync.when(
        data: (project) {
          final localizedName = isRtl ? project.nameAr : project.name;
          final localizedDescription =
              isRtl ? project.descriptionAr : project.description;

          return CustomScrollView(
            slivers: [
              // App Bar with Cover
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: project.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: project.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.surfaceVariant,
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withAlpha(25),
                          child: Icon(
                            Icons.store,
                            size: 64,
                            color: AppColors.primary.withAlpha(128),
                          ),
                        ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(204),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  _FavoriteButton(projectId: projectId),
                ],
              ),

              // Project Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Logo
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.divider),
                              color: AppColors.surface,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: project.logoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: project.logoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.store,
                                    color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 16),

                          // Name & Rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizedName,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: AppColors.warning, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      project.averageRating.toStringAsFixed(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      ' (${project.totalReviews})',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.location_on_outlined,
                                        color: AppColors.textTertiary,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      project.city,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      if (localizedDescription != null &&
                          localizedDescription.isNotEmpty) ...[
                        Text(
                          localizedDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Social Links
                      if (project.socialLinks != null &&
                          project.socialLinks!.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          children: project.socialLinks!.entries.map((entry) {
                            return IconButton(
                              icon: _getSocialIcon(entry.key),
                              onPressed: () => _launchUrl(entry.value),
                              tooltip: entry.key,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                      ],

                      const SizedBox(height: 16),
                      Text(
                        context.tr(
                            'common.products'), // Ensure this key exists or use fallback
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),

              // Products Grid
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            context
                                .tr('common.noProducts'), // Ensure key exists
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ProductCard(
                            product: products[index],
                            onTap: () {
                              context.push(
                                Routes.productDetail.replaceFirst(
                                  ':productId',
                                  products[index].id.toString(),
                                ),
                              );
                            },
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        Center(child: Text('Error loading products: $error')),
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Icon _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Icon(Icons.camera_alt, color: Color(0xFFE1306C));
      case 'twitter':
      case 'x':
        return const Icon(Icons.alternate_email, color: Colors.black);
      case 'facebook':
        return const Icon(Icons.facebook, color: Color(0xFF1877F2));
      case 'whatsapp':
        return const Icon(Icons.phone, color: Color(0xFF25D366));
      case 'website':
        return const Icon(Icons.language, color: AppColors.primary);
      default:
        return const Icon(Icons.link, color: AppColors.textSecondary);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

/// Favorite button widget with toggle functionality
class _FavoriteButton extends ConsumerStatefulWidget {
  final int projectId;

  const _FavoriteButton({required this.projectId});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final isFav = await repository.checkFavorite(widget.projectId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final newStatus = await repository.toggleFavorite(widget.projectId);
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
          _isLoading = false;
        });
        // Refresh favorites list
        ref.invalidate(favoritesProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(204),
        shape: BoxShape.circle,
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? AppColors.error : AppColors.textPrimary,
              ),
              onPressed: _toggleFavorite,
            ),
    );
  }
}
