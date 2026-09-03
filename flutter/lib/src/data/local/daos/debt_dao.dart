// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart';

part 'debt_dao.g.dart';

@DriftAccessor(tables: [Debts])
class DebtDao extends DatabaseAccessor<AppDatabase> with _$DebtDaoMixin {
  DebtDao(super.db);

  Future<List<Debt>> getAllDebts() => select(debts).get();

  Stream<List<Debt>> watchAllDebts() => select(debts).watch();

  Future<Debt> getDebtById(String id) =>
      (select(debts)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertDebt(DebtsCompanion debt) => into(debts).insert(debt);

  Future<bool> updateDebt(DebtsCompanion debt) => update(debts).replace(debt);

  Future<int> deleteDebt(String id) =>
      (delete(debts)..where((t) => t.id.equals(id))).go();
}
