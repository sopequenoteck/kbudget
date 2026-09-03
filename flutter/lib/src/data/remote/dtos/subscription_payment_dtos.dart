// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/models/subscription_payment.dart';
import 'package:k_budget/src/domain/models/subscription_total_paid.dart';

part 'subscription_payment_dtos.freezed.dart';
part 'subscription_payment_dtos.g.dart';

@freezed
class SubscriptionPaymentResponse with _$SubscriptionPaymentResponse {
  const factory SubscriptionPaymentResponse({
    required String id,
    required double montant,
    required String date,
    String? subscriptionName,
    String? accountName,
  }) = _SubscriptionPaymentResponse;

  factory SubscriptionPaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPaymentResponseFromJson(json);
}

extension SubscriptionPaymentResponseMapper on SubscriptionPaymentResponse {
  SubscriptionPayment toDomain() {
    return SubscriptionPayment(
      id: id,
      montant: montant,
      date: DateTime.parse(date),
      subscriptionName: subscriptionName,
      accountName: accountName,
    );
  }
}

@freezed
class SubscriptionTotalPaidResponse with _$SubscriptionTotalPaidResponse {
  const factory SubscriptionTotalPaidResponse({
    required String subscriptionId,
    String? subscriptionName,
    required double totalPaid,
    required int paymentCount,
  }) = _SubscriptionTotalPaidResponse;

  factory SubscriptionTotalPaidResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTotalPaidResponseFromJson(json);
}

extension SubscriptionTotalPaidResponseMapper on SubscriptionTotalPaidResponse {
  SubscriptionTotalPaid toDomain() {
    return SubscriptionTotalPaid(
      subscriptionId: subscriptionId,
      subscriptionName: subscriptionName,
      totalPaid: totalPaid,
      paymentCount: paymentCount,
    );
  }
}
