import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/routes.dart';
import '../../../data/models/project.dart';
import '../../../data/repositories/projects_repository.dart';
import '../providers/projects_refresh_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  int _currentPage = 1;
  bool _isLoading = false;
  List<Project> _projects = [];
  String _currentStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
        switch (_tabController.index) {
          case 0:
            _currentStatus = 'all';
            break;
          case 1:
            _currentStatus = 'pending';
            break;
          case 2:
            _currentStatus = 'approved';
            break;
          case 3:
            _currentStatus = 'rejected';
            break;
        }
      });
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getProjects(
        page: _currentPage,
        status: _currentStatus,
        search: _searchController.text,
      );
      setState(() {
        _projects = response.projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectsRefreshProvider, (previous, next) {
      if (previous != next) {
        _loadProjects();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadProjects();
                  },
                ),
              ),
              onSubmitted: (_) => _loadProjects(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? const Center(child: Text('No projects found'))
                    : SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: PaginatedDataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Owner')),
                              DataColumn(label: Text('City')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Actions')),
                            ],
                            source: _ProjectsDataSource(
                              _projects,
                              (id) async {
                                final result = await context
                                    .push('${AdminRoutes.projects}/$id');
                                if (result == true) {
                                  _loadProjects();
                                }
                              },
                            ),
                            rowsPerPage: 10,
                            showCheckboxColumn: false,
                            onPageChanged: (page) {
                              // Calculate new page index (1-based)
                              final newPage = (page ~/ 10) + 1;
                              if (newPage != _currentPage) {
                                setState(() => _currentPage = newPage);
                                _loadProjects();
                              }
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsDataSource extends DataTableSource {
  final List<Project> _projects;
  final Function(int) _onView;

  _ProjectsDataSource(this._projects, this._onView);

  @override
  DataRow? getRow(int index) {
    if (index >= _projects.length) return null;
    final project = _projects[index];
    return DataRow(
      cells: [
        DataCell(Text('#${project.id}')),
        DataCell(Text(project.name)),
        DataCell(Text(project.owner?.fullName ?? 'Unknown')),
        DataCell(Text(project.city)),
        DataCell(_buildStatusChip(project.status)),
        DataCell(Text(DateFormat('MMM d, y').format(project.createdAt))),
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => _onView(project.id),
          ),
        ),
      ],
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
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _projects.length;

  @override
  int get selectedRowCount => 0;
}
