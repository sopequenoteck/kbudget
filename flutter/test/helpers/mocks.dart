import 'package:mockito/annotations.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/domain/repositories/transaction_repository.dart';
import 'package:k_budget/src/domain/repositories/subscription_repository.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';
import 'package:k_budget/src/domain/repositories/category_repository.dart';
import 'package:k_budget/src/domain/repositories/account_repository.dart';
import 'package:k_budget/src/domain/repositories/product_repository.dart';
import 'package:k_budget/src/domain/repositories/exchange_rate_repository.dart';
import 'package:k_budget/src/domain/repositories/budget_repository.dart';

@GenerateNiceMocks([
  MockSpec<AppConfigRepository>(),
  MockSpec<AuthRepository>(),
  MockSpec<TransactionRepository>(),
  MockSpec<SubscriptionRepository>(),
  MockSpec<DebtRepository>(),
  MockSpec<CategoryRepository>(),
  MockSpec<AccountRepository>(),
  MockSpec<ProductRepository>(),
  MockSpec<ExchangeRateRepository>(),
  MockSpec<BudgetRepository>(),
])
void main() {}
