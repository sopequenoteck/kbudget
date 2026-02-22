import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockSubscriptionRepository mockRepo;
  late ProviderContainer container;

  final sub1 = Subscription(
    id: '1',
    nom: 'Netflix',
    montant: 15.99,
    frequence: Frequency.mensuel,
    dateDebut: DateTime(2026, 1, 1),
    actif: true,
  );
  final sub2 = Subscription(
    id: '2',
    nom: 'Spotify',
    montant: 9.99,
    frequence: Frequency.mensuel,
    dateDebut: DateTime(2026, 1, 15),
    actif: true,
  );

  setUp(() {
    mockRepo = MockSubscriptionRepository();
    container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  SubscriptionNotifier notifier() =>
      container.read(subscriptionNotifierProvider.notifier);

  ListState<Subscription> state() =>
      container.read(subscriptionNotifierProvider);

  group('SubscriptionNotifier', () {
    test('should_haveEmptyState_when_created', () {
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
    });

    test('should_showItems_when_loadSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().items[0].nom, 'Netflix');
      expect(state().items[1].nom, 'Spotify');
    });

    test('should_showError_when_loadFails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, contains('Impossible de charger'));
    });

    test('should_addItem_when_createSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => sub2);
      await notifier().create(sub2);

      expect(state().items, hasLength(2));
    });

    test('should_updateItem_when_updateSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      final updated = sub1.copyWith(montant: 19.99);
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.montant, 19.99);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_removeItem_when_deleteSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
    });

    test('should_rollbackItem_when_deleteFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().error, contains('Erreur lors de la suppression'));
    });

    test('should_toggleActif_when_toggleActifCalled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      final deactivated = sub1.copyWith(actif: false);
      when(mockRepo.update(any)).thenAnswer((_) async => deactivated);
      await notifier().toggleActif('1');

      expect(state().items.first.actif, false);
    });

    test('should_deactivate_when_activeSubscriptionToggled', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();
      expect(state().items.first.actif, true);

      final deactivated = sub1.copyWith(actif: false);
      when(mockRepo.update(any)).thenAnswer((_) async => deactivated);
      await notifier().toggleActif('1');

      expect(state().items.first.actif, false);

      // Toggle back
      final reactivated = sub1.copyWith(actif: true);
      when(mockRepo.update(any)).thenAnswer((_) async => reactivated);
      // Need to reload since _allItems was updated with actif=false
      when(mockRepo.getAll()).thenAnswer((_) async => [deactivated]);
      await notifier().refresh();
      await notifier().toggleActif('1');

      expect(state().items.first.actif, true);
    });

    test('should_loadNextPage_when_loadMoreCalled', () async {
      final items = List.generate(
        25,
        (i) => Subscription(
          id: '$i',
          nom: 'Sub ${i.toString().padLeft(2, '0')}',
          montant: 10.0,
          frequence: Frequency.mensuel,
          dateDebut: DateTime(2026, 1, 1),
        ),
      );
      when(mockRepo.getAll()).thenAnswer((_) async => items);

      await notifier().loadItems();
      expect(state().items, hasLength(20));

      notifier().loadMore();
      expect(state().items, hasLength(25));
      expect(state().hasMore, false);
    });
  });
}
