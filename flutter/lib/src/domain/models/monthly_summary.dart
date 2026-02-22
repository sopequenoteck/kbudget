import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'monthly_summary.freezed.dart';
part 'monthly_summary.g.dart';

@freezed
class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required int month,
    required int year,
    required double totalRecettes,
    required double totalDepenses,
    required double solde,
    required Currency currency,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}
