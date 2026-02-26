import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/transactions/application/transaction_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late ProviderContainer container;

  final tx1 = Transaction(
    id: '1',
    montant: 50.0,
    libelle: 'Courses',
    type: TransactionType.depense,
    date: DateTime(2026, 2, 20),
  );
  final tx2 = Transaction(
    id: '2',
    montant: 100.0,
    libelle: 'Salaire',
    type: TransactionType.recette,
    date: DateTime(2026, 2, 22),
  );
  final tx3 = Transaction(
    id: '3',
    montant: 30.0,
    libelle: 'Restaurant',
    type: TransactionType.depense,
    date: DateTime(2026, 2, 21),
  );

  setUp(() {
    mockRepo = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  TransactionNotifier notifier() =>
      container.read(transactionNotifierProvider.notifier);

  ListState<Transaction> state() =>
      container.read(transactionNotifierProvider);

  group('TransactionNotifier', () {
    test('should_haveEmptyState_when_created', () {
      final s = state();
      expect(s.items, isEmpty);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.currentPage, 0);
      expect(s.hasMore, true);
      expect(s.mutatingIds, isEmpty);
    });

    test('should_showLoading_when_loadItemsCalled', () async {
      when(mockRepo.getAll()).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () => [tx1]),
      );

      final future = notifier().loadItems();
      // State should be loading immediately after call
      expect(state().isLoading, true);

      await future;
      expect(state().isLoading, false);
    });

    test('should_showItems_when_loadSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1, tx2]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_sortByDateDesc_when_loaded', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1, tx2, tx3]);

      await notifier().loadItems();

      final items = state().items;
      expect(items[0].id, '2'); // 2026-02-22
      expect(items[1].id, '3'); // 2026-02-21
      expect(items[2].id, '1'); // 2026-02-20
    });

    test('should_showError_when_loadFails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().isLoading, false);
      expect(state().error, contains('Impossible de charger'));
      expect(state().items, isEmpty);
    });

    test('should_showEmptyList_when_noData', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => []);

      await notifier().loadItems();

      expect(state().items, isEmpty);
      expect(state().isLoading, false);
      expect(state().hasMore, false);
    });

    test('should_reloadItems_when_refreshCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1]);

      await notifier().loadItems();
      expect(state().items, hasLength(1));

      when(mockRepo.getAll()).thenAnswer((_) async => [tx1, tx2]);
      await notifier().refresh();

      expect(state().items, hasLength(2));
      verify(mockRepo.getAll()).called(2);
    });

    test('should_addItem_when_createSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => tx2);
      await notifier().create(tx2);

      expect(state().items, hasLength(2));
      expect(state().items.first.id, '2'); // tx2 is more recent
      expect(state().isLoading, false);
    });

    test('should_showError_when_createFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenThrow(Exception('Server error'));
      await notifier().create(tx2);

      expect(state().error, contains('Erreur lors de la création'));
      expect(state().items, hasLength(1)); // unchanged
    });

    test('should_updateItem_when_updateSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1]);
      await notifier().loadItems();

      final updated = tx1.copyWith(montant: 75.0);
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.montant, 75.0);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_showError_when_updateFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenThrow(Exception('Server error'));
      await notifier().update(tx1.copyWith(montant: 75.0));

      expect(state().error, contains('Erreur lors de la modification'));
      expect(state().mutatingIds, isEmpty);
      expect(state().items.first.montant, 50.0); // unchanged
    });

    test('should_removeItem_when_deleteSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1, tx2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().items.first.id, '2');
      expect(state().mutatingIds, isEmpty);
    });

    test('should_rollbackItem_when_deleteFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1, tx2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(2));
      expect(state().error, contains('Erreur lors de la suppression'));
      expect(state().mutatingIds, isEmpty);
    });

    test('should_loadNextPage_when_loadMoreCalled', () async {
      // Generate 25 items to test pagination (page size = 20)
      final items = List.generate(
        25,
        (i) => Transaction(
          id: '$i',
          montant: 10.0 * i,
          libelle: 'Item $i',
          type: TransactionType.depense,
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
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
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1, tx2]);
      await notifier().loadItems();

      expect(state().hasMore, false);

      notifier().loadMore();
      // Should not change state
      expect(state().items, hasLength(2));
      expect(state().currentPage, 0);
    });

    test('should_trackMutatingIds_when_mutationInProgress', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [tx1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () => tx1),
      );

      final future = notifier().update(tx1.copyWith(montant: 75.0));
      expect(state().mutatingIds, contains('1'));

      await future;
      expect(state().mutatingIds, isEmpty);
    });
  });
}
