// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/models/unbudgeted_item.dart';

part 'budget_overview.freezed.dart';
part 'budget_overview.g.dart';

@freezed
class BudgetOverview with _$BudgetOverview {
  const factory BudgetOverview({
    required String month,
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required String currency,
    required List<BudgetOverviewItem> items,
    @Default([]) List<UnbudgetedItem> unbudgetedItems,
    @Default(0) double unbudgetedTotal,
  }) = _BudgetOverview;

  factory BudgetOverview.fromJson(Map<String, dynamic> json) =>
      _$BudgetOverviewFromJson(json);
}

@freezed
class BudgetOverviewItem with _$BudgetOverviewItem {
  const factory BudgetOverviewItem({
    required String budgetId,
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantBudget,
    required double montantBudgetNormalise,
    required String currency,
    required double montantDepense,
    required double percentage,
    required String frequence,
  }) = _BudgetOverviewItem;

  factory BudgetOverviewItem.fromJson(Map<String, dynamic> json) =>
      _$BudgetOverviewItemFromJson(json);
}
