// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';

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
  });
}
