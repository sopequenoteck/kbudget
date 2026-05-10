import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

import '../../../../../helpers/theme_test_helpers.dart';

void main() {
  const accountPositive = Account(
    id: '1',
    nom: 'Courant',
    type: AccountType.courant,
    soldeInitial: 0,
    icone: '🏦',
    couleur: '#000',
    currency: Currency.eur,
    solde: 1000.0,
  );

  const accountNegative = Account(
    id: '2',
    nom: 'Courant négatif',
    type: AccountType.courant,
    soldeInitial: 0,
    icone: '🏦',
    couleur: '#000',
    currency: Currency.eur,
    solde: -500.0,
  );

  const summaryPositive = MonthlySummary(
    month: 1,
    year: 2026,
    totalRecettes: 500,
    totalDepenses: 200,
    bilan: 300,
    currency: Currency.eur,
  );

  Future<void> pumpDashboardHero(
    WidgetTester tester,
    ThemeData theme, {
    List<Account> accounts = const [],
    Currency activeCurrency = Currency.eur,
    bool isLoading = false,
    MonthlySummary? currentSummary,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: DashboardHeroWidget(
          accounts: accounts,
          activeCurrency: activeCurrency,
          exchangeRates: const [],
          currencies: const [],
          isLoading: isLoading,
          currentSummary: currentSummary,
        ),
      ),
    ));
  }

  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_key_dashboard_hero_when_not_loading_$themeName',
      (tester) async {
        await pumpDashboardHero(
          tester,
          theme,
          accounts: const [accountPositive],
          isLoading: false,
        );

        expect(find.byKey(const Key('dashboard_hero')), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_skeleton_key_when_loading_$themeName',
      (tester) async {
        await pumpDashboardHero(
          tester,
          theme,
          accounts: const [accountPositive],
          isLoading: true,
        );

        expect(
          find.byKey(const Key('dashboard_hero_skeleton')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('dashboard_hero')), findsNothing);
      },
    );

    testWidgets(
      'should_show_income_color_when_patrimoine_positive_$themeName',
      (tester) async {
        await pumpDashboardHero(
          tester,
          theme,
          accounts: const [accountPositive],
          isLoading: false,
          currentSummary: summaryPositive,
        );

        // Le Text du montant patrimoine est le premier Text avec couleur
        // patrimoineTotal = 1000 >= 0 → incomeColor
        final expectedColor = theme.extension<AppThemeExtension>()!.incomeColor;

        // Trouver le Text qui affiche le montant (premier grand texte coloré)
        final texts = tester.widgetList<Text>(find.byType(Text));
        final amountText = texts.firstWhere(
          (t) => t.style?.color == expectedColor,
          orElse: () => throw TestFailure(
            'Aucun Text avec incomeColor ($expectedColor) trouvé pour $themeName',
          ),
        );
        expect(amountText.style?.color, expectedColor);
      },
    );

    testWidgets(
      'should_show_expense_color_when_patrimoine_negative_$themeName',
      (tester) async {
        await pumpDashboardHero(
          tester,
          theme,
          accounts: const [accountNegative],
          isLoading: false,
        );

        // patrimoineTotal = -500 < 0 → expenseColor
        final expectedColor = theme.extension<AppThemeExtension>()!.expenseColor;

        final texts = tester.widgetList<Text>(find.byType(Text));
        final amountText = texts.firstWhere(
          (t) => t.style?.color == expectedColor,
          orElse: () => throw TestFailure(
            'Aucun Text avec expenseColor ($expectedColor) trouvé pour $themeName',
          ),
        );
        expect(amountText.style?.color, expectedColor);
      },
    );
  });
}
