// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/local/database.dart';
import 'package:k_budget/src/features/accounts/data/account_repository_local.dart';

void main() {
  late AppDatabase db;
  late AccountRepositoryLocal repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AccountRepositoryLocal(db.accountDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('AccountRepositoryLocal.adjustBalance', () {
    test('should_throwUnimplementedError_when_labelAbsent', () {
      expect(
        () => repo.adjustBalance('acc-001', 100.0),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('should_throwUnimplementedError_when_labelProvided', () {
      expect(
        () => repo.adjustBalance('acc-001', 100.0, libelle: 'Ajustement'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
