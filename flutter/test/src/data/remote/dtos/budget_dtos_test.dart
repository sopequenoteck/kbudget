// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/budget_dtos.dart';

Map<String, dynamic> _category({String? key}) => {
      'categoryId': 'cat-001',
      'categoryNom': 'Debt',
      'categoryIcone': '💸',
      'categoryCouleur': '#EF4444',
      'categorySystemKey': ?key,
    };

Map<String, dynamic> _overviewItem({String? key}) => {
      ..._category(key: key),
      'budgetId': 'bud-001',
      'montantBudget': 100.0,
      'montantBudgetNormalise': 100.0,
      'currency': 'EUR',
      'montantDepense': 40.0,
      'percentage': 40.0,
      'frequence': 'MENSUEL',
    };

Map<String, dynamic> _historyItem({String? key}) => {
      ..._category(key: key),
      'montantBudget': 100.0,
      'currency': 'EUR',
      'montantDepense': 40.0,
      'percentage': 40.0,
    };

Map<String, dynamic> _unbudgeted({String? key}) => {
      ..._category(key: key),
      'montantDepense': 12.0,
    };

void main() {
  group('BudgetOverviewItemResponse.fromJson', () {
    test('should_readCategorySystemKey_when_present', () {
      final r = BudgetOverviewItemResponse.fromJson(
        _overviewItem(key: 'DEBT'),
      );

      expect(r.categorySystemKey, 'DEBT');
    });

    test('should_leaveCategorySystemKeyNull_when_absent', () {
      final r = BudgetOverviewItemResponse.fromJson(_overviewItem());

      expect(r.categorySystemKey, isNull);
    });
  });

  group('BudgetHistoryItemResponse.fromJson', () {
    test('should_readCategorySystemKey_when_present', () {
      final r = BudgetHistoryItemResponse.fromJson(
        _historyItem(key: 'TRANSFER'),
      );

      expect(r.categorySystemKey, 'TRANSFER');
    });

    test('should_leaveCategorySystemKeyNull_when_absent', () {
      final r = BudgetHistoryItemResponse.fromJson(_historyItem());

      expect(r.categorySystemKey, isNull);
    });
  });

  group('UnbudgetedItemDto.fromJson', () {
    test('should_readCategorySystemKey_when_present', () {
      final r = UnbudgetedItemDto.fromJson(_unbudgeted(key: 'ADJUSTMENT'));

      expect(r.categorySystemKey, 'ADJUSTMENT');
    });

    test('should_leaveCategorySystemKeyNull_when_absent', () {
      final r = UnbudgetedItemDto.fromJson(_unbudgeted());

      expect(r.categorySystemKey, isNull);
    });
  });

  group('BudgetResponse.fromJson', () {
    test('should_keepNestedSystemKey_when_categoryCarriesIt', () {
      final r = BudgetResponse.fromJson(const {
        'id': 'bud-001',
        'montant': 100.0,
        'currency': 'EUR',
        'frequence': 'MENSUEL',
        'seuilNotification': 80,
        'actif': true,
        'category': {'id': 'cat-001', 'nom': 'Debt', 'systemKey': 'DEBT'},
      });

      expect(r.category['systemKey'], 'DEBT');
    });
  });
}
