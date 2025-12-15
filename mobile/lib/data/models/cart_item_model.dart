import 'product_model.dart';

/// Represents a cart item in the inquiry cart
class CartItem {
  final int id;
  final int userId;
  final int productId;
  final int? variantId;
  final int quantity;
  final String? note;
  final DateTime createdAt;
  final Product? product;
  final ProductVariant? variant;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.variantId,
    required this.quantity,
    this.note,
    required this.createdAt,
    this.product,
    this.variant,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? json['user_id'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['product_id'] as int? ?? 0,
      variantId: json['variantId'] as int? ?? json['variant_id'] as int?,
      quantity: json['quantity'] as int? ?? 1,
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      variant: json['variant'] != null
          ? ProductVariant.fromJson(json['variant'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    int? id,
    int? userId,
    int? productId,
    int? variantId,
    int? quantity,
    String? note,
    DateTime? createdAt,
    Product? product,
    ProductVariant? variant,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
      variant: variant ?? this.variant,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a group of cart items from the same project
class CartGroup {
  final ProjectSummary project;
  final List<CartItem> items;

  const CartGroup({
    required this.project,
    required this.items,
  });

  factory CartGroup.fromJson(Map<String, dynamic> json) {
    return CartGroup(
      project: ProjectSummary.fromJson(json['project'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Minimal project info for cart grouping
class ProjectSummary {
  final int id;
  final String name;
  final String nameAr;
  final String? logoUrl;
  final String city;

  const ProjectSummary({
    required this.id,
    required this.name,
    required this.nameAr,
    this.logoUrl,
    required this.city,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      city: json['city'] as String? ?? '',
    );
  }

  String getLocalizedName(String locale) {
    return locale == 'ar' ? nameAr : name;
  }
}

/// Response from GET /cart endpoint
class CartResponse {
  final List<CartGroup> groups;
  final int totalItems;

  const CartResponse({
    required this.groups,
    required this.totalItems,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      groups: (json['groups'] as List<dynamic>?)
              ?.map(
                  (group) => CartGroup.fromJson(group as Map<String, dynamic>))
              .toList() ??
          [],
      totalItems: json['totalItems'] as int? ?? 0,
    );
  }

  bool get isEmpty => groups.isEmpty;
  int get projectCount => groups.length;
}

/// Response from POST /cart/send-inquiries endpoint
class SendInquiriesResponse {
  final String message;
  final List<int> conversationIds;
  final int projectCount;

  const SendInquiriesResponse({
    required this.message,
    required this.conversationIds,
    required this.projectCount,
  });

  factory SendInquiriesResponse.fromJson(Map<String, dynamic> json) {
    return SendInquiriesResponse(
      message: json['message'] as String? ?? '',
      conversationIds: (json['conversationIds'] as List<dynamic>?)
              ?.map((id) => id as int)
              .toList() ??
          [],
      projectCount: json['projectCount'] as int? ?? 0,
    );
  }
}
