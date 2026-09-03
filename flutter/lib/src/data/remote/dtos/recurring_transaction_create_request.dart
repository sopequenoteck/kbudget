// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_transaction_create_request.freezed.dart';
part 'recurring_transaction_create_request.g.dart';

@freezed
class RecurringTransactionCreateRequest with _$RecurringTransactionCreateRequest {
  const factory RecurringTransactionCreateRequest({
    required double montant,
    required String libelle,
    required String type,
    required String frequency,
    required String nextOccurrence,
    String? categoryId,
    String? accountId,
    String? note,
  }) = _RecurringTransactionCreateRequest;

  factory RecurringTransactionCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionCreateRequestFromJson(json);
}
