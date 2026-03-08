import 'package:freezed_annotation/freezed_annotation.dart';

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
