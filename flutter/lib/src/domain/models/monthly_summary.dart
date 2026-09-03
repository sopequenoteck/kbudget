// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
    required double bilan,
    required Currency currency,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}
