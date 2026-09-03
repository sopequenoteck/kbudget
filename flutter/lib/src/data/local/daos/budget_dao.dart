// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, BudgetSnapshots, Categories, Transactions])
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

  // --- Queries with JOIN ---

  /// Sum of expenses by categoryId for a given month
  Future<Map<String, double>> getSpentByCategoryForMonth(
      int month, int year) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final rows = await customSelect(
      'SELECT category_id, SUM(montant) as total FROM transactions '
      'WHERE date >= ? AND date < ? AND type = ? AND category_id IS NOT NULL '
      'GROUP BY category_id',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withString('depense'),
      ],
    ).get();
    return {
      for (final row in rows)
        row.read<String>('category_id'): row.read<double>('total')
    };
  }

  /// Active budgets JOIN categories
  Future<List<QueryRow>> getActiveBudgetsWithCategory() {
    return customSelect(
      'SELECT b.id, b.category_id, b.montant, b.frequence, b.currency, '
      'c.nom AS category_nom, c.icone AS category_icone, c.couleur AS category_couleur '
      'FROM budgets b LEFT JOIN categories c ON b.category_id = c.id '
      'WHERE b.actif = 1',
    ).get();
  }

  /// Snapshots JOIN categories for a given month
  Future<List<QueryRow>> getSnapshotsWithCategory(String month) {
    return customSelect(
      'SELECT s.category_id, s.montant_budget, s.currency, s.taux_change, '
      's.montant_depense, s.created_at, '
      'c.nom AS category_nom, c.icone AS category_icone, c.couleur AS category_couleur '
      'FROM budget_snapshots s LEFT JOIN categories c ON s.category_id = c.id '
      'WHERE s.mois = ?',
      variables: [Variable.withString(month)],
    ).get();
  }

  /// Dépenses par catégorie non budgétée pour un mois donné
  Future<List<QueryRow>> getUnbudgetedSpendingForMonth(int month, int year) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return customSelect(
      'SELECT c.id, c.nom, c.icone, c.couleur, SUM(t.montant) as total '
      'FROM transactions t '
      'JOIN categories c ON t.category_id = c.id '
      'WHERE t.date >= ? AND t.date < ? AND t.type = ? '
      'AND t.category_id IS NOT NULL '
      'AND t.category_id NOT IN (SELECT category_id FROM budgets WHERE actif = 1) '
      'GROUP BY c.id, c.nom, c.icone, c.couleur',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withString('depense'),
      ],
    ).get();
  }
}
