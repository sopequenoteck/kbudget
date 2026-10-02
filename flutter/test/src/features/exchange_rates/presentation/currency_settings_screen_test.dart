import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/currency_settings_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../helpers/pump_app.dart';
import '../exchange_rates_test_helpers.dart';

void main() {
  late FakeExchangeRateNotifier rates;
  late FakeCurrencyConfigNotifier currencies;

  Future<void> pumpScreen(
    WidgetTester tester, {
    ListState<ExchangeRate> ratesState = const ListState(),
    List<Currency> configured = const [Currency.eur, Currency.usd],
    List<Account> accounts = const [],
  }) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    rates = FakeExchangeRateNotifier(ratesState);
    currencies = FakeCurrencyConfigNotifier(configured);
    await tester.pumpApp(
      const CurrencySettingsScreen(),
      overrides: [
        exchangeRateListProvider.overrideWith(() => rates),
        currencyConfigNotifierProvider.overrideWith(() => currencies),
        accountNotifierProvider.overrideWith(
          () => FakeAccountNotifier(accounts),
        ),
      ],
    );
    await tester.pump();
  }

  group('etat de la liste', () {
    testWidgets('should_showTitlesAndSections_when_rendered', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Devises & Taux'), findsOneWidget);
      expect(find.text('MES DEVISES'), findsOneWidget);
      expect(find.text('TAUX DE CONVERSION'), findsOneWidget);
      expect(find.text('CALCULATEUR'), findsOneWidget);
    });

    testWidgets('should_showSpinner_when_loading', (tester) async {
      await pumpScreen(tester, ratesState: const ListState(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_showErrorWithoutPrefix_when_stateHasError', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        ratesState: const ListState(
          error: 'Impossible de charger les taux de change',
        ),
      );

      expect(
        find.text('Impossible de charger les taux de change'),
        findsOneWidget,
      );
      expect(find.textContaining('Erreur :'), findsNothing);
    });

    testWidgets('should_showEmptyTitle_when_noRate', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Aucun taux configuré'), findsOneWidget);
    });

    testWidgets('should_showFormattedRates_when_ratesExist', (tester) async {
      await pumpScreen(
        tester,
        ratesState: ListState(
          items: [rateOf(Currency.xof, 655.957), rateOf(Currency.usd, 1.1)],
        ),
      );

      expect(find.text('EUR → XOF'), findsOneWidget);
      expect(find.text('655,957'), findsOneWidget);
      expect(find.text('1,1'), findsOneWidget);
      expect(find.byTooltip('Modifier'), findsNWidgets(2));
      expect(find.byTooltip('Supprimer'), findsNWidgets(2));
    });
  });

  group('devises', () {
    testWidgets('should_showPrimaryChipAndSubtitle_when_firstCurrency', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Principale'), findsOneWidget);
      expect(find.text('Principale • Euro'), findsOneWidget);
      expect(find.text('Dollar US'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('should_confirmUnusedRemoval_when_noActiveAccount', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Supprimer cette devise'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer USD ?'), findsOneWidget);
      expect(find.text('Retirer USD de vos devises ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);

      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();
      expect(currencies.removed, [Currency.usd]);
    });

    testWidgets('should_warnUsedCurrency_when_activeAccountUsesIt', (
      tester,
    ) async {
      await pumpScreen(tester, accounts: [accountIn(Currency.usd)]);

      await tester.tap(find.byTooltip('Supprimer cette devise'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'La devise USD est utilisée par des comptes existants. '
          'Retirer quand même ?',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_notRemove_when_removalCancelled', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Supprimer cette devise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(currencies.removed, isEmpty);
    });

    testWidgets('should_treatInactiveAccountAsUnused_when_removing', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        accounts: [accountIn(Currency.usd, actif: false)],
      );

      await tester.tap(find.byTooltip('Supprimer cette devise'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer USD de vos devises ?'), findsOneWidget);
    });
  });

  group('ajout de devise', () {
    Future<void> tapAdd(WidgetTester tester, int index) async {
      await tester.tap(find.byIcon(PhosphorIconsRegular.plus).at(index));
      await tester.pumpAndSettle();
    }

    testWidgets('should_listAvailableCurrenciesWithNames_when_addingCurrency', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tapAdd(tester, 0);

      expect(find.text('Ajouter une devise'), findsOneWidget);
      expect(find.text('Franc CFA (BCEAO)'), findsOneWidget);
      expect(find.text('Livre sterling'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);
    });

    testWidgets('should_addCurrency_when_itemTapped', (tester) async {
      await pumpScreen(tester);

      await tapAdd(tester, 0);
      await tester.tap(find.text('GBP'));
      await tester.pumpAndSettle();

      expect(currencies.added, [Currency.gbp]);
    });

    testWidgets('should_doNothing_when_allCurrenciesConfigured', (
      tester,
    ) async {
      await pumpScreen(tester, configured: Currency.values);

      await tapAdd(tester, 0);

      expect(find.text('Ajouter une devise'), findsNothing);
    });
  });

  group('taux', () {
    final listed = ListState(items: [rateOf(Currency.usd, 1.1)]);

    testWidgets('should_confirmRateDeletion_when_deleteTapped', (tester) async {
      await pumpScreen(tester, ratesState: listed);

      await tester.tap(find.byTooltip('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('EUR → USD'), findsNWidgets(2));
      expect(find.text('Supprimer le taux EUR → USD ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();
      expect(rates.deleted, [(Currency.eur, Currency.usd)]);
    });

    testWidgets('should_notDelete_when_deletionCancelled', (tester) async {
      await pumpScreen(tester, ratesState: listed);

      await tester.tap(find.byTooltip('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(rates.deleted, isEmpty);
    });

    testWidgets('should_openAddForm_when_addRateTapped', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(PhosphorIconsRegular.plus).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter un taux'), findsOneWidget);
      expect(find.text('Devise de base'), findsOneWidget);
    });

    testWidgets('should_openEditForm_when_editTapped', (tester) async {
      await pumpScreen(tester, ratesState: listed);

      await tester.tap(find.byTooltip('Modifier'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le taux'), findsOneWidget);
      expect(find.text('1.1'), findsOneWidget);
    });
  });
}
