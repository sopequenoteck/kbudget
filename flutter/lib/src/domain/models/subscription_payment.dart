import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_payment.freezed.dart';
part 'subscription_payment.g.dart';

@freezed
class SubscriptionPayment with _$SubscriptionPayment {
  const factory SubscriptionPayment({
    required String id,
    required double montant,
    required DateTime date,
    String? subscriptionName,
    String? accountName,
  }) = _SubscriptionPayment;

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPaymentFromJson(json);
}
