// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';

abstract class AccountRepository extends CrudRepository<Account> {
  Stream<List<Account>> watchAll();
  Future<Account> getById(String id);
  Future<Account> setDefault(String id);
  /// Ajuste le solde du compte [id]. [libelle] nomme la transaction
  /// d'ajustement ; sans lui, l'API ecrit un defaut anglais.
  Future<Account> adjustBalance(
    String id,
    double newBalance, {
    String? libelle,
  });
}
