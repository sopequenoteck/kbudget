import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, BudgetSnapshots])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  // --- Budgets ---

  Future<List<Budget>> getAllBudgets() => select(budgets).get();

  Future<List<Budget>> getActiveBudgets() =>
      (select(budgets)..where((t) => t.actif.equals(true))).get();

  Future<Budget> getBudgetById(String id) =>
      (select(budgets)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertBudget(BudgetsCompanion budget) =>
      into(budgets).insert(budget);

  Future<bool> updateBudget(BudgetsCompanion budget) =>
      update(budgets).replace(budget);

  Future<int> deleteBudget(String id) =>
      (delete(budgets)..where((t) => t.id.equals(id))).go();

  // --- Snapshots ---

  Future<List<BudgetSnapshot>> getSnapshotsByMonth(String month) =>
      (select(budgetSnapshots)..where((t) => t.mois.equals(month))).get();

  Future<int> insertSnapshot(BudgetSnapshotsCompanion snapshot) =>
      into(budgetSnapshots).insert(snapshot);
}
