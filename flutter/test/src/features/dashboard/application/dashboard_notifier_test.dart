import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAccountRepository mockAccountRepo;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;
  late MockAppConfigRepository mockAppConfigRepo;
  late MockRecurringTransactionRepository mockRecurringRepo;
  late ProviderContainer container;

  // --- Fixtures ---

  const activeAccount1 = Account(
    id: 'acc-1',
    nom: 'Courant',
    type: AccountType.courant,
    soldeInitial: 1000.0,
    icone: '🏦',
    couleur: '#f59e0b',
    isDefault: true,
    actif: true,
    solde: 1500.0,
    currency: Currency.eur,
  );

  const activeAccount2 = Account(
    id: 'acc-2',
    nom: 'Epargne',
    type: AccountType.epargne,
    soldeInitial: 5000.0,
    icone: '💰',
    couleur: '#4f46e5',
    isDefault: false,
    actif: true,
    solde: 5200.0,
    currency: Currency.eur,
  );

  const inactiveAccount = Account(
    id: 'acc-3',
    nom: 'Fermé',
    type: AccountType.courant,
    soldeInitial: 0.0,
    icone: '🔒',
    couleur: '#000000',
    isDefault: false,
    actif: false,
    solde: 0.0,
  );

  final tx1 = Transaction(
    id: 'tx-1',
    montant: 50.0,
    libelle: 'Courses',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 20),
  );

  final tx2 = Transaction(
    id: 'tx-2',
    montant: 2000.0,
    libelle: 'Salaire',
    type: TransactionType.recette,
    date: DateTime(2026, 3, 18),
  );

  final tx3 = Transaction(
    id: 'tx-3',
    montant: 30.0,
    libelle: 'Restaurant',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 15),
  );

  final tx4 = Transaction(
    id: 'tx-4',
    montant: 80.0,
    libelle: 'Abonnement',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 10),
  );

  final tx5 = Transaction(
    id: 'tx-5',
    montant: 45.0,
    libelle: 'Pharmacie',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 8),
  );

  final tx6 = Transaction(
    id: 'tx-6',
    montant: 20.0,
    libelle: 'Café',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 5),
  );

  // Fixtures summary dynamiques pour rester alignées avec DateTime.now()
  // (le notifier charge le mois courant et le mois précédent dynamiquement)
  final now0 = DateTime.now();
  final prevMonth = now0.month == 1 ? 12 : now0.month - 1;
  final prevYear = now0.month == 1 ? now0.year - 1 : now0.year;

  final currentSummary = MonthlySummary(
    month: now0.month,
    year: now0.year,
    totalRecettes: 2000.0,
    totalDepenses: 225.0,
    bilan: 1775.0,
    currency: Currency.eur,
  );

  final previousSummary = MonthlySummary(
    month: prevMonth,
    year: prevYear,
    totalRecettes: 1800.0,
    totalDepenses: 600.0,
    bilan: 1200.0,
    currency: Currency.eur,
  );

  const exchangeRate = ExchangeRate(
    id: 'er-1',
    baseCurrency: Currency.eur,
    targetCurrency: Currency.usd,
    rate: 1.08,
  );

  // --- Setup helpers ---

  /// Crée un container avec tous les repositories mockés en mode local
  /// (DataMode.local pour éviter les appels réseau dans les tests).
  ProviderContainer buildContainer({
    List<Override> extraOverrides = const [],
  }) {
    return ProviderContainer(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockAppConfigRepo),
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        exchangeRateRepositoryProvider.overrideWith(
          (ref) async => mockExchangeRateRepo,
        ),
        dataModeProvider.overrideWith((ref) async => DataMode.local),
        budgetNotifierProvider.overrideWith(() => _FakeBudgetNotifier()),
        recurringTransactionRepositoryProvider.overrideWith(
          (_) async => mockRecurringRepo,
        ),
        currentUserNameProvider.overrideWith((ref) async => null),
        ...extraOverrides,
      ],
    );
  }

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();
    mockAppConfigRepo = MockAppConfigRepository();
    mockRecurringRepo = MockRecurringTransactionRepository();

    // Comportements par défaut (retours vides)
    when(mockAccountRepo.getAll()).thenAnswer((_) async => []);
    when(mockTransactionRepo.getAll()).thenAnswer((_) async => []);
    when(mockTransactionRepo.getMonthlySummary(any, any))
        .thenAnswer((_) async => []);
    when(mockCategoryRepo.getAll()).thenAnswer((_) async => []);
    when(mockExchangeRateRepo.getAll()).thenAnswer((_) async => []);
    when(mockAppConfigRepo.getDataMode())
        .thenAnswer((_) async => DataMode.local);
    when(mockRecurringRepo.listActive()).thenAnswer((_) async => []);

    container = buildContainer();
  });

  tearDown(() {
    container.dispose();
  });

  DashboardNotifier notifier() =>
      container.read(dashboardNotifierProvider.notifier);

  DashboardState state() => container.read(dashboardNotifierProvider);

  group('DashboardNotifier - état initial', () {
    test('should_haveLoadingTrue_when_created', () {
      // L'état initial a isLoading: true par défaut (défini dans DashboardState)
      final s = state();
      expect(s.isLoading, true);
    });

    test('should_haveNoData_when_created', () {
      final s = state();
      expect(s.accounts, isEmpty);
      expect(s.recentTransactions, isEmpty);
      expect(s.currentSummary, isNull);
      expect(s.previousSummary, isNull);
      expect(s.error, isNull);
      expect(s.userName, isNull);
    });

    test('should_haveDefaultCurrency_when_created', () {
      final s = state();
      expect(s.activeCurrency, Currency.eur);
      expect(s.currencies, [Currency.eur]);
      expect(s.exchangeRates, isEmpty);
    });
  });

  group('DashboardNotifier - loadDashboard()', () {
    test('should_loadAccounts_when_loadDashboardSucceeds', () async {
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1, activeAccount2]);

      await notifier().loadDashboard();

      expect(state().accounts, hasLength(2));
      expect(state().accounts.map((a) => a.id),
          containsAll(['acc-1', 'acc-2']));
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_excludeInactiveAccounts_when_loadDashboardSucceeds',
        () async {
      when(mockAccountRepo.getAll()).thenAnswer(
          (_) async => [activeAccount1, activeAccount2, inactiveAccount]);

      await notifier().loadDashboard();

      expect(state().accounts, hasLength(2));
      expect(state().accounts.map((a) => a.id), isNot(contains('acc-3')));
    });

    test('should_setDefaultAccount_when_accountHasIsDefaultTrue', () async {
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1, activeAccount2]);

      await notifier().loadDashboard();

      expect(state().defaultAccount, isNotNull);
      expect(state().defaultAccount!.id, 'acc-1');
      expect(state().defaultAccount!.isDefault, true);
    });

    test('should_setFirstActiveAsDefault_when_noDefaultAccount', () async {
      const acc1NoDefault = Account(
        id: 'acc-1',
        nom: 'Courant',
        type: AccountType.courant,
        soldeInitial: 1000.0,
        icone: '🏦',
        couleur: '#f59e0b',
        isDefault: false,
        actif: true,
        solde: 1500.0,
      );
      const acc2NoDefault = Account(
        id: 'acc-2',
        nom: 'Epargne',
        type: AccountType.epargne,
        soldeInitial: 5000.0,
        icone: '💰',
        couleur: '#4f46e5',
        isDefault: false,
        actif: true,
        solde: 5200.0,
      );
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [acc1NoDefault, acc2NoDefault]);

      await notifier().loadDashboard();

      // Le premier actif est sélectionné comme default
      expect(state().defaultAccount, isNotNull);
    });

    test('should_setNullDefaultAccount_when_noActiveAccounts', () async {
      when(mockAccountRepo.getAll()).thenAnswer((_) async => [inactiveAccount]);

      await notifier().loadDashboard();

      expect(state().defaultAccount, isNull);
    });

    test('should_loadCurrentSummary_when_loadDashboardSucceeds', () async {
      when(mockTransactionRepo.getMonthlySummary(any, any))
          .thenAnswer((inv) async {
        final month = inv.positionalArguments[0] as int;
        final now = DateTime.now();
        if (month == now.month) return [currentSummary];
        return [previousSummary];
      });

      await notifier().loadDashboard();

      expect(state().currentSummary, isNotNull);
      expect(state().currentSummary!.month, DateTime.now().month);
      expect(state().currentSummary!.year, DateTime.now().year);
    });

    test('should_loadPreviousSummary_when_loadDashboardSucceeds', () async {
      when(mockTransactionRepo.getMonthlySummary(any, any))
          .thenAnswer((inv) async {
        final month = inv.positionalArguments[0] as int;
        final now = DateTime.now();
        if (month == now.month) return [currentSummary];
        return [previousSummary];
      });

      await notifier().loadDashboard();

      expect(state().previousSummary, isNotNull);
    });

    test('should_keepNullSummary_when_noSummaryReturned', () async {
      when(mockTransactionRepo.getMonthlySummary(any, any))
          .thenAnswer((_) async => []);

      await notifier().loadDashboard();

      expect(state().currentSummary, isNull);
      expect(state().previousSummary, isNull);
    });

    test('should_continueDashboardLoad_when_summaryThrowsException', () async {
      when(mockTransactionRepo.getMonthlySummary(any, any))
          .thenThrow(Exception('Summary error'));
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1]);

      await notifier().loadDashboard();

      // Le dashboard doit quand même se charger malgré l'erreur summary
      expect(state().isLoading, false);
      expect(state().accounts, hasLength(1));
      expect(state().currentSummary, isNull);
      expect(state().previousSummary, isNull);
    });

    test('should_loadRecentTransactions_when_transactionsExist', () async {
      when(mockTransactionRepo.getAll())
          .thenAnswer((_) async => [tx1, tx2, tx3]);

      await notifier().loadDashboard();

      expect(state().recentTransactions, hasLength(3));
    });

    test('should_limitRecentTransactionsToFive_when_moreTransactionsExist',
        () async {
      when(mockTransactionRepo.getAll())
          .thenAnswer((_) async => [tx1, tx2, tx3, tx4, tx5, tx6]);

      await notifier().loadDashboard();

      expect(state().recentTransactions, hasLength(5));
    });

    test('should_sortRecentTransactionsByDateDesc_when_loaded', () async {
      // Ordre inversé pour vérifier le tri
      when(mockTransactionRepo.getAll())
          .thenAnswer((_) async => [tx3, tx1, tx2]);

      await notifier().loadDashboard();

      final txs = state().recentTransactions;
      expect(txs[0].id, 'tx-1'); // 2026-03-20 (le plus récent)
      expect(txs[1].id, 'tx-2'); // 2026-03-18
      expect(txs[2].id, 'tx-3'); // 2026-03-15
    });

    test('should_loadExchangeRates_when_loadDashboardSucceeds', () async {
      when(mockExchangeRateRepo.getAll())
          .thenAnswer((_) async => [exchangeRate]);

      await notifier().loadDashboard();

      expect(state().exchangeRates, hasLength(1));
      expect(state().exchangeRates.first.id, 'er-1');
    });

    test('should_setIsLoadingFalse_when_loadDashboardCompletes', () async {
      await notifier().loadDashboard();

      expect(state().isLoading, false);
    });

    test('should_setError_when_loadDashboardFails', () async {
      // Le bloc catch du DashboardNotifier est atteint quand un provider
      // intermédiaire lance une exception non-gérée (ex: dataModeProvider).
      // Les CrudNotifiers (account, transaction, category) catchent eux-mêmes
      // leurs exceptions. Pour tester l'erreur du DashboardNotifier, on simule
      // une exception sur currentUserNameProvider.
      final errorContainer = buildContainer(extraOverrides: [
        currentUserNameProvider.overrideWith(
          (ref) async => throw Exception('Storage error'),
        ),
      ]);
      addTearDown(errorContainer.dispose);

      await errorContainer
          .read(dashboardNotifierProvider.notifier)
          .loadDashboard();

      expect(errorContainer.read(dashboardNotifierProvider).isLoading, false);
      expect(errorContainer.read(dashboardNotifierProvider).error, isNotNull);
      expect(errorContainer.read(dashboardNotifierProvider).error,
          contains('Storage error'));
    });

    test('should_setIsLoadingTrue_during_loadDashboard', () async {
      when(mockAccountRepo.getAll()).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () => []),
      );

      final future = notifier().loadDashboard();

      // Immédiatement après l'appel, isLoading doit être true
      expect(state().isLoading, true);

      await future;
      expect(state().isLoading, false);
    });

    test('should_setCurrenciesWithDefaultEur_when_localMode', () async {
      // En mode local, les currencies ne sont pas chargées depuis les prefs
      // Le fallback est [Currency.eur]
      await notifier().loadDashboard();

      expect(state().currencies, isNotEmpty);
      expect(state().activeCurrency, Currency.eur);
    });

    test('should_loadUserName_when_nameProvidedByStorage', () async {
      final localContainer = buildContainer(extraOverrides: [
        currentUserNameProvider.overrideWith((ref) async => 'Alice'),
      ]);
      addTearDown(localContainer.dispose);

      await localContainer
          .read(dashboardNotifierProvider.notifier)
          .loadDashboard();

      expect(localContainer.read(dashboardNotifierProvider).userName, 'Alice');
    });

    test('should_haveNullUserName_when_storageReturnsNull', () async {
      // currentUserNameProvider override déjà à null dans buildContainer()
      await notifier().loadDashboard();

      expect(state().userName, isNull);
    });
  });

  group('DashboardNotifier - patrimoine total (accounts)', () {
    test('should_sumSoldeOfActiveAccounts_when_loaded', () async {
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1, activeAccount2]);

      await notifier().loadDashboard();

      // Le calcul du patrimoine est fait côté widget, le notifier
      // expose simplement la liste des comptes actifs avec leurs soldes
      final accounts = state().accounts;
      final totalSolde =
          accounts.fold<double>(0, (sum, a) => sum + a.solde);
      expect(totalSolde, 6700.0); // 1500 + 5200
    });

    test('should_notIncludeInactiveAccountsInBalance_when_loaded', () async {
      when(mockAccountRepo.getAll()).thenAnswer(
          (_) async => [activeAccount1, activeAccount2, inactiveAccount]);

      await notifier().loadDashboard();

      final accounts = state().accounts;
      expect(accounts.any((a) => a.id == 'acc-3'), false);
      final totalSolde =
          accounts.fold<double>(0, (sum, a) => sum + a.solde);
      expect(totalSolde, 6700.0); // inactif exclu
    });

    test('should_haveZeroBalance_when_noActiveAccounts', () async {
      when(mockAccountRepo.getAll()).thenAnswer((_) async => [inactiveAccount]);

      await notifier().loadDashboard();

      final accounts = state().accounts;
      expect(accounts, isEmpty);
      final totalSolde =
          accounts.fold<double>(0, (sum, a) => sum + a.solde);
      expect(totalSolde, 0.0);
    });
  });

  group('DashboardNotifier - setActiveCurrencyAndCurrencies()', () {
    test('should_updateActiveCurrency_when_called', () async {
      await notifier().loadDashboard();

      notifier()
          .setActiveCurrencyAndCurrencies(Currency.usd, [Currency.eur, Currency.usd]);

      expect(state().activeCurrency, Currency.usd);
    });

    test('should_updateCurrencies_when_called', () async {
      await notifier().loadDashboard();

      notifier()
          .setActiveCurrencyAndCurrencies(Currency.usd, [Currency.eur, Currency.usd]);

      expect(state().currencies, [Currency.eur, Currency.usd]);
    });

    test('should_notAffectOtherState_when_setActiveCurrencyAndCurrencies',
        () async {
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1]);
      await notifier().loadDashboard();

      final accountsBefore = state().accounts;

      notifier()
          .setActiveCurrencyAndCurrencies(Currency.xof, [Currency.xof]);

      expect(state().accounts, accountsBefore);
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });
  });

  group('DashboardNotifier - refresh()', () {
    test('should_reloadData_when_refreshCalled', () async {
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1]);
      await notifier().loadDashboard();
      expect(state().accounts, hasLength(1));

      // Changer le comportement du mock pour simuler de nouvelles données
      when(mockAccountRepo.getAll())
          .thenAnswer((_) async => [activeAccount1, activeAccount2]);

      await notifier().refresh();

      expect(state().accounts, hasLength(2));
      expect(state().isLoading, false);
    });

    test('should_clearError_when_refreshSucceedsAfterFailure', () async {
      // Simuler une erreur via currentUserNameProvider (non-absorbée par CrudNotifier)
      int callCount = 0;
      final errorThenSuccessContainer = buildContainer(extraOverrides: [
        currentUserNameProvider.overrideWith((ref) async {
          callCount++;
          if (callCount == 1) throw Exception('Storage error');
          return null;
        }),
      ]);
      addTearDown(errorThenSuccessContainer.dispose);

      await errorThenSuccessContainer
          .read(dashboardNotifierProvider.notifier)
          .loadDashboard();
      expect(
          errorThenSuccessContainer.read(dashboardNotifierProvider).error,
          isNotNull);

      await errorThenSuccessContainer
          .read(dashboardNotifierProvider.notifier)
          .refresh();

      expect(
          errorThenSuccessContainer.read(dashboardNotifierProvider).error,
          isNull);
    });

    test('should_setIsLoadingFalse_when_refreshCompletes', () async {
      await notifier().refresh();

      expect(state().isLoading, false);
    });
  });

  group('DashboardNotifier - updateExchangeRates()', () {
    test('should_updateExchangeRates_when_called', () async {
      await notifier().loadDashboard();

      notifier().updateExchangeRates([exchangeRate]);

      expect(state().exchangeRates, hasLength(1));
      expect(state().exchangeRates.first.baseCurrency, Currency.eur);
      expect(state().exchangeRates.first.targetCurrency, Currency.usd);
    });

    test('should_clearExchangeRates_when_calledWithEmptyList', () async {
      when(mockExchangeRateRepo.getAll())
          .thenAnswer((_) async => [exchangeRate]);
      await notifier().loadDashboard();
      expect(state().exchangeRates, hasLength(1));

      notifier().updateExchangeRates([]);

      expect(state().exchangeRates, isEmpty);
    });
  });
}

class _FakeBudgetNotifier extends BudgetNotifier {
  @override
  BudgetListState build() => const BudgetListState();

  @override
  Future<void> loadOverview() async {
    // No-op pour les tests du dashboard
  }
}
