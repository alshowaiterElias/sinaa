import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

/// State class for transactions
class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final TransactionStatus? statusFilter;

  TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.statusFilter,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    TransactionStatus? statusFilter,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

/// Notifier for transactions state management
class TransactionsNotifier extends Notifier<TransactionsState> {
  @override
  TransactionsState build() {
    return TransactionsState();
  }

  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);

  /// Load transactions
  Future<void> loadTransactions({bool refresh = false, int? page}) async {
    if (state.isLoading) return;

    final targetPage = page ?? (refresh ? 1 : state.currentPage);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await _repository.getTransactions(
        status: state.statusFilter,
        page: targetPage,
      );

      state = state.copyWith(
        transactions: refresh || targetPage == 1
            ? response.transactions
            : [...state.transactions, ...response.transactions],
        isLoading: false,
        currentPage: response.page,
        totalPages: response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set status filter
  void setStatusFilter(TransactionStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearFilter: status == null,
    );
    loadTransactions(refresh: true);
  }

  /// Confirm transaction
  Future<bool> confirmTransaction(int transactionId) async {
    try {
      final updated = await _repository.confirmTransaction(transactionId);

      // Update in list
      final index = state.transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        final updatedList = List<Transaction>.from(state.transactions);
        updatedList[index] = updated;
        state = state.copyWith(transactions: updatedList);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Deny transaction
  Future<bool> denyTransaction(int transactionId) async {
    try {
      await _repository.denyTransaction(transactionId);
      // Refresh to get updated data
      await loadTransactions(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Cancel transaction
  Future<bool> cancelTransaction(int transactionId) async {
    try {
      await _repository.cancelTransaction(transactionId);

      // Remove from list
      state = state.copyWith(
        transactions:
            state.transactions.where((t) => t.id != transactionId).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Open dispute
  Future<bool> openDispute({
    required int transactionId,
    required String reason,
    required String description,
  }) async {
    try {
      await _repository.openDispute(
        transactionId: transactionId,
        reason: reason,
        description: description,
      );

      // Refresh to get updated status
      await loadTransactions(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Initiate transaction
  Future<Transaction?> initiateTransaction({
    required int conversationId,
    int? productId,
  }) async {
    try {
      final transaction = await _repository.initiateTransaction(
        conversationId: conversationId,
        productId: productId,
      );

      // Add to beginning of list
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
      );

      return transaction;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

/// Provider for transactions
final transactionsProvider =
    NotifierProvider<TransactionsNotifier, TransactionsState>(() {
  return TransactionsNotifier();
});

/// Provider for single transaction detail
final transactionDetailProvider =
    FutureProvider.family<Transaction?, int>((ref, id) async {
  final repository = ref.watch(transactionRepositoryProvider);
  try {
    return await repository.getTransactionById(id);
  } catch (e) {
    return null;
  }
});

/// Provider for pending transactions count
final pendingTransactionsCountProvider = Provider<int>((ref) {
  final state = ref.watch(transactionsProvider);
  return state.transactions.where((t) => t.isPending).length;
});
