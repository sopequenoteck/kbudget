import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

part 'transaction_list_state.freezed.dart';

enum TransactionTypeFilter { all, depense, recette }

@freezed
class TransactionListState with _$TransactionListState {
  const factory TransactionListState({
    @Default([]) List<Transaction> allMonthTransactions,
    @Default([]) List<Transaction> filteredTransactions,
    @Default(TransactionTypeFilter.all) TransactionTypeFilter activeFilter,
    required int selectedMonth,
    required int selectedYear,
    MonthlySummary? summary,
    @Default(true) bool isLoading,
    String? error,
  }) = _TransactionListState;
}
