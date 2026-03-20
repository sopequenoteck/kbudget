import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_payment.freezed.dart';
part 'debt_payment.g.dart';

@freezed
class DebtPayment with _$DebtPayment {
  const factory DebtPayment({
    required String id,
    required double montant,
    required DateTime date,
    String? accountName,
  }) = _DebtPayment;

  factory DebtPayment.fromJson(Map<String, dynamic> json) =>
      _$DebtPaymentFromJson(json);
}
