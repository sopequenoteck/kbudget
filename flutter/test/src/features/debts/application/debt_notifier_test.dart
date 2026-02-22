import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockDebtRepository mockRepo;
  late ProviderContainer container;

  final debt1 = Debt(
    id: '1',
    personne: 'Alice',
    montant: 50.0,
    sens: DebtType.emprunt,
    date: DateTime(2026, 2, 10),
  );
  final debt2 = Debt(
    id: '2',
    personne: 'Bob',
    montant: 100.0,
    sens: DebtType.pret,
    date: DateTime(2026, 2, 20),
  );

  setUp(() {
    mockRepo = MockDebtRepository();
    container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  DebtNotifier notifier() =>
      container.read(debtNotifierProvider.notifier);

  ListState<Debt> state() => container.read(debtNotifierProvider);

  group('DebtNotifier', () {
    test('should_haveEmptyState_when_created', () {
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
    });

    test('should_showItems_when_loadSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1, debt2]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
    });

    test('should_sortByDateDesc_when_loaded', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1, debt2]);

      await notifier().loadItems();

      expect(state().items[0].id, '2'); // 2026-02-20
      expect(state().items[1].id, '1'); // 2026-02-10
    });

    test('should_showError_when_loadFails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, contains('Impossible de charger'));
    });

    test('should_addItem_when_createSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => debt2);
      await notifier().create(debt2);

      expect(state().items, hasLength(2));
    });

    test('should_updateItem_when_updateSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1]);
      await notifier().loadItems();

      final updated = debt1.copyWith(montant: 75.0);
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.montant, 75.0);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_removeItem_when_deleteSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1, debt2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
    });

    test('should_rollbackItem_when_deleteFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().error, contains('Erreur lors de la suppression'));
    });

    test('should_markAsRepaid_when_markAsRepaidCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1]);
      await notifier().loadItems();

      final repaid = debt1.copyWith(rembourse: true);
      when(mockRepo.update(any)).thenAnswer((_) async => repaid);
      await notifier().markAsRepaid('1');

      expect(state().items.first.rembourse, true);
    });

    test('should_showError_when_markAsRepaidFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenThrow(Exception('Server error'));
      await notifier().markAsRepaid('1');

      expect(state().error, contains('Erreur lors de la modification'));
      expect(state().items.first.rembourse, false);
    });

    test('should_loadNextPage_when_loadMoreCalled', () async {
      final items = List.generate(
        25,
        (i) => Debt(
          id: '$i',
          personne: 'Person $i',
          montant: 10.0 * i,
          sens: DebtType.emprunt,
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
      );
      when(mockRepo.getAll()).thenAnswer((_) async => items);

      await notifier().loadItems();
      expect(state().items, hasLength(20));

      notifier().loadMore();
      expect(state().items, hasLength(25));
      expect(state().hasMore, false);
    });

    test('should_trackMutatingIds_when_mutationInProgress', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [debt1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () => debt1),
      );

      final future = notifier().update(debt1.copyWith(montant: 75.0));
      expect(state().mutatingIds, contains('1'));

      await future;
      expect(state().mutatingIds, isEmpty);
    });
  });
}
