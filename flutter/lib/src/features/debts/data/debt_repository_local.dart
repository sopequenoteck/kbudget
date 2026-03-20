import 'package:k_budget/src/data/local/daos/debt_dao.dart';
import 'package:k_budget/src/data/local/mappers.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';

class DebtRepositoryLocal implements DebtRepository {
  final DebtDao _dao;

  DebtRepositoryLocal(this._dao);

  @override
  Future<List<Debt>> getAll() async {
    final rows = await _dao.getAllDebts();
    return rows.map(debtFromDb).toList();
  }

  @override
  Stream<List<Debt>> watchAll() {
    return _dao.watchAllDebts().map(
          (rows) => rows.map(debtFromDb).toList(),
        );
  }

  @override
  Future<Debt> getById(String id) async {
    final row = await _dao.getDebtById(id);
    return debtFromDb(row);
  }

  @override
  Future<Debt> create(Debt debt) async {
    await _dao.insertDebt(debtToDb(debt));
    return debt;
  }

  @override
  Future<Debt> update(Debt debt) async {
    await _dao.updateDebt(debtToDb(debt));
    return debt;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteDebt(id);
  }

  @override
  Future<Debt> repay(String id, String accountId, double? amount) async {
    throw Exception('Remboursement disponible en mode serveur uniquement');
  }

  @override
  Future<List<DebtPayment>> getPayments(String id) async => [];

  @override
  Future<Debt> snooze(String id, String reminderDate, String reminderTime) async {
    throw Exception('Report de rappel disponible en mode serveur uniquement');
  }
}
