import 'package:k_budget/src/domain/models/debt.dart';

abstract class DebtRepository {
  Future<List<Debt>> getAll();
  Stream<List<Debt>> watchAll();
  Future<Debt> getById(String id);
  Future<Debt> create(Debt debt);
  Future<Debt> update(Debt debt);
  Future<void> delete(String id);
}
