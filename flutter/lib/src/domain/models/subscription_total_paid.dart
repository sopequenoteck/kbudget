// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_total_paid.freezed.dart';
part 'subscription_total_paid.g.dart';

@freezed
class SubscriptionTotalPaid with _$SubscriptionTotalPaid {
  const factory SubscriptionTotalPaid({
    required String subscriptionId,
    String? subscriptionName,
    required double totalPaid,
    required int paymentCount,
  }) = _SubscriptionTotalPaid;

  factory SubscriptionTotalPaid.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTotalPaidFromJson(json);
}
