import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_hero_widget.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

import '../../../../../helpers/theme_test_helpers.dart';

void main() {
  const summaryPositive = MonthlySummary(
    month: 1,
    year: 2026,
    totalRecettes: 500,
    totalDepenses: 200,
    bilan: 300,
    currency: Currency.eur,
  );

  const summaryNegative = MonthlySummary(
    month: 1,
    year: 2026,
    totalRecettes: 100,
    totalDepenses: 300,
    bilan: -200,
    currency: Currency.eur,
  );

  Future<void> pumpTransactionHero(
    WidgetTester tester,
    ThemeData theme, {
    MonthlySummary? summary,
    Currency? primaryCurrency,
    bool isLoading = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: TransactionHeroWidget(
          summary: summary,
          primaryCurrency: primaryCurrency,
          isLoading: isLoading,
        ),
      ),
    ));
  }

  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_key_transaction_hero_when_not_loading_$themeName',
      (tester) async {
        await pumpTransactionHero(
          tester,
          theme,
          summary: summaryPositive,
          isLoading: false,
        );

        expect(find.byKey(const Key('transaction_hero')), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_skeleton_key_when_loading_$themeName',
      (tester) async {
        await pumpTransactionHero(
          tester,
          theme,
          isLoading: true,
        );

        expect(
          find.byKey(const Key('transaction_hero_skeleton')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('transaction_hero')), findsNothing);
      },
    );

    testWidgets(
      'should_show_income_color_when_bilan_positive_$themeName',
      (tester) async {
        // bilan = 500 - 200 = 300 >= 0 → incomeColor
        await pumpTransactionHero(
          tester,
          theme,
          summary: summaryPositive,
          isLoading: false,
        );

        final expectedColor = theme.extension<AppThemeExtension>()!.incomeColor;
        final texts = tester.widgetList<Text>(find.byType(Text));
        final bilanText = texts.firstWhere(
          (t) => t.style?.color == expectedColor,
          orElse: () => throw TestFailure(
            'Aucun Text avec incomeColor ($expectedColor) trouvé pour $themeName',
          ),
        );
        expect(bilanText.style?.color, expectedColor);
      },
    );

    testWidgets(
      'should_show_expense_color_when_bilan_negative_$themeName',
      (tester) async {
        // bilan = 100 - 300 = -200 < 0 → expenseColor
        await pumpTransactionHero(
          tester,
          theme,
          summary: summaryNegative,
          isLoading: false,
        );

        final expectedColor =
            theme.extension<AppThemeExtension>()!.expenseColor;
        final texts = tester.widgetList<Text>(find.byType(Text));
        final bilanText = texts.firstWhere(
          (t) => t.style?.color == expectedColor,
          orElse: () => throw TestFailure(
            'Aucun Text avec expenseColor ($expectedColor) trouvé pour $themeName',
          ),
        );
        expect(bilanText.style?.color, expectedColor);
      },
    );
  });
}
