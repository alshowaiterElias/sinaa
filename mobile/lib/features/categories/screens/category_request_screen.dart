import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../core/localization/app_localizations.dart';

class CategoryRequestScreen extends ConsumerStatefulWidget {
  const CategoryRequestScreen({super.key});

  @override
  ConsumerState<CategoryRequestScreen> createState() =>
      _CategoryRequestScreenState();
}

class _CategoryRequestScreenState extends ConsumerState<CategoryRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _iconController = TextEditingController();
  Category? _selectedParent;
  bool _isLoading = false;
  List<Category> _myRequests = [];
  bool _isLoadingRequests = false;
  List<Category> _parentCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _loadMyRequests();
    _loadParentCategories();
  }

  Future<void> _loadMyRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests =
          await ref.read(categoriesRepositoryProvider).getMyRequests();
      if (mounted) {
        setState(() {
          _myRequests = requests;
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _loadParentCategories() async {
    try {
      final categories =
          await ref.read(categoriesRepositoryProvider).getParentCategories();
      if (mounted) {
        setState(() => _parentCategories = categories);
      }
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(categoriesRepositoryProvider).requestCategory(
            name: _nameController.text,
            nameAr: _nameArController.text,
            icon: _iconController.text.isNotEmpty ? _iconController.text : null,
            parentId: _selectedParent?.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('categoryRequestSubmitted')),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _nameArController.clear();
        _iconController.clear();
        setState(() => _selectedParent = null);
        _tabController.animateTo(1); // Switch to My Requests tab
        _loadMyRequests(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${context.l10n.tr('error')}: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tr('categoryRequests')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.tr('newRequest')),
            Tab(text: context.l10n.tr('myRequests')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestForm(),
          _buildMyRequestsList(),
        ],
      ),
    );
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.tr('requestNewCategory'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.tr('categoryRequestNote'),
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.tr('categoryNameEn'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.tr('enterEnglishName');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameArController,
              decoration: InputDecoration(
                labelText: context.l10n.tr('categoryNameAr'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.translate),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.tr('enterArabicName');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Category>(
              value: _selectedParent,
              decoration: InputDecoration(
                labelText: context.l10n.tr('parentCategoryOptional'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_open),
              ),
              items: [
                DropdownMenuItem<Category>(
                  value: null,
                  child: Text(context.l10n.tr('noneMainCategory')),
                ),
                ..._parentCategories.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.nameAr),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedParent = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: InputDecoration(
                labelText: context.l10n.tr('iconNameOptional'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
                hintText: context.l10n.tr('iconHint'),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.tr('submitRequest')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsList() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              context.l10n.tr('noRequestsYet'),
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: Text(context.l10n.tr('makeRequest')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final category = _myRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(
                          Icons
                              .category, // Replace with actual icon if available
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.nameAr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(category.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.yMMMd().format(category.createdAt),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (category.parent != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.folder_open,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          category.parent!.nameAr,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  if (category.status == 'rejected' &&
                      category.rejectionReason != null) ...[
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${context.l10n.tr('rejectionReason')}: ${category.rejectionReason}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = context.l10n.tr('approved');
        break;
      case 'rejected':
        color = Colors.red;
        text = context.l10n.tr('rejected');
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = context.l10n.tr('pending');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
