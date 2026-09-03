// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
    @Default(false) bool isLoading,
    String? error,
  }) = _TransactionListState;
}
