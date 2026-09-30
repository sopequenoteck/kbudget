import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/frequency.dart';
import 'package:k_budget/src/domain/enums/transaction_type.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_detail_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';
import 'package:shimmer/shimmer.dart';

import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/mocks.mocks.dart';

class _TestBudgetNotifier extends BudgetNotifier {
  _TestBudgetNotifier({required this.preloadedOverview});

  final BudgetOverview preloadedOverview;

  @override
  BudgetListState build() => BudgetListState(overview: preloadedOverview);

  @override
  Future<void> loadOverview() async {
    state = state.copyWith(overview: preloadedOverview, isLoading: false);
  }

  @override
  Future<void> delete(String id) async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.delete(id);
    state = state.copyWith(
      overview: state.overview?.copyWith(
        items: state.overview!.items
            .where((item) => item.budgetId != id)
            .toList(),
      ),
    );
  }

  @override
  Future<void> update(Budget item) async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.update(item);
    await loadOverview();
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockBudgetRepository mockBudgetRepo;
  late MockTransactionRepository mockTransactionRepo;
  late MockAccountRepository mockAccountRepo;

  const overviewWithCat1 = BudgetOverview(
    month: '2026-05',
    totalBudget: 200,
    totalSpent: 45,
    percentage: 22.5,
    currency: 'EUR',
    items: [
      BudgetOverviewItem(
        budgetId: 'b1',
        categoryId: 'cat-1',
        categoryNom: 'Alimentation',
        categoryIcone: '🛒',
        categoryCouleur: '#4CAF50',
        montantBudget: 200,
        montantBudgetNormalise: 200,
        currency: 'EUR',
        montantDepense: 45,
        percentage: 22.5,
        frequence: 'MENSUEL',
      ),
    ],
  );


  const historyWithCat1 = BudgetHistory(
    month: '2025-01',
    totalBudget: 200,
    totalSpent: 45,
    percentage: 22.5,
    currency: 'EUR',
    items: [
      BudgetHistoryItem(
        categoryId: 'cat-1',
        categoryNom: 'Alimentation',
        categoryIcone: '🛒',
        categoryCouleur: '#4CAF50',
        montantBudget: 200,
        currency: 'EUR',
        montantDepense: 45,
        percentage: 22.5,
      ),
    ],
  );

  void setupDefaultStubs() {
    when(mockBudgetRepo.getOverview())
        .thenAnswer((_) async => overviewWithCat1);
    when(mockBudgetRepo.getAll(includeInactive: anyNamed('includeInactive')))
        .thenAnswer((_) async => []);
    when(mockTransactionRepo.getByMonth(any, any))
        .thenAnswer((_) async => []);
    when(mockAccountRepo.getAll()).thenAnswer((_) async => []);
  }

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockAccountRepo = MockAccountRepository();
    setupDefaultStubs();
  });

  List<Override> buildOverrides() => [
        displayLocaleOverride(),
        budgetRepositoryProvider.overrideWithValue(mockBudgetRepo),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        preferenceRemoteDataSourceProvider
            .overrideWith((_) => Future.error('test-disabled')),
      ];

  Widget buildApp({String categoryId = 'cat-1', String? month}) {
    return ProviderScope(
      overrides: buildOverrides(),
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BudgetDetailScreen(categoryId: categoryId, month: month),
        ),
      ),
    );
  }

  Widget buildAppWithRouter({
    String categoryId = 'cat-1',
    String? month,
    List<Override> extraOverrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/budget-detail',
      routes: [
        GoRoute(
          path: '/budget-detail',
          builder: (_, _) => Scaffold(
            body: BudgetDetailScreen(categoryId: categoryId, month: month),
          ),
        ),
        GoRoute(
          path: RouteNames.budgets,
          builder: (_, _) => const Scaffold(body: Text('Budgets')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [...buildOverrides(), ...extraOverrides],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    );
  }

  group('BudgetDetailScreen', () {
    testWidgets(
      'should_showCategoryName_when_overviewLoaded',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('Alimentation'), findsWidgets);
      },
    );

    testWidgets(
      'should_showDepenseLabel_when_heroRendered',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('DÉPENSÉ'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showProgressBar_when_overviewHasPercentage',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'should_showActionPills_when_currentMonthAndOverviewItem',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Supprimer'), findsOneWidget);
        expect(find.text('Désactiver'), findsOneWidget);
        expect(find.text('Modifier'), findsOneWidget);
      },
    );

    testWidgets(
      'should_hideActionPills_when_historyMonth',
      (tester) async {
        when(mockBudgetRepo.getHistory('2025-01'))
            .thenAnswer((_) async => historyWithCat1);

        await tester.pumpWidget(buildApp(month: '2025-01'));
        await tester.pumpAndSettle();

        expect(find.text('Supprimer'), findsNothing);
        expect(find.text('Désactiver'), findsNothing);
      },
    );

    testWidgets(
      'should_callDelete_when_deleteConfirmed',
      (tester) async {
        when(mockBudgetRepo.delete('b1')).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildAppWithRouter(
            extraOverrides: [
              budgetNotifierProvider.overrideWith(
                () => _TestBudgetNotifier(preloadedOverview: overviewWithCat1),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Supprimer'));
        await tester.pumpAndSettle();

        expect(find.text('Supprimer le budget'), findsOneWidget);
        expect(
          find.text('Voulez-vous vraiment supprimer ce budget ?'),
          findsOneWidget,
        );

        final dialogSupprimer = find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Supprimer'),
        );
        await tester.tap(dialogSupprimer);
        await tester.pumpAndSettle();

        verify(mockBudgetRepo.delete('b1')).called(1);
      },
    );

    testWidgets(
      'should_callGetById_when_toggleTapped',
      (tester) async {
        when(mockBudgetRepo.getById('b1')).thenAnswer(
          (_) async => const Budget(
            id: 'b1',
            categoryId: 'cat-1',
            montant: 200,
            frequence: Frequency.mensuel,
            currency: Currency.eur,
            actif: true,
          ),
        );
        when(mockBudgetRepo.update(any)).thenAnswer(
          (_) async => const Budget(
            id: 'b1',
            categoryId: 'cat-1',
            montant: 200,
            frequence: Frequency.mensuel,
            currency: Currency.eur,
            actif: false,
          ),
        );

        await tester.pumpWidget(
          buildAppWithRouter(
            extraOverrides: [
              budgetNotifierProvider.overrideWith(
                () => _TestBudgetNotifier(preloadedOverview: overviewWithCat1),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Désactiver'));
        await tester.pumpAndSettle();

        verify(mockBudgetRepo.getById('b1')).called(1);
      },
    );

    testWidgets(
      'should_showSkeleton_when_loading',
      (tester) async {
        final completer = Completer<BudgetOverview>();
        when(mockBudgetRepo.getOverview())
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildApp());
        await tester.pump();

        expect(find.byType(Shimmer), findsWidgets);

        completer.complete(overviewWithCat1);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'should_showEmptyState_when_noMatchingTransactions',
      (tester) async {
        final now = DateTime.now();
        when(mockTransactionRepo.getByMonth(any, any)).thenAnswer(
          (_) async => [
            Transaction(
              id: 'tx-other',
              montant: 20,
              libelle: 'Autre catégorie',
              type: TransactionType.depense,
              date: DateTime(now.year, now.month, 10),
              categoryId: 'cat-other',
            ),
            Transaction(
              id: 'tx-recette',
              montant: 100,
              libelle: 'Salaire',
              type: TransactionType.recette,
              date: DateTime(now.year, now.month, 5),
              categoryId: 'cat-1',
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Aucune transaction ce mois'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showGroupedTransactionRows_when_matchingTransactionsExist',
      (tester) async {
        final now = DateTime.now();
        final olderDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 10));
        when(mockTransactionRepo.getByMonth(any, any)).thenAnswer(
          (_) async => [
            Transaction(
              id: 'tx-old',
              montant: 30,
              libelle: 'Courses anciennes',
              type: TransactionType.depense,
              date: olderDate,
              categoryId: 'cat-1',
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Courses anciennes'), findsOneWidget);
        expect(find.textContaining('30,00'), findsWidgets);
      },
    );

    testWidgets(
      'should_orderGroups_todayYesterdayThenMostRecent_when_severalDays',
      (tester) async {
        // Surface haute : les cinq groupes doivent etre construits
        tester.view.physicalSize = const Size(2400, 9000);
        addTearDown(tester.view.resetPhysicalSize);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 12);
        Transaction tx(String id, DateTime date) => Transaction(
              id: id,
              montant: 10,
              libelle: 'Achat $id',
              type: TransactionType.depense,
              date: date,
              categoryId: 'cat-1',
            );
        final tomorrow = today.add(const Duration(days: 1));
        final threeDaysAgo = today.subtract(const Duration(days: 3));
        final fiveDaysAgo = today.subtract(const Duration(days: 5));
        when(mockTransactionRepo.getByMonth(any, any)).thenAnswer(
          (_) async => [
            tx('j-5', fiveDaysAgo),
            tx('j', today),
            tx('j+1', tomorrow),
            tx('j-3', threeDaysAgo),
            tx('j-1', today.subtract(const Duration(days: 1))),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final format = DateFormat.MMMMd('fr_FR');
        final labels = [
          "Aujourd'hui",
          'Hier',
          format.format(tomorrow),
          format.format(threeDaysAgo),
          format.format(fiveDaysAgo),
        ];
        final tops = [
          for (final label in labels) tester.getTopLeft(find.text(label)).dy,
        ];
        for (var i = 1; i < tops.length; i++) {
          expect(tops[i], greaterThan(tops[i - 1]), reason: labels[i]);
        }
      },
    );

    testWidgets(
      'should_showLoadError_when_transactionsFail',
      (tester) async {
        when(mockTransactionRepo.getByMonth(any, any))
            .thenThrow(Exception('network'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Erreur de chargement'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showOverBudgetAmount_when_spentExceedsBudget',
      (tester) async {
        when(mockBudgetRepo.getOverview()).thenAnswer(
          (_) async => overviewWithCat1.copyWith(
            items: [
              overviewWithCat1.items.first.copyWith(
                montantDepense: 250,
                percentage: 125,
              ),
            ],
          ),
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('dépassement 50,00'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showRetry_when_overviewFails',
      (tester) async {
        when(mockBudgetRepo.getOverview()).thenThrow(Exception('network'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Réessayer'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showTranslatedTitle_when_overviewItemIsSystem',
      (tester) async {
        when(mockBudgetRepo.getOverview()).thenAnswer(
          (_) async => overviewWithCat1.copyWith(
            items: [
              overviewWithCat1.items.first.copyWith(
                categoryId: 'cat-sys',
                categoryNom: 'Subscription',
                categorySystemKey: 'SUBSCRIPTION',
              ),
            ],
          ),
        );

        await tester.pumpWidget(buildApp(categoryId: 'cat-sys'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Abonnement'), findsWidgets);
        expect(find.textContaining('Subscription'), findsNothing);
      },
    );

    testWidgets(
      'should_showTranslatedTitle_when_fallbackBudgetIsSystem',
      (tester) async {
        when(mockBudgetRepo.getOverview()).thenAnswer(
          (_) async => overviewWithCat1.copyWith(items: []),
        );
        when(
          mockBudgetRepo.getAll(includeInactive: anyNamed('includeInactive')),
        ).thenAnswer((_) async => [
                  const Budget(
                    id: 'b-sys',
                    categoryId: 'cat-sys',
                    montant: 100,
                    frequence: Frequency.mensuel,
                    currency: Currency.eur,
                    actif: false,
                    categoryNom: 'Debt',
                    categorySystemKey: 'DEBT',
                  ),
                ]);

        await tester.pumpWidget(buildApp(categoryId: 'cat-sys'));
        await tester.pumpAndSettle();
        // L'ecran ne charge que l'overview : le budget de repli vient de la
        // liste, chargee ici comme le fait l'ecran des budgets.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(BudgetDetailScreen)),
        );
        await container
            .read(budgetNotifierProvider.notifier)
            .loadItems(includeInactive: true);
        await tester.pumpAndSettle();

        expect(find.textContaining('Dette'), findsWidgets);
        expect(find.textContaining('Debt'), findsNothing);
      },
    );
  });
}
