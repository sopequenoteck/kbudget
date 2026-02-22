import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/local/database.dart';
import 'package:k_budget/src/data/local/daos/account_dao.dart';
import 'package:k_budget/src/data/local/daos/category_dao.dart';
import 'package:k_budget/src/data/local/daos/debt_dao.dart';
import 'package:k_budget/src/data/local/daos/subscription_dao.dart';
import 'package:k_budget/src/data/local/daos/transaction_dao.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/data/remote/connectivity_interceptor.dart';
import 'package:k_budget/src/data/remote/data_sources/account_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/category_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/debt_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/subscription_remote_data_source.dart';
import 'package:k_budget/src/data/remote/data_sources/transaction_remote_data_source.dart';
import 'package:k_budget/src/data/remote/jwt_interceptor.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/repositories/account_repository.dart';
import 'package:k_budget/src/domain/repositories/category_repository.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';
import 'package:k_budget/src/domain/repositories/subscription_repository.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/repositories/transaction_repository.dart';
import 'package:k_budget/src/features/accounts/data/account_repository_local.dart';
import 'package:k_budget/src/features/accounts/data/account_repository_remote.dart';
import 'package:k_budget/src/features/categories/data/category_repository_local.dart';
import 'package:k_budget/src/features/categories/data/category_repository_remote.dart';
import 'package:k_budget/src/features/debts/data/debt_repository_local.dart';
import 'package:k_budget/src/features/debts/data/debt_repository_remote.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/subscriptions/data/subscription_repository_local.dart';
import 'package:k_budget/src/features/subscriptions/data/subscription_repository_remote.dart';
import 'package:k_budget/src/features/transactions/data/transaction_repository_local.dart';
import 'package:k_budget/src/features/transactions/data/transaction_repository_remote.dart';

// Database provider (local mode)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Data mode provider — reads from AppConfig
final dataModeProvider = FutureProvider<DataMode>((ref) async {
  final configRepo = ref.watch(appConfigRepositoryProvider);
  return configRepo.getDataMode();
});

// Configured Dio with JWT and connectivity interceptors (server mode)
final authenticatedDioProvider = FutureProvider<Dio>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  const secureStorage = FlutterSecureStorage();

  dio.interceptors.addAll([
    ConnectivityInterceptor(),
    JwtInterceptor(dio: dio, secureStorage: secureStorage),
  ]);

  return dio;
});

// Repository providers — switch between local and remote based on DataMode.

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final modeAsync = ref.watch(dataModeProvider);
  return modeAsync.when(
    data: (mode) {
      if (mode == DataMode.server) {
        final dioAsync = ref.watch(authenticatedDioProvider);
        return dioAsync.when(
          data: (dio) => TransactionRepositoryRemote(TransactionRemoteDataSource(dio)),
          loading: () => TransactionRepositoryLocal(TransactionDao(ref.watch(databaseProvider))),
          error: (_, _) => TransactionRepositoryLocal(TransactionDao(ref.watch(databaseProvider))),
        );
      }
      final db = ref.watch(databaseProvider);
      return TransactionRepositoryLocal(TransactionDao(db));
    },
    loading: () {
      final db = ref.watch(databaseProvider);
      return TransactionRepositoryLocal(TransactionDao(db));
    },
    error: (_, _) {
      final db = ref.watch(databaseProvider);
      return TransactionRepositoryLocal(TransactionDao(db));
    },
  );
});

// Monthly summary provider — uses transaction repository to get aggregated data
final monthlySummaryProvider =
    FutureProvider.family<List<MonthlySummary>, ({int month, int year})>(
        (ref, params) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getMonthlySummary(params.month, params.year);
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final modeAsync = ref.watch(dataModeProvider);
  return modeAsync.when(
    data: (mode) {
      if (mode == DataMode.server) {
        final dioAsync = ref.watch(authenticatedDioProvider);
        return dioAsync.when(
          data: (dio) => SubscriptionRepositoryRemote(SubscriptionRemoteDataSource(dio)),
          loading: () => SubscriptionRepositoryLocal(SubscriptionDao(ref.watch(databaseProvider))),
          error: (_, _) => SubscriptionRepositoryLocal(SubscriptionDao(ref.watch(databaseProvider))),
        );
      }
      final db = ref.watch(databaseProvider);
      return SubscriptionRepositoryLocal(SubscriptionDao(db));
    },
    loading: () {
      final db = ref.watch(databaseProvider);
      return SubscriptionRepositoryLocal(SubscriptionDao(db));
    },
    error: (_, _) {
      final db = ref.watch(databaseProvider);
      return SubscriptionRepositoryLocal(SubscriptionDao(db));
    },
  );
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final modeAsync = ref.watch(dataModeProvider);
  return modeAsync.when(
    data: (mode) {
      if (mode == DataMode.server) {
        final dioAsync = ref.watch(authenticatedDioProvider);
        return dioAsync.when(
          data: (dio) => DebtRepositoryRemote(DebtRemoteDataSource(dio)),
          loading: () => DebtRepositoryLocal(DebtDao(ref.watch(databaseProvider))),
          error: (_, _) => DebtRepositoryLocal(DebtDao(ref.watch(databaseProvider))),
        );
      }
      final db = ref.watch(databaseProvider);
      return DebtRepositoryLocal(DebtDao(db));
    },
    loading: () {
      final db = ref.watch(databaseProvider);
      return DebtRepositoryLocal(DebtDao(db));
    },
    error: (_, _) {
      final db = ref.watch(databaseProvider);
      return DebtRepositoryLocal(DebtDao(db));
    },
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final modeAsync = ref.watch(dataModeProvider);
  return modeAsync.when(
    data: (mode) {
      if (mode == DataMode.server) {
        final dioAsync = ref.watch(authenticatedDioProvider);
        return dioAsync.when(
          data: (dio) => CategoryRepositoryRemote(CategoryRemoteDataSource(dio)),
          loading: () => CategoryRepositoryLocal(CategoryDao(ref.watch(databaseProvider))),
          error: (_, _) => CategoryRepositoryLocal(CategoryDao(ref.watch(databaseProvider))),
        );
      }
      final db = ref.watch(databaseProvider);
      return CategoryRepositoryLocal(CategoryDao(db));
    },
    loading: () {
      final db = ref.watch(databaseProvider);
      return CategoryRepositoryLocal(CategoryDao(db));
    },
    error: (_, _) {
      final db = ref.watch(databaseProvider);
      return CategoryRepositoryLocal(CategoryDao(db));
    },
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final modeAsync = ref.watch(dataModeProvider);
  return modeAsync.when(
    data: (mode) {
      if (mode == DataMode.server) {
        final dioAsync = ref.watch(authenticatedDioProvider);
        return dioAsync.when(
          data: (dio) => AccountRepositoryRemote(AccountRemoteDataSource(dio)),
          loading: () => AccountRepositoryLocal(AccountDao(ref.watch(databaseProvider))),
          error: (_, _) => AccountRepositoryLocal(AccountDao(ref.watch(databaseProvider))),
        );
      }
      final db = ref.watch(databaseProvider);
      return AccountRepositoryLocal(AccountDao(db));
    },
    loading: () {
      final db = ref.watch(databaseProvider);
      return AccountRepositoryLocal(AccountDao(db));
    },
    error: (_, _) {
      final db = ref.watch(databaseProvider);
      return AccountRepositoryLocal(AccountDao(db));
    },
  );
});
