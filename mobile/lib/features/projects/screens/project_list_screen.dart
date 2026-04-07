import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/projects_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../config/routes.dart';

/// Project List Screen - displays all projects with filtering
class ProjectListScreen extends ConsumerStatefulWidget {
  final String? searchQuery;

  const ProjectListScreen({
    super.key,
    this.searchQuery,
  });

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Search and Filter state
  late TextEditingController _searchController;
  String _sortBy = 'rating'; // Default sort
  double? _minRating;
  String _searchQuery = '';
  // Location filters
  double? _searchRadius;
  String? _city;

  // View mode: 'all' or 'nearby'
  String _viewMode = 'all';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchQuery = widget.searchQuery ?? '';
    _loadProjects();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final user = ref.read(currentUserProvider);

      // Only send location params when in 'nearby' mode
      double? lat;
      double? lon;

      if (_viewMode == 'nearby' &&
          user?.latitude != null &&
          user?.longitude != null) {
        lat = user!.latitude;
        lon = user.longitude;
      }

      final response = await repository.getProjects(
        page: 1,
        limit: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _viewMode == 'nearby' ? 'distance' : _sortBy,
        minRating: _minRating,
        city: _city,
        radius: _viewMode == 'nearby' ? (_searchRadius ?? 50) : null,
        lat: lat,
        lon: lon,
      );

      // Client-side safety filter: never show the current user's own project
      final filtered = user != null
          ? response.projects.where((p) => p.ownerId != user.id).toList()
          : response.projects;

      setState(() {
        _projects = filtered;
        _hasMore = response.pagination.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final user = ref.read(currentUserProvider);

      double? lat;
      double? lon;

      if (_viewMode == 'nearby' &&
          user?.latitude != null &&
          user?.longitude != null) {
        lat = user!.latitude;
        lon = user.longitude;
      }

      final response = await repository.getProjects(
        page: _currentPage,
        limit: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _viewMode == 'nearby' ? 'distance' : _sortBy,
        minRating: _minRating,
        city: _city,
        radius: _viewMode == 'nearby' ? (_searchRadius ?? 50) : null,
        lat: lat,
        lon: lon,
      );

      // Client-side safety filter
      final filtered = user != null
          ? response.projects.where((p) => p.ownerId != user.id).toList()
          : response.projects;

      setState(() {
        _projects.addAll(filtered);
        _hasMore = response.pagination.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // final isRtl = context.isRtl; // Unused

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 100,
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
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list_rounded,
                      color: Colors.white, size: 18),
                ),
                onPressed: _showFilterSheet,
              ),
            ],
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Text(
                      l10n.tr('projects'),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SearchTextField(
                  controller: _searchController,
                  hint: l10n.tr('common.searchPlaceholder3'),
                  onChanged: (value) {
                    _searchQuery = value;
                  },
                  onSubmitted: (value) {
                    _searchQuery = value;
                    _loadProjects();
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadProjects();
                  },
                ),
              ),
            ),
          ),

          // All/Nearby toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_viewMode != 'all') {
                            setState(() => _viewMode = 'all');
                            _loadProjects();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _viewMode == 'all'
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              l10n.tr('allProjects'),
                              style: TextStyle(
                                color: _viewMode == 'all'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: _viewMode == 'all'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_viewMode != 'nearby') {
                            setState(() => _viewMode = 'nearby');
                            _loadProjects();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _viewMode == 'nearby'
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 16,
                                  color: _viewMode == 'nearby'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.tr('nearbyProjects'),
                                  style: TextStyle(
                                    color: _viewMode == 'nearby'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: _viewMode == 'nearby'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Projects List
          _buildProjectsSliver(),
        ],
      ),
    );
  }

  Widget _buildProjectsSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('error'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadProjects,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_projects.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 80,
                color: AppColors.textTertiary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.isRtl ? 'لا توجد مشاريع' : 'No projects found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _projects.length) {
              return _isLoadingMore
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  : const SizedBox();
            }

            final project = _projects[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildProjectCard(context, project),
            );
          },
          childCount: _projects.length + (_hasMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    final isRtl = context.isRtl;

    return GestureDetector(
      onTap: () {
        context.push(
          Routes.projectDetail
              .replaceFirst(':projectId', project.id.toString()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: project.coverUrl != null
                    ? Image.network(
                        ApiEndpoints.imageUrl(project.coverUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.image,
                              color: AppColors.textTertiary),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image,
                            color: AppColors.textTertiary),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                      image: project.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(
                                  ApiEndpoints.imageUrl(project.logoUrl!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: project.logoUrl == null
                        ? const Icon(Icons.business,
                            color: AppColors.textTertiary)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? project.nameAr : project.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project.city,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (project.distance != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  project.formattedDistance,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              project.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${project.totalReviews})',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
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
                          _city = null;
                        });
                      },
                      child: Text(l10n.tr('reset')),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City Filter (from DB)
                      Text(
                        l10n.tr('city'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          final citiesAsync = ref.watch(projectCitiesProvider);
                          return citiesAsync.when(
                            data: (cities) {
                              return Autocomplete<String>(
                                optionsBuilder: (textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return cities;
                                  }
                                  return cities.where((c) => c
                                      .toLowerCase()
                                      .contains(
                                          textEditingValue.text.toLowerCase()));
                                },
                                initialValue:
                                    TextEditingValue(text: _city ?? ''),
                                onSelected: (selectedCity) {
                                  setSheetState(() {
                                    _city = selectedCity;
                                  });
                                },
                                fieldViewBuilder: (context, controller,
                                    focusNode, onSubmitted) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      hintText: context.isRtl
                                          ? 'ابحث عن مدينة...'
                                          : 'Search city...',
                                      prefixIcon: const Icon(
                                          Icons.location_city_rounded),
                                      suffixIcon: _city != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                controller.clear();
                                                setSheetState(() {
                                                  _city = null;
                                                });
                                              },
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.surfaceVariant,
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Text(
                              context.isRtl
                                  ? 'فشل تحميل المدن'
                                  : 'Failed to load cities',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Apply Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadProjects();
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
}
