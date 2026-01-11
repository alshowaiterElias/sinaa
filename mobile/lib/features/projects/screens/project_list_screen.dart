import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../data/providers/auth_provider.dart';
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

  // Cities list (mock for now, ideally fetched from API or constants)
  final List<String> _cities = [
    'Riyadh',
    'Jeddah',
    'Dammam',
    'Mecca',
    'Medina',
    'Khobar',
    'Tabuk',
    'Abha',
    'Taif',
    'Buraidah',
  ];

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

      // Use user location if available for distance sorting/filtering
      double? lat;
      double? lon;

      if (user?.latitude != null && user?.longitude != null) {
        lat = user!.latitude;
        lon = user.longitude;
      }

      final response = await repository.getProjects(
        page: 1,
        limit: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
        minRating: _minRating,
        city: _city,
        radius: _searchRadius,
        lat: lat,
        lon: lon,
      );

      setState(() {
        _projects = response.projects;
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

      if (user?.latitude != null && user?.longitude != null) {
        lat = user!.latitude;
        lon = user.longitude;
      }

      final response = await repository.getProjects(
        page: _currentPage,
        limit: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
        minRating: _minRating,
        city: _city,
        radius: _searchRadius,
        lat: lat,
        lon: lon,
      );

      setState(() {
        _projects.addAll(response.projects);
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
                  hint: l10n.tr('searchPlaceholder'),
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
          height: MediaQuery.of(context).size.height * 0.85,
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
                          _sortBy = 'rating';
                          _minRating = null;
                          _searchRadius = null;
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
                      // Sort By
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
                          _buildSortChip(
                            context,
                            l10n.tr('rating'),
                            'rating',
                            Icons.star_rounded,
                            setSheetState,
                          ),
                          _buildSortChip(
                            context,
                            l10n.tr('location.sortByDistance'),
                            'distance',
                            Icons.near_me_rounded,
                            setSheetState,
                          ),
                          _buildSortChip(
                            context,
                            l10n.tr('location.sortByNewest'),
                            'newest',
                            Icons.schedule_rounded,
                            setSheetState,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Distance Range (Slider)
                      Text(
                        '${l10n.tr('location.distance')}: ${_searchRadius?.toInt() ?? 50} km',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _searchRadius ?? 50,
                        min: 1,
                        max: 100,
                        divisions: 100,
                        label: '${_searchRadius?.toInt() ?? 50} km',
                        onChanged: (value) {
                          setSheetState(() {
                            _searchRadius = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Rating
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
                            groupValue: _minRating,
                            onChanged: (value) {
                              setSheetState(() {
                                _minRating = value;
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

                      // City
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
                        children: _cities.map((city) {
                          final isSelected = _city == city;
                          return FilterChip(
                            label: Text(city),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                _city = selected ? city : null;
                              });
                            },
                            backgroundColor: AppColors.surfaceVariant,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          );
                        }).toList(),
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

  Widget _buildSortChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    StateSetter setSheetState,
  ) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
