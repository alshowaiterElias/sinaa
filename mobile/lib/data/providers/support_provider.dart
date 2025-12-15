import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_ticket_model.dart';
import '../repositories/support_repository.dart';

/// State for support tickets
class SupportTicketsState {
  final List<SupportTicket> tickets;
  final bool isLoading;
  final String? error;

  const SupportTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  SupportTicketsState copyWith({
    List<SupportTicket>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return SupportTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Support tickets notifier
class SupportTicketsNotifier extends Notifier<SupportTicketsState> {
  @override
  SupportTicketsState build() {
    return const SupportTicketsState();
  }

  SupportRepository get _repository => ref.read(supportRepositoryProvider);

  /// Load user's tickets
  Future<void> loadTickets({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tickets = await _repository.getMyTickets();
      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create new ticket
  Future<SupportTicket?> createTicket({
    required TicketType type,
    required String subject,
    required String description,
  }) async {
    try {
      final ticket = await _repository.createTicket(
        type: type,
        subject: subject,
        description: description,
      );

      // Add to list
      state = state.copyWith(
        tickets: [ticket, ...state.tickets],
      );

      return ticket;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

/// Provider for support tickets
final supportTicketsProvider =
    NotifierProvider<SupportTicketsNotifier, SupportTicketsState>(
  SupportTicketsNotifier.new,
);

/// Provider for single ticket detail
final ticketDetailProvider =
    FutureProvider.family<SupportTicket, int>((ref, id) async {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.getTicketById(id);
});
