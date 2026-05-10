import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/debts/application/debt_list_state.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/debt_hero_widget.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

import '../../../../../helpers/theme_test_helpers.dart';

void main() {
  // summary net positif : totalPrets (200) > totalEmprunts (50) → net = +150
  const summaryNetPositive = {
    Currency.eur: (totalEmprunts: 50.0, totalPrets: 200.0),
  };

  // summary net négatif : totalPrets (50) < totalEmprunts (200) → net = -150
  const summaryNetNegative = {
    Currency.eur: (totalEmprunts: 200.0, totalPrets: 50.0),
  };

  Future<void> pumpDebtHero(
    WidgetTester tester,
    ThemeData theme, {
    Map<Currency, DebtCurrencySummary> summary = const {},
    int enCours = 0,
    bool isLoading = false,
    Currency? primaryCurrency,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: DebtHeroWidget(
          summary: summary,
          enCours: enCours,
          isLoading: isLoading,
          primaryCurrency: primaryCurrency,
        ),
      ),
    ));
  }

  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_key_debt_hero_when_not_loading_$themeName',
      (tester) async {
        await pumpDebtHero(
          tester,
          theme,
          summary: summaryNetPositive,
          enCours: 1,
          isLoading: false,
        );

        expect(find.byKey(const Key('debt_hero')), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_skeleton_key_when_loading_$themeName',
      (tester) async {
        await pumpDebtHero(
          tester,
          theme,
          summary: summaryNetPositive,
          isLoading: true,
        );

        expect(
          find.byKey(const Key('debt_hero_skeleton')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('debt_hero')), findsNothing);
      },
    );

    testWidgets(
      'should_render_shrink_when_summary_empty_$themeName',
      (tester) async {
        await pumpDebtHero(
          tester,
          theme,
          summary: const {},
          isLoading: false,
        );

        // summary vide + pas de loading → SizedBox.shrink()
        expect(find.byKey(const Key('debt_hero')), findsNothing);
        expect(find.byKey(const Key('debt_hero_skeleton')), findsNothing);
        expect(find.byType(SizedBox), findsWidgets);
      },
    );

    testWidgets(
      'should_show_income_color_when_net_positive_$themeName',
      (tester) async {
        // net = totalPrets (200) - totalEmprunts (50) = +150 > 0 → incomeColor
        await pumpDebtHero(
          tester,
          theme,
          summary: summaryNetPositive,
          isLoading: false,
        );

        final expectedColor = theme.extension<AppThemeExtension>()!.incomeColor;
        final texts = tester.widgetList<Text>(find.byType(Text));
        final netText = texts.firstWhere(
          (t) => t.style?.color == expectedColor,
          orElse: () => throw TestFailure(
            'Aucun Text avec incomeColor ($expectedColor) trouvé pour $themeName',
          ),
        );
        expect(netText.style?.color, expectedColor);
      },
    );

    testWidgets(
      'should_show_expense_color_when_net_negative_$themeName',
      (tester) async {
        // net = totalPrets (50) - totalEmprunts (200) = -150 < 0 → expenseColor
        await pumpDebtHero(
          tester,
          theme,
          summary: summaryNetNegative,
          isLoading: false,
        );

        final expectedColor =
            theme.extension<AppThemeExtension>()!.expenseColor;
        final texts = tester.widgetList<Text>(find.byType(Text));
        final netText = texts.firstWhere(
          (t) => t.style?.color == expectedColor,
          orElse: () => throw TestFailure(
            'Aucun Text avec expenseColor ($expectedColor) trouvé pour $themeName',
          ),
        );
        expect(netText.style?.color, expectedColor);
      },
    );
  });
}
