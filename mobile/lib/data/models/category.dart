import 'package:equatable/equatable.dart';

/// Category model for Sina'a marketplace
class Category extends Equatable {
  final int id;
  final int? parentId;
  final String name;
  final String nameAr;
  final String? icon;
  final int sortOrder;
  final bool isActive;
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

  /// Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'nameAr': nameAr,
      'icon': icon,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'children': children.map((c) => c.toJson()).toList(),
      if (parent != null) 'parent': parent!.toJson(),
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

  /// Get localized name based on language
  String getLocalizedName(String language) {
    return language == 'ar' ? nameAr : name;
  }

  /// Get the display name (Arabic by default for Saudi market)
  String get displayName => nameAr;

  /// Get the secondary name (English)
  String get secondaryName => name;

  /// Get Material icon name or default
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
        createdAt,
      ];
}

