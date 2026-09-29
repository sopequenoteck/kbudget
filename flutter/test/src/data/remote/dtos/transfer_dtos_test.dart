// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/transfer_dtos.dart';

void main() {
  group('TransferRequest', () {
    test('should_serializeLabels_when_provided', () {
      const request = TransferRequest(
        fromAccountId: 'a',
        toAccountId: 'b',
        montant: 10,
        libelleDebit: 'Virement vers B',
        libelleCredit: 'Virement depuis A',
      );

      final json = request.toJson();

      expect(json['libelleDebit'], 'Virement vers B');
      expect(json['libelleCredit'], 'Virement depuis A');
    });

    test('should_serializeNullLabels_when_absent', () {
      const request = TransferRequest(
        fromAccountId: 'a',
        toAccountId: 'b',
        montant: 10,
      );

      final json = request.toJson();

      expect(json['libelleDebit'], isNull);
      expect(json['libelleCredit'], isNull);
    });
  });
}
