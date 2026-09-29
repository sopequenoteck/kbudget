// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:json_annotation/json_annotation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum Feature {
  @JsonValue('SUBSCRIPTIONS')
  subscriptions,
  @JsonValue('DEBTS')
  debts,
  @JsonValue('BUDGETS')
  budgets;

  PhosphorIconData get icon => switch (this) {
    Feature.subscriptions => PhosphorIconsFill.arrowsClockwise,
    Feature.debts => PhosphorIconsFill.handshake,
    Feature.budgets => PhosphorIconsFill.chartPie,
  };

  PhosphorIconData get outlinedIcon => switch (this) {
    Feature.subscriptions => PhosphorIconsRegular.arrowsClockwise,
    Feature.debts => PhosphorIconsRegular.handshake,
    Feature.budgets => PhosphorIconsRegular.chartPie,
  };

  bool get defaultEnabled => switch (this) {
    Feature.subscriptions => true,
    Feature.debts => true,
    Feature.budgets => false,
  };
}
