import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_list_state.dart';
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
  final subInactive = Subscription(
    id: '3',
    nom: 'Amazon Prime',
    montant: 49.0,
    frequence: Frequency.annuel,
    dateDebut: DateTime(2025, 6, 1),
    actif: false,
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

  SubscriptionListState state() =>
      container.read(subscriptionNotifierProvider);

  group('SubscriptionNotifier', () {
    test('should_have_empty_state_when_created', () {
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
    });

    test('should_show_items_when_load_succeeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().items[0].nom, 'Netflix');
      expect(state().items[1].nom, 'Spotify');
    });

    test('should_show_error_when_load_fails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, contains('Impossible de charger'));
    });

    test('should_add_item_when_create_succeeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => sub2);
      await notifier().create(sub2);

      expect(state().items, hasLength(2));
    });

    test('should_update_item_when_update_succeeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      final updated = sub1.copyWith(montant: 19.99);
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.montant, 19.99);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_remove_item_when_delete_succeeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
    });

    test('should_rollback_item_when_delete_fails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().error, contains('Erreur lors de la suppression'));
    });

    test('should_toggle_actif_when_toggleActif_called', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1]);
      await notifier().loadItems();

      final deactivated = sub1.copyWith(actif: false);
      when(mockRepo.update(any)).thenAnswer((_) async => deactivated);
      await notifier().toggleActif('1');

      expect(state().items.first.actif, false);
    });

    test('should_deactivate_when_active_subscription_toggled', () async {
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
      when(mockRepo.getAll()).thenAnswer((_) async => [deactivated]);
      await notifier().refresh();
      await notifier().toggleActif('1');

      expect(state().items.first.actif, true);
    });

    test('should_load_next_page_when_loadMore_called', () async {
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

  group('SubscriptionNotifier — filter', () {
    test('should_filter_active_subscriptions_when_filter_set_to_actif',
        () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [sub1, sub2, subInactive]);
      await notifier().loadItems();

      notifier().setFilter(SubscriptionStatusFilter.actif);

      expect(state().items, hasLength(2));
      expect(state().items.every((s) => s.actif), true);
      expect(state().activeFilter, SubscriptionStatusFilter.actif);
    });

    test('should_filter_inactive_subscriptions_when_filter_set_to_inactif',
        () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [sub1, sub2, subInactive]);
      await notifier().loadItems();

      notifier().setFilter(SubscriptionStatusFilter.inactif);

      expect(state().items, hasLength(1));
      expect(state().items.first.nom, 'Amazon Prime');
      expect(state().activeFilter, SubscriptionStatusFilter.inactif);
    });

    test('should_show_all_subscriptions_when_filter_set_to_all', () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [sub1, sub2, subInactive]);
      await notifier().loadItems();

      notifier().setFilter(SubscriptionStatusFilter.actif);
      notifier().setFilter(SubscriptionStatusFilter.all);

      expect(state().items, hasLength(3));
      expect(state().activeFilter, SubscriptionStatusFilter.all);
    });

    test('should_preserve_filter_when_refresh_called', () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [sub1, sub2, subInactive]);
      await notifier().loadItems();

      notifier().setFilter(SubscriptionStatusFilter.actif);
      expect(state().items, hasLength(2));

      when(mockRepo.getAll())
          .thenAnswer((_) async => [sub1, sub2, subInactive]);
      await notifier().refresh();

      expect(state().activeFilter, SubscriptionStatusFilter.actif);
      expect(state().items, hasLength(2));
    });
  });

  group('SubscriptionNotifier — monthly totals', () {
    test('should_compute_monthly_total_when_active_subscriptions_exist',
        () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);
      await notifier().loadItems();

      // sub1: 15.99 + sub2: 9.99 = 25.98
      expect(state().monthlyTotals[Currency.eur], closeTo(25.98, 0.01));
    });

    test('should_convert_annual_to_monthly_when_computing_totals', () async {
      final annualSub = Subscription(
        id: '4',
        nom: 'Annual Service',
        montant: 120.0,
        frequence: Frequency.annuel,
        dateDebut: DateTime(2026, 1, 1),
        actif: true,
      );
      when(mockRepo.getAll()).thenAnswer((_) async => [annualSub]);
      await notifier().loadItems();

      // 120 / 12 = 10
      expect(state().monthlyTotals[Currency.eur], closeTo(10.0, 0.01));
    });

    test('should_group_totals_by_currency_when_multi_currency', () async {
      final subUsd = Subscription(
        id: '5',
        nom: 'US Service',
        montant: 20.0,
        frequence: Frequency.mensuel,
        dateDebut: DateTime(2026, 1, 1),
        actif: true,
        currency: Currency.usd,
      );
      when(mockRepo.getAll()).thenAnswer((_) async => [sub1, subUsd]);
      await notifier().loadItems();

      expect(state().monthlyTotals[Currency.eur], closeTo(15.99, 0.01));
      expect(state().monthlyTotals[Currency.usd], closeTo(20.0, 0.01));
    });

    test('should_return_empty_totals_when_no_active_subscriptions', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [subInactive]);
      await notifier().loadItems();

      expect(state().monthlyTotals, isEmpty);
    });

    test('should_not_change_monthly_totals_when_filter_changes', () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [sub1, sub2, subInactive]);
      await notifier().loadItems();

      final totalsBeforeFilter =
          Map<Currency, double>.from(state().monthlyTotals);

      notifier().setFilter(SubscriptionStatusFilter.inactif);

      expect(state().monthlyTotals, totalsBeforeFilter);
    });
  });
}
