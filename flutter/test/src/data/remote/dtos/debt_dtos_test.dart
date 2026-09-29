// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/debt_dtos.dart';

void main() {
  group('RepayRequest', () {
    test('should_serializeLabel_when_provided', () {
      const request = RepayRequest(
        accountId: 'acc',
        amount: 25,
        libelle: 'Remboursement - Alice',
      );

      expect(request.toJson(), {
        'accountId': 'acc',
        'amount': 25.0,
        'libelle': 'Remboursement - Alice',
      });
    });

    test('should_serializeNullLabel_when_absent', () {
      const request = RepayRequest(accountId: 'acc');

      expect(request.toJson(), {
        'accountId': 'acc',
        'amount': null,
        'libelle': null,
      });
    });
  });
}
