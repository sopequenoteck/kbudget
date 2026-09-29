// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/local/database.dart';
import 'package:k_budget/src/features/debts/data/debt_repository_local.dart';

void main() {
  late AppDatabase db;
  late DebtRepositoryLocal repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DebtRepositoryLocal(db.debtDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('DebtRepositoryLocal.repay', () {
    test('should_throwException_when_labelAbsent', () {
      expect(
        () => repo.repay('debt-001', 'acc-001', 30.0),
        throwsA(isA<Exception>()),
      );
    });

    test('should_throwException_when_labelProvided', () {
      expect(
        () => repo.repay('debt-001', 'acc-001', 30.0, libelle: 'Remboursement'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
