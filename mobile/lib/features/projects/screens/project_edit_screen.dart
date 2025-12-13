import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/projects_provider.dart';

class ProjectEditScreen extends ConsumerStatefulWidget {
  const ProjectEditScreen({super.key});

  @override
  ConsumerState<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends ConsumerState<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    final project = ref.read(myProjectProvider).project;
    _nameController = TextEditingController(text: project?.name);
    _nameArController = TextEditingController(text: project?.nameAr);
    _descriptionController = TextEditingController(text: project?.description);
    _descriptionArController =
        TextEditingController(text: project?.descriptionAr);
    _cityController = TextEditingController(text: project?.city);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(myProjectProvider.notifier).updateProject({
        'name': _nameController.text,
        'nameAr': _nameArController.text,
        'description': _descriptionController.text,
        'descriptionAr': _descriptionArController.text,
        'city': _cityController.text,
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.tr('project.updateSuccess'))),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(myProjectProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('project.editDetails')),
        actions: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info
            Text(
              l10n.tr('project.basicInfo'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.tr('project.nameEn'),
                prefixIcon: const Icon(Icons.store_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.tr('validation.required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameArController,
              decoration: InputDecoration(
                labelText: l10n.tr('project.nameAr'),
                prefixIcon: const Icon(Icons.store_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.tr('validation.required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),

            // Description
            Text(
              l10n.tr('project.description'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.tr('project.descriptionEn'),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionArController,
              decoration: InputDecoration(
                labelText: l10n.tr('project.descriptionAr'),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Additional Details
            Text(
              l10n.tr('project.additionalDetails'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.access_time,
              title: l10n.tr('project.workingHours'),
              subtitle: l10n.tr('project.workingHoursSubtitle'),
              onTap: () => context.push(Routes.projectWorkingHours),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.location_on,
              title: l10n.tr('project.location'),
              subtitle: _cityController.text.isNotEmpty
                  ? _cityController.text
                  : l10n.tr('project.locationSubtitle'),
              onTap: () async {
                final result = await context.push<Map<String, dynamic>>(
                  Routes.projectLocation,
                  extra: {
                    'latitude': ref.read(myProjectProvider).project?.latitude,
                    'longitude': ref.read(myProjectProvider).project?.longitude,
                  },
                );

                if (result != null && mounted) {
                  // Update project with new location
                  try {
                    await ref.read(myProjectProvider.notifier).updateProject({
                      'latitude': result['latitude'],
                      'longitude': result['longitude'],
                      'city': result['city'] ??
                          _cityController
                              .text, // Use returned city or keep existing
                    });

                    if (result['city'] != null) {
                      setState(() {
                        _cityController.text = result['city'];
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(l10n.tr('project.locationUpdated'))),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.link,
              title: l10n.tr('project.socialLinks'),
              subtitle: l10n.tr('project.socialLinksSubtitle'),
              onTap: () => context.push(Routes.projectSocialLinks),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
