import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

// Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(adminDioProvider);
  return DashboardRepository(dio);
});

// Stats State Provider
final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats?>>(
        (ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardStatsNotifier(repository);
});

class DashboardStatsNotifier
    extends StateNotifier<AsyncValue<DashboardStats?>> {
  final DashboardRepository _repository;

  DashboardStatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }
}
