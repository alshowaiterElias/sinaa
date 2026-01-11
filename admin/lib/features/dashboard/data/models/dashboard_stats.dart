import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats.g.dart';

@JsonSerializable()
class DashboardStats {
  final DashboardCounts counts;
  final DashboardGraphs graphs;
  final List<RecentActivity> recentActivity;

  DashboardStats({
    required this.counts,
    required this.graphs,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}

@JsonSerializable()
class DashboardCounts {
  final int users;
  final int projects;
  final int products;
  final int pendingTickets;

  DashboardCounts({
    required this.users,
    required this.projects,
    required this.products,
    required this.pendingTickets,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> json) =>
      _$DashboardCountsFromJson(json);
}

@JsonSerializable()
class DashboardGraphs {
  final List<GraphPoint> userGrowth;
  final List<GraphPoint> productGrowth;
  final List<CategoryDistribution> categoryDistribution;

  DashboardGraphs({
    required this.userGrowth,
    required this.productGrowth,
    required this.categoryDistribution,
  });

  factory DashboardGraphs.fromJson(Map<String, dynamic> json) =>
      _$DashboardGraphsFromJson(json);
}

@JsonSerializable()
class GraphPoint {
  final String month;
  final int count;

  GraphPoint({required this.month, required this.count});

  factory GraphPoint.fromJson(Map<String, dynamic> json) =>
      _$GraphPointFromJson(json);
}

@JsonSerializable()
class CategoryDistribution {
  final String name;
  final int count;

  CategoryDistribution({required this.name, required this.count});

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) =>
      _$CategoryDistributionFromJson(json);
}

@JsonSerializable()
class RecentActivity {
  final int id;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final String? avatarUrl;

  RecentActivity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.avatarUrl,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityFromJson(json);
}
