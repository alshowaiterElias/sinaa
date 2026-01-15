import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/projects_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can access the project from the provider since it should be loaded
    final state = ref.watch(myProjectProvider);
    final project = state.project;
    final l10n = context.l10n;

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tr('project.statusPending')),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  project?.isRejected == true
                      ? Icons.cancel_outlined
                      : Icons.hourglass_empty_rounded,
                  size: 80,
                  color: project?.isRejected == true
                      ? AppColors.error
                      : AppColors.warning,
                ),
                const SizedBox(height: 24),
                Text(
                  project?.isRejected == true
                      ? l10n.tr('project.statusRejected')
                      : l10n.tr('project.statusPending'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  project?.isRejected == true
                      ? (project?.rejectionReason ?? '')
                      : l10n.tr('project.pendingMessage'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Allow editing even if pending/rejected
                    context.push(Routes.projectEdit);
                  },
                  child: Text(l10n.tr('project.editDetails')),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Go to home instead of back
                    context.go(Routes.home);
                  },
                  child: Text(l10n.tr('homeTitle')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
