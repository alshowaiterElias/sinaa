import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/project.dart';
import '../../../data/repositories/projects_repository.dart';
import '../providers/projects_refresh_provider.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _isLoading = false;
  Project? _project;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final project = await repository.getProjectById(widget.projectId);
      setState(() {
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    }
  }

  Future<void> _performAction(
      Future<Project> Function() action, String successMessage) async {
    setState(() => _isLoading = true);
    try {
      final updatedProject = await action();
      setState(() {
        _project = updatedProject;
        _isLoading = false;
        _hasChanges = true;
      });
      ref.read(projectsRefreshProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _approveProject() async {
    if (_project == null) return;
    await _performAction(
      () => ref.read(projectsRepositoryProvider).approveProject(_project!.id),
      'Project approved successfully',
    );
  }

  Future<void> _disableProject() async {
    if (_project == null) return;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Are you sure you want to disable this project? It will be hidden from users.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Disable Reason',
                hintText: 'Enter reason for disabling...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Disable', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await _performAction(
        () => ref
            .read(projectsRepositoryProvider)
            .disableProject(_project!.id, reason),
        'Project disabled successfully',
      );
    }
  }

  Future<void> _enableProject() async {
    if (_project == null) return;
    await _performAction(
      () => ref.read(projectsRepositoryProvider).enableProject(_project!.id),
      'Project enabled successfully',
    );
  }

  Future<void> _rejectProject() async {
    if (_project == null) return;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Project'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await _performAction(
        () => ref.read(projectsRepositoryProvider).rejectProject(
              _project!.id,
              reason,
            ),
        'Project rejected successfully',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          context.pop(true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(_hasChanges),
          ),
        ),
        body: _isLoading && _project == null
            ? const Center(child: CircularProgressIndicator())
            : _project == null
                ? const Center(child: Text('Project not found'))
                : _buildContent(),
        bottomNavigationBar: _project != null ? _buildBottomBar() : null,
      ),
    );
  }

  Widget _buildContent() {
    final project = _project!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(project),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildInfoCard(project)),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildOwnerCard(project)),
            ],
          ),
          const SizedBox(height: 16),
          _buildAdditionalInfoCard(project),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Project project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            if (project.logoUrl != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(project.logoUrl!),
              )
            else
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.store, size: 40),
              ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    project.nameAr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(project.status),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Created: ${DateFormat('MMM d, y').format(project.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${project.averageRating} (${project.totalReviews} reviews)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Project project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Description (English)'),
            Text(project.description ?? 'No description'),
            const SizedBox(height: 16),
            _buildSectionTitle('Description (Arabic)'),
            Text(project.descriptionAr ?? 'No Arabic description'),
            const SizedBox(height: 16),
            _buildSectionTitle('Location'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on),
              title: Text(project.city),
              subtitle: project.latitude != null
                  ? Text('${project.latitude}, ${project.longitude}')
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(Project project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Owner Information'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: project.owner?.avatarUrl != null
                    ? NetworkImage(project.owner!.avatarUrl!)
                    : null,
                child: project.owner?.avatarUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(project.owner?.fullName ?? 'Unknown'),
              subtitle: Text(project.owner?.email ?? ''),
            ),
            if (project.owner?.phone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone),
                title: Text(project.owner!.phone!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(Project project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Working Hours'),
                  if (project.workingHours != null)
                    ...project.workingHours!.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              Text(e.value.toString()),
                            ],
                          ),
                        ))
                  else
                    const Text('Not specified'),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Social Links'),
                  if (project.socialLinks != null)
                    Wrap(
                      spacing: 8,
                      children: project.socialLinks!.entries.map((e) {
                        return Chip(
                          avatar: _getSocialIcon(e.key),
                          label: Text(e.key),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    )
                  else
                    const Text('Not specified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final project = _project!;
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (project.status == ProjectStatus.pending) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _rejectProject,
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _approveProject,
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (project.status == ProjectStatus.approved) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _disableProject,
                icon: const Icon(Icons.block),
                label: const Text('Disable Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (project.status == ProjectStatus.disabled) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _enableProject,
                icon: const Icon(Icons.restore),
                label: const Text('Enable Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    Color color;
    switch (status) {
      case ProjectStatus.approved:
        color = Colors.green;
        break;
      case ProjectStatus.pending:
        color = Colors.orange;
        break;
      case ProjectStatus.rejected:
        color = Colors.red;
        break;
      case ProjectStatus.disabled:
        color = Colors.grey;
        break;
    }
    return Chip(
      label: Text(
        status.label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Icon _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Icon(Icons.facebook, size: 16);
      case 'twitter':
      case 'x':
        return const Icon(Icons.alternate_email, size: 16);
      case 'instagram':
        return const Icon(Icons.camera_alt, size: 16);
      case 'website':
        return const Icon(Icons.language, size: 16);
      default:
        return const Icon(Icons.link, size: 16);
    }
  }
}
