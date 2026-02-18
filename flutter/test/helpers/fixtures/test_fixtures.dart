import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/debt.dart';

class TestFixtures {
  TestFixtures._();

  static const testUserId = 'test-user-id-001';

  static AppConfig get defaultAppConfig => const AppConfig(
        dataMode: DataMode.local,
        theme: AppTheme.light,
        lockEnabled: false,
        onboardingCompleted: false,
      );

  static AppConfig get completedOnboardingConfig => const AppConfig(
        dataMode: DataMode.local,
        theme: AppTheme.light,
        lockEnabled: false,
        onboardingCompleted: true,
      );

  static AppConfig get serverModeConfig => const AppConfig(
        dataMode: DataMode.server,
        serverUrl: 'https://budget.example.com/api',
        theme: AppTheme.light,
        lockEnabled: false,
        onboardingCompleted: true,
      );

  static User get testUser => const User(
        id: testUserId,
        email: 'test@example.com',
        name: 'Test User',
        defaultCurrency: Currency.eur,
      );

  static Category get testCategory => Category(
        id: 'cat-001',
        nom: 'Alimentation',
        icone: '🍔',
        couleur: '#10B981',
        isSystem: false,
        updatedAt: DateTime(2026, 1, 1),
      );

  static Account get testAccount => Account(
        id: 'acc-001',
        nom: 'Compte courant',
        type: AccountType.courant,
        soldeInitial: 1000.0,
        icone: '🏦',
        couleur: '#3B82F6',
        isDefault: true,
        currency: Currency.eur,
        actif: true,
        updatedAt: DateTime(2026, 1, 1),
      );

  static Transaction get testTransaction => Transaction(
        id: 'txn-001',
        montant: 42.50,
        libelle: 'Courses supermarché',
        type: TransactionType.depense,
        date: DateTime(2026, 2, 1),
        categoryId: 'cat-001',
        accountId: 'acc-001',
        updatedAt: DateTime(2026, 2, 1),
      );

  static Subscription get testSubscription => Subscription(
        id: 'sub-001',
        nom: 'Netflix',
        montant: 13.49,
        frequence: Frequency.mensuel,
        dateDebut: DateTime(2025, 1, 1),
        currency: Currency.eur,
        actif: true,
        categoryId: 'cat-001',
        updatedAt: DateTime(2026, 1, 1),
      );

  static Debt get testDebt => Debt(
        id: 'debt-001',
        personne: 'Jean',
        montant: 50.0,
        sens: DebtType.pret,
        date: DateTime(2026, 1, 15),
        currency: Currency.eur,
        rembourse: false,
        updatedAt: DateTime(2026, 1, 15),
      );

  static List<Transaction> get transactionList => [
        testTransaction,
        Transaction(
          id: 'txn-002',
          montant: 2500.0,
          libelle: 'Salaire',
          type: TransactionType.recette,
          date: DateTime(2026, 2, 1),
          accountId: 'acc-001',
          updatedAt: DateTime(2026, 2, 1),
        ),
      ];

  static List<Category> get categoryList => [
        testCategory,
        Category(
          id: 'cat-002',
          nom: 'Transport',
          icone: '🚗',
          couleur: '#F59E0B',
          isSystem: false,
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

  static List<Account> get accountList => [
        testAccount,
        Account(
          id: 'acc-002',
          nom: 'Épargne',
          type: AccountType.epargne,
          soldeInitial: 5000.0,
          icone: '💰',
          couleur: '#10B981',
          isDefault: false,
          currency: Currency.eur,
          actif: true,
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
}
