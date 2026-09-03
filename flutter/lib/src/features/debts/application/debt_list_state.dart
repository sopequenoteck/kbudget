// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';

part 'debt_list_state.freezed.dart';

typedef DebtCurrencySummary = ({double totalEmprunts, double totalPrets});

@freezed
class DebtListState with _$DebtListState {
  const factory DebtListState({
    @Default([]) List<Debt> items,
    @Default(false) bool isLoading,
    String? error,
    @Default(DebtStatusFilter.all) DebtStatusFilter activeFilter,
    @Default({}) Map<Currency, DebtCurrencySummary> summary,
    @Default(0) int currentPage,
    @Default(true) bool hasMore,
    @Default({}) Set<String> mutatingIds,
  }) = _DebtListState;
}
