import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
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
    List<Currency> currencies = const [],
    bool isLoading = false,
    MonthlySummary? currentSummary,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: DashboardHeroWidget(
          accounts: accounts,
          activeCurrency: activeCurrency,
          exchangeRates: const [],
          currencies: currencies,
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

  testWidgets('should_showUppercaseNetWorthLabel_when_rendered',
      (tester) async {
    await pumpDashboardHero(
      tester,
      app_theme.AppTheme.light,
      accounts: const [accountPositive],
    );

    expect(find.text('PATRIMOINE TOTAL'), findsOneWidget);
  });

  testWidgets('should_showVariationWithPercentage_when_startOfMonthNonZero',
      (tester) async {
    // Patrimoine 1000, net du mois 300 : debut du mois 700, soit +42,9 %
    await pumpDashboardHero(
      tester,
      app_theme.AppTheme.light,
      accounts: const [accountPositive],
      currentSummary: summaryPositive,
    );

    final label = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((t) => t.contains('ce mois'));
    expect(label, startsWith('+'));
    expect(label, contains('300,00'));
    expect(label, matches(RegExp(r'\(\+42,9\s?%\)$')));
  });

  testWidgets('should_showVariationWithoutPercentage_when_startOfMonthZero',
      (tester) async {
    // Patrimoine 300, net du mois 300 : debut du mois a zero
    await pumpDashboardHero(
      tester,
      app_theme.AppTheme.light,
      accounts: const [
        Account(
          id: '3',
          nom: 'Courant',
          type: AccountType.courant,
          soldeInitial: 0,
          icone: '🏦',
          couleur: '#000',
          currency: Currency.eur,
          solde: 300.0,
        ),
      ],
      currentSummary: summaryPositive,
    );

    final label = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((t) => t.contains('ce mois'));
    expect(label, endsWith('ce mois'));
    expect(label, isNot(contains('%')));
  });

  testWidgets('should_showConversionTooltip_when_rateMissing',
      (tester) async {
    await pumpDashboardHero(
      tester,
      app_theme.AppTheme.light,
      accounts: const [
        Account(
          id: '4',
          nom: 'Compte US',
          type: AccountType.courant,
          soldeInitial: 0,
          icone: '🏦',
          couleur: '#000',
          currency: Currency.usd,
          solde: 100.0,
        ),
      ],
    );

    expect(
      find.byTooltip("Certains montants n'ont pas pu être convertis"),
      findsOneWidget,
    );
  });
}
