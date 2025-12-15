import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/products_repository.dart';

/// Tags Input Widget - allows selecting tags for a product
class TagsInputWidget extends ConsumerStatefulWidget {
  final List<ProductTag> selectedTags;
  final Function(List<ProductTag>) onChanged;

  const TagsInputWidget({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  ConsumerState<TagsInputWidget> createState() => _TagsInputWidgetState();
}

class _TagsInputWidgetState extends ConsumerState<TagsInputWidget> {
  List<ProductTag> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final repository = ref.read(productsRepositoryProvider);
      final tags = await repository.getTags();
      setState(() {
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleTag(ProductTag tag) {
    final newTags = List<ProductTag>.from(widget.selectedTags);
    final index = newTags.indexWhere((t) => t.id == tag.id);
    if (index >= 0) {
      newTags.removeAt(index);
    } else {
      newTags.add(tag);
    }
    widget.onChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allTags.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isRtl ? 'لا توجد علامات متاحة' : 'No tags available',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allTags.map((tag) {
        final isSelected = widget.selectedTags.any((t) => t.id == tag.id);
        return FilterChip(
          label: Text(isRtl ? tag.nameAr : tag.name),
          selected: isSelected,
          onSelected: (_) => _toggleTag(tag),
          selectedColor: AppColors.primaryLight.withAlpha(77),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }
}
