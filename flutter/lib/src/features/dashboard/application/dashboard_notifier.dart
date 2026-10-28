// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/features/transactions/application/transaction_notifier.dart';

/// Provider qui lit le nom utilisateur depuis FlutterSecureStorage.
/// Fallback null si cle absente (jamais connecte).
final currentUserNameProvider = FutureProvider<String?>((ref) async {
  // Le nom stocke appartient a la session : reconstruit a chaque connexion
  // et deconnexion, sinon le nom de l'ancien compte survit au changement
  ref.watch(authNotifierProvider);
  const storage = FlutterSecureStorage();
  return storage.read(key: 'user_name');
});

/// Provider principal du dashboard.
final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

/// Etat du tableau de bord : nom, comptes, totaux du mois et taux.
class DashboardNotifier extends Notifier<DashboardState>
    with SessionGuard {
  @override
  DashboardState build() {
    // L'etat appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546).
    watchSession(ref);
    return const DashboardState();
  }

  Future<void> loadDashboard() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // S'assurer que le Dio authentifie est resolu avant de lire
      // les repositories
      await ref.read(authenticatedDioProvider.future);
      if (isStale(token)) {
        return;
      }

      // Charger le nom utilisateur
      final userName = await ref.read(currentUserNameProvider.future);
      if (isStale(token)) {
        return;
      }

      // Charger les donnees des notifiers sous-jacents
      await Future.wait([
        ref.read(accountNotifierProvider.notifier).loadItems(),
        ref.read(transactionNotifierProvider.notifier).loadItems(),
        ref.read(categoryNotifierProvider.notifier).loadItems(),
        ref.read(exchangeRateListProvider.notifier).loadItems(),
        ref.read(budgetNotifierProvider.notifier).loadOverview(),
        ref.read(recurringListNotifierProvider.notifier).loadItems(),
      ]);
      if (isStale(token)) {
        return;
      }

      // Lire les donnees chargees
      final accountState = ref.read(accountNotifierProvider);
      final transactionState = ref.read(transactionNotifierProvider);
      final exchangeRateState = ref.read(exchangeRateListProvider);

      // Charger les devises depuis les preferences
      List<Currency> currencies = [Currency.eur];
      try {
        final prefDataSource =
            await ref.read(preferenceRemoteDataSourceProvider.future);
        final prefs = await prefDataSource.getPreferences();
        if (isStale(token)) {
          return;
        }
        currencies = prefs.currencies
            .map((s) => Currency.values.byName(s.toLowerCase()))
            .toList();
      } on Object catch (_) {
        // Fallback si erreur serveur
      }

      // Comptes actifs
      final activeAccounts =
          accountState.items.where((a) => a.actif).toList();

      // Compte par defaut : isDefault ou premier actif
      final defaultAccount = activeAccounts.isEmpty
          ? null
          : activeAccounts.cast<Account?>().firstWhere(
                (a) => a!.isDefault,
                orElse: () => activeAccounts.first,
              );

      // Resume mensuel mois courant
      final now = clock.now();
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      MonthlySummary? currentSummary;
      MonthlySummary? previousSummary;

      try {
        final currentSummaries = await ref.read(
          monthlySummaryProvider(
            (month: now.month, year: now.year),
          ).future,
        );
        if (isStale(token)) {
          return;
        }
        if (currentSummaries.isNotEmpty) {
          currentSummary = currentSummaries.first;
        }
      } on Exception {
        // Erreur summary non-bloquante pour le reste du dashboard
      }

      try {
        final previousSummaries = await ref.read(
          monthlySummaryProvider(
            (month: prevMonth, year: prevYear),
          ).future,
        );
        if (isStale(token)) {
          return;
        }
        if (previousSummaries.isNotEmpty) {
          previousSummary = previousSummaries.first;
        }
      } on Exception {
        // Erreur summary non-bloquante pour le reste du dashboard
      }

      // 5 dernieres transactions triees par date desc
      final allTransactions = transactionState.items;
      final sortedTransactions = List<Transaction>.from(allTransactions);
      sortedTransactions.sort((a, b) => b.date.compareTo(a.date));
      final recentTransactions = sortedTransactions.take(5).toList();

      state = state.copyWith(
        accounts: activeAccounts,
        defaultAccount: defaultAccount,
        currentSummary: currentSummary,
        previousSummary: previousSummary,
        recentTransactions: recentTransactions,
        userName: userName,
        exchangeRates: exchangeRateState.items,
        currencies: currencies,
        activeCurrency:
            currencies.isNotEmpty ? currencies.first : Currency.eur,
        isLoading: false,
        error: null,
      );
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackLoadError,
      );
    }
  }

  Future<void> refresh() async {
    // Recharger les notifiers sous-jacents
    ref.invalidate(accountNotifierProvider);
    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(categoryNotifierProvider);
    ref.invalidate(budgetNotifierProvider);
    ref.invalidate(recurringListNotifierProvider);
    ref.invalidate(currentUserNameProvider);

    await loadDashboard();
  }

  void setActiveCurrencyAndCurrencies(
      Currency currency, List<Currency> currencies) {
    state = state.copyWith(
      activeCurrency: currency,
      currencies: currencies,
    );
  }

  void updateExchangeRates(List<ExchangeRate> rates) {
    state = state.copyWith(exchangeRates: rates);
  }
}
