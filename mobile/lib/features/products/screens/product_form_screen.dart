import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/models/category.dart';
import '../widgets/variants_editor_widget.dart';

/// Product Form Screen - stunning UI for creating/editing products
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  final int projectId;

  const ProductFormScreen({
    super.key,
    this.product,
    required this.projectId,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  int? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  List<Category> _categories = [];
  final List<File> _newImages = [];
  List<ProductImage> _existingImages = [];
  List<int> _deletedImageIds = []; // Track images to delete from database
  bool _posterDeleted = false; // Track if poster was deleted
  List<Map<String, dynamic>> _variants = [];
  List<String> _customTags = [];
  final _tagController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadCategories();
    if (_isEditing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final product = widget.product!;
    _nameController.text = product.name;
    _nameArController.text = product.nameAr;
    _descriptionController.text = product.description ?? '';
    _descriptionArController.text = product.descriptionAr ?? '';
    _priceController.text = product.basePrice.toString();
    _quantityController.text = product.quantity.toString();
    _selectedCategoryId = product.categoryId;
    _isAvailable = product.isAvailable;

    // Add poster image as the first image (using id -1 to mark it as poster)
    _existingImages = [];
    if (product.posterImageUrl.isNotEmpty) {
      _existingImages.add(ProductImage(
        id: -1, // Special ID to mark as poster
        productId: product.id,
        imageUrl: product.posterImageUrl,
        sortOrder: 0,
      ));
    }
    // Add other images after poster
    _existingImages.addAll(product.images);

    _variants = product.variants
        .map((v) => {
              'id': v.id,
              'name': v.name,
              'nameAr': v.nameAr,
              'priceModifier': v.priceModifier,
              'quantity': v.quantity,
              'isAvailable': v.isAvailable,
            })
        .toList();
    // Load existing tags
    _customTags = product.tags.map((t) => t.name).toList();
  }

  Future<void> _loadCategories() async {
    try {
      final repository = ref.read(categoriesRepositoryProvider);
      final response = await repository.getCategories();
      setState(() {
        _categories = response;
        _isCategoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCategoriesLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image != null) {
      setState(() {
        _newImages.add(File(image.path));
      });
    }
  }

  void _showImageSourcePicker() {
    final isRtl = context.isRtl;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isRtl ? 'إضافة صور' : 'Add Photos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: isRtl ? 'المعرض' : 'Gallery',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages();
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: isRtl ? 'الكاميرا' : 'Camera',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withAlpha(51),
                  color.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(51)),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      final image = _existingImages[index];
      // Track for deletion (skip poster image which has id=-1)
      if (image.id > 0) {
        _deletedImageIds.add(image.id);
      } else if (image.id == -1) {
        // Poster was deleted
        _posterDeleted = true;
      }
      _existingImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showError(
          context.isRtl ? 'يرجى اختيار التصنيف' : 'Please select a category');
      return;
    }
    if (_newImages.isEmpty && _existingImages.isEmpty) {
      _showError(context.isRtl
          ? 'يرجى إضافة صورة واحدة على الأقل'
          : 'Please add at least one image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(productsRepositoryProvider);

      final productData = {
        'categoryId': _selectedCategoryId,
        'name': _nameController.text.trim(),
        'nameAr': _nameArController.text.trim(),
        'description': _descriptionController.text.trim(),
        'descriptionAr': _descriptionArController.text.trim(),
        'basePrice': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'isAvailable': _isAvailable,
      };

      Product savedProduct;
      if (_isEditing) {
        savedProduct =
            await repository.updateProduct(widget.product!.id, productData);

        // Handle poster replacement when poster was deleted
        int newImageStartIndex = 0;
        if (_posterDeleted) {
          if (_newImages.isNotEmpty) {
            // Use first new image as poster
            final posterImage = _newImages.first;
            final imageBytes = await posterImage.readAsBytes();
            final imageFilename = posterImage.path.split('/').last;
            await repository.updateProductPoster(
              savedProduct.id,
              imageBytes,
              imageFilename,
            );
            newImageStartIndex =
                1; // Skip first new image since it's now the poster
          } else if (_existingImages.isNotEmpty) {
            // Promote first remaining existing image as new poster
            final firstExisting = _existingImages.first;
            await repository.promoteImageAsPoster(
                savedProduct.id, firstExisting.id);
            // Mark this image for deletion from product_images since it's now the poster
            _deletedImageIds.add(firstExisting.id);
          }
        }

        // Upload additional new images (skip first if it was used as poster)
        for (int i = newImageStartIndex; i < _newImages.length; i++) {
          final bytes = await _newImages[i].readAsBytes();
          await repository.addProductImage(
            savedProduct.id,
            bytes,
            _newImages[i].path.split('/').last,
          );
        }
      } else {
        // For new products, use the first image as poster
        final posterImage = _newImages.first;
        final imageBytes = await posterImage.readAsBytes();
        final imageFilename = posterImage.path.split('/').last;

        savedProduct = await repository.createProduct(
          productData: productData,
          imageBytes: imageBytes,
          imageFilename: imageFilename,
        );

        // Upload additional images (skip the first one which is already the poster)
        if (_newImages.length > 1) {
          for (int i = 1; i < _newImages.length; i++) {
            final bytes = await _newImages[i].readAsBytes();
            await repository.addProductImage(
              savedProduct.id,
              bytes,
              _newImages[i].path.split('/').last,
            );
          }
        }
      }

      // Delete removed images (only when editing)
      if (_isEditing && _deletedImageIds.isNotEmpty) {
        for (final imageId in _deletedImageIds) {
          try {
            await repository.deleteProductImage(savedProduct.id, imageId);
          } catch (e) {
            // Continue even if deletion fails (image might already be deleted)
            print('Failed to delete image $imageId: $e');
          }
        }
      }

      // Handle variants
      for (final variant in _variants) {
        if (variant['id'] == null) {
          await repository.addProductVariant(savedProduct.id, variant);
        } else {
          await repository.updateProductVariant(variant['id'], variant);
        }
      }

      // Handle custom tags
      if (_customTags.isNotEmpty) {
        await repository.addCustomTagsToProduct(savedProduct.id, _customTags);
      }

      if (mounted) {
        _showSuccess(_isEditing
            ? (context.isRtl ? 'تم تحديث المنتج بنجاح' : 'Product updated!')
            : (context.isRtl ? 'تم إضافة المنتج بنجاح' : 'Product added!'));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isRtl),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      _buildImagesSection(isRtl),
                      const SizedBox(height: 28),
                      _buildBasicInfoCard(isRtl),
                      const SizedBox(height: 20),
                      _buildPricingCard(isRtl),
                      const SizedBox(height: 20),
                      _buildVariantsCard(isRtl),
                      const SizedBox(height: 20),
                      _buildTagsCard(isRtl),
                      const SizedBox(height: 20),
                      _buildAvailabilityCard(isRtl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(isRtl),
    );
  }

  Widget _buildHeader(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? (isRtl ? 'تعديل المنتج' : 'Edit Product')
                      : (isRtl ? 'إضافة منتج جديد' : 'Add New Product'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  isRtl
                      ? 'أضف تفاصيل منتجك هنا'
                      : 'Add your product details here',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(bool isRtl) {
    final totalImages = _existingImages.length + _newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(51),
                    AppColors.primary.withAlpha(26),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'صور المنتج' : 'Product Photos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    isRtl
                        ? '$totalImages صور مرفوعة'
                        : '$totalImages photos uploaded',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Poster image notification
        if (_newImages.isNotEmpty || _existingImages.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRtl
                        ? 'الصورة الأولى ستكون صورة الغلاف الرئيسية للمنتج'
                        : 'First image will be the main poster/cover image',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add image card
              _buildAddImageCard(isRtl),
              const SizedBox(width: 12),
              // Existing images (with poster badge on first)
              ..._existingImages.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildImageCard(
                    entry.value.imageUrl,
                    true,
                    () => _removeExistingImage(entry.key),
                    isPoster: entry.key == 0 && _newImages.isEmpty,
                  ),
                );
              }),
              // New images (with poster badge on first)
              ..._newImages.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildImageCard(
                    entry.value.path,
                    false,
                    () => _removeNewImage(entry.key),
                    isPoster: entry.key == 0,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageCard(bool isRtl) {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withAlpha(51),
              AppColors.primaryLight.withAlpha(26),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withAlpha(77),
            width: 2,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRtl ? 'إضافة صورة' : 'Add Photo',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String path, bool isNetwork, VoidCallback onRemove,
      {bool isPoster = false}) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isPoster
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withAlpha(26),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isPoster ? 17 : 20),
            child: isNetwork
                ? Image.network(ApiEndpoints.imageUrl(path),
                    fit: BoxFit.cover, width: 120, height: 160)
                : Image.file(File(path),
                    fit: BoxFit.cover, width: 120, height: 160),
          ),
        ),
        // Poster badge
        if (isPoster)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(102),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    context.isRtl ? 'الغلاف' : 'Poster',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withAlpha(102),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBasicInfoCard(bool isRtl) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.info_outline_rounded,
            title: isRtl ? 'المعلومات الأساسية' : 'Basic Info',
            color: AppColors.info,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: isRtl ? 'اسم المنتج (English)' : 'Product Name (English)',
            icon: Icons.abc_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameArController,
            label: isRtl ? 'اسم المنتج (عربي)' : 'Product Name (Arabic)',
            icon: Icons.translate_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: isRtl ? 'الوصف (English)' : 'Description (English)',
            icon: Icons.description_outlined,
            maxLines: 3,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionArController,
            label: isRtl ? 'الوصف (عربي)' : 'Description (Arabic)',
            icon: Icons.description_outlined,
            maxLines: 3,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildCategoryDropdown(isRtl),
        ],
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(51), color.withAlpha(26)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceVariant.withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return context.tr('validation.required');
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildCategoryDropdown(bool isRtl) {
    if (_isCategoriesLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withAlpha(128),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: isRtl ? 'التصنيف' : 'Category',
        prefixIcon:
            Icon(Icons.category_outlined, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceVariant.withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category.id,
          child: Text(isRtl ? category.nameAr : category.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategoryId = value);
      },
      validator: (value) {
        if (value == null) {
          return context.tr('validation.required');
        }
        return null;
      },
    );
  }

  Widget _buildPricingCard(bool isRtl) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.attach_money_rounded,
            title: isRtl ? 'التسعير والمخزون' : 'Pricing & Inventory',
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _priceController,
                  label: isRtl ? 'السعر (SAR)' : 'Price (SAR)',
                  icon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _quantityController,
                  label: isRtl ? 'الكمية' : 'Qty',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCard(bool isRtl) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.style_outlined,
            title: isRtl ? 'المتغيرات (اختياري)' : 'Variants (Optional)',
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          VariantsEditorWidget(
            variants: _variants,
            onChanged: (variants) {
              setState(() => _variants = variants);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard(bool isRtl) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.local_offer_outlined,
            title: isRtl ? 'الوسوم (اختياري)' : 'Tags (Optional)',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          Text(
            isRtl
                ? 'أضف وسوم لمساعدة العملاء على إيجاد منتجك'
                : 'Add tags to help customers find your product',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // Tags input field
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: isRtl ? 'مثال: صنع يدوي' : 'e.g. Handmade',
                    prefixIcon: Icon(Icons.tag, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant.withAlpha(128),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onFieldSubmitted: (value) => _addTag(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addTag,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.purple.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

          // Display added tags
          if (_customTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customTags.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withAlpha(204),
                        Colors.purple.withAlpha(153),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_customTags.contains(tag)) {
      setState(() {
        _customTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _customTags.removeAt(index);
    });
  }

  Widget _buildAvailabilityCard(bool isRtl) {
    return _buildCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (_isAvailable ? AppColors.success : AppColors.textTertiary)
                      .withAlpha(51),
                  (_isAvailable ? AppColors.success : AppColors.textTertiary)
                      .withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: _isAvailable ? AppColors.success : AppColors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'متاح للبيع' : 'Available for Sale',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  isRtl
                      ? 'سيظهر المنتج للعملاء'
                      : 'Product will be visible to customers',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isRtl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: _isLoading ? null : _saveProduct,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLoading
                    ? [
                        AppColors.textTertiary,
                        AppColors.textTertiary.withAlpha(179),
                      ]
                    : [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(102),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEditing
                              ? Icons.save_rounded
                              : Icons.add_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isEditing
                              ? (isRtl ? 'حفظ التغييرات' : 'Save Changes')
                              : (isRtl ? 'إضافة المنتج' : 'Add Product'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
