import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_calculator.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCalculator(WidgetTester tester) => tester.pumpApp(
    const Scaffold(body: SingleChildScrollView(child: RateCalculator())),
  );

  Future<void> enterAmounts(WidgetTester tester, String from, String to) async {
    await tester.enterText(find.byType(TextField).first, from);
    await tester.enterText(find.byType(TextField).last, to);
    await tester.pump();
  }

  testWidgets('should_showTranslatedLabelsAndHint_when_rendered', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.text("J'ai"), findsOneWidget);
    expect(find.text('Devise'), findsNWidgets(2));
    expect(find.text('='), findsOneWidget);
    expect(
      find.text('Saisissez deux montants pour calculer le taux'),
      findsOneWidget,
    );
    expect(find.text('€ — Euro'), findsOneWidget);
    expect(find.text('CFA — Franc CFA (BCEAO)'), findsOneWidget);
  });

  testWidgets('should_showFormattedRate_when_bothAmountsAreValid', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await enterAmounts(tester, '1', '655.957');

    expect(find.text('Taux : 1 € = 655,957 CFA'), findsOneWidget);
    expect(
      find.text('Saisissez deux montants pour calculer le taux'),
      findsNothing,
    );
  });

  testWidgets('should_capRateAtSixDecimals_when_ratioIsNotExact', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await enterAmounts(tester, '3', '1');

    expect(find.text('Taux : 1 € = 0,333333 CFA'), findsOneWidget);
  });

  testWidgets('should_acceptCommaDecimal_when_typedWithComma', (tester) async {
    await pumpCalculator(tester);

    await enterAmounts(tester, '1', '1,5');

    expect(find.text('Taux : 1 € = 1,5 CFA'), findsOneWidget);
  });

  for (final (from, to) in [('0', '5'), ('5', '0'), ('', '5'), ('5', '')]) {
    testWidgets('should_showPrompt_when_amountsAre${from}And$to', (
      tester,
    ) async {
      await pumpCalculator(tester);

      await enterAmounts(tester, from, to);

      expect(
        find.text('Saisissez deux montants pour calculer le taux'),
        findsOneWidget,
      );
    });
  }

  testWidgets('should_resetResult_when_currencyChanges', (tester) async {
    await pumpCalculator(tester);
    await enterAmounts(tester, '1', '2');
    expect(find.text('Taux : 1 € = 2 CFA'), findsOneWidget);

    await tester.tap(find.text('€ — Euro'));
    await tester.pumpAndSettle();
    expect(find.text(r'$ — Dollar US'), findsOneWidget);
    await tester.tap(find.text(r'$ — Dollar US'));
    await tester.pumpAndSettle();

    expect(find.text(r'Taux : 1 $ = 2 CFA'), findsOneWidget);
  });
}
