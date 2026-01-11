import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/projects_provider.dart';
import '../widgets/project_card.dart';

class MyProjectScreen extends ConsumerStatefulWidget {
  const MyProjectScreen({super.key});

  @override
  ConsumerState<MyProjectScreen> createState() => _MyProjectScreenState();
}

class _MyProjectScreenState extends ConsumerState<MyProjectScreen> {
  @override
  void initState() {
    super.initState();
    // Load my project when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProjectProvider.notifier).loadMyProject();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myProjectProvider, (previous, next) {
      if (next.project != null) {
        if (next.project!.isDisabled) {
          context.pushReplacement(Routes.projectDisabled);
        } else if (!next.project!.isApproved) {
          context.pushReplacement(Routes.pendingApproval);
        }
      }
    });

    final state = ref.watch(myProjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile.myProject')), // Ensure key exists
        actions: [
          if (state.project != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit screen
                context.push(Routes.projectEdit);
              },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(myProjectProvider.notifier).loadMyProject(),
                    child: Text(context.tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state.project == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 80,
                      color: AppColors.primary.withAlpha(128),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('project.noProjectTitle'), // TODO: Add key
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('project.noProjectSubtitle'), // TODO: Add key
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to create project
                        // context.push('/projects/create');
                      },
                      child: Text(
                          context.tr('project.createProject')), // TODO: Add key
                    ),
                  ],
                ),
              ),
            );
          }

          final project = state.project!;

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(myProjectProvider.notifier).loadMyProject(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  if (!project.isApproved)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: project.isRejected
                            ? AppColors.errorLight
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: project.isRejected
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                project.isRejected
                                    ? Icons.cancel
                                    : Icons.hourglass_empty,
                                color: project.isRejected
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                project.isRejected
                                    ? context.tr('project.statusRejected')
                                    : context.tr('project.statusPending'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: project.isRejected
                                          ? AppColors.error
                                          : AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          if (project.rejectionReason != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              project.rejectionReason!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Project Card Preview
                  Text(
                    context.tr('project.preview'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ProjectCard(
                    project: project,
                    onTap: () {
                      // Navigate to details
                      // context.push('/projects/${project.id}');
                    },
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    context.tr('project.actions'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _ActionCard(
                        icon: Icons.edit,
                        title: context.tr('project.editDetails'),
                        onTap: () {
                          context.push(Routes.projectEdit);
                        },
                      ),
                      _ActionCard(
                        icon: Icons.inventory_2,
                        title: context.tr('project.manageProducts'),
                        onTap: () {
                          // Navigate to products management
                          context.push(
                            Routes.projectProducts.replaceFirst(
                              ':projectId',
                              project.id.toString(),
                            ),
                            extra: {'isOwner': true},
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
