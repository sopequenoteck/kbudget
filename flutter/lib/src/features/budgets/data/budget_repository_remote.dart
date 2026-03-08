import 'package:k_budget/src/data/remote/data_sources/budget_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/budget_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/repositories/budget_repository.dart';
import 'package:k_budget/src/utils/enum_utils.dart';

class BudgetRepositoryRemote implements BudgetRepository {
  final BudgetRemoteDataSource _dataSource;

  BudgetRepositoryRemote(this._dataSource);

  @override
  Future<List<Budget>> getAll({bool includeInactive = false}) async {
    final responses = await _dataSource.getAll(includeInactive: includeInactive);
    return responses.map(_toDomain).toList();
  }

  @override
  Future<Budget> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Budget> create(Budget budget) async {
    final request = _toRequest(budget);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Budget> update(Budget budget) async {
    final request = _toRequest(budget);
    final response = await _dataSource.update(budget.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<BudgetOverview> getOverview() async {
    final response = await _dataSource.getOverview();
    return BudgetOverview(
      month: response.month,
      totalBudget: response.totalBudget,
      totalSpent: response.totalSpent,
      percentage: response.percentage,
      currency: response.currency,
      items: response.items.map((item) => BudgetOverviewItem(
        budgetId: item.budgetId,
        categoryId: item.categoryId,
        categoryNom: item.categoryNom,
        categoryIcone: item.categoryIcone,
        categoryCouleur: item.categoryCouleur,
        montantBudget: item.montantBudget,
        montantBudgetNormalise: item.montantBudgetNormalise,
        currency: item.currency,
        montantDepense: item.montantDepense,
        percentage: item.percentage,
        frequence: item.frequence,
      )).toList(),
    );
  }

  @override
  Future<BudgetHistory> getHistory(String month) async {
    final response = await _dataSource.getHistory(month);
    return BudgetHistory(
      month: response.month,
      totalBudget: response.totalBudget,
      totalSpent: response.totalSpent,
      percentage: response.percentage,
      currency: response.currency,
      items: response.items.map((item) => BudgetHistoryItem(
        categoryId: item.categoryId,
        categoryNom: item.categoryNom,
        categoryIcone: item.categoryIcone,
        categoryCouleur: item.categoryCouleur,
        montantBudget: item.montantBudget,
        currency: item.currency,
        tauxChange: item.tauxChange,
        montantDepense: item.montantDepense,
        percentage: item.percentage,
        createdAt: item.createdAt,
      )).toList(),
    );
  }

  Budget _toDomain(BudgetResponse r) {
    final category = r.category;
    return Budget(
      id: r.id,
      categoryId: category['id'] as String,
      montant: r.montant,
      frequence: Frequency.values.byNameOrDefault(
        r.frequence.toLowerCase(),
        Frequency.mensuel,
      ),
      currency: Currency.values.byNameOrDefault(
        r.currency.toLowerCase(),
        Currency.eur,
      ),
      seuilNotification: r.seuilNotification,
      actif: r.actif,
      categoryNom: category['nom'] as String?,
      categoryIcone: category['icone'] as String?,
      categoryCouleur: category['couleur'] as String?,
      spent: r.spent,
      updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
    );
  }

  BudgetRequest _toRequest(Budget b) => BudgetRequest(
    categoryId: b.categoryId,
    montant: b.montant,
    frequence: b.frequence.name.toUpperCase(),
    currency: b.currency.name.toUpperCase(),
    seuilNotification: b.seuilNotification,
    actif: b.actif,
  );
}
