import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_form.dart';

import '../../../../../helpers/pump_app.dart';
import '../../exchange_rates_test_helpers.dart';

void main() {
  late FakeExchangeRateNotifier fake;
  late int saved;

  Future<void> pumpForm(
    WidgetTester tester, {
    bool editing = false,
    Exception? upsertError,
  }) async {
    fake = FakeExchangeRateNotifier(
      const ListState(),
      upsertError: upsertError,
    );
    saved = 0;
    await tester.pumpApp(
      Scaffold(
        body: SingleChildScrollView(
          child: RateForm(
            baseCurrency: Currency.eur,
            existingRate: editing ? rateOf(Currency.usd, 1.1) : null,
            onSaved: () => saved++,
          ),
        ),
      ),
      overrides: [exchangeRateListProvider.overrideWith(() => fake)],
    );
  }

  Future<void> submit(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField), value);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
  }

  testWidgets('should_showTranslatedLabels_when_rendered', (tester) async {
    await pumpForm(tester);

    expect(find.text('Devise de base'), findsOneWidget);
    expect(find.text('€ — Euro'), findsOneWidget);
    expect(find.text('Devise cible'), findsOneWidget);
    expect(find.text('Taux (1 € = X CFA)'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });

  testWidgets('should_prefillFixedParity_when_targetIsXof', (tester) async {
    await pumpForm(tester);

    expect(find.text('655.957'), findsOneWidget);
  });

  testWidgets('should_showPlaceholderAndPairLabel_when_targetHasNoParity', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('CFA — Franc CFA (BCEAO)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'$ — Dollar US'));
    await tester.pumpAndSettle();

    expect(find.text(r'Taux (1 € = X $)'), findsOneWidget);
    expect(find.text('Ex: 655.957'), findsOneWidget);
  });

  testWidgets('should_showRequiredError_when_rateIsEmpty', (tester) async {
    await pumpForm(tester);

    await submit(tester, '');

    expect(find.text('Ce champ est requis.'), findsOneWidget);
    expect(fake.upserted, isEmpty);
  });

  for (final value in ['0', '.']) {
    testWidgets('should_showInvalidError_when_rateIs$value', (tester) async {
      await pumpForm(tester);

      await submit(tester, value);

      expect(
        find.text('Veuillez saisir un taux valide (> 0).'),
        findsOneWidget,
      );
      expect(fake.upserted, isEmpty);
    });
  }

  testWidgets('should_upsertAndNotify_when_rateIsValid', (tester) async {
    await pumpForm(tester);

    await submit(tester, '1,25');
    await tester.pump();

    expect(fake.upserted, [(Currency.eur, Currency.xof, 1.25)]);
    expect(saved, 1);
  });

  testWidgets('should_showSaveErrorSnackbar_when_upsertThrows', (tester) async {
    await pumpForm(tester, upsertError: Exception('boom'));

    await submit(tester, '1.5');
    await tester.pump();

    expect(
      find.text("Erreur lors de l'enregistrement du taux."),
      findsOneWidget,
    );
    expect(saved, 0);
  });

  testWidgets('should_prefillRateAndDisableTarget_when_editing', (
    tester,
  ) async {
    await pumpForm(tester, editing: true);

    expect(find.text('1.1'), findsOneWidget);
    expect(find.text(r'$ — Dollar US'), findsOneWidget);
    expect(find.text(r'Taux (1 € = X $)'), findsOneWidget);
  });
}
