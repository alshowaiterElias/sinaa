import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/projects_provider.dart';

class DisabledProjectScreen extends ConsumerWidget {
  const DisabledProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProjectProvider);
    final project = state.project;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Disabled'), // TODO: Localize
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 80,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Your project has been disabled', // TODO: Localize
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                project?.disableReason ?? 'No reason provided',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement contact support or similar
                },
                child: const Text('Contact Support'), // TODO: Localize
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Go back to profile or home
                  context.pop();
                },
                child: Text(l10n.tr('common.back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
