import 'package:freezed_annotation/freezed_annotation.dart';

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
