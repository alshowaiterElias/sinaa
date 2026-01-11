import 'package:equatable/equatable.dart';

/// User role enum
enum UserRole {
  customer,
  projectOwner,
  admin;

  static UserRole fromString(String value) {
    switch (value) {
      case 'project_owner':
        return UserRole.projectOwner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  String toJson() {
    switch (this) {
      case UserRole.projectOwner:
        return 'project_owner';
      case UserRole.admin:
        return 'admin';
      default:
        return 'customer';
    }
  }
}

/// User model
class User extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool locationSharingEnabled;
  final bool notificationsEnabled;
  final DateTime? locationUpdatedAt;
  final UserRole role;
  final String language;
  final bool isActive;
  final bool isBanned;
  final String? banReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.city,
    this.latitude,
    this.longitude,
    this.locationSharingEnabled = true,
    this.notificationsEnabled = true,
    this.locationUpdatedAt,
    required this.role,
    required this.language,
    required this.isActive,
    required this.isBanned,
    this.banReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      locationSharingEnabled: json['locationSharingEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      locationUpdatedAt: json['locationUpdatedAt'] != null
          ? DateTime.parse(json['locationUpdatedAt'] as String)
          : null,
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      language: json['language'] as String? ?? 'ar',
      isActive: json['isActive'] as bool? ?? true,
      isBanned: json['isBanned'] as bool? ?? false,
      banReason: json['banReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'locationSharingEnabled': locationSharingEnabled,
      'notificationsEnabled': notificationsEnabled,
      'locationUpdatedAt': locationUpdatedAt?.toIso8601String(),
      'role': role.toJson(),
      'language': language,
      'isActive': isActive,
      'isBanned': isBanned,
      'banReason': banReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? city,
    double? latitude,
    double? longitude,
    bool? locationSharingEnabled,
    bool? notificationsEnabled,
    DateTime? locationUpdatedAt,
    UserRole? role,
    String? language,
    bool? isActive,
    bool? isBanned,
    String? banReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      role: role ?? this.role,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is project owner
  bool get isProjectOwner => role == UserRole.projectOwner;

  /// Check if user is customer
  bool get isCustomer => role == UserRole.customer;

  /// Check if user can access the app
  bool get canAccess => isActive && !isBanned;

  /// Get initials for avatar
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  /// Check if user has location data
  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        avatarUrl,
        city,
        latitude,
        longitude,
        locationSharingEnabled,
        notificationsEnabled,
        role,
        language,
        isActive,
        isBanned,
        banReason,
        createdAt,
        updatedAt,
      ];
}

/// Project model (for project owners)
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
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

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
