import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_model.dart';
import '../models/product_model.dart';
import '../repositories/project_repository.dart';

/// Projects state
class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String? cityFilter;
  final String? searchQuery;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.cityFilter,
    this.searchQuery,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    int? currentPage,
    int? totalPages,
    String? cityFilter,
    String? searchQuery,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      cityFilter: cityFilter ?? this.cityFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Projects notifier
class ProjectsNotifier extends Notifier<ProjectsState> {
  late ProjectsRepository _repository;

  @override
  ProjectsState build() {
    _repository = ref.watch(projectsRepositoryProvider);
    return const ProjectsState();
  }

  /// Load projects with current filters
  Future<void> loadProjects({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        projects: [],
        currentPage: 1,
        isInitialized: false,
        isLoading: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.getProjects(
        page: state.currentPage,
        city: state.cityFilter,
        search: state.searchQuery,
      );

      state = state.copyWith(
        projects: refresh
            ? response.projects
            : [...state.projects, ...response.projects],
        currentPage: response.pagination.currentPage + 1,
        totalPages: response.pagination.totalPages,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Apply filters
  Future<void> setFilters({String? city, String? search}) async {
    state = state.copyWith(
      cityFilter: city,
      searchQuery: search,
    );
    await loadProjects(refresh: true);
  }

  /// Load more projects (pagination)
  Future<void> loadMore() async {
    if (state.currentPage <= state.totalPages) {
      await loadProjects();
    }
  }
}

/// My Project state (for owner)
class MyProjectState {
  final Project? project;
  final bool isLoading;
  final String? error;

  const MyProjectState({
    this.project,
    this.isLoading = false,
    this.error,
  });

  MyProjectState copyWith({
    Project? project,
    bool? isLoading,
    String? error,
  }) {
    return MyProjectState(
      project: project ?? this.project,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// My Project notifier
class MyProjectNotifier extends Notifier<MyProjectState> {
  late ProjectsRepository _repository;

  @override
  MyProjectState build() {
    _repository = ref.watch(projectsRepositoryProvider);
    return const MyProjectState();
  }

  Future<void> loadMyProject() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final project = await _repository.getMyProject();
      state = state.copyWith(
        project: project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createProject(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final project = await _repository.createProject(data);
      state = state.copyWith(
        project: project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateProject(Map<String, dynamic> data) async {
    if (state.project == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final project = await _repository.updateProject(state.project!.id, data);
      state = state.copyWith(
        project: project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

// Providers

final projectsStateProvider =
    NotifierProvider<ProjectsNotifier, ProjectsState>(() {
  return ProjectsNotifier();
});

final myProjectProvider =
    NotifierProvider<MyProjectNotifier, MyProjectState>(() {
  return MyProjectNotifier();
});

/// Provider to get a single project by ID (fetches if not in list)
final projectByIdProvider =
    FutureProvider.family<Project, int>((ref, id) async {
  // Check if in list
  final projectsState = ref.read(projectsStateProvider);
  final cached = projectsState.projects.where((p) => p.id == id).firstOrNull;

  if (cached != null) return cached;

  // Fetch from API
  final repository = ref.read(projectsRepositoryProvider);
  return repository.getProjectById(id);
});

/// Provider to get products for a project
final projectProductsProvider =
    FutureProvider.family<List<Product>, int>((ref, projectId) async {
  final repository = ref.read(projectsRepositoryProvider);
  final response = await repository.getProjectProducts(projectId);
  return response.products;
});
