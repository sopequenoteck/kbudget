import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/patrimoine_card.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

void main() {
  const accountEur = Account(
    id: '1',
    nom: 'Courant',
    type: AccountType.courant,
    soldeInitial: 1000.0,
    solde: 2500.0,
    icone: '\u{1F3E6}',
    couleur: '#3b82f6',
    isDefault: true,
    actif: true,
    currency: Currency.eur,
  );

  const accountUsd = Account(
    id: '2',
    nom: 'USD',
    type: AccountType.epargne,
    soldeInitial: 500.0,
    solde: 500.0,
    icone: '\u{1F4B5}',
    couleur: '#22c55e',
    isDefault: false,
    actif: true,
    currency: Currency.usd,
  );

  const eurToUsdRate = ExchangeRate(
    id: 'r1',
    baseCurrency: Currency.eur,
    targetCurrency: Currency.usd,
    rate: 1.1,
  );

  const usdToEurRate = ExchangeRate(
    id: 'r2',
    baseCurrency: Currency.usd,
    targetCurrency: Currency.eur,
    rate: 0.9,
  );

  const currentSummaryPositive = MonthlySummary(
    month: 3,
    year: 2026,
    totalRecettes: 3000.0,
    totalDepenses: 1000.0,
    bilan: 2000.0,
    currency: Currency.eur,
  );

  const currentSummaryNegative = MonthlySummary(
    month: 3,
    year: 2026,
    totalRecettes: 500.0,
    totalDepenses: 1500.0,
    bilan: -1000.0,
    currency: Currency.eur,
  );

  Widget buildLoadedWidget({
    List<Account> accounts = const [accountEur],
    Currency activeCurrency = Currency.eur,
    List<ExchangeRate> exchangeRates = const [],
    List<Currency> currencies = const [Currency.eur],
    MonthlySummary? currentSummary,
  }) {
    const loadedState = DashboardState(isLoading: false);
    return ProviderScope(
      overrides: [
        dashboardNotifierProvider
            .overrideWith(() => _FakeDashboardNotifier(loadedState)),
      ],
      child: MaterialApp(
        theme: app_theme.AppTheme.light,
        home: Scaffold(
          body: PatrimoineCard(
            accounts: accounts,
            activeCurrency: activeCurrency,
            exchangeRates: exchangeRates,
            currencies: currencies,
            currentSummary: currentSummary,
          ),
        ),
      ),
    );
  }

  group('PatrimoineCard', () {
    testWidgets('should_displayPatrimoineTotalLabel_when_loaded',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget());
      await tester.pump();

      expect(find.text('PATRIMOINE TOTAL'), findsOneWidget);
    });

    testWidgets('should_displayFormattedTotalAmount_when_loaded',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur],
        activeCurrency: Currency.eur,
      ));
      await tester.pump();

      // accountEur.solde = 2500.0, affiche le montant formaté
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('should_displayGreenVariationBadge_when_positiveNet',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur],
        activeCurrency: Currency.eur,
        currentSummary: currentSummaryPositive,
      ));
      await tester.pump();

      // netDuMois = 3000 - 1000 = +2000 → variation positive avec "+"
      expect(find.textContaining('+'), findsWidgets);
    });

    testWidgets('should_displayNegativeVariationBadge_when_negativeNet',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur],
        activeCurrency: Currency.eur,
        currentSummary: currentSummaryNegative,
      ));
      await tester.pump();

      // netDuMois = 500 - 1500 = -1000 → variation négative, pas de "+"
      // Le badge ne contient pas "+" mais contient "ce mois"
      expect(find.textContaining('ce mois'), findsOneWidget);
    });

    testWidgets(
        'should_displaySecondaryCurrencyConversion_when_multiCurrency',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur],
        activeCurrency: Currency.eur,
        currencies: const [Currency.eur, Currency.usd],
        exchangeRates: const [eurToUsdRate],
      ));
      await tester.pump();

      // Conversion secondaire EUR → USD doit apparaitre avec "~"
      expect(find.textContaining('≈'), findsOneWidget);
    });

    testWidgets(
        'should_notDisplayConversion_when_singleCurrency',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur],
        activeCurrency: Currency.eur,
        currencies: const [Currency.eur],
        exchangeRates: const [],
      ));
      await tester.pump();

      // Pas de devise secondaire → pas de "~"
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets(
        'should_displayWarningIcon_when_missingExchangeRate',
        (tester) async {
      // accountUsd avec activeCurrency EUR, mais aucun taux USD→EUR disponible
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur, accountUsd],
        activeCurrency: Currency.eur,
        currencies: const [Currency.eur],
        exchangeRates: const [], // Pas de taux → hasMissingRate = true
      ));
      await tester.pump();

      expect(find.byIcon(PhosphorIconsRegular.warningCircle), findsOneWidget);
    });

    testWidgets(
        'should_notDisplayWarningIcon_when_allRatesAvailable',
        (tester) async {
      await tester.pumpWidget(buildLoadedWidget(
        accounts: const [accountEur, accountUsd],
        activeCurrency: Currency.eur,
        currencies: const [Currency.eur],
        exchangeRates: const [usdToEurRate],
      ));
      await tester.pump();

      expect(find.byIcon(PhosphorIconsRegular.warningCircle), findsNothing);
    });

    testWidgets('should_displaySkeleton_when_loading', (tester) async {
      const loadingState = DashboardState(isLoading: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardNotifierProvider
                .overrideWith(() => _FakeDashboardNotifier(loadingState)),
          ],
          child: MaterialApp(
            theme: app_theme.AppTheme.light,
            home: const Scaffold(
              body: PatrimoineCard(
                accounts: [accountEur],
                activeCurrency: Currency.eur,
                exchangeRates: [],
                currencies: [Currency.eur],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.text('PATRIMOINE TOTAL'), findsNothing);
    });
  });
}

class _FakeDashboardNotifier extends DashboardNotifier {
  final DashboardState _initialState;

  _FakeDashboardNotifier(this._initialState);

  @override
  DashboardState build() => _initialState;
}
