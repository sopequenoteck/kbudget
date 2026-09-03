// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';

part 'budget_list_state.freezed.dart';

@freezed
class BudgetListState with _$BudgetListState {
  const factory BudgetListState({
    @Default([]) List<Budget> items,
    @Default(false) bool isLoading,
    String? error,
    @Default(0) int currentPage,
    @Default(true) bool hasMore,
    @Default({}) Set<String> mutatingIds,
    BudgetOverview? overview,
    BudgetHistory? history,
  }) = _BudgetListState;
}
