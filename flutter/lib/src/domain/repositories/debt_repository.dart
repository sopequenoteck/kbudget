// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';

abstract class DebtRepository {
  Future<List<Debt>> getAll();
  Stream<List<Debt>> watchAll();
  Future<Debt> getById(String id);
  Future<Debt> create(Debt debt);
  Future<Debt> update(Debt debt);
  Future<void> delete(String id);

  Future<Debt> repay(String id, String accountId, double? amount) async {
    throw Exception('Remboursement disponible en mode serveur uniquement');
  }

  Future<List<DebtPayment>> getPayments(String id) async {
    return [];
  }

  Future<Debt> snooze(String id, String reminderDate, String reminderTime) async {
    throw Exception('Report de rappel disponible en mode serveur uniquement');
  }
}
