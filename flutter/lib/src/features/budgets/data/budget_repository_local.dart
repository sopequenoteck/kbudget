import 'package:k_budget/src/data/local/daos/budget_dao.dart';
import 'package:k_budget/src/data/local/mappers.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/repositories/budget_repository.dart';

class BudgetRepositoryLocal implements BudgetRepository {
  final BudgetDao _dao;

  BudgetRepositoryLocal(this._dao);

  @override
  Future<List<Budget>> getAll({bool includeInactive = false}) async {
    final rows = includeInactive
        ? await _dao.getAllBudgets()
        : await _dao.getActiveBudgets();
    return rows.map(budgetFromDb).toList();
  }

  @override
  Future<Budget> getById(String id) async {
    final row = await _dao.getBudgetById(id);
    return budgetFromDb(row);
  }

  @override
  Future<Budget> create(Budget budget) async {
    await _dao.insertBudget(budgetToDb(budget));
    return budget;
  }

  @override
  Future<Budget> update(Budget budget) async {
    await _dao.updateBudget(budgetToDb(budget));
    return budget;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteBudget(id);
  }

  @override
  Future<BudgetOverview> getOverview() async {
    // Local mode: return overview from active budgets without spending calculation
    final budgets = await getAll();
    final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.montant);
    return BudgetOverview(
      month: _currentMonth(),
      totalBudget: totalBudget,
      totalSpent: 0,
      percentage: 0,
      currency: 'EUR',
      items: [],
    );
  }

  @override
  Future<BudgetHistory> getHistory(String month) async {
    final snapshots = await _dao.getSnapshotsByMonth(month);
    final totalBudget = snapshots.fold<double>(0, (sum, s) => sum + s.montantBudget);
    final totalSpent = snapshots.fold<double>(0, (sum, s) => sum + s.montantDepense);
    return BudgetHistory(
      month: month,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      percentage: totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0,
      currency: 'EUR',
      items: [],
    );
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
