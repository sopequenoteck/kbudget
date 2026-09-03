// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
