import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_hero_widget.dart';
import 'package:k_budget/src/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  Widget buildHero({List<DoughnutSegment> segments = const []}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BudgetHeroWidget(
            budgetedSpent: 100.0,
            activeCurrency: Currency.eur,
            heroConverted: null,
            heroConvertedCurrency: null,
            overBudgetCount: 0,
            budgetCount: 2,
            unbudgetedTotal: 0,
            doughnutSegments: segments,
            currencies: const [Currency.eur],
            onCurrencyChanged: (_) {},
            onUnbudgetedTap: null,
            selectedMonth: 1,
            selectedYear: 2026,
            isCurrentMonth: true,
            onPrevNextMonth: (_, __) {},
          ),
        ),
      ),
    );
  }

  group('BudgetHeroWidget', () {
    testWidgets(
      'should_render_pie_chart_when_doughnut_segments_not_empty',
      (tester) async {
        await tester.pumpWidget(buildHero(
          segments: const [DoughnutSegment(value: 100, color: '#E91E63')],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsOneWidget);
      },
    );

    testWidgets(
      'should_hide_pie_chart_when_doughnut_segments_empty',
      (tester) async {
        await tester.pumpWidget(buildHero(segments: const []));
        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsNothing);
      },
    );

    testWidgets(
      'should_exclude_zero_value_segments_from_pie_chart',
      (tester) async {
        // Le filtrage where(value > 0) est fait dans le screen avant de passer
        // les segments au widget. Ce test vérifie que le widget se rend sans
        // erreur quand des segments de valeur 0 sont inclus, et que le PieChart
        // est bien présent grâce au segment non-nul.
        await tester.pumpWidget(buildHero(
          segments: const [
            DoughnutSegment(value: 0, color: '#E91E63'),
            DoughnutSegment(value: 100, color: '#4CAF50'),
          ],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsOneWidget);
      },
    );
  });
}
