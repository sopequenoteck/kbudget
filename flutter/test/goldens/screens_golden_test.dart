// Captures golden des écrans principaux, dans les deux thèmes (KKS-600).
//
// Références : test/goldens/references/, produites par la CI dans l'image
// ghcr.io/cirruslabs/flutter (workflow flutter-goldens.yml), jamais sur un
// poste : le rendu dépend de la plateforme. Comparées par *Tests Flutter*.
//
// Rendu figé : date du 25 octobre 2026 à 11 h (clock), écran 390 × 844,
// locale fr, police Inter chargée, données de test fixes.
@Tags(['golden'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/presentation/login_screen.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';
import 'package:k_budget/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/app_fonts.dart';
import '../helpers/display_locale.dart';
import '../helpers/mocks.mocks.dart';

final _now = DateTime(2026, 10, 25, 11);

const _screen = Size(390, 844);

const _account = Account(
  id: 'acc1',
  nom: 'Compte courant',
  type: AccountType.courant,
  soldeInitial: 1000,
  icone: '🏦',
  couleur: '#4CAF50',
  isDefault: true,
  actif: true,
  solde: 2480.35,
);

const _groceries = Category(
  id: 'cat1',
  nom: 'Alimentation',
  icone: '🛒',
  couleur: '#FF5733',
);

const _salary = Category(
  id: 'cat2',
  nom: 'Revenus',
  icone: '💰',
  couleur: '#33FF57',
);

final _transactions = [
  Transaction(
    id: 'tx1',
    montant: 64.20,
    libelle: 'Courses',
    type: TransactionType.depense,
    date: DateTime(2026, 10, 25),
    categoryId: 'cat1',
    accountId: 'acc1',
  ),
  Transaction(
    id: 'tx2',
    montant: 2100,
    libelle: 'Salaire',
    type: TransactionType.recette,
    date: DateTime(2026, 10, 24),
    categoryId: 'cat2',
    accountId: 'acc1',
  ),
  Transaction(
    id: 'tx3',
    montant: 18.90,
    libelle: 'Boulangerie',
    type: TransactionType.depense,
    date: DateTime(2026, 10, 20),
    categoryId: 'cat1',
    accountId: 'acc1',
  ),
];

const _summary = MonthlySummary(
  month: 10,
  year: 2026,
  totalRecettes: 2100,
  totalDepenses: 83.10,
  bilan: 2016.90,
  currency: Currency.eur,
);

class _FixedDashboard extends DashboardNotifier {
  @override
  DashboardState build() => DashboardState(
        accounts: const [_account],
        defaultAccount: _account,
        currentSummary: _summary,
        recentTransactions: _transactions,
        userName: 'Kelly',
        isLoading: false,
      );

  @override
  Future<void> loadDashboard() async {}
}

class _FixedCategories extends CategoryNotifier {
  @override
  ListState<Category> build() =>
      const ListState<Category>(items: [_groceries, _salary]);
}

class _FixedAccounts extends AccountNotifier {
  @override
  ListState<Account> build() => const ListState<Account>(items: [_account]);
}

class _EmptyRecurring extends RecurringListNotifier {
  @override
  ListState<RecurringTransaction> build() =>
      const ListState<RecurringTransaction>();
}

class _EmptyBudgets extends BudgetNotifier {
  @override
  BudgetListState build() => const BudgetListState();
}

class _UnlockedLock extends AppLockNotifier {
  @override
  AppLockState build() =>
      const AppLockState(status: LockStatus.unlocked, enabled: false);
}

Widget _app(
  ThemeData theme,
  Widget home, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [displayLocaleOverride(), ...overrides],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: home,
    ),
  );
}

Widget _routerApp(
  ThemeData theme,
  String location,
  Widget screen, {
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [GoRoute(path: location, builder: (_, __) => screen)],
  );
  return ProviderScope(
    overrides: [displayLocaleOverride(), ...overrides],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      routerConfig: router,
    ),
  );
}

