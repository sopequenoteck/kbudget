import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String categoryId,
    required double montant,
    required Frequency frequence,
    @Default(Currency.eur) Currency currency,
    @Default(80) int seuilNotification,
    @Default(true) bool actif,
    String? categoryNom,
    String? categoryIcone,
    String? categoryCouleur,
    double? spent,
    DateTime? updatedAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}
