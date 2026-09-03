// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/data/remote/data_sources/debt_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/debt_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';

class DebtRepositoryRemote implements DebtRepository {
  final DebtRemoteDataSource _dataSource;

  DebtRepositoryRemote(this._dataSource);

  @override
  Future<List<Debt>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Stream<List<Debt>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<Debt> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Debt> create(Debt debt) async {
    final request = _toRequest(debt);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Debt> update(Debt debt) async {
    final request = _toRequest(debt);
    final response = await _dataSource.update(debt.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<Debt> repay(String id, String accountId, double? amount) async {
    final request = RepayRequest(accountId: accountId, amount: amount);
    final response = await _dataSource.repay(id, request);
    return _toDomain(response);
  }

  @override
  Future<List<DebtPayment>> getPayments(String id) async {
    final responses = await _dataSource.getPayments(id);
    return responses
        .map((r) => DebtPayment(
              id: r.id,
              montant: r.amount,
              date: DateTime.parse(r.date),
              accountName: r.accountName,
            ))
        .toList();
  }

  @override
  Future<Debt> snooze(
      String id, String reminderDate, String reminderTime) async {
    final request =
        SnoozeRequest(reminderDate: reminderDate, reminderTime: reminderTime);
    final response = await _dataSource.snooze(id, request);
    return _toDomain(response);
  }

  Debt _toDomain(DebtResponse r) => Debt(
        id: r.id,
        personne: r.personne,
        montant: r.montant,
        sens: DebtType.values
            .byNameOrDefault(r.sens.toLowerCase(), DebtType.emprunt),
        date: DateTime.parse(r.date),
        currency: Currency.values
            .byNameOrDefault(r.currency.toLowerCase(), Currency.eur),
        rembourse: r.rembourse,
        categoryId: r.category?.id,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
        accountId: r.account?.id,
        accountName: r.account?.nom,
        includeInBalance: r.includeInBalance,
        dueDate: r.dueDate != null ? DateTime.parse(r.dueDate!) : null,
        reminderDate:
            r.reminderDate != null ? DateTime.parse(r.reminderDate!) : null,
        reminderTime: r.reminderTime,
        remainingAmount: r.montantRestant,
      );

  DebtRequest _toRequest(Debt d) => DebtRequest(
        personne: d.personne,
        montant: d.montant,
        sens: d.sens.name.toUpperCase(),
        date: d.date.toIso8601String(),
        rembourse: d.rembourse,
        categoryId: d.categoryId,
        accountId: d.accountId,
        currency: d.currency.name.toUpperCase(),
        includeInBalance: d.includeInBalance,
        reminderDate: d.reminderDate?.toIso8601String().split('T').first,
        reminderTime: d.reminderTime,
        dueDate: d.dueDate?.toIso8601String().split('T').first,
      );
}
