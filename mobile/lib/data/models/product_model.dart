import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final int projectId;
  final int categoryId;
  final String name;
  final String nameAr;
  final String? description;
  final String? descriptionAr;
  final double price;
  final List<String> images;
  final bool isActive;
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
    required this.price,
    this.images = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      categoryId: json['categoryId'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      images: json['images'] != null
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : const [],
      isActive: json['isActive'] as bool? ?? true,
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
      'price': price,
      'images': images,
      'isActive': isActive,
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

  String? get mainImage => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [
        id,
        projectId,
        categoryId,
        name,
        nameAr,
        price,
        isActive,
        createdAt,
      ];
}
