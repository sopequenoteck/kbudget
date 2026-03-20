import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

part 'dashboard_state.freezed.dart';

@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    // Comptes
    @Default([]) List<Account> accounts,
    Account? defaultAccount,

    // Resumes mensuels
    MonthlySummary? currentSummary,
    MonthlySummary? previousSummary,

    // Dernieres transactions
    @Default([]) List<Transaction> recentTransactions,

    // Multi-devise
    @Default(Currency.eur) Currency activeCurrency,
    @Default([]) List<ExchangeRate> exchangeRates,
    @Default([Currency.eur]) List<Currency> currencies,

    // User
    String? userName,

    // Loading / Error
    @Default(true) bool isLoading,
    String? error,
  }) = _DashboardState;
}
