// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:json_annotation/json_annotation.dart';

part 'adjust_balance_request.g.dart';

@JsonSerializable()
class AdjustBalanceRequest {
  final double newBalance;

  const AdjustBalanceRequest({required this.newBalance});

  factory AdjustBalanceRequest.fromJson(Map<String, dynamic> json) =>
      _$AdjustBalanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustBalanceRequestToJson(this);
}
