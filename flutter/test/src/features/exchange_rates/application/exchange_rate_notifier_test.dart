import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';
import '../exchange_rates_test_helpers.dart';

void main() {
  late ProviderContainer container;
  late MockExchangeRateRepository repo;

  ExchangeRateNotifier notifier() =>
      container.read(exchangeRateListProvider.notifier);

  ListState<ExchangeRate> state() => container.read(exchangeRateListProvider);

  setUp(() {
    repo = MockExchangeRateRepository();
    container = ProviderContainer(
      overrides: [
        exchangeRateRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(container.dispose);
  });

  group('loadItems', () {
    test('should_storeRates_when_repositorySucceeds', () async {
      final rates = [rateOf(Currency.usd, 1.1)];
      when(repo.getAll()).thenAnswer((_) async => rates);

      await notifier().loadItems();

      expect(state().items, rates);
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_setLocalizedLoadError_when_repositoryThrows', () async {
      when(repo.getAll()).thenThrow(Exception('boom'));

      await notifier().loadItems();

      expect(state().error, 'Impossible de charger les taux de change');
      expect(state().isLoading, false);
    });
  });

  group('upsert', () {
    test('should_appendRate_when_pairIsNew', () async {
      final created = rateOf(Currency.usd, 1.1);
      when(
        repo.upsert(Currency.eur, Currency.usd, 1.1),
      ).thenAnswer((_) async => created);

      await notifier().upsert(Currency.eur, Currency.usd, 1.1);

      expect(state().items, [created]);
    });

    test('should_replaceRate_when_pairAlreadyExists', () async {
      when(repo.getAll()).thenAnswer((_) async => [rateOf(Currency.usd, 1.1)]);
      await notifier().loadItems();
      final updated = rateOf(Currency.usd, 1.2);
      when(
        repo.upsert(Currency.eur, Currency.usd, 1.2),
      ).thenAnswer((_) async => updated);

      await notifier().upsert(Currency.eur, Currency.usd, 1.2);

      expect(state().items, [updated]);
    });

    test('should_setLocalizedSaveError_when_repositoryThrows', () async {
      when(repo.upsert(any, any, any)).thenThrow(Exception('boom'));

      await notifier().upsert(Currency.eur, Currency.usd, 1.1);

      expect(state().error, "Erreur lors de l'enregistrement du taux.");
    });
  });

  group('delete', () {
    test('should_removeRate_when_repositorySucceeds', () async {
      when(repo.getAll()).thenAnswer(
        (_) async => [rateOf(Currency.usd, 1.1), rateOf(Currency.gbp, 0.85)],
      );
      await notifier().loadItems();
      when(repo.delete(Currency.eur, Currency.usd)).thenAnswer((_) async {});

      await notifier().delete(Currency.eur, Currency.usd);

      expect(state().items.map((r) => r.targetCurrency), [Currency.gbp]);
    });

    test('should_setLocalizedDeleteError_when_repositoryThrows', () async {
      when(repo.delete(any, any)).thenThrow(Exception('boom'));

      await notifier().delete(Currency.eur, Currency.usd);

      expect(state().error, 'Erreur lors de la suppression');
    });
  });

  group('getRateFor', () {
    test('should_returnOne_when_currenciesAreEqual', () {
      expect(notifier().getRateFor(Currency.eur, Currency.eur), 1.0);
    });
  });
}
