// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_dtos.freezed.dart';
part 'bank_dtos.g.dart';

@freezed
class BankResponse with _$BankResponse {
  const factory BankResponse({
    required String code,
    required String name,
    String? country,
    required String brandColor,
    String? logoUrl,
  }) = _BankResponse;

  factory BankResponse.fromJson(Map<String, dynamic> json) =>
      _$BankResponseFromJson(json);
}
