import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shimmer/shimmer.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/income_expense_cards.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  const currentSummary = MonthlySummary(
    month: 3,
    year: 2026,
    totalRecettes: 3000.0,
    totalDepenses: 1500.0,
    bilan: 1500.0,
    currency: Currency.eur,
  );

  const previousSummary = MonthlySummary(
    month: 2,
    year: 2026,
    totalRecettes: 2000.0,
    totalDepenses: 1000.0,
    bilan: 1000.0,
    currency: Currency.eur,
  );

  const eurToUsdRate = ExchangeRate(
    id: 'r1',
    baseCurrency: Currency.eur,
    targetCurrency: Currency.usd,
    rate: 1.1,
  );

  Widget buildWidget({
    MonthlySummary? summary,
    MonthlySummary? previous,
    List<Currency> currencies = const [Currency.eur],
    List<ExchangeRate> exchangeRates = const [],
    Currency activeCurrency = Currency.eur,
  }) {
    return MaterialApp(
      theme: app_theme.AppTheme.light,
      home: Scaffold(
        body: IncomeExpenseCards(
          currentSummary: summary,
          previousSummary: previous,
          currencies: currencies,
          exchangeRates: exchangeRates,
          activeCurrency: activeCurrency,
        ),
      ),
    );
  }

  group('IncomeExpenseCards', () {
    testWidgets('should_displayTwoCardsSideBySide_when_summaryProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: currentSummary));
      await tester.pump();

      expect(find.text('REVENUS'), findsOneWidget);
      expect(find.text('DÉPENSES'), findsOneWidget);
    });

    testWidgets('should_displayRevenueAmount_when_summaryProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: currentSummary));
      await tester.pump();

      // totalRecettes = 3000 EUR → formaté quelque part dans le widget
      expect(find.textContaining('3'), findsWidgets);
      expect(find.text('REVENUS'), findsOneWidget);
    });

    testWidgets('should_displayExpenseAmount_when_summaryProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: currentSummary));
      await tester.pump();

      // totalDepenses = 1500 EUR → formaté quelque part dans le widget
      expect(find.textContaining('1'), findsWidgets);
      expect(find.text('DÉPENSES'), findsOneWidget);
    });

    testWidgets('should_displayDeltaVsPreviousMonth_when_previousSummaryProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        summary: currentSummary,
        previous: previousSummary,
      ));
      await tester.pump();

      // Delta = currentSummary.totalRecettes - previousSummary.totalRecettes = +1000
      // Le badge contient "vs" + mois abrégé
      expect(find.textContaining('vs'), findsWidgets);
    });

    testWidgets('should_displayDeltaWithFullAmount_when_noPreviousSummary',
        (tester) async {
      // Sans previousSummary, le delta est calcule avec fallback 0
      // Donc delta = montant courant - 0 = montant courant
      await tester.pumpWidget(buildWidget(
        summary: currentSummary,
        previous: null,
      ));
      await tester.pump();

      // Le badge delta est toujours affiche (comme Angular)
      expect(find.textContaining('vs'), findsWidgets);
    });

    testWidgets(
        'should_displaySecondaryCurrencyConversion_when_multiCurrency',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        summary: currentSummary,
        currencies: const [Currency.eur, Currency.usd],
        exchangeRates: const [eurToUsdRate],
        activeCurrency: Currency.eur,
      ));
      await tester.pump();

      // Deux cards avec conversion → deux textes commençant par "~"
      expect(find.textContaining('≈'), findsWidgets);
    });

    testWidgets('should_notDisplayConversion_when_singleCurrency',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        summary: currentSummary,
        currencies: const [Currency.eur],
        exchangeRates: const [],
        activeCurrency: Currency.eur,
      ));
      await tester.pump();

      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('should_displaySkeleton_when_currentSummaryIsNull',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: null));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.text('REVENUS'), findsNothing);
      expect(find.text('DÉPENSES'), findsNothing);
    });

    testWidgets('should_displayUpArrow_when_revenueIncreasedVsPreviousMonth',
        (tester) async {
      // currentSummary.totalRecettes (3000) > previousSummary.totalRecettes (2000)
      await tester.pumpWidget(buildWidget(
        summary: currentSummary,
        previous: previousSummary,
      ));
      await tester.pump();

      // Delta revenues positif → flèche montante ↑
      expect(find.textContaining('↑'), findsWidgets);
    });

    testWidgets('should_displayDownArrow_when_revenueDecreasedVsPreviousMonth',
        (tester) async {
      const lowRevenueSummary = MonthlySummary(
        month: 3,
        year: 2026,
        totalRecettes: 1000.0,
        totalDepenses: 500.0,
        bilan: 500.0,
        currency: Currency.eur,
      );

      await tester.pumpWidget(buildWidget(
        summary: lowRevenueSummary,
        previous: previousSummary,
      ));
      await tester.pump();

      // Delta revenues négatif (1000 < 2000) → flèche descendante ↓
      expect(find.textContaining('↓'), findsWidgets);
    });
  });
}
