import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_ticket.dart';
import '../repositories/tickets_repository.dart';

/// State for tickets list
class TicketsState {
  final List<SupportTicket> tickets;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final int totalPages;
  final String statusFilter;
  final String typeFilter;
  final String searchQuery;

  const TicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.statusFilter = 'all',
    this.typeFilter = 'all',
    this.searchQuery = '',
  });

  TicketsState copyWith({
    List<SupportTicket>? tickets,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    int? totalPages,
    String? statusFilter,
    String? typeFilter,
    String? searchQuery,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Tickets notifier
class TicketsNotifier extends Notifier<TicketsState> {
  @override
  TicketsState build() {
    return const TicketsState();
  }

  TicketsRepository get _repository => ref.read(ticketsRepositoryProvider);

  /// Load tickets
  Future<void> loadTickets({int page = 1, bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null, page: page);

    try {
      final response = await _repository.getTickets(
        page: page,
        status: state.statusFilter,
        type: state.typeFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      state = state.copyWith(
        tickets: response.tickets,
        isLoading: false,
        total: response.total,
        totalPages: response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set status filter
  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadTickets();
  }

  /// Set type filter
  void setTypeFilter(String type) {
    state = state.copyWith(typeFilter: type);
    loadTickets();
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTickets();
  }

  /// Update ticket status
  Future<bool> updateStatus(int ticketId, String status) async {
    try {
      final updated = await _repository.updateTicketStatus(ticketId, status);

      final tickets = state.tickets.map((t) {
        return t.id == ticketId ? updated : t;
      }).toList();

      state = state.copyWith(tickets: tickets);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Assign ticket to self
  Future<bool> assignToMe(int ticketId) async {
    try {
      final updated = await _repository.assignTicket(ticketId);

      final tickets = state.tickets.map((t) {
        return t.id == ticketId ? updated : t;
      }).toList();

      state = state.copyWith(tickets: tickets);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Resolve ticket
  Future<bool> resolveTicket(int ticketId, String resolution) async {
    try {
      final updated = await _repository.resolveTicket(ticketId, resolution);

      final tickets = state.tickets.map((t) {
        return t.id == ticketId ? updated : t;
      }).toList();

      state = state.copyWith(tickets: tickets);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for tickets
final ticketsProvider = NotifierProvider<TicketsNotifier, TicketsState>(
  TicketsNotifier.new,
);

/// Provider for single ticket detail
final ticketDetailProvider =
    FutureProvider.family<SupportTicket, int>((ref, id) async {
  final repository = ref.watch(ticketsRepositoryProvider);
  return repository.getTicketById(id);
});
