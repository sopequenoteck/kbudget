import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/domain/repositories/transaction_repository.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_state.dart';

final transactionListNotifierProvider =
    NotifierProvider<TransactionListNotifier, TransactionListState>(
  TransactionListNotifier.new,
);

class TransactionListNotifier extends Notifier<TransactionListState> {
  TransactionRepository get _repo =>
      ref.read(transactionRepositoryProvider);

  @override
  TransactionListState build() {
    final now = DateTime.now();
    return TransactionListState(
      selectedMonth: now.month,
      selectedYear: now.year,
    );
  }

  Future<void> loadMonth(int month, int year) async {
    state = state.copyWith(
      selectedMonth: month,
      selectedYear: year,
      isLoading: true,
      error: null,
    );
    try {
      final transactions = await _repo.getByMonth(month, year);
      final summaries = await _repo.getMonthlySummary(month, year);

      // FR-016 : ignorer la réponse si le mois a changé entre-temps
      if (state.selectedMonth != month || state.selectedYear != year) return;

      final filtered = _applyFilter(transactions, state.activeFilter);
      state = state.copyWith(
        allMonthTransactions: transactions,
        filteredTransactions: filtered,
        summary: summaries.isNotEmpty ? summaries.first : null,
        isLoading: false,
      );
    } on Exception catch (e) {
      if (state.selectedMonth != month || state.selectedYear != year) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les transactions: $e',
      );
    }
  }

  void changeMonth(int month, int year) {
    loadMonth(month, year);
  }

  /// Rafraîchit le mois courant sans afficher de shimmer.
  /// En cas d'erreur, conserve les données existantes et rethrow
  /// pour que le caller (RefreshIndicator) puisse afficher un SnackBar.
  Future<void> refresh() async {
    final month = state.selectedMonth;
    final year = state.selectedYear;

    // Si aucune donnée n'est chargée, déléguer à loadMonth (affiche shimmer + error state)
    if (state.allMonthTransactions.isEmpty && state.summary == null) {
      return loadMonth(month, year);
    }

    try {
      final transactions = await _repo.getByMonth(month, year);
      final summaries = await _repo.getMonthlySummary(month, year);

      if (state.selectedMonth != month || state.selectedYear != year) return;

      final filtered = _applyFilter(transactions, state.activeFilter);
      state = state.copyWith(
        allMonthTransactions: transactions,
        filteredTransactions: filtered,
        summary: summaries.isNotEmpty ? summaries.first : null,
        error: null,
      );
    } on Exception {
      // Conserver les données existantes — rethrow pour SnackBar côté UI
      rethrow;
    }
  }

  void setFilter(TransactionTypeFilter filter) {
    final filtered = _applyFilter(state.allMonthTransactions, filter);
    state = state.copyWith(
      activeFilter: filter,
      filteredTransactions: filtered,
    );
  }

  List<Transaction> _applyFilter(
    List<Transaction> transactions,
    TransactionTypeFilter filter,
  ) {
    return switch (filter) {
      TransactionTypeFilter.all => transactions,
      TransactionTypeFilter.depense =>
        transactions.where((t) => t.type == TransactionType.depense).toList(),
      TransactionTypeFilter.recette =>
        transactions.where((t) => t.type == TransactionType.recette).toList(),
    };
  }
}
