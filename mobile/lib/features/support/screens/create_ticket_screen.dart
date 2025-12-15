import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/support_ticket_model.dart';
import '../../../data/providers/support_provider.dart';

/// Create new support ticket screen
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketType _selectedType = TicketType.general;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final ticket = await ref.read(supportTicketsProvider.notifier).createTicket(
          type: _selectedType,
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (ticket != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr('ticketCreated')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr('ticketCreateError')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRtl = context.isRtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('newTicket')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ticket type selection
            Text(
              l10n.tr('ticketType'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TicketType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(
                    isRtl ? type.labelAr : type.label,
                  ),
                  avatar: Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Subject
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: l10n.tr('subject'),
                hintText: l10n.tr('subjectHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 5) {
                  return l10n.tr('subjectRequired');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.tr('description'),
                hintText: l10n.tr('descriptionHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return l10n.tr('descriptionRequired');
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.tr('submitTicket'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