/// Rend [build] sur l'écran de référence, à la date figée, puis compare à
/// `references/<name>.png`. [act] interagit avant la capture (ouvrir un
/// dialogue).
void _golden(
  String name,
  Widget Function(ThemeData theme) build, {
  Future<void> Function(WidgetTester tester)? act,
}) {
  for (final (themeName, theme) in [
    ('dark', app_theme.AppTheme.dark),
    ('light', app_theme.AppTheme.light),
  ]) {
    testWidgets('should_match_reference_when_rendering_${themeName}_$name',
        (tester) async {
      tester.view
        ..physicalSize = _screen * 2
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await withClock(Clock.fixed(_now), () async {
        await tester.pumpWidget(build(theme));
        await tester.pumpAndSettle();
        if (act != null) {
          await act(tester);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('references/$themeName-$name.png'),
        );
      });
    });
  }
}

void main() {
  late MockAuthRepository authRepo;
  late MockTransactionRepository transactionRepo;
  late MockCategoryRepository categoryRepo;
  late MockAccountRepository accountRepo;
  late MockExchangeRateRepository exchangeRateRepo;
  late MockRecurringTransactionRepository recurringRepo;

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    await loadAppFonts();
    // Version affichée par les réglages : figée.
    PackageInfo.setMockInitialValues(
      appName: 'k-budget',
      packageName: 'fr.kksdev.budget',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    // Stockage sécurisé vide : configuration, thème et taille de texte par
    // défaut, sans plugin natif.
    FlutterSecureStorage.setMockInitialValues({});
    authRepo = MockAuthRepository();
    transactionRepo = MockTransactionRepository();
    categoryRepo = MockCategoryRepository();
    accountRepo = MockAccountRepository();
    exchangeRateRepo = MockExchangeRateRepository();
    recurringRepo = MockRecurringTransactionRepository();

    when(transactionRepo.getByMonth(any, any))
        .thenAnswer((_) async => _transactions);
    when(transactionRepo.getMonthlySummary(any, any))
        .thenAnswer((_) async => [_summary]);
    when(transactionRepo.getAll()).thenAnswer((_) async => _transactions);
    when(categoryRepo.getAll())
        .thenAnswer((_) async => [_groceries, _salary]);
    when(accountRepo.getAll()).thenAnswer((_) async => [_account]);
    when(exchangeRateRepo.getAll())
        .thenAnswer((_) async => <ExchangeRate>[]);
    when(recurringRepo.listActive()).thenAnswer((_) async => []);
  });

  List<Override> repositories() => [
        transactionRepositoryProvider.overrideWithValue(transactionRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        exchangeRateRepositoryProvider
            .overrideWith((_) async => exchangeRateRepo),
        recurringTransactionRepositoryProvider
            .overrideWith((_) async => recurringRepo),
      ];

  _golden(
    'connexion',
    (theme) => _routerApp(
      theme,
      '/login',
      const LoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWith((_) async => authRepo),
      ],
    ),
  );

  _golden(
    'dashboard',
    (theme) => _app(
      theme,
      const Scaffold(body: SafeArea(child: DashboardScreen())),
      overrides: [
        ...repositories(),
        dashboardNotifierProvider.overrideWith(_FixedDashboard.new),
        categoryNotifierProvider.overrideWith(_FixedCategories.new),
        recurringListNotifierProvider.overrideWith(_EmptyRecurring.new),
        budgetNotifierProvider.overrideWith(_EmptyBudgets.new),
      ],
    ),
  );

  _golden(
    'transactions',
    (theme) => _app(
      theme,
      const Scaffold(body: SafeArea(child: TransactionListScreen())),
      overrides: repositories(),
    ),
  );

  Widget transactionSheet(ThemeData theme) => _app(
        theme,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 600,
              child: TransactionForm(
                transaction: _transactions.first,
                type: TransactionType.depense,
                onSaved: (_) async {},
                onDeleted: (_) async {},
                onCancelled: () {},
              ),
            ),
          ),
        ),
        overrides: [
          ...repositories(),
          accountNotifierProvider.overrideWith(_FixedAccounts.new),
          categoryNotifierProvider.overrideWith(_FixedCategories.new),
        ],
      );

  _golden('bottom-sheet', transactionSheet);

  _golden(
    'confirm',
    transactionSheet,
    act: (tester) async {
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
    },
  );

  _golden(
    'reglages',
    (theme) => _routerApp(
      theme,
      '/settings',
      const SettingsHubScreen(),
      overrides: [appLockNotifierProvider.overrideWith(_UnlockedLock.new)],
    ),
  );
}
