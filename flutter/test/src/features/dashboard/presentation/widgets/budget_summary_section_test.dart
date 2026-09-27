import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/budget_summary_section.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

class _TestBudgetNotifier extends BudgetNotifier {
  _TestBudgetNotifier(this.preloadedOverview);

  final BudgetOverview preloadedOverview;

  @override
  BudgetListState build() => BudgetListState(overview: preloadedOverview);
}

class _TestFeatureConfigNotifier extends FeatureConfigNotifier {
  @override
  FeatureConfigState build() =>
      const FeatureConfigState(enabledFeatures: [Feature.budgets]);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  const overview = BudgetOverview(
    month: '2026-03',
    totalBudget: 300,
    totalSpent: 120,
    percentage: 40,
    currency: 'EUR',
    items: [
      BudgetOverviewItem(
        budgetId: 'b1',
        categoryId: 'cat-1',
        categoryNom: 'Alimentation',
        categoryIcone: '🛒',
        categoryCouleur: '#4CAF50',
        montantBudget: 300,
        montantBudgetNormalise: 300,
        currency: 'EUR',
        montantDepense: 120,
        percentage: 40,
        frequence: 'MENSUEL',
      ),
    ],
  );

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        budgetNotifierProvider.overrideWith(() => _TestBudgetNotifier(overview)),
        featureConfigNotifierProvider.overrideWith(
          () => _TestFeatureConfigNotifier(),
        ),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const Scaffold(
          body: BudgetSummarySection(),
        ),
      ),
    );
  }

  group('BudgetSummarySection', () {
    testWidgets(
        'should_displayMonthHeaderAndFormattedTotals_when_overviewHasItems',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Budgets ·'), findsOneWidget);
      expect(find.textContaining('120,00'), findsWidgets);
      expect(find.textContaining('300,00'), findsWidgets);
      expect(find.text('Alimentation'), findsOneWidget);
    });
  });
}
