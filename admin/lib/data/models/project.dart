import 'admin_user.dart';

enum ProjectStatus {
  pending,
  approved,
  rejected,
  disabled;

  String get label {
    switch (this) {
      case ProjectStatus.pending:
        return 'Pending';
      case ProjectStatus.approved:
        return 'Approved';
      case ProjectStatus.rejected:
        return 'Rejected';
      case ProjectStatus.disabled:
        return 'Disabled';
    }
  }
}

class Project {
  final int id;
  final int ownerId;
  final String name;
  final String nameAr;
  final String? description;
  final String? descriptionAr;
  final String? logoUrl;
  final String? coverUrl;
  final String city;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? workingHours;
  final Map<String, dynamic>? socialLinks;
  final ProjectStatus status;
  final String? rejectionReason;
  final String? disableReason;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AdminUser? owner;

  const Project({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.nameAr,
    this.description,
    this.descriptionAr,
    this.logoUrl,
    this.coverUrl,
    required this.city,
    this.latitude,
    this.longitude,
    this.workingHours,
    this.socialLinks,
    required this.status,
    this.rejectionReason,
    this.disableReason,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      city: json['city'] as String,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      workingHours: json['workingHours'] as Map<String, dynamic>?,
      socialLinks: json['socialLinks'] as Map<String, dynamic>?,
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.pending,
      ),
      rejectionReason: json['rejectionReason'] as String?,
      disableReason: json['disableReason'] as String?,
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '') ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      owner: json['owner'] != null
          ? AdminUser.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'workingHours': workingHours,
      'socialLinks': socialLinks,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'disableReason': disableReason,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'owner': owner?.toJson(),
    };
  }
}
