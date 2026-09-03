// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'debt.freezed.dart';
part 'debt.g.dart';

@freezed
class Debt with _$Debt {
  const factory Debt({
    required String id,
    required String personne,
    required double montant,
    required DebtType sens,
    required DateTime date,
    @Default(Currency.eur) Currency currency,
    @Default(false) bool rembourse,
    String? categoryId,
    DateTime? updatedAt,
    String? accountId,
    String? accountName,
    @Default(false) bool includeInBalance,
    DateTime? dueDate,
    DateTime? reminderDate,
    String? reminderTime,
    double? remainingAmount,
  }) = _Debt;

  factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
}
