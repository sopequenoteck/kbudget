// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'recurring_transaction.freezed.dart';
part 'recurring_transaction.g.dart';

@freezed
class RecurringTransaction with _$RecurringTransaction {
  const RecurringTransaction._();

  const factory RecurringTransaction({
    required String id,
    required double montant,
    required String libelle,
    required TransactionType type,
    required Frequency frequency,
    required DateTime nextOccurrence,
    required bool recurringActive,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? accountName,
    Currency? accountCurrency,
  }) = _RecurringTransaction;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);

  RecurringStatus get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final occurrence = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
    );
    if (occurrence.isBefore(today)) return RecurringStatus.overdue;
    if (occurrence.isAtSameMomentAs(today)) return RecurringStatus.today;
    return RecurringStatus.upcoming;
  }
}
