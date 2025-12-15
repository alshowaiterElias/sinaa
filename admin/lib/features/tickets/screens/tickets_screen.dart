import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../data/models/support_ticket.dart';
import '../../../data/providers/tickets_provider.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ticketsProvider.notifier).loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تذاكر الدعم الفني',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                onPressed: () => ref
                    .read(ticketsProvider.notifier)
                    .loadTickets(refresh: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          _buildFilters(state),
          const SizedBox(height: 16),

          // Data Table
          Expanded(
            child: state.isLoading && state.tickets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(ticketsProvider.notifier)
                                  .loadTickets(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : state.tickets.isEmpty
                        ? const Center(child: Text('لا توجد تذاكر'))
                        : _buildDataTable(state),
          ),

          // Pagination
          if (state.totalPages > 1) _buildPagination(state),
        ],
      ),
    );
  }

  Widget _buildFilters(TicketsState state) {
    return Row(
      children: [
        // Search
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (value) {
              ref.read(ticketsProvider.notifier).setSearchQuery(value);
            },
          ),
        ),
        const SizedBox(width: 16),

        // Status filter
        Expanded(
          child: DropdownButtonFormField<String>(
            value: state.statusFilter,
            decoration: InputDecoration(
              labelText: 'الحالة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('الكل')),
              DropdownMenuItem(value: 'open', child: Text('مفتوح')),
              DropdownMenuItem(
                  value: 'in_progress', child: Text('قيد المعالجة')),
              DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
              DropdownMenuItem(value: 'closed', child: Text('مغلق')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(ticketsProvider.notifier).setStatusFilter(value);
              }
            },
          ),
        ),
        const SizedBox(width: 16),

        // Type filter
        Expanded(
          child: DropdownButtonFormField<String>(
            value: state.typeFilter,
            decoration: InputDecoration(
              labelText: 'النوع',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('الكل')),
              DropdownMenuItem(value: 'general', child: Text('عام')),
              DropdownMenuItem(value: 'dispute', child: Text('نزاع')),
              DropdownMenuItem(value: 'report', child: Text('بلاغ')),
              DropdownMenuItem(value: 'feedback', child: Text('اقتراح')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(ticketsProvider.notifier).setTypeFilter(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(TicketsState state) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('الموضوع')),
            DataColumn(label: Text('المستخدم')),
            DataColumn(label: Text('النوع')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('المسند إليه')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('الإجراءات')),
          ],
          rows: state.tickets.map((ticket) {
            return DataRow(
              cells: [
                DataCell(Text('#${ticket.id}')),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      ticket.subject,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(ticket.user?.fullName ?? '-')),
                DataCell(_buildTypeBadge(ticket.type)),
                DataCell(_buildStatusBadge(ticket.status)),
                DataCell(Text(ticket.assignee?.fullName ?? 'غير مسند')),
                DataCell(
                    Text(DateFormat('yyyy/MM/dd').format(ticket.createdAt))),
                DataCell(_buildActions(ticket)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TicketType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.labelAr,
        style: TextStyle(
          color: type.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TicketStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActions(SupportTicket ticket) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          tooltip: 'عرض التفاصيل',
          onPressed: () => _showTicketDetails(ticket),
        ),
        if (ticket.assignedTo == null)
          IconButton(
            icon: const Icon(Icons.person_add, size: 20),
            tooltip: 'استلام التذكرة',
            onPressed: () async {
              final success = await ref
                  .read(ticketsProvider.notifier)
                  .assignToMe(ticket.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم استلام التذكرة')),
                );
              }
            },
          ),
        if (ticket.isOpen)
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            tooltip: 'حل التذكرة',
            onPressed: () => _showResolveDialog(ticket),
          ),
      ],
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تذكرة #${ticket.id}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('الموضوع', ticket.subject),
              _detailRow('النوع', ticket.type.labelAr),
              _detailRow('الحالة', ticket.status.labelAr),
              _detailRow('المستخدم', ticket.user?.fullName ?? '-'),
              _detailRow('البريد', ticket.user?.email ?? '-'),
              const Divider(),
              const Text('الوصف:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(ticket.description),
              if (ticket.resolution != null) ...[
                const Divider(),
                const Text('الحل:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(ticket.resolution!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showResolveDialog(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ResolveTicketDialog(
        ticket: ticket,
        onResolve: (resolution) async {
          final success = await ref
              .read(ticketsProvider.notifier)
              .resolveTicket(ticket.id, resolution);

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حل التذكرة')),
            );
          }
        },
      ),
    );
  }

  Widget _buildPagination(TicketsState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.page > 1
                ? () => ref
                    .read(ticketsProvider.notifier)
                    .loadTickets(page: state.page - 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          Text('${state.page} / ${state.totalPages}'),
          IconButton(
            onPressed: state.page < state.totalPages
                ? () => ref
                    .read(ticketsProvider.notifier)
                    .loadTickets(page: state.page + 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }
}

class _ResolveTicketDialog extends StatefulWidget {
  final SupportTicket ticket;
  final Function(String) onResolve;

  const _ResolveTicketDialog({
    required this.ticket,
    required this.onResolve,
  });

  @override
  State<_ResolveTicketDialog> createState() => _ResolveTicketDialogState();
}

class _ResolveTicketDialogState extends State<_ResolveTicketDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حل التذكرة'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'ملاحظات الحل',
          hintText: 'اكتب تفاصيل الحل...',
          border: OutlineInputBorder(),
        ),
        enabled: !_isSubmitting,
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_controller.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('الرجاء كتابة الحل (10 أحرف على الأقل)')),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);

                  // Close dialog first
                  Navigator.pop(context);

                  // Then execute action
                  await widget.onResolve(_controller.text.trim());
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حل'),
        ),
      ],
    );
  }
}
