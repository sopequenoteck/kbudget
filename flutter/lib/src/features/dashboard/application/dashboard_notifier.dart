import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_notifier.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';

/// Provider qui lit le nom utilisateur depuis FlutterSecureStorage.
/// Fallback null si cle absente (mode local ou jamais connecte).
final currentUserNameProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return storage.read(key: 'user_name');
});

/// Provider principal du dashboard.
final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    final now = DateTime.now();
    return DashboardState(
      selectedMonth: now.month,
      selectedYear: now.year,
    );
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // S'assurer que les providers async sont resolus
      // avant de lire les repositories (evite fallback local)
      final mode = await ref.read(dataModeProvider.future);
      if (mode == DataMode.server) {
        await ref.read(authenticatedDioProvider.future);
      }

      // Charger le nom utilisateur
      final userName = await ref.read(currentUserNameProvider.future);

      // Charger les donnees des notifiers sous-jacents
      await Future.wait([
        ref.read(accountNotifierProvider.notifier).loadItems(),
        ref.read(transactionNotifierProvider.notifier).loadItems(),
        ref.read(subscriptionNotifierProvider.notifier).loadItems(),
        ref.read(debtNotifierProvider.notifier).loadItems(),
        ref.read(categoryNotifierProvider.notifier).loadItems(),
        ref.read(exchangeRateListProvider.notifier).loadItems(),
      ]);

      // Lire les donnees chargees
      final accountState = ref.read(accountNotifierProvider);
      final transactionState = ref.read(transactionNotifierProvider);
      final subscriptionState = ref.read(subscriptionNotifierProvider);
      final debtState = ref.read(debtNotifierProvider);
      final exchangeRateState = ref.read(exchangeRateListProvider);

      // Charger les devises depuis les preferences (mode server uniquement)
      List<Currency> currencies = [Currency.eur];
      if (mode == DataMode.server) {
        try {
          final prefDataSource =
              await ref.read(preferenceRemoteDataSourceProvider.future);
          final prefs = await prefDataSource.getPreferences();
          currencies = prefs.currencies
              .map((s) => Currency.values.byName(s.toLowerCase()))
              .toList();
        } catch (_) {
          // Fallback si erreur serveur
        }
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

      // Resume mensuel
      List<MonthlySummary> summaries = [];
      try {
        summaries = await ref.read(
          monthlySummaryProvider(
            (month: state.selectedMonth, year: state.selectedYear),
          ).future,
        );
      } on Exception {
        // Erreur summary non-bloquante pour le reste du dashboard
      }

      // Calcul montant mensuel abonnements (actifs uniquement)
      final activeSubscriptions =
          subscriptionState.items.where((s) => s.actif).toList();
      final subscriptionMonthlyTotal = activeSubscriptions.fold<double>(
        0,
        (sum, s) =>
            sum +
            (s.frequence == Frequency.mensuel ? s.montant : s.montant / 12),
      );

      // Calcul solde net dettes (non remboursees)
      final activDebts =
          debtState.items.where((d) => !d.rembourse).toList();
      final debtNetBalance = activDebts.fold<double>(
        0,
        (sum, d) =>
            sum + (d.sens == DebtType.pret ? d.montant : -d.montant),
      );

      // 5 dernieres transactions triees par date desc
      final allTransactions = transactionState.items;
      final sortedTransactions = List<Transaction>.from(allTransactions);
      sortedTransactions.sort((a, b) => b.date.compareTo(a.date));
      final recentTransactions = sortedTransactions.take(5).toList();

      state = state.copyWith(
        accounts: activeAccounts,
        defaultAccount: defaultAccount,
        monthlySummaries: summaries,
        subscriptionMonthlyTotal: subscriptionMonthlyTotal,
        activeSubscriptionCount: activeSubscriptions.length,
        debtNetBalance: debtNetBalance,
        activeDebtCount: activDebts.length,
        recentTransactions: recentTransactions,
        userName: userName,
        exchangeRates: exchangeRateState.items,
        currencies: currencies,
        activeCurrency:
            currencies.isNotEmpty ? currencies.first : Currency.eur,
        isLoading: false,
        error: null,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    // Recharger les notifiers sous-jacents
    ref.invalidate(accountNotifierProvider);
    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(subscriptionNotifierProvider);
    ref.invalidate(debtNotifierProvider);
    ref.invalidate(categoryNotifierProvider);
    ref.invalidate(currentUserNameProvider);

    await loadDashboard();
  }

  void setActiveCurrency(Currency currency) {
    state = state.copyWith(activeCurrency: currency);
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

  Future<void> changeMonth(int month, int year) async {
    state = state.copyWith(
      selectedMonth: month,
      selectedYear: year,
      isSummaryLoading: true,
    );

    try {
      final summaries = await ref.read(
        monthlySummaryProvider((month: month, year: year)).future,
      );
      state = state.copyWith(
        monthlySummaries: summaries,
        isSummaryLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        monthlySummaries: [],
        isSummaryLoading: false,
        error: 'Erreur chargement résumé: $e',
      );
    }
  }
}
