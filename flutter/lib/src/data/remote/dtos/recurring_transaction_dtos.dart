import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';

part 'recurring_transaction_dtos.freezed.dart';
part 'recurring_transaction_dtos.g.dart';

@freezed
class RecurringTransactionResponse with _$RecurringTransactionResponse {
  const factory RecurringTransactionResponse({
    required String id,
    required double montant,
    required String libelle,
    required String type,
    required String frequency,
    required String nextOccurrence,
    required bool recurringActive,
    RecurringCategoryResponse? category,
    RecurringAccountSummary? account,
  }) = _RecurringTransactionResponse;

  factory RecurringTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionResponseFromJson(json);
}

extension RecurringTransactionResponseMapper on RecurringTransactionResponse {
  RecurringTransaction toDomain() {
    return RecurringTransaction(
      id: id,
      montant: montant,
      libelle: libelle,
      type: TransactionType.values.firstWhere(
        (e) => e.name.toUpperCase() == type.toUpperCase(),
        orElse: () => TransactionType.depense,
      ),
      frequency: Frequency.values.firstWhere(
        (e) => e.name.toUpperCase() == frequency.toUpperCase(),
        orElse: () => Frequency.mensuel,
      ),
      nextOccurrence: DateTime.parse(nextOccurrence),
      recurringActive: recurringActive,
      categoryName: category?.nom,
      categoryIcon: category?.icone,
      categoryColor: category?.couleur,
      accountName: account?.nom,
      accountCurrency: account?.currency != null
          ? Currency.values.firstWhere(
              (e) => e.name.toUpperCase() == account!.currency!.toUpperCase(),
              orElse: () => Currency.eur,
            )
          : null,
    );
  }
}

@freezed
class RecurringCategoryResponse with _$RecurringCategoryResponse {
  const factory RecurringCategoryResponse({
    required String id,
    required String nom,
    required String icone,
    required String couleur,
    required bool isSystem,
  }) = _RecurringCategoryResponse;

  factory RecurringCategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$RecurringCategoryResponseFromJson(json);
}

@freezed
class RecurringAccountSummary with _$RecurringAccountSummary {
  const factory RecurringAccountSummary({
    required String id,
    String? nom,
    String? currency,
  }) = _RecurringAccountSummary;

  factory RecurringAccountSummary.fromJson(Map<String, dynamic> json) =>
      _$RecurringAccountSummaryFromJson(json);
}
