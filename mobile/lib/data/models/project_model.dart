import 'package:equatable/equatable.dart';

class Project extends Equatable {
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
  final String status;
  final String? rejectionReason;
  final String? disableReason;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

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
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      workingHours: json['workingHours'] as Map<String, dynamic>?,
      socialLinks: json['socialLinks'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
      disableReason: json['disableReason'] as String?,
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
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
      'status': status,
      'rejectionReason': rejectionReason,
      'disableReason': disableReason,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isDisabled => status == 'disabled';

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        nameAr,
        city,
        status,
        averageRating,
        totalReviews,
      ];
}
