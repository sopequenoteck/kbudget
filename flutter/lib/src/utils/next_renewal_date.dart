// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/enums/enums.dart';

DateTime nextRenewalDate(
  DateTime dateDebut,
  Frequency frequence, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  var nextDate = dateDebut;

  while (!nextDate.isAfter(now)) {
    nextDate = switch (frequence) {
      Frequency.hebdomadaire =>
        nextDate.add(const Duration(days: 7)),
      Frequency.mensuel =>
        DateTime(nextDate.year, nextDate.month + 1, nextDate.day),
      Frequency.annuel =>
        DateTime(nextDate.year + 1, nextDate.month, nextDate.day),
    };
  }

  return nextDate;
}
