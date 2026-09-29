// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/adjust_balance_request.dart';

void main() {
  group('AdjustBalanceRequest', () {
    test('should_serializeLabel_when_provided', () {
      const request = AdjustBalanceRequest(
        newBalance: 0,
        libelle: 'Ajustement de solde',
      );

      expect(request.toJson(), {
        'newBalance': 0.0,
        'libelle': 'Ajustement de solde',
      });
    });

    test('should_serializeNullLabel_when_absent', () {
      const request = AdjustBalanceRequest(newBalance: 1500.5);

      expect(request.toJson(), {'newBalance': 1500.5, 'libelle': null});
    });
  });
}
