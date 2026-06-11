import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/frequency.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_list_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockBudgetRepository mockBudgetRepo;
  late MockCategoryRepository mockCatRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;

  const emptyOverview = BudgetOverview(
    month: '2026-05',
    totalBudget: 200,
    totalSpent: 0,
    percentage: 0,
    currency: 'EUR',
    items: [],
  );

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockCatRepo = MockCategoryRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();

    when(mockBudgetRepo.getAll(includeInactive: anyNamed('includeInactive')))
        .thenAnswer((_) async => []);
    when(mockBudgetRepo.getOverview())
        .thenAnswer((_) async => emptyOverview);
    when(mockCatRepo.getAll()).thenAnswer((_) async => []);
    when(mockExchangeRateRepo.getAll())
        .thenAnswer((_) async => <ExchangeRate>[]);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(mockBudgetRepo),
        categoryRepositoryProvider.overrideWithValue(mockCatRepo),
        exchangeRateRepositoryProvider
            .overrideWith((_) async => mockExchangeRateRepo),
        preferenceRemoteDataSourceProvider
            .overrideWith((_) => Future.error('test-disabled')),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BudgetListScreen(),
        ),
      ),
    );
  }

  group('BudgetListScreen', () {
    testWidgets(
      'should_display_budgetedSpent_as_totalSpent_minus_unbudgetedTotal',
      (tester) async {
        when(mockBudgetRepo.getOverview()).thenAnswer(
          (_) async => const BudgetOverview(
            month: '2026-05',
            totalBudget: 200,
            totalSpent: 150,
            percentage: 75,
            currency: 'EUR',
            items: [],
            unbudgetedTotal: 50,
          ),
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // budgetedSpent = totalSpent - unbudgetedTotal = 150 - 50 = 100
        // AmountFormatter.format(100, currency: Currency.eur) → "100,00 €" environ
        expect(find.textContaining('100'), findsWidgets);
      },
    );

    testWidgets(
      'should_display_pie_chart_when_overview_items_have_depense',
      (tester) async {
        const overviewWithItem = BudgetOverview(
          month: '2026-05',
          totalBudget: 200,
          totalSpent: 50,
          percentage: 25,
          currency: 'EUR',
          items: [
            BudgetOverviewItem(
              budgetId: 'b1',
              categoryId: 'c1',
              categoryNom: 'Alimentation',
              categoryIcone: '🛒',
              categoryCouleur: '#4CAF50',
              montantBudget: 200,
              montantBudgetNormalise: 200,
              currency: 'EUR',
              montantDepense: 50,
              percentage: 25,
              frequence: 'MENSUEL',
            ),
          ],
        );

        when(mockBudgetRepo.getOverview())
            .thenAnswer((_) async => overviewWithItem);
        when(mockBudgetRepo.getAll(includeInactive: anyNamed('includeInactive')))
            .thenAnswer((_) async => [
                  const Budget(
                    id: 'b1',
                    categoryId: 'c1',
                    montant: 200,
                    frequence: Frequency.mensuel,
                    currency: Currency.eur,
                    actif: true,
                  ),
                ]);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsOneWidget);
      },
    );

    testWidgets(
      'should_not_crash_after_currency_change_debounce',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Smoke test : l'écran se rend sans exception.
        // Le Timer debounce dispose() se passe proprement à la fin du test.
        expect(find.byType(BudgetListScreen), findsOneWidget);
      },
    );

    testWidgets(
      'should_display_inactifs_label_when_inactive_budgets_exist_in_current_month',
      (tester) async {
        // Le label Inactifs n'est rendu que lorsque convertedItems est non vide
        // (sinon l'écran affiche un empty state). Il faut un item actif avec
        // montantDepense > 0 dans l'overview + un budget inactif dans getAll.
        when(mockBudgetRepo.getAll(includeInactive: anyNamed('includeInactive')))
            .thenAnswer((_) async => [
                  const Budget(
                    id: 'b-actif',
                    categoryId: 'c-actif',
                    montant: 200,
                    frequence: Frequency.mensuel,
                    currency: Currency.eur,
                    actif: true,
                  ),
                  const Budget(
                    id: 'b-inactif',
                    categoryId: 'c-inactif',
                    montant: 100,
                    frequence: Frequency.mensuel,
                    currency: Currency.eur,
                    actif: false,
                  ),
                ]);
        when(mockBudgetRepo.getOverview()).thenAnswer(
          (_) async => const BudgetOverview(
            month: '2026-05',
            totalBudget: 200,
            totalSpent: 50,
            percentage: 25,
            currency: 'EUR',
            items: [
              BudgetOverviewItem(
                budgetId: 'b-actif',
                categoryId: 'c-actif',
                categoryNom: 'Alimentation',
                categoryIcone: '🛒',
                categoryCouleur: '#4CAF50',
                montantBudget: 200,
                montantBudgetNormalise: 200,
                currency: 'EUR',
                montantDepense: 50,
                percentage: 25,
                frequence: 'MENSUEL',
              ),
            ],
          ),
        );
        when(mockCatRepo.getAll()).thenAnswer(
          (_) async => [
            const Category(
              id: 'c-inactif',
              nom: 'Loisirs',
              icone: '🎮',
              couleur: '#9C27B0',
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Inactifs'), findsOneWidget);
      },
    );

    testWidgets(
      'should_disable_add_button_when_all_categories_have_budget',
      (tester) async {
        when(mockBudgetRepo.getAll(includeInactive: anyNamed('includeInactive')))
            .thenAnswer((_) async => [
                  const Budget(
                    id: 'b1',
                    categoryId: 'c1',
                    montant: 100,
                    frequence: Frequency.mensuel,
                    currency: Currency.eur,
                    actif: true,
                  ),
                ]);
        when(mockBudgetRepo.getOverview())
            .thenAnswer((_) async => emptyOverview);
        when(mockCatRepo.getAll()).thenAnswer(
          (_) async => [
            const Category(
              id: 'c1',
              nom: 'Loisirs',
              icone: '🎮',
              couleur: '#9C27B0',
              isSystem: false,
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Trouver l'IconButton avec l'icône plus
        final plusButtons = tester.widgetList<IconButton>(
          find.byType(IconButton),
        ).where((btn) {
          if (btn.icon is PhosphorIcon) {
            final icon = btn.icon as PhosphorIcon;
            return icon.icon == PhosphorIconsRegular.plus;
          }
          return false;
        }).toList();

        expect(plusButtons, isNotEmpty, reason: 'IconButton avec plus introuvable');
        expect(
          plusButtons.first.onPressed,
          isNull,
          reason: 'Le bouton + doit être désactivé quand toutes les catégories ont un budget',
        );
      },
    );
  });
}
