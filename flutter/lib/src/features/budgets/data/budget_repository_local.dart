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
    final now = DateTime.now();
    final budgetRows = await _dao.getActiveBudgetsWithCategory();
    final spentMap = await _dao.getSpentByCategoryForMonth(now.month, now.year);

    final items = budgetRows.map((row) {
      final categoryId = row.read<String>('category_id');
      final montant = row.read<double>('montant');
      final frequence = row.read<String>('frequence');
      final currency = row.read<String>('currency');
      final montantNormalise = _normalize(montant, frequence);
      final depense = spentMap[categoryId] ?? 0.0;
      final pct = montantNormalise > 0 ? (depense / montantNormalise * 100) : 0.0;
      return BudgetOverviewItem(
        budgetId: row.read<String>('id'),
        categoryId: categoryId,
        categoryNom: row.read<String>('category_nom'),
        categoryIcone: row.read<String>('category_icone'),
        categoryCouleur: row.read<String>('category_couleur'),
        montantBudget: montant,
        montantBudgetNormalise: montantNormalise,
        currency: currency,
        montantDepense: depense,
        percentage: pct,
        frequence: frequence,
      );
    }).toList();

    final totalBudget = items.fold<double>(0, (s, i) => s + i.montantBudgetNormalise);
    final totalSpent = items.fold<double>(0, (s, i) => s + i.montantDepense);
    final currency = items.isNotEmpty ? items.first.currency : 'EUR';

    return BudgetOverview(
      month: _currentMonth(),
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      percentage: totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0,
      currency: currency,
      items: items,
    );
  }

  @override
  Future<BudgetHistory> getHistory(String month) async {
    final rows = await _dao.getSnapshotsWithCategory(month);

    final items = rows.map((row) {
      final montantBudget = row.read<double>('montant_budget');
      final depense = row.read<double>('montant_depense');
      final pct = montantBudget > 0 ? (depense / montantBudget * 100) : 0.0;
      final createdAtRaw = row.readNullable<String>('created_at');
      final createdAt =
          createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
      return BudgetHistoryItem(
        categoryId: row.read<String>('category_id'),
        categoryNom: row.read<String>('category_nom'),
        categoryIcone: row.read<String>('category_icone'),
        categoryCouleur: row.read<String>('category_couleur'),
        montantBudget: montantBudget,
        currency: row.read<String>('currency'),
        tauxChange: row.readNullable<double>('taux_change'),
        montantDepense: depense,
        percentage: pct,
        createdAt: createdAt,
      );
    }).toList();

    final totalBudget = items.fold<double>(0, (s, i) => s + i.montantBudget);
    final totalSpent = items.fold<double>(0, (s, i) => s + i.montantDepense);
    final currency = items.isNotEmpty ? items.first.currency : 'EUR';

    return BudgetHistory(
      month: month,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      percentage: totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0,
      currency: currency,
      items: items,
    );
  }

  double _normalize(double montant, String frequence) => switch (frequence) {
        'hebdomadaire' => montant * 52 / 12,
        'annuel' => montant / 12,
        _ => montant,
      };

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
