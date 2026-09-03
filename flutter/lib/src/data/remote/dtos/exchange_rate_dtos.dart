// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate_dtos.freezed.dart';
part 'exchange_rate_dtos.g.dart';

@freezed
class ExchangeRateRequest with _$ExchangeRateRequest {
  const factory ExchangeRateRequest({
    required String baseCurrency,
    required String targetCurrency,
    required double rate,
  }) = _ExchangeRateRequest;

  factory ExchangeRateRequest.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateRequestFromJson(json);
}

@freezed
class ExchangeRateResponse with _$ExchangeRateResponse {
  const factory ExchangeRateResponse({
    required String id,
    required String baseCurrency,
    required String targetCurrency,
    required double rate,
    String? updatedAt,
  }) = _ExchangeRateResponse;

  factory ExchangeRateResponse.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateResponseFromJson(json);
}
