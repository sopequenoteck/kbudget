// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/budget_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/budget_dtos.dart';
import 'package:k_budget/src/features/budgets/data/budget_repository_remote.dart';

/// Source de donnees factice : renvoie des reponses fixes, sans reseau.
class _FakeBudgetRemoteDataSource extends BudgetRemoteDataSource {
  _FakeBudgetRemoteDataSource() : super(Dio());

  @override
  Future<BudgetResponse> getById(String id) async => BudgetResponse(
        id: id,
        montant: 100,
        currency: 'EUR',
        frequence: 'MENSUEL',
        seuilNotification: 80,
        actif: true,
        category: {
          'id': 'cat-debt',
          'nom': 'Debt',
          'systemKey': id == 'bud-sys' ? 'DEBT' : null,
        },
      );

  @override
  Future<BudgetOverviewResponse> getOverview() async =>
      const BudgetOverviewResponse(
        month: '2026-09',
        totalBudget: 100,
        totalSpent: 40,
        percentage: 40,
        currency: 'EUR',
        items: [
          BudgetOverviewItemResponse(
            budgetId: 'bud-sys',
            categoryId: 'cat-sub',
            categoryNom: 'Subscription',
            categorySystemKey: 'SUBSCRIPTION',
            categoryIcone: '🔁',
            categoryCouleur: '#8B5CF6',
            montantBudget: 100,
            montantBudgetNormalise: 100,
            currency: 'EUR',
            montantDepense: 40,
            percentage: 40,
            frequence: 'MENSUEL',
          ),
        ],
        unbudgetedItems: [_unbudgeted],
      );

  @override
  Future<BudgetHistoryResponse> getHistory(String month) async =>
      BudgetHistoryResponse(
        month: month,
        totalBudget: 100,
        totalSpent: 40,
        percentage: 40,
        currency: 'EUR',
        items: const [
          BudgetHistoryItemResponse(
            categoryId: 'cat-tr',
            categoryNom: 'Transfer',
            categorySystemKey: 'TRANSFER',
            categoryIcone: '🔄',
            categoryCouleur: '#6B7280',
            montantBudget: 100,
            currency: 'EUR',
            montantDepense: 40,
            percentage: 40,
          ),
        ],
        unbudgetedItems: const [_unbudgeted],
      );
}

const _unbudgeted = UnbudgetedItemDto(
  categoryId: 'cat-adj',
  categoryNom: 'Balance adjustment',
  categorySystemKey: 'ADJUSTMENT',
  categoryIcone: '⚖️',
  categoryCouleur: '#6B7280',
  montantDepense: 12,
);

void main() {
  late BudgetRepositoryRemote repo;

  setUp(() {
    repo = BudgetRepositoryRemote(_FakeBudgetRemoteDataSource());
  });

  group('BudgetRepositoryRemote mapping', () {
    test('should_readNestedSystemKey_when_budgetCategoryIsSystem', () async {
      final budget = await repo.getById('bud-sys');

      expect(budget.categorySystemKey, 'DEBT');
      expect(budget.categoryNom, 'Debt');
    });

    test('should_leaveCategorySystemKeyNull_when_keyAbsent', () async {
      final budget = await repo.getById('bud-usr');

      expect(budget.categorySystemKey, isNull);
    });

    test('should_carryCategorySystemKey_when_mappingOverview', () async {
      final overview = await repo.getOverview();

      expect(overview.items.single.categorySystemKey, 'SUBSCRIPTION');
      expect(
        overview.unbudgetedItems.single.categorySystemKey,
        'ADJUSTMENT',
      );
    });

    test('should_carryCategorySystemKey_when_mappingHistory', () async {
      final history = await repo.getHistory('2026-08');

      expect(history.items.single.categorySystemKey, 'TRANSFER');
      expect(
        history.unbudgetedItems.single.categorySystemKey,
        'ADJUSTMENT',
      );
    });
  });
}
