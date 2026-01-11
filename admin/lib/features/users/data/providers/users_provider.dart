import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sinaa_admin/features/users/data/repositories/users_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/admin_user.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final dio = ref.watch(adminDioProvider);
  return UsersRepository(dio);
});

class UsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  final int total;
  final int totalPages;
  final int currentPage;

  // Filters
  final String searchQuery;
  final String roleFilter;
  final String statusFilter;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.totalPages = 0,
    this.currentPage = 1,
    this.searchQuery = '',
    this.roleFilter = 'all',
    this.statusFilter = 'all',
  });

  UsersState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
    int? total,
    int? totalPages,
    int? currentPage,
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final UsersRepository _repository;

  UsersNotifier(this._repository) : super(UsersState()) {
    loadUsers();
  }

  Future<void> loadUsers({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getUsers(
        page: refresh ? 1 : state.currentPage,
        search: state.searchQuery,
        role: state.roleFilter,
        status: state.statusFilter,
      );

      state = state.copyWith(
        users: refresh ? response.users : [...state.users, ...response.users],
        total: response.total,
        totalPages: response.totalPages,
        currentPage: response.currentPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    loadUsers(refresh: true);
  }

  void setRoleFilter(String role) {
    if (state.roleFilter == role) return;
    state = state.copyWith(roleFilter: role);
    loadUsers(refresh: true);
  }

  void setStatusFilter(String status) {
    if (state.statusFilter == status) return;
    state = state.copyWith(statusFilter: status);
    loadUsers(refresh: true);
  }

  Future<void> toggleUserBan(int userId) async {
    try {
      await _repository.toggleUserBan(userId);
      loadUsers(refresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void loadMore() {
    if (state.currentPage < state.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadUsers();
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier(ref.watch(usersRepositoryProvider));
});
