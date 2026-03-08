import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockBudgetRepository mockRepo;
  late ProviderContainer container;

  final budget1 = Budget(
    id: '1',
    categoryId: 'cat-1',
    montant: 300.0,
    frequence: Frequency.mensuel,
    currency: Currency.eur,
    seuilNotification: 80,
    actif: true,
    categoryNom: 'Alimentation',
    categoryIcone: '🛒',
    categoryCouleur: '#f59e0b',
    updatedAt: DateTime(2026, 2, 20),
  );

  final budget2 = Budget(
    id: '2',
    categoryId: 'cat-2',
    montant: 100.0,
    frequence: Frequency.mensuel,
    currency: Currency.eur,
    seuilNotification: 80,
    actif: true,
    categoryNom: 'Transport',
    categoryIcone: '🚗',
    categoryCouleur: '#4f46e5',
    updatedAt: DateTime(2026, 2, 22),
  );

  final budget3 = Budget(
    id: '3',
    categoryId: 'cat-3',
    montant: 50.0,
    frequence: Frequency.mensuel,
    currency: Currency.eur,
    seuilNotification: 80,
    actif: true,
    categoryNom: 'Loisirs',
    categoryIcone: '🎬',
    categoryCouleur: '#10b981',
    updatedAt: DateTime(2026, 2, 21),
  );

  const sampleOverview = BudgetOverview(
    month: '2026-02',
    totalBudget: 400.0,
    totalSpent: 150.0,
    percentage: 37.5,
    currency: 'EUR',
    items: [],
  );

  const sampleHistory = BudgetHistory(
    month: '2026-02',
    totalBudget: 400.0,
    totalSpent: 150.0,
    percentage: 37.5,
    currency: 'EUR',
    items: [],
  );

  setUp(() {
    mockRepo = MockBudgetRepository();
    container = ProviderContainer(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  BudgetNotifier notifier() =>
      container.read(budgetNotifierProvider.notifier);

  BudgetListState state() => container.read(budgetNotifierProvider);

  group('BudgetNotifier', () {
    test('should_haveEmptyState_when_created', () {
      final s = state();
      expect(s.items, isEmpty);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.currentPage, 0);
      expect(s.hasMore, true);
      expect(s.mutatingIds, isEmpty);
      expect(s.overview, isNull);
      expect(s.history, isNull);
    });

    test('should_loadItems_when_loadItemsCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1, budget2]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_sortByUpdatedAtDesc_when_loaded', () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [budget1, budget2, budget3]);

      await notifier().loadItems();

      final items = state().items;
      expect(items[0].id, '2'); // 2026-02-22
      expect(items[1].id, '3'); // 2026-02-21
      expect(items[2].id, '1'); // 2026-02-20
    });

    test('should_setError_when_loadItemsFails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().isLoading, false);
      expect(state().error, contains('Impossible de charger les budgets'));
      expect(state().items, isEmpty);
    });

    test('should_addItem_when_createCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => budget2);
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);
      await notifier().create(budget2);

      expect(state().items, hasLength(2));
      expect(state().isLoading, false);
      expect(state().items.any((b) => b.id == '2'), isTrue);
    });

    test('should_showError_when_createFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenThrow(Exception('Server error'));
      await notifier().create(budget2);

      expect(state().error, contains('Erreur lors de la création'));
      expect(state().items, hasLength(1));
    });

    test('should_updateItem_when_updateCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1, budget2]);
      await notifier().loadItems();

      final updated = budget1.copyWith(montant: 500.0);
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);
      await notifier().update(updated);

      final item = state().items.firstWhere((b) => b.id == '1');
      expect(item.montant, 500.0);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_showError_when_updateFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenThrow(Exception('Server error'));
      await notifier().update(budget1.copyWith(montant: 500.0));

      expect(state().error, contains('Erreur lors de la modification'));
      expect(state().mutatingIds, isEmpty);
      expect(state().items.first.montant, 300.0);
    });

    test('should_removeItem_when_deleteCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1, budget2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().items.first.id, '2');
      expect(state().mutatingIds, isEmpty);
    });

    test('should_rollbackItem_when_deleteFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1, budget2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(2));
      expect(state().error, contains('Erreur lors de la suppression'));
      expect(state().mutatingIds, isEmpty);
    });

    test('should_loadOverview_when_loadOverviewCalled', () async {
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);

      await notifier().loadOverview();

      expect(state().overview, isNotNull);
      expect(state().overview!.month, '2026-02');
      expect(state().overview!.totalBudget, 400.0);
      expect(state().overview!.totalSpent, 150.0);
      expect(state().error, isNull);
    });

    test('should_setError_when_loadOverviewFails', () async {
      when(mockRepo.getOverview()).thenThrow(Exception('Network error'));

      await notifier().loadOverview();

      expect(state().error, contains('Impossible de charger l\'aperçu'));
      expect(state().overview, isNull);
    });

    test('should_loadHistory_when_loadHistoryCalled', () async {
      when(mockRepo.getHistory(any)).thenAnswer((_) async => sampleHistory);

      await notifier().loadHistory('2026-02');

      expect(state().history, isNotNull);
      expect(state().history!.month, '2026-02');
      expect(state().history!.totalSpent, 150.0);
      expect(state().error, isNull);
    });

    test('should_setError_when_loadHistoryFails', () async {
      when(mockRepo.getHistory(any)).thenThrow(Exception('Network error'));

      await notifier().loadHistory('2026-02');

      expect(state().error, contains('Impossible de charger l\'historique'));
      expect(state().history, isNull);
    });

    test('should_setMutatingId_when_deleteInProgress', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () {}),
      );
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);

      final future = notifier().delete('1');
      expect(state().mutatingIds, contains('1'));

      await future;
      expect(state().mutatingIds, isEmpty);
    });

    test('should_setMutatingId_when_updateInProgress', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 100),
          () => budget1.copyWith(montant: 500.0),
        ),
      );
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);

      final future = notifier().update(budget1.copyWith(montant: 500.0));
      expect(state().mutatingIds, contains('1'));

      await future;
      expect(state().mutatingIds, isEmpty);
    });

    test('should_setSelectedMonth_when_setMonthCalled', () {
      notifier().setMonth(3, 2026);

      expect(state().selectedMonth, 3);
      expect(state().selectedYear, 2026);
    });

    test('should_loadNextPage_when_loadMoreCalled', () async {
      final items = List.generate(
        25,
        (i) => Budget(
          id: '$i',
          categoryId: 'cat-$i',
          montant: 100.0,
          frequence: Frequency.mensuel,
          updatedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
      );
      when(mockRepo.getAll()).thenAnswer((_) async => items);

      await notifier().loadItems();

      expect(state().items, hasLength(20));
      expect(state().hasMore, true);
      expect(state().currentPage, 0);

      notifier().loadMore();

      expect(state().items, hasLength(25));
      expect(state().hasMore, false);
      expect(state().currentPage, 1);
    });

    test('should_stopPagination_when_noMoreItems', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1, budget2]);
      await notifier().loadItems();

      expect(state().hasMore, false);

      notifier().loadMore();

      expect(state().items, hasLength(2));
      expect(state().currentPage, 0);
    });

    test('should_refreshItemsAndOverview_when_refreshCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [budget1]);
      when(mockRepo.getOverview()).thenAnswer((_) async => sampleOverview);

      await notifier().refresh();

      expect(state().items, hasLength(1));
      expect(state().overview, isNotNull);
      verify(mockRepo.getAll()).called(1);
      verify(mockRepo.getOverview()).called(1);
    });
  });
}
