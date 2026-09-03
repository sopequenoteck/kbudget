// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:json_annotation/json_annotation.dart';

enum EntityType {
  @JsonValue('SUBSCRIPTION')
  subscription,
  @JsonValue('DEBT')
  debt,
  @JsonValue('RECURRING_TRANSACTION')
  recurringTransaction,
  @JsonValue('BUDGET')
  budget,
  @JsonValue('TRANSACTION')
  transaction;
}
