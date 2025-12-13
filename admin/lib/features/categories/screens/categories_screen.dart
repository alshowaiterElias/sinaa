import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../data/models/category.dart';
import '../../../data/providers/categories_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminCategoriesStateProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(adminCategoriesStateProvider);
    final stats = categoriesState.stats;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة التصنيفات',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (stats != null)
                    Text(
                      '${stats.total} تصنيف • ${stats.parents} رئيسي • ${stats.active} نشط',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminColors.textSecondary,
                          ),
                    ),
                ],
              ),
              Row(
                children: [
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: categoriesState.isLoading
                        ? null
                        : () {
                            ref
                                .read(adminCategoriesStateProvider.notifier)
                                .refresh();
                          },
                  ),
                  const SizedBox(width: 8),
                  // Add category button
                  ElevatedButton.icon(
                    onPressed: () => _showCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة تصنيف'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats cards
          if (stats != null) ...[
            Row(
              children: [
                _buildStatCard(
                  context,
                  'إجمالي التصنيفات',
                  stats.total.toString(),
                  Icons.category_rounded,
                  AdminColors.primary,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'التصنيفات الرئيسية',
                  stats.parents.toString(),
                  Icons.folder_rounded,
                  AdminColors.secondary,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'التصنيفات الفرعية',
                  stats.subcategories.toString(),
                  Icons.subdirectory_arrow_right_rounded,
                  AdminColors.accent,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'غير نشط',
                  stats.inactive.toString(),
                  Icons.visibility_off_rounded,
                  AdminColors.error,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Categories list
          Expanded(
            child: Card(
              child: categoriesState.isLoading &&
                      categoriesState.categories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : categoriesState.error != null &&
                          categoriesState.categories.isEmpty
                      ? _buildError(context, categoriesState.error!)
                      : categoriesState.categories.isEmpty
                          ? _buildEmpty(context)
                          : _buildCategoriesList(
                              context,
                              categoriesState.parentCategories,
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AdminColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'فشل تحميل التصنيفات',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(adminCategoriesStateProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AdminColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تصنيفات',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة تصنيف جديد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة تصنيف'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, List<Category> categories) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final orders = <Map<String, int>>[];
        final reordered = List<Category>.from(categories);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);

        for (var i = 0; i < reordered.length; i++) {
          orders.add({'id': reordered[i].id, 'sortOrder': i});
        }

        await ref
            .read(adminCategoriesStateProvider.notifier)
            .reorderCategories(orders);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(context, category, key: ValueKey(category.id));
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    Category category, {
    Key? key,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.isActive
                ? AdminColors.primary.withOpacity(0.1)
                : AdminColors.textTertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(category.iconName),
            color:
                category.isActive ? AdminColors.primary : AdminColors.textTertiary,
          ),
        ),
        title: Row(
          children: [
            Text(
              category.nameAr,
              style: TextStyle(
                color: category.isActive
                    ? AdminColors.textPrimary
                    : AdminColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${category.name})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminColors.textTertiary,
                  ),
            ),
            if (!category.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'غير نشط',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AdminColors.error,
                      ),
                ),
              ),
            ],
          ],
        ),
        subtitle: category.hasChildren
            ? Text('${category.children.length} تصنيف فرعي')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle active
            IconButton(
              icon: Icon(
                category.isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: category.isActive
                    ? AdminColors.success
                    : AdminColors.textTertiary,
              ),
              tooltip: category.isActive ? 'إخفاء' : 'إظهار',
              onPressed: () => _toggleCategory(category),
            ),
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'تعديل',
              onPressed: () => _showCategoryDialog(context, category: category),
            ),
            // Add subcategory
            if (category.isParentCategory)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'إضافة تصنيف فرعي',
                onPressed: () =>
                    _showCategoryDialog(context, parentId: category.id),
              ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AdminColors.error),
              tooltip: 'حذف',
              onPressed: () => _deleteCategory(category),
            ),
            // Drag handle
            const Icon(Icons.drag_handle, color: AdminColors.textTertiary),
          ],
        ),
        children: category.hasChildren
            ? category.children.map((sub) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(right: 72, left: 16),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: sub.isActive
                          ? AdminColors.secondary.withOpacity(0.1)
                          : AdminColors.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getCategoryIcon(sub.iconName),
                      size: 16,
                      color: sub.isActive
                          ? AdminColors.secondary
                          : AdminColors.textTertiary,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        sub.nameAr,
                        style: TextStyle(
                          color: sub.isActive
                              ? AdminColors.textPrimary
                              : AdminColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${sub.name})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AdminColors.textTertiary,
                            ),
                      ),
                      if (!sub.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'غير نشط',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AdminColors.error,
                                      fontSize: 10,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          sub.isActive
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 18,
                          color: sub.isActive
                              ? AdminColors.success
                              : AdminColors.textTertiary,
                        ),
                        onPressed: () => _toggleCategory(sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showCategoryDialog(context, category: sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AdminColors.error),
                        onPressed: () => _deleteCategory(sub),
                      ),
                    ],
                  ),
                );
              }).toList()
            : [],
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context, {
    Category? category,
    int? parentId,
  }) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name);
    final nameArController = TextEditingController(text: category?.nameAr);
    final iconController = TextEditingController(text: category?.icon);
    var isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit
              ? 'تعديل التصنيف'
              : parentId != null
                  ? 'إضافة تصنيف فرعي'
                  : 'إضافة تصنيف جديد'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالإنجليزية',
                    hintText: 'Category Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالعربية',
                    hintText: 'اسم التصنيف',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'أيقونة (اختياري)',
                    hintText: 'restaurant, checkroom, handyman...',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    nameArController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
                  );
                  return;
                }

                Navigator.pop(context);

                final notifier =
                    ref.read(adminCategoriesStateProvider.notifier);

                try {
                  if (isEdit) {
                    await notifier.updateCategory(
                      id: category.id,
                      name: nameController.text,
                      nameAr: nameArController.text,
                      icon: iconController.text.isNotEmpty
                          ? iconController.text
                          : null,
                      isActive: isActive,
                    );
                    _showSuccessSnackBar('تم تحديث التصنيف بنجاح');
                  } else {
                    await notifier.createCategory(
                      name: nameController.text,
                      nameAr: nameArController.text,
                      icon: iconController.text.isNotEmpty
                          ? iconController.text
                          : null,
                      parentId: parentId,
                      isActive: isActive,
                    );
                    _showSuccessSnackBar('تم إضافة التصنيف بنجاح');
                  }
                } catch (e) {
                  _showErrorSnackBar('حدث خطأ: $e');
                }
              },
              child: Text(isEdit ? 'تحديث' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCategory(Category category) async {
    try {
      await ref
          .read(adminCategoriesStateProvider.notifier)
          .toggleCategory(category.id);
      _showSuccessSnackBar(
        category.isActive ? 'تم إخفاء التصنيف' : 'تم تفعيل التصنيف',
      );
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: $e');
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${category.nameAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(adminCategoriesStateProvider.notifier)
          .deleteCategory(category.id);

      if (success) {
        _showSuccessSnackBar('تم حذف التصنيف بنجاح');
      } else {
        _showErrorSnackBar('فشل حذف التصنيف');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.error,
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant_rounded,
      'checkroom': Icons.checkroom_rounded,
      'handyman': Icons.handyman_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'watch': Icons.watch_rounded,
      'spa': Icons.spa_rounded,
      'home': Icons.home_rounded,
      'child_care': Icons.child_care_rounded,
      'category': Icons.category_rounded,
      'local_dining': Icons.local_dining_rounded,
      'cake': Icons.cake_rounded,
      'local_cafe': Icons.local_cafe_rounded,
      'eco': Icons.eco_rounded,
      'woman': Icons.woman_rounded,
      'man': Icons.man_rounded,
      'child_friendly': Icons.child_friendly_rounded,
      'style': Icons.style_rounded,
      'brush': Icons.brush_rounded,
      'palette': Icons.palette_rounded,
      'carpenter': Icons.carpenter_rounded,
      'texture': Icons.texture_rounded,
      'face': Icons.face_rounded,
      'sanitizer': Icons.sanitizer_rounded,
      'air_freshener': Icons.air_rounded,
    };

    return iconMap[iconName] ?? Icons.category_rounded;
  }
}
