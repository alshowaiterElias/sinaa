import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/projects_provider.dart';

class SocialLinksEditor extends ConsumerStatefulWidget {
  final Map<String, String>? initialValue;
  final bool isSelectionMode;

  const SocialLinksEditor({
    super.key,
    this.initialValue,
    this.isSelectionMode = false,
  });

  @override
  ConsumerState<SocialLinksEditor> createState() => _SocialLinksEditorState();
}

class _SocialLinksEditorState extends ConsumerState<SocialLinksEditor> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _hasChanges = false;

  final List<String> _platforms = [
    'website',
    'facebook',
    'twitter',
    'instagram',
    'linkedin',
    'whatsapp',
  ];

  @override
  void initState() {
    super.initState();
    final socialLinks = widget.initialValue ??
        ref.read(myProjectProvider).project?.socialLinks ??
        {};

    _controllers = {};
    for (final platform in _platforms) {
      _controllers[platform] = TextEditingController(
        text: socialLinks[platform]?.toString() ?? '',
      );
      _controllers[platform]!.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final socialLinks = <String, String>{};
    for (final entry in _controllers.entries) {
      if (entry.value.text.isNotEmpty) {
        socialLinks[entry.key] = entry.value.text;
      }
    }

    if (widget.isSelectionMode) {
      navigator.pop(socialLinks);
      return;
    }

    try {
      await ref.read(myProjectProvider.notifier).updateProject({
        'socialLinks': socialLinks,
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

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'website':
        return Icons.language;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email; // Placeholder for X
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.business;
      case 'whatsapp':
        return Icons.chat;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(myProjectProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('project.socialLinks')),
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
              onPressed: _hasChanges ? _save : null,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _platforms.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final platform = _platforms[index];
            return TextFormField(
              controller: _controllers[platform],
              decoration: InputDecoration(
                labelText: l10n.tr('social.$platform'),
                prefixIcon: Icon(_getPlatformIcon(platform)),
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            );
          },
        ),
      ),
    );
  }
}
