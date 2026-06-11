import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockRecurringTransactionRepository mockRepo;
  late ProviderContainer container;

  // Reference date: today = 2026-03-15
  final overdueItem = RecurringTransaction(
    id: 'overdue-1',
    montant: 50.0,
    libelle: 'Netflix',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime(2026, 3, 10), // before today
    recurringActive: true,
    categoryIcon: '🎬',
  );

  final overdueItem2 = RecurringTransaction(
    id: 'overdue-2',
    montant: 20.0,
    libelle: 'Spotify',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime(2026, 3, 5), // before today, earlier date
    recurringActive: true,
  );

  final todayItem = RecurringTransaction(
    id: 'today-1',
    montant: 100.0,
    libelle: 'Loyer',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime(2026, 3, 15), // today
    recurringActive: true,
  );

  final upcomingItem = RecurringTransaction(
    id: 'upcoming-1',
    montant: 200.0,
    libelle: 'Assurance',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime(2026, 3, 20), // future
    recurringActive: true,
  );

  setUp(() {
    mockRepo = MockRecurringTransactionRepository();
    container = ProviderContainer(
      overrides: [
        recurringTransactionRepositoryProvider
            .overrideWith((_) async => mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  RecurringListNotifier notifier() =>
      container.read(recurringListNotifierProvider.notifier);

  ListState<RecurringTransaction> state() =>
      container.read(recurringListNotifierProvider);

  group('RecurringListNotifier', () {
    test('should_haveEmptyState_when_created', () {
      final s = state();
      expect(s.items, isEmpty);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.mutatingIds, isEmpty);
    });

    test('should_load_items_sorted_by_status_then_date', () async {
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [upcomingItem, todayItem, overdueItem2, overdueItem],
      );

      await notifier().loadItems();

      final items = state().items;
      expect(items, hasLength(4));

      // Order: overdue (earliest first), today, upcoming
      expect(items[0].id, 'overdue-2'); // 2026-03-05
      expect(items[1].id, 'overdue-1'); // 2026-03-10
      expect(items[2].id, 'today-1'); // 2026-03-15
      expect(items[3].id, 'upcoming-1'); // 2026-03-20
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_validate_and_refresh_list', () async {
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [overdueItem, todayItem],
      );
      await notifier().loadItems();
      expect(state().items, hasLength(2));

      when(mockRepo.validate('overdue-1')).thenAnswer((_) async {});
      // After validate, listActive returns only todayItem
      when(mockRepo.listActive()).thenAnswer((_) async => [todayItem]);

      await notifier().validate('overdue-1');

      verify(mockRepo.validate('overdue-1')).called(1);
      expect(state().items, hasLength(1));
      expect(state().items.first.id, 'today-1');
      expect(state().mutatingIds, isEmpty);
    });

    test('should_skip_and_refresh_list', () async {
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [overdueItem, todayItem],
      );
      await notifier().loadItems();

      final updatedOverdue = RecurringTransaction(
        id: 'overdue-1',
        montant: 50.0,
        libelle: 'Netflix',
        type: TransactionType.depense,
        frequency: Frequency.mensuel,
        nextOccurrence: DateTime(2026, 4, 10),
        recurringActive: true,
      );
      when(mockRepo.skip('overdue-1')).thenAnswer((_) async => updatedOverdue);
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [todayItem, updatedOverdue],
      );

      await notifier().skip('overdue-1');

      verify(mockRepo.skip('overdue-1')).called(1);
      expect(state().mutatingIds, isEmpty);
      expect(state().error, isNull);
    });

    test('should_deactivate_and_refresh_list', () async {
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [overdueItem, todayItem],
      );
      await notifier().loadItems();

      final deactivated = RecurringTransaction(
        id: 'overdue-1',
        montant: 50.0,
        libelle: 'Netflix',
        type: TransactionType.depense,
        frequency: Frequency.mensuel,
        nextOccurrence: DateTime(2026, 3, 10),
        recurringActive: false,
      );
      when(mockRepo.deactivate('overdue-1'))
          .thenAnswer((_) async => deactivated);
      when(mockRepo.listActive()).thenAnswer((_) async => [todayItem]);

      await notifier().deactivate('overdue-1');

      verify(mockRepo.deactivate('overdue-1')).called(1);
      expect(state().items, hasLength(1));
      expect(state().items.first.id, 'today-1');
      expect(state().mutatingIds, isEmpty);
    });

    group('validateAll', () {
      test(
          'should_validateAll_call_validate_for_each_id_and_clear_sentinel',
          () async {
        when(mockRepo.listActive()).thenAnswer(
          (_) async => [overdueItem, overdueItem2],
        );
        await notifier().loadItems();

        when(mockRepo.validate('overdue-1')).thenAnswer((_) async {});
        when(mockRepo.validate('overdue-2')).thenAnswer((_) async {});
        when(mockRepo.listActive()).thenAnswer((_) async => []);

        await notifier().validateAll(['overdue-1', 'overdue-2']);

        verify(mockRepo.validate('overdue-1')).called(1);
        verify(mockRepo.validate('overdue-2')).called(1);
        expect(state().mutatingIds, isNot(contains('__all__')));
        expect(state().mutatingIds, isEmpty);
      });

      test(
          'should_validateAll_stop_at_first_failure_and_clear_sentinel',
          () async {
        when(mockRepo.listActive()).thenAnswer(
          (_) async => [overdueItem, overdueItem2],
        );
        await notifier().loadItems();

        // overdue-2 fails
        when(mockRepo.validate('overdue-2'))
            .thenThrow(Exception('Network error'));
        // After failing, listActive still returns both (no change)
        when(mockRepo.listActive())
            .thenAnswer((_) async => [overdueItem, overdueItem2]);

        await notifier().validateAll(['overdue-2']);

        // Sentinel must be cleared in finally
        expect(state().mutatingIds, isNot(contains('__all__')));
      });

      test('should_validateAll_return_immediately_when_ids_empty', () async {
        when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
        await notifier().loadItems();

        await notifier().validateAll([]);

        verifyNever(mockRepo.validate(any));
        expect(state().mutatingIds, isEmpty);
      });
    });

    test('should_set_error_on_failure', () async {
      when(mockRepo.listActive()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, isNotNull);
      expect(state().error, contains('Network error'));
      expect(state().isLoading, false);
    });

    test('should_track_mutating_ids', () async {
      when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
      await notifier().loadItems();

      bool validated = false;
      when(mockRepo.validate('overdue-1')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        validated = true;
      });
      when(mockRepo.listActive()).thenAnswer((_) async => []);

      final future = notifier().validate('overdue-1');

      // Right after calling validate, id should be in mutatingIds
      expect(state().mutatingIds, contains('overdue-1'));

      await future;

      expect(validated, isTrue);
      expect(state().mutatingIds, isEmpty);
    });
  });
}
