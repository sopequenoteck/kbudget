// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';

import '../../settings/application/language_notifier_test.dart'
    show FakeAuthNotifier;

/// Preferences serveur qui renvoient deux devises.
class _TwoCurrenciesDataSource extends PreferenceRemoteDataSource {
  _TwoCurrenciesDataSource() : super(Dio());

  @override
  Future<UserPreferenceResponse> getPreferences() async =>
      const UserPreferenceResponse(
        enabledFeatures: [Feature.budgets],
        navOrder: [Feature.budgets],
        currencies: ['EUR', 'USD'],
      );
}

/// Preferences serveur dont la reponse est pilotee par le test.
class _PendingDataSource extends PreferenceRemoteDataSource {
  _PendingDataSource() : super(Dio());

  final pending = Completer<UserPreferenceResponse>();

  @override
  Future<UserPreferenceResponse> getPreferences() => pending.future;
}

/// Preferences serveur qui enregistrent les ecritures.
class _RecordingDataSource extends _TwoCurrenciesDataSource {
  final requests = <UserPreferenceRequest>[];

  @override
  Future<UserPreferenceResponse> updatePreferences(
      UserPreferenceRequest request) async {
    requests.add(request);
    return getPreferences();
  }
}

class _FakeFeatureConfig extends FeatureConfigNotifier {
  @override
  FeatureConfigState build() =>
      const FeatureConfigState(enabledFeatures: [Feature.budgets]);
}

void main() {
  group('CurrencyConfigNotifier', () {
    test('should_resetState_when_sessionEnds', () async {
      final container = ProviderContainer(
        overrides: [
          preferenceRemoteDataSourceProvider
              .overrideWith((ref) async => _TwoCurrenciesDataSource()),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.authenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(currencyConfigNotifierProvider.notifier)
          .loadCurrencies();
      expect(
        container.read(currencyConfigNotifierProvider),
        [Currency.eur, Currency.usd],
      );

      (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
          .emit(const AuthState.unauthenticated());

      expect(container.read(currencyConfigNotifierProvider), [Currency.eur]);
    });

    test('should_ignoreStaleResponse_when_sessionChangesDuringLoad', () async {
      final dataSource = _PendingDataSource();
      final sessionContainer = ProviderContainer(
        overrides: [
          preferenceRemoteDataSourceProvider
              .overrideWith((ref) async => dataSource),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.authenticated()),
          ),
        ],
      );
      addTearDown(sessionContainer.dispose);
      final loading = sessionContainer
          .read(currencyConfigNotifierProvider.notifier)
          .loadCurrencies();
      await pumpEventQueue();

      // A se deconnecte et B se connecte avant la reponse de A.
      final auth = sessionContainer.read(authNotifierProvider.notifier)
          as FakeAuthNotifier;
      auth.emit(const AuthState.unauthenticated());
      auth.emit(const AuthState.authenticated());
      // Un widget qui observe l'etat reconstruit le notifier pour B.
      sessionContainer.read(currencyConfigNotifierProvider);
      dataSource.pending.complete(
        const UserPreferenceResponse(
          enabledFeatures: [Feature.budgets],
          navOrder: [Feature.budgets],
          currencies: ['EUR', 'USD'],
        ),
      );
      await loading;

      expect(
        sessionContainer.read(currencyConfigNotifierProvider),
        [Currency.eur],
      );
    });

    ProviderContainer persistingContainer(_RecordingDataSource dataSource) {
      final container = ProviderContainer(
        overrides: [
          preferenceRemoteDataSourceProvider
              .overrideWith((ref) async => dataSource),
          featureConfigNotifierProvider.overrideWith(_FakeFeatureConfig.new),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.authenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('should_persistCurrenciesAndFeatures_when_currencyAdded', () async {
      final dataSource = _RecordingDataSource();
      final container = persistingContainer(dataSource);

      await container
          .read(currencyConfigNotifierProvider.notifier)
          .addCurrency(Currency.usd);

      expect(
        container.read(currencyConfigNotifierProvider),
        [Currency.eur, Currency.usd],
      );
      expect(dataSource.requests, hasLength(1));
      expect(dataSource.requests.single.currencies, ['EUR', 'USD']);
      expect(dataSource.requests.single.enabledFeatures, [Feature.budgets]);
    });

    test('should_persistNewOrder_when_reorderedWithSamePrimary', () async {
      final dataSource = _RecordingDataSource();
      final container = persistingContainer(dataSource);
      final notifier = container.read(currencyConfigNotifierProvider.notifier);
      await notifier.addCurrency(Currency.usd);
      await notifier.addCurrency(Currency.gbp);

      await notifier.reorderCurrencies(
        [Currency.eur, Currency.gbp, Currency.usd],
      );

      expect(
        container.read(currencyConfigNotifierProvider),
        [Currency.eur, Currency.gbp, Currency.usd],
      );
      expect(dataSource.requests.last.currencies, ['EUR', 'GBP', 'USD']);
    });
  });
}
