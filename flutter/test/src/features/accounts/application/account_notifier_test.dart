import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAccountRepository mockRepo;
  late ProviderContainer container;

  const acc1 = Account(
    id: '1',
    nom: 'Courant',
    type: AccountType.courant,
    soldeInitial: 1000.0,
    icone: '🏦',
    couleur: '#000000',
    isDefault: true,
  );
  const acc2 = Account(
    id: '2',
    nom: 'Épargne',
    type: AccountType.epargne,
    soldeInitial: 5000.0,
    icone: '💰',
    couleur: '#00FF00',
  );

  setUp(() {
    mockRepo = MockAccountRepository();
    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  AccountNotifier notifier() =>
      container.read(accountNotifierProvider.notifier);

  ListState<Account> state() => container.read(accountNotifierProvider);

  group('AccountNotifier', () {
    test('should_haveEmptyState_when_created', () {
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_showItems_when_loadSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc2, acc1]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().isLoading, false);
    });

    test('should_sortByNameAsc_when_loaded', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc2, acc1]);

      await notifier().loadItems();

      expect(state().items[0].nom, 'Courant');
      expect(state().items[1].nom, 'Épargne');
    });

    test('should_showError_when_loadFails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, contains('Impossible de charger'));
      expect(state().isLoading, false);
    });

    test('should_addItem_when_createSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => acc2);
      await notifier().create(acc2);

      expect(state().items, hasLength(2));
    });

    test('should_updateItem_when_updateSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);
      await notifier().loadItems();

      final updated = acc1.copyWith(nom: 'Principal');
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.nom, 'Principal');
      expect(state().mutatingIds, isEmpty);
    });

    test('should_removeItem_when_deleteSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1, acc2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().items.first.id, '2');
    });

    test('should_rollbackItem_when_deleteFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1, acc2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(2));
      expect(state().error, contains('Erreur lors de la suppression'));
    });

    test('should_setDefault_when_setDefaultSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1, acc2]);
      await notifier().loadItems();

      final updatedAcc2 = acc2.copyWith(isDefault: true);
      when(mockRepo.setDefault('2')).thenAnswer((_) async => updatedAcc2);
      await notifier().setDefault('2');

      final items = state().items;
      final newDefault = items.firstWhere((e) => e.id == '2');
      final oldDefault = items.firstWhere((e) => e.id == '1');
      expect(newDefault.isDefault, true);
      expect(oldDefault.isDefault, false);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_updatePreviousDefault_when_newDefaultSet', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1, acc2]);
      await notifier().loadItems();

      // acc1 is currently default
      expect(state().items.firstWhere((e) => e.id == '1').isDefault, true);

      final updatedAcc2 = acc2.copyWith(isDefault: true);
      when(mockRepo.setDefault('2')).thenAnswer((_) async => updatedAcc2);
      await notifier().setDefault('2');

      // acc1 should no longer be default
      expect(state().items.firstWhere((e) => e.id == '1').isDefault, false);
      expect(state().items.firstWhere((e) => e.id == '2').isDefault, true);
    });

    test('should_showError_when_setDefaultFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1, acc2]);
      await notifier().loadItems();

      when(mockRepo.setDefault('2')).thenThrow(Exception('Server error'));
      await notifier().setDefault('2');

      expect(state().error, contains('Erreur lors du changement'));
      expect(state().mutatingIds, isEmpty);
    });

    test('should_loadNextPage_when_loadMoreCalled', () async {
      final items = List.generate(
        25,
        (i) => Account(
          id: '$i',
          nom: 'Account ${i.toString().padLeft(2, '0')}',
          type: AccountType.courant,
          soldeInitial: 100.0 * i,
          icone: '🏦',
          couleur: '#000000',
        ),
      );
      when(mockRepo.getAll()).thenAnswer((_) async => items);

      await notifier().loadItems();
      expect(state().items, hasLength(20));
      expect(state().hasMore, true);

      notifier().loadMore();
      expect(state().items, hasLength(25));
      expect(state().hasMore, false);
    });

    test('should_trackMutatingIds_when_mutationInProgress', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);
      await notifier().loadItems();

      when(mockRepo.update(any)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () => acc1),
      );

      final future = notifier().update(acc1.copyWith(nom: 'Updated'));
      expect(state().mutatingIds, contains('1'));

      await future;
      expect(state().mutatingIds, isEmpty);
    });

    test('should_updateBalance_when_adjustBalanceCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);
      await notifier().loadItems();

      final adjusted = acc1.copyWith(solde: 2000.0);
      when(mockRepo.adjustBalance('1', 2000.0))
          .thenAnswer((_) async => adjusted);
      await notifier().adjustBalance('1', 2000.0);

      expect(state().items.first.solde, 2000.0);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_setError_when_adjustBalanceFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);
      await notifier().loadItems();

      when(mockRepo.adjustBalance('1', 2000.0))
          .thenThrow(Exception('Server error'));
      await notifier().adjustBalance('1', 2000.0);

      expect(state().error, contains('ajustement du solde'));
      expect(state().mutatingIds, isEmpty);
    });

    test('should_trackMutatingId_when_adjustBalanceInProgress', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);
      await notifier().loadItems();

      final adjusted = acc1.copyWith(solde: 2000.0);
      when(mockRepo.adjustBalance('1', 2000.0)).thenAnswer(
        (_) =>
            Future.delayed(const Duration(milliseconds: 100), () => adjusted),
      );

      final future = notifier().adjustBalance('1', 2000.0);
      expect(state().mutatingIds, contains('1'));

      await future;
      expect(state().mutatingIds, isEmpty);
    });
  });
}
