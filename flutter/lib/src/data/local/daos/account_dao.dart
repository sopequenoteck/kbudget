// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAllAccounts() => select(accounts).get();

  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();

  Future<Account> getAccountById(String id) =>
      (select(accounts)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<bool> updateAccount(AccountsCompanion account) =>
      update(accounts).replace(account);

  Future<int> deleteAccount(String id) =>
      (delete(accounts)..where((t) => t.id.equals(id))).go();

  Future<void> setDefault(String id) async {
    await (update(accounts)
          ..where((t) => t.isDefault.equals(true)))
        .write(const AccountsCompanion(isDefault: Value(false)));
    await (update(accounts)
          ..where((t) => t.id.equals(id)))
        .write(const AccountsCompanion(isDefault: Value(true)));
  }
}
