import 'package:equatable/equatable.dart';

import 'category.dart';
import 'project_model.dart';

/// Product Image Model
class ProductImage extends Equatable {
  final int id;
  final int productId;
  final String imageUrl;
  final int sortOrder;
  final DateTime? createdAt;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int,
      productId: json['productId'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [id, productId, imageUrl, sortOrder];
}

/// Product Variant Model
class ProductVariant extends Equatable {
  final int id;
  final int productId;
  final String name;
  final String nameAr;
  final double priceModifier;
  final int quantity;
  final bool isAvailable;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.nameAr,
    this.priceModifier = 0,
    this.quantity = 0,
    this.isAvailable = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      productId: json['productId'] as int? ?? 0,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      priceModifier: double.tryParse(json['priceModifier'].toString()) ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'name': name,
        'nameAr': nameAr,
        'priceModifier': priceModifier,
        'quantity': quantity,
        'isAvailable': isAvailable,
      };

  String getLocalizedName(String language) {
    return language == 'ar' ? nameAr : name;
  }

  @override
  List<Object?> get props =>
      [id, productId, name, nameAr, priceModifier, quantity, isAvailable];
}

/// Product Tag Model
class ProductTag extends Equatable {
  final int id;
  final String name;
  final String nameAr;

  const ProductTag({
    required this.id,
    required this.name,
    required this.nameAr,
  });

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    return ProductTag(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameAr': nameAr,
      };

  String getLocalizedName(String language) {
    return language == 'ar' ? nameAr : name;
  }

  @override
  List<Object?> get props => [id, name, nameAr];
}

/// Product Model
class Product extends Equatable {
  final int id;
  final int projectId;
  final int categoryId;
  final String name;
  final String nameAr;
  final String? description;
  final String? descriptionAr;
  final double basePrice;
  final String posterImageUrl;
  final int quantity;
  final bool isAvailable;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final double averageRating;
  final int totalReviews;
  final int viewCount;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final List<ProductTag> tags;
  final Project? project;
  final Category? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Helper to parse int field that could be int or string
  static int? _parseIntField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  const Product({
    required this.id,
    required this.projectId,
    required this.categoryId,
    required this.name,
    required this.nameAr,
    this.description,
    this.descriptionAr,
    required this.basePrice,
    required this.posterImageUrl,
    this.quantity = 0,
    this.isAvailable = true,
    this.status = 'pending',
    this.rejectionReason,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.viewCount = 0,
    this.images = const [],
    this.variants = const [],
    this.tags = const [],
    this.project,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseIntField(json, 'id') ?? 0,
      projectId: _parseIntField(json, 'projectId') ??
          _parseIntField(json, 'project_id') ??
          0,
      categoryId: _parseIntField(json, 'categoryId') ??
          _parseIntField(json, 'category_id') ??
          0,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      description: json['description'] as String?,
      descriptionAr:
          json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      basePrice: double.tryParse(json['basePrice']?.toString() ??
              json['base_price']?.toString() ??
              '0') ??
          0.0,
      posterImageUrl: json['posterImageUrl'] as String? ??
          json['poster_image_url'] as String? ??
          '',
      quantity: json['quantity'] as int? ?? 0,
      isAvailable:
          json['isAvailable'] as bool? ?? json['is_available'] as bool? ?? true,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String? ??
          json['rejection_reason'] as String?,
      averageRating: double.tryParse(json['averageRating']?.toString() ??
              json['average_rating']?.toString() ??
              '0') ??
          0.0,
      totalReviews:
          json['totalReviews'] as int? ?? json['total_reviews'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? json['view_count'] as int? ?? 0,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      tags: json['tags'] != null
          ? (json['tags'] as List)
              .map((e) => ProductTag.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      project: json['project'] != null
          ? Project.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
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
      'projectId': projectId,
      'categoryId': categoryId,
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'basePrice': basePrice,
      'posterImageUrl': posterImageUrl,
      'quantity': quantity,
      'isAvailable': isAvailable,
      'status': status,
      'rejectionReason': rejectionReason,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'viewCount': viewCount,
      'images': images.map((e) => e.toJson()).toList(),
      'variants': variants.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      if (project != null) 'project': project!.toJson(),
      if (category != null) 'category': category!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String getLocalizedName(String language) {
    return language == 'ar' ? nameAr : name;
  }

  String getLocalizedDescription(String language) {
    return language == 'ar'
        ? (descriptionAr ?? description ?? '')
        : (description ?? '');
  }

  String? get mainImage => posterImageUrl.isNotEmpty ? posterImageUrl : null;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [
        id,
        projectId,
        categoryId,
        name,
        nameAr,
        basePrice,
        status,
        isAvailable,
        createdAt,
        project,
        category,
      ];
}
