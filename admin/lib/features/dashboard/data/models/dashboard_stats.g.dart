// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      counts: DashboardCounts.fromJson(json['counts'] as Map<String, dynamic>),
      graphs: DashboardGraphs.fromJson(json['graphs'] as Map<String, dynamic>),
      recentActivity: (json['recentActivity'] as List<dynamic>)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'counts': instance.counts,
      'graphs': instance.graphs,
      'recentActivity': instance.recentActivity,
    };

DashboardCounts _$DashboardCountsFromJson(Map<String, dynamic> json) =>
    DashboardCounts(
      users: (json['users'] as num).toInt(),
      projects: (json['projects'] as num).toInt(),
      products: (json['products'] as num).toInt(),
      pendingTickets: (json['pendingTickets'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardCountsToJson(DashboardCounts instance) =>
    <String, dynamic>{
      'users': instance.users,
      'projects': instance.projects,
      'products': instance.products,
      'pendingTickets': instance.pendingTickets,
    };

DashboardGraphs _$DashboardGraphsFromJson(Map<String, dynamic> json) =>
    DashboardGraphs(
      userGrowth: (json['userGrowth'] as List<dynamic>)
          .map((e) => GraphPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      productGrowth: (json['productGrowth'] as List<dynamic>)
          .map((e) => GraphPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryDistribution: (json['categoryDistribution'] as List<dynamic>)
          .map((e) => CategoryDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardGraphsToJson(DashboardGraphs instance) =>
    <String, dynamic>{
      'userGrowth': instance.userGrowth,
      'productGrowth': instance.productGrowth,
      'categoryDistribution': instance.categoryDistribution,
    };

GraphPoint _$GraphPointFromJson(Map<String, dynamic> json) => GraphPoint(
  month: json['month'] as String,
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$GraphPointToJson(GraphPoint instance) =>
    <String, dynamic>{'month': instance.month, 'count': instance.count};

CategoryDistribution _$CategoryDistributionFromJson(
  Map<String, dynamic> json,
) => CategoryDistribution(
  name: json['name'] as String,
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$CategoryDistributionToJson(
  CategoryDistribution instance,
) => <String, dynamic>{'name': instance.name, 'count': instance.count};

RecentActivity _$RecentActivityFromJson(Map<String, dynamic> json) =>
    RecentActivity(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$RecentActivityToJson(RecentActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'createdAt': instance.createdAt.toIso8601String(),
      'avatarUrl': instance.avatarUrl,
    };
