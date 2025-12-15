/// Product status enum
enum ProductStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ProductStatus.pending:
        return 'Pending';
      case ProductStatus.approved:
        return 'Approved';
      case ProductStatus.rejected:
        return 'Rejected';
    }
  }

  String get labelAr {
    switch (this) {
      case ProductStatus.pending:
        return 'قيد المراجعة';
      case ProductStatus.approved:
        return 'معتمد';
      case ProductStatus.rejected:
        return 'مرفوض';
    }
  }
}

/// Product Image Model
class ProductImage {
  final int id;
  final String imageUrl;
  final int sortOrder;

  const ProductImage({
    required this.id,
    required this.imageUrl,
    this.sortOrder = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

/// Product Variant Model
class ProductVariant {
  final int id;
  final String name;
  final String nameAr;
  final double priceModifier;
  final int quantity;
  final bool isAvailable;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.nameAr,
    this.priceModifier = 0,
    this.quantity = 0,
    this.isAvailable = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      priceModifier:
          double.tryParse(json['priceModifier']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

/// Product Tag Model
class ProductTag {
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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
    );
  }
}

/// Simplified Project for embedding in Product
class ProductProject {
  final int id;
  final int ownerId;
  final String name;
  final String nameAr;
  final String city;
  final double averageRating;
  final ProductOwner? owner;

  const ProductProject({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.nameAr,
    required this.city,
    this.averageRating = 0,
    this.owner,
  });

  factory ProductProject.fromJson(Map<String, dynamic> json) {
    return ProductProject(
      id: json['id'] as int? ?? 0,
      ownerId: json['ownerId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      city: json['city'] as String? ?? '',
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      owner: json['owner'] != null
          ? ProductOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Owner info embedded in ProductProject
class ProductOwner {
  final int id;
  final String name;
  final String email;
  final String? phone;

  const ProductOwner({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory ProductOwner.fromJson(Map<String, dynamic> json) {
    return ProductOwner(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

/// Simplified Category for embedding in Product
class ProductCategory {
  final int id;
  final String name;
  final String nameAr;
  final String? icon;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    this.icon,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}

/// Main Product Model
class Product {
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
  final ProductStatus status;
  final String? rejectionReason;
  final double averageRating;
  final int totalReviews;
  final int viewCount;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final List<ProductTag> tags;
  final ProductProject? project;
  final ProductCategory? category;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.status,
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
      id: json['id'] as int? ?? 0,
      projectId: json['projectId'] as int? ?? 0,
      categoryId: json['categoryId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      basePrice: double.tryParse(json['basePrice']?.toString() ?? '0') ?? 0.0,
      posterImageUrl: json['posterImageUrl'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.pending,
      ),
      rejectionReason: json['rejectionReason'] as String?,
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
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
          ? ProductProject.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? ProductCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Check if product is disabled by admin
  bool get isDisabled =>
      !isAvailable && (rejectionReason?.startsWith('[DISABLED]') ?? false);

  /// Get disable reason if disabled
  String? get disableReason =>
      isDisabled ? rejectionReason?.replaceFirst('[DISABLED] ', '') : null;
}
