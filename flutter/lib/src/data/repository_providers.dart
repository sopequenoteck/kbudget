// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/data/remote/connectivity_interceptor.dart';
import 'package:k_budget/src/data/remote/data_sources/account_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/category_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/debt_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/subscription_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/transaction_remote_data_source.dart';
import 'package:k_budget/src/data/remote/jwt_interceptor.dart';
import 'package:k_budget/src/domain/repositories/account_repository.dart';
import 'package:k_budget/src/domain/repositories/category_repository.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';
import 'package:k_budget/src/domain/repositories/exchange_rate_repository.dart';
import 'package:k_budget/src/domain/repositories/subscription_repository.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/repositories/transaction_repository.dart';
import 'package:k_budget/src/features/accounts/data/account_repository_remote.dart';
import 'package:k_budget/src/data/remote/data_sources/notification_remote_data_source.dart';
import 'package:k_budget/src/domain/repositories/notification_repository.dart';
import 'package:k_budget/src/features/exchange_rates/data/exchange_rate_remote_data_source.dart';
import 'package:k_budget/src/features/exchange_rates/data/exchange_rate_repository_impl.dart';
import 'package:k_budget/src/features/notifications/data/notification_repository_remote.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/categories/data/category_repository_remote.dart';
import 'package:k_budget/src/data/remote/data_sources/budget_remote_data_source.dart';
import 'package:k_budget/src/domain/repositories/budget_repository.dart';
import 'package:k_budget/src/features/budgets/data/budget_repository_remote.dart';
import 'package:k_budget/src/features/debts/data/debt_repository_remote.dart';
import 'package:k_budget/src/features/subscriptions/data/subscription_repository_remote.dart';
import 'package:k_budget/src/features/transactions/data/transaction_repository_remote.dart';

// Configured Dio with JWT and connectivity interceptors. The router resolves it
// before any authenticated route, which is what lets the repository providers
// below read it synchronously with `requireValue`.
final authenticatedDioProvider = FutureProvider<Dio>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  const secureStorage = FlutterSecureStorage();

  dio.interceptors.addAll([
    ConnectivityInterceptor(),
    JwtInterceptor(
      dio: dio,
      secureStorage: secureStorage,
      onAuthFailure: () {
        ref.read(authNotifierProvider.notifier).forceUnauthenticated();
      },
      onPasswordResetRequired: () {
        ref.read(authNotifierProvider.notifier).requirePasswordReset();
      },
    ),
  ]);

  return dio;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider).requireValue;
  return TransactionRepositoryRemote(TransactionRemoteDataSource(dio));
});

// Monthly summary provider — uses transaction repository to get aggregated data
final monthlySummaryProvider =
    FutureProvider.family<List<MonthlySummary>, ({int month, int year})>(
        (ref, params) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getMonthlySummary(params.month, params.year);
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider).requireValue;
  return SubscriptionRepositoryRemote(SubscriptionRemoteDataSource(dio));
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider).requireValue;
  return DebtRepositoryRemote(DebtRemoteDataSource(dio));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider).requireValue;
  return CategoryRepositoryRemote(CategoryRemoteDataSource(dio));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider).requireValue;
  return AccountRepositoryRemote(AccountRemoteDataSource(dio));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider).requireValue;
  return BudgetRepositoryRemote(BudgetRemoteDataSource(dio));
});

// AccountRemoteDataSource provider (used for transfer)
final accountRemoteDataSourceProvider =
    FutureProvider<AccountRemoteDataSource>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return AccountRemoteDataSource(dio);
});

// Exchange rate repository provider
final exchangeRateRepositoryProvider = FutureProvider<ExchangeRateRepository>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return ExchangeRateRepositoryImpl(ExchangeRateRemoteDataSource(dio));
});

// Notification repository provider
final notificationRepositoryProvider = FutureProvider<NotificationRepository>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return NotificationRepositoryRemote(NotificationRemoteDataSource(dio));
});
