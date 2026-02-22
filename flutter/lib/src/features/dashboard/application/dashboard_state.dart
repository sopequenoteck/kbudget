import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

part 'dashboard_state.freezed.dart';

@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    // Comptes
    @Default([]) List<Account> accounts,
    Account? defaultAccount,

    // Resume mensuel
    @Default([]) List<MonthlySummary> monthlySummaries,
    @Default(0) int selectedMonth,
    @Default(0) int selectedYear,

    // Mini-cards
    @Default(0.0) double subscriptionMonthlyTotal,
    @Default(0) int activeSubscriptionCount,
    @Default(0.0) double debtNetBalance,
    @Default(0) int activeDebtCount,

    // Dernieres transactions
    @Default([]) List<Transaction> recentTransactions,

    // User
    String? userName,

    // Loading / Error
    @Default(true) bool isLoading,
    @Default(false) bool isSummaryLoading,
    String? error,
  }) = _DashboardState;
}
