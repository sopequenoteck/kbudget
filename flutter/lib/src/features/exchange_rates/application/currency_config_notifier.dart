// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';

final currencyConfigNotifierProvider =
    NotifierProvider<CurrencyConfigNotifier, List<Currency>>(
  CurrencyConfigNotifier.new,
);

/// Devises actives du compte, la premiere est la devise principale.
class CurrencyConfigNotifier extends Notifier<List<Currency>>
    with SessionGuard {
  @override
  List<Currency> build() {
    // L'etat appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546).
    watchSession(ref);
    return [Currency.eur];
  }

  Future<void> loadCurrencies() async {
    final token = session;
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      if (isStale(token)) {
        return;
      }
      state = prefs.currencies
          .map((s) => Currency.values.byName(s.toLowerCase()))
          .toList();
    } catch (_) {
      // Fallback déjà set au build
    }
  }

  Future<void> addCurrency(Currency currency) async {
    if (state.contains(currency)) return;
    final updated = [...state, currency];
    state = updated;
    await _persist(updated);
  }

  Future<void> removeCurrency(Currency currency) async {
    if (state.length <= 1) return; // min 1 devise
    if (state.first == currency) return; // ne pas supprimer la principale (FR-013)
    final updated = state.where((c) => c != currency).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> reorderCurrencies(List<Currency> newOrder) async {
    final oldPrimary = state.isNotEmpty ? state.first : null;
    state = newOrder;
    final token = session;
    await _persist(newOrder);
    if (isStale(token)) {
      return;
    }
    final newPrimary = newOrder.isNotEmpty ? newOrder.first : null;
    if (oldPrimary != null && newPrimary != null && oldPrimary != newPrimary) {
      try {
        await ref.read(exchangeRateListProvider.notifier).loadItems();
      } catch (e) {
        // Les taux n'ont pas pu être rechargés — l'UI observant exchangeRateListProvider affichera l'erreur
      }
    }
  }

  Future<void> _persist(List<Currency> currencies) async {
    final token = session;
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      // Sinon les fonctionnalites de B partiraient avec le jeton de A.
      if (isStale(token)) {
        return;
      }
      final featureState = ref.read(featureConfigNotifierProvider);
      await dataSource.updatePreferences(
        UserPreferenceRequest(
          enabledFeatures: featureState.enabledFeatures,
          navOrder: featureState.navOrder,
          currencies: currencies.map((c) => c.name.toUpperCase()).toList(),
        ),
      );
    } catch (_) {
      // silently fail — state déjà mis à jour optimistiquement
    }
  }
}
