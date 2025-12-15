import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';

/// Variants Editor Widget - allows adding/editing product variants
class VariantsEditorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> variants;
  final Function(List<Map<String, dynamic>>) onChanged;

  const VariantsEditorWidget({
    super.key,
    required this.variants,
    required this.onChanged,
  });

  @override
  State<VariantsEditorWidget> createState() => _VariantsEditorWidgetState();
}

class _VariantsEditorWidgetState extends State<VariantsEditorWidget> {
  void _addVariant() {
    final newVariants = List<Map<String, dynamic>>.from(widget.variants);
    newVariants.add({
      'name': '',
      'nameAr': '',
      'priceModifier': 0.0,
      'quantity': 0,
      'isAvailable': true,
    });
    widget.onChanged(newVariants);
  }

  void _removeVariant(int index) {
    final newVariants = List<Map<String, dynamic>>.from(widget.variants);
    newVariants.removeAt(index);
    widget.onChanged(newVariants);
  }

  void _updateVariant(int index, String field, dynamic value) {
    final newVariants = List<Map<String, dynamic>>.from(widget.variants);
    newVariants[index] = Map<String, dynamic>.from(newVariants[index]);
    newVariants[index][field] = value;
    widget.onChanged(newVariants);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'لا توجد متغيرات' : 'No variants added',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRtl
                            ? 'أضف متغيرات مثل الحجم أو اللون'
                            : 'Add variants like size or color',
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
          )
        else
          ...widget.variants.asMap().entries.map((entry) {
            return _buildVariantCard(entry.key, entry.value, isRtl);
          }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addVariant,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(isRtl ? 'إضافة متغير جديد' : 'Add New Variant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(
      int index, Map<String, dynamic> variant, bool isRtl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with variant number and delete button
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withAlpha(51),
                      AppColors.accent.withAlpha(26),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isRtl ? 'متغير' : 'Variant'} ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              // Availability toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRtl ? 'متاح' : 'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: variant['isAvailable'] ?? true,
                    onChanged: (value) =>
                        _updateVariant(index, 'isAvailable', value),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: AppColors.success,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: AppColors.error, size: 22),
                onPressed: () => _removeVariant(index),
                visualDensity: VisualDensity.compact,
                tooltip: isRtl ? 'حذف' : 'Delete',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name (English)
          _buildTextField(
            initialValue: variant['name'] ?? '',
            label: isRtl ? 'اسم المتغير (English)' : 'Variant Name (English)',
            hint: isRtl ? 'مثال: كبير، أحمر' : 'e.g. Large, Red',
            icon: Icons.label_outline,
            onChanged: (value) => _updateVariant(index, 'name', value),
          ),
          const SizedBox(height: 12),

          // Name (Arabic)
          _buildTextField(
            initialValue: variant['nameAr'] ?? '',
            label: isRtl ? 'اسم المتغير (عربي)' : 'Variant Name (Arabic)',
            hint: isRtl ? 'مثال: كبير، أحمر' : 'e.g. كبير، أحمر',
            icon: Icons.translate,
            onChanged: (value) => _updateVariant(index, 'nameAr', value),
          ),
          const SizedBox(height: 12),

          // Price modifier and quantity in a row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  initialValue: (variant['priceModifier'] ?? 0).toString(),
                  label: isRtl ? 'فرق السعر (SAR)' : 'Price +/- (SAR)',
                  hint: '0',
                  icon: Icons.add_circle_outline,
                  keyboardType: TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  onChanged: (value) => _updateVariant(
                      index, 'priceModifier', double.tryParse(value) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  initialValue: (variant['quantity'] ?? 0).toString(),
                  label: isRtl ? 'الكمية' : 'Stock Qty',
                  hint: '0',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateVariant(
                      index, 'quantity', int.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant.withAlpha(77),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }
}
