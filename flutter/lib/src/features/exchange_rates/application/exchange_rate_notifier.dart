// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/exchange_rate_repository.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/services/stomp_service.dart';

final exchangeRateListProvider =
    NotifierProvider<ExchangeRateNotifier, ListState<ExchangeRate>>(
  ExchangeRateNotifier.new,
);

/// Taux de change du compte.
class ExchangeRateNotifier extends Notifier<ListState<ExchangeRate>>
    with SessionGuard {
  Future<ExchangeRateRepository> get _repository =>
      ref.read(exchangeRateRepositoryProvider.future);

  @override
  ListState<ExchangeRate> build() {
    // The state belongs to the session: rebuilt on every login and logout,
    // otherwise user B would inherit user A's data (KKS-546).
    ref.watch(exchangeRateRepositoryProvider);
    watchSession(ref);
    return const ListState();
  }

  Future<void> loadItems() async {
    final l10n = ref.read(appLocalizationsProvider);
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = await _repository;
      final rates = await repository.getAll();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(items: rates, isLoading: false);
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: l10n.exchangeRatesFeedbackLoadError,
      );
    }
  }

  Future<void> upsert(
      Currency baseCurrency, Currency targetCurrency, double rate) async {
    final l10n = ref.read(appLocalizationsProvider);
    final token = session;
    try {
      final repository = await _repository;
      final result =
          await repository.upsert(baseCurrency, targetCurrency, rate);
      if (isStale(token)) {
        return;
      }
      final items = [...state.items];
      final index = items.indexWhere(
        (r) =>
            r.baseCurrency == baseCurrency && r.targetCurrency == targetCurrency,
      );
      if (index >= 0) {
        items[index] = result;
      } else {
        items.add(result);
      }
      state = state.copyWith(items: items);
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        error: l10n.exchangeRatesFeedbackSaveError,
      );
    }
  }

  Future<void> delete(Currency baseCurrency, Currency targetCurrency) async {
    final l10n = ref.read(appLocalizationsProvider);
    final token = session;
    try {
      final repository = await _repository;
      await repository.delete(baseCurrency, targetCurrency);
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        items: state.items
            .where((r) => !(r.baseCurrency == baseCurrency &&
                r.targetCurrency == targetCurrency))
            .toList(),
      );
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        error: l10n.commonFeedbackDeleteError,
      );
    }
  }

  /// Helper to get rate for a specific currency pair
  double? getRateFor(Currency base, Currency target) {
    if (base == target) return 1.0;
    try {
      return state.items
          .firstWhere(
              (r) => r.baseCurrency == base && r.targetCurrency == target)
          .rate;
    } catch (_) {
      return null;
    }
  }
}

final exchangeRateStompListenerProvider = Provider<void>((ref) {
  final stompService = ref.watch(stompServiceProvider);
  final notifier = ref.watch(exchangeRateListProvider.notifier);

  final StreamSubscription<void> subscription =
      stompService.exchangeRatesUpdated.listen((_) {
    notifier.loadItems();
  });

  ref.onDispose(() => subscription.cancel());
});
