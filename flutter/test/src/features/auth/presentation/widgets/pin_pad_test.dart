import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/pin_pad.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:k_budget/src/theme/app_theme_extension.dart';

import '../../../../../helpers/app_fonts.dart';
import '../../../../../helpers/pump_app.dart';

void main() {
  group('PinPad', () {
    testWidgets('should_sendDigit_when_keyTapped', (tester) async {
      final digits = <String>[];
      await tester.pumpApp(PinPad(onDigit: digits.add, onDelete: () {}));

      for (final digit in '9051'.split('')) {
        await tester.tap(find.text(digit));
      }

      expect(digits, ['9', '0', '5', '1']);
    });

    testWidgets('should_callOnDelete_when_deleteTapped', (tester) async {
      var deleted = 0;
      await tester.pumpApp(PinPad(onDigit: (_) {}, onDelete: () => deleted++));

      await tester.tap(find.bySemanticsLabel('Effacer'));

      expect(deleted, 1);
    });

    testWidgets('should_leaveSlotEmpty_when_biometricNotGiven', (tester) async {
      await tester.pumpApp(PinPad(onDigit: (_) {}, onDelete: () {}));

      expect(find.bySemanticsLabel('Déverrouillage biométrique'), findsNothing);
      // 10 digits + delete.
      expect(find.byType(InkWell), findsNWidgets(11));
    });

    testWidgets('should_showBiometricKey_when_callbackGiven', (tester) async {
      var asked = 0;
      await tester.pumpApp(
        PinPad(onDigit: (_) {}, onDelete: () {}, onBiometric: () => asked++),
      );

      await tester.tap(find.bySemanticsLabel('Déverrouillage biométrique'));

      expect(asked, 1);
      expect(find.byType(InkWell), findsNWidgets(12));
    });

    testWidgets('should_placeBiometricKeyBottomLeft_when_shown', (
      tester,
    ) async {
      await tester.pumpApp(
        PinPad(onDigit: (_) {}, onDelete: () {}, onBiometric: () {}),
      );

      final biometric = tester.getCenter(
        find.bySemanticsLabel('Déverrouillage biométrique'),
      );
      final zero = tester.getCenter(find.text('0'));
      final seven = tester.getCenter(find.text('7'));
      final delete = tester.getCenter(find.bySemanticsLabel('Effacer'));

      expect(biometric.dy, zero.dy);
      expect(biometric.dx, lessThan(zero.dx));
      expect(delete.dx, greaterThan(zero.dx));
      expect(biometric.dx, seven.dx);
      expect(biometric.dy, greaterThan(seven.dy));
    });

    testWidgets('should_labelEveryKey_when_semanticsEnabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        PinPad(onDigit: (_) {}, onDelete: () {}, onBiometric: () {}),
      );

      for (final label in [
        ...'0123456789'.split(''),
        'Effacer',
        'Déverrouillage biométrique',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });

    testWidgets('should_useIconCircleBackground_when_rendered', (tester) async {
      await tester.pumpApp(PinPad(onDigit: (_) {}, onDelete: () {}));

      final key = tester.widget<Material>(
        find
            .ancestor(of: find.text('5'), matching: find.byType(Material))
            .first,
      );
      expect(
        key.color,
        app_theme.AppTheme.light.extension<AppThemeExtension>()!.iconCircleBg,
      );
    });
  });

  group('PinDots', () {
    testWidgets('should_announceCountOnly_when_digitsTyped', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const PinDots(filled: 3));

      expect(find.bySemanticsLabel('3 chiffres saisis sur 4'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('should_announceSingular_when_oneDigitTyped', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const PinDots(filled: 1));

      expect(find.bySemanticsLabel('1 chiffre saisi sur 4'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('should_drawFourDots_when_rendered', (tester) async {
      await tester.pumpApp(const PinDots(filled: 0));

      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('should_fillTypedDotsWithPrimary_when_digitsTyped', (
      tester,
    ) async {
      await tester.pumpApp(const PinDots(filled: 2));
      await tester.pumpAndSettle();

      final fills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      final primary = app_theme.AppTheme.light.colorScheme.primary;
      expect(fills, [primary, primary, Colors.transparent, Colors.transparent]);
    });
  });

  group('PinEntry', () {
    Future<void> tapDigits(WidgetTester tester, String digits) async {
      for (final digit in digits.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
    }

    testWidgets('should_callOnCompletedOnceWithPin_when_fourthDigitTyped', (
      tester,
    ) async {
      final pins = <String>[];
      await tester.pumpApp(PinEntry(onCompleted: (pin) async => pins.add(pin)));

      await tapDigits(tester, '4827');
      await tester.pump();

      expect(pins, ['4827']);
    });

    testWidgets('should_notCall_when_threeDigitsTyped', (tester) async {
      final pins = <String>[];
      await tester.pumpApp(PinEntry(onCompleted: (pin) async => pins.add(pin)));

      await tapDigits(tester, '482');

      expect(pins, isEmpty);
    });

    testWidgets('should_emptyDots_when_onCompletedReturns', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(PinEntry(onCompleted: (_) async {}));

      await tapDigits(tester, '1234');
      await tester.pump();

      expect(find.bySemanticsLabel('0 chiffre saisi sur 4'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('should_ignoreInput_when_validationRunning', (tester) async {
      final gate = Completer<void>();
      final pins = <String>[];
      await tester.pumpApp(
        PinEntry(
          onCompleted: (pin) {
            pins.add(pin);
            return gate.future;
          },
        ),
      );

      await tapDigits(tester, '1234');
      await tapDigits(tester, '5678');
      expect(pins, ['1234']);

      gate.complete();
      await tester.pump();
      await tapDigits(tester, '5678');
      await tester.pump();

      expect(pins, ['1234', '5678']);
    });

    testWidgets('should_ignoreDigit_when_fiveTypedWithoutValidation', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final gate = Completer<void>();
      await tester.pumpApp(PinEntry(onCompleted: (_) => gate.future));

      await tapDigits(tester, '12345');

      expect(find.bySemanticsLabel('4 chiffres saisis sur 4'), findsOneWidget);
      handle.dispose();
      gate.complete();
      await tester.pump();
    });

    testWidgets('should_showMessageInExpenseColor_when_messageGiven', (
      tester,
    ) async {
      await tester.pumpApp(
        PinEntry(onCompleted: (_) async {}, message: 'Les deux PIN diffèrent'),
      );

      final text = tester.widget<Text>(find.text('Les deux PIN diffèrent'));
      expect(
        text.style?.color,
        app_theme.AppTheme.light.extension<AppThemeExtension>()!.expenseColor,
      );
    });

    testWidgets('should_showNoMessage_when_messageNull', (tester) async {
      await tester.pumpApp(PinEntry(onCompleted: (_) async {}));

      expect(find.byType(Text), findsNWidgets(10));
    });

    testWidgets('should_showBiometricKey_when_callbackGiven', (tester) async {
      await tester.pumpApp(
        PinEntry(
          onCompleted: (_) async {},
          onBiometric: () {},
          biometricKind: BiometricKind.face,
        ),
      );

      expect(
        find.bySemanticsLabel('Déverrouillage biométrique'),
        findsOneWidget,
      );
    });

    testWidgets('should_dropState_when_disposedWhileValidating', (
      tester,
    ) async {
      final gate = Completer<void>();
      await tester.pumpApp(PinEntry(onCompleted: (_) => gate.future));
      await tapDigits(tester, '1234');

      await tester.pumpWidget(const SizedBox());
      gate.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('without the app theme extension', () {
    testWidgets('should_fallBackToColorScheme_when_extensionMissing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: PinEntry(onCompleted: (_) async {}, message: 'Erreur'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Erreur'));
      expect(text.style?.color, ThemeData().colorScheme.error);
      expect(tester.takeException(), isNull);
    });
  });

  group('diagnostics', () {
    test('should_describeProperties_when_widgetsAreInspected', () {
      expect(
        const PinDots(filled: 2).toDiagnosticsNode().toStringDeep(),
        contains('filled: 2'),
      );
      expect(
        PinPad(
          onDigit: (_) {},
          onDelete: () {},
          onBiometric: () {},
        ).toDiagnosticsNode().toStringDeep(),
        allOf(contains('onDigit'), contains('onBiometric')),
      );
      expect(
        PinEntry(
          onCompleted: (_) async {},
          message: 'Erreur',
        ).toDiagnosticsNode().toStringDeep(),
        allOf(contains('message: "Erreur"'), contains('onCompleted')),
      );
    });
  });

  group('PinEntry at 360 px', () {
    setUpAll(loadAppFonts);

    for (final scale in const [1.0, 1.3]) {
      testWidgets('should_notOverflow_when_textScaleIs_$scale', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpApp(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(
              child: PinEntry(
                onCompleted: (_) async {},
                message: 'PIN incorrect. 4 essais restants',
                onBiometric: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(PinPad)).width,
          lessThanOrEqualTo(360),
        );
      });
    }
  });
}
