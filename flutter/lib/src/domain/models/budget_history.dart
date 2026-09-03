// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/models/unbudgeted_item.dart';

part 'budget_history.freezed.dart';
part 'budget_history.g.dart';

@freezed
class BudgetHistory with _$BudgetHistory {
  const factory BudgetHistory({
    required String month,
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required String currency,
    required List<BudgetHistoryItem> items,
    @Default([]) List<UnbudgetedItem> unbudgetedItems,
    @Default(0) double unbudgetedTotal,
  }) = _BudgetHistory;

  factory BudgetHistory.fromJson(Map<String, dynamic> json) =>
      _$BudgetHistoryFromJson(json);
}

@freezed
class BudgetHistoryItem with _$BudgetHistoryItem {
  const factory BudgetHistoryItem({
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantBudget,
    required String currency,
    double? tauxChange,
    required double montantDepense,
    required double percentage,
    DateTime? createdAt,
  }) = _BudgetHistoryItem;

  factory BudgetHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$BudgetHistoryItemFromJson(json);
}
