import 'package:equatable/equatable.dart';

/// Category model for admin panel
class Category extends Equatable {
  final int id;
  final int? parentId;
  final String name;
  final String nameAr;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  final String status;
  final int? createdBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final List<Category> children;
  final Category? parent;

  const Category({
    required this.id,
    this.parentId,
    required this.name,
    required this.nameAr,
    this.icon,
    this.sortOrder = 0,
    this.isActive = true,
    this.status = 'active',
    this.createdBy,
    this.rejectionReason,
    required this.createdAt,
    this.children = const [],
    this.parent,
  });

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      icon: json['icon'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      createdBy: json['createdBy'] as int?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      children: json['children'] != null
          ? (json['children'] as List)
              .map((child) => Category.fromJson(child as Map<String, dynamic>))
              .toList()
          : const [],
      parent: json['parent'] != null
          ? Category.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert Category to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'nameAr': nameAr,
      'icon': icon,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'status': status,
      'createdBy': createdBy,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    int? id,
    int? parentId,
    String? name,
    String? nameAr,
    String? icon,
    int? sortOrder,
    bool? isActive,
    String? status,
    int? createdBy,
    String? rejectionReason,
    DateTime? createdAt,
    List<Category>? children,
    Category? parent,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  /// Check if this is a parent category
  bool get isParentCategory => parentId == null;

  /// Check if this is a subcategory
  bool get isSubcategory => parentId != null;

  /// Check if category has subcategories
  bool get hasChildren => children.isNotEmpty;

  /// Get the display name (Arabic)
  String get displayName => nameAr;

  /// Get icon name or default
  String get iconName => icon ?? 'category';

  @override
  List<Object?> get props => [
        id,
        parentId,
        name,
        nameAr,
        icon,
        sortOrder,
        isActive,
        status,
        createdBy,
        rejectionReason,
      ];
}

/// Categories stats from admin API
class CategoriesStats {
  final int total;
  final int parents;
  final int subcategories;
  final int active;
  final int inactive;

  CategoriesStats({
    required this.total,
    required this.parents,
    required this.subcategories,
    required this.active,
    required this.inactive,
  });

  factory CategoriesStats.fromJson(Map<String, dynamic> json) {
    return CategoriesStats(
      total: json['total'] as int? ?? 0,
      parents: json['parents'] as int? ?? 0,
      subcategories: json['subcategories'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      inactive: json['inactive'] as int? ?? 0,
    );
  }
}
