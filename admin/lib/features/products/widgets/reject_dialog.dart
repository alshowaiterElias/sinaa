import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Reusable dialog for rejection/disable reasons
class RejectDialog extends StatefulWidget {
  final String title;
  final String itemName;
  final String reasonLabel;
  final String confirmLabel;

  const RejectDialog({
    super.key,
    required this.title,
    required this.itemName,
    this.reasonLabel = 'سبب الرفض',
    this.confirmLabel = 'رفض',
  });

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المنتج: ${widget.itemName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: widget.reasonLabel,
                hintText: 'أدخل السبب...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال السبب';
                }
                if (value.trim().length < 5) {
                  return 'السبب قصير جداً';
                }
                return null;
              },
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.error,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _reasonController.text.trim());
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
