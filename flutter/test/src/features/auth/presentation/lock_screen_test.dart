import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/auth/presentation/lock_screen.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/pin_pad.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:mockito/mockito.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../helpers/app_fonts.dart';
import '../../../../helpers/lock_test_helpers.dart';

void main() {
  late LockHarness harness;
  late ProviderContainer container;

  AppLockState lock() => container.read(appLockNotifierProvider);

  Future<void> pumpLockScreen(
    WidgetTester tester, {
    LockHarness? useHarness,
    double textScale = 1,
    ThemeData? theme,
  }) async {
    harness = useHarness ?? harness;
    container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    // The screen is only shown once the lock is known to be on.
    container.read(appLockNotifierProvider);
    await tester.pump();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme ?? app_theme.AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const LockScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump();
  }

  setUp(() => harness = LockHarness());

  group('LockScreen', () {
    testWidgets('should_showNameSubtitleAndPad_when_rendered', (tester) async {
      await pumpLockScreen(tester);

      expect(find.text('K-Budget'), findsOneWidget);
      expect(find.text('Saisissez votre PIN'), findsOneWidget);
      for (final digit in '0123456789'.split('')) {
        expect(find.text(digit), findsOneWidget);
      }
      expect(find.text('PIN oublié ?'), findsOneWidget);
    });

    testWidgets('should_haveNoButtonAndNoSystemKeyboard_when_rendered',
        (tester) async {
      await pumpLockScreen(tester);

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('should_unlockAtFourthDigit_when_pinRight', (tester) async {
      await pumpLockScreen(tester);

      await typePin(tester, '1234');

      expect(lock().status, LockStatus.unlocked);
    });

    testWidgets('should_notCheckPin_when_onlyThreeDigitsTyped',
        (tester) async {
      await pumpLockScreen(tester);

      await typePin(tester, '123');

      expect(lock().status, LockStatus.locked);
      expect(harness.repo.writes, 0);
      expect(find.textContaining('PIN incorrect'), findsNothing);
    });

    testWidgets('should_showAttemptsLeftAndEmptyDots_when_pinWrong',
        (tester) async {
      await pumpLockScreen(tester);

      await typePin(tester, '0000');

      expect(
        find.text('PIN incorrect. 4 essais restants'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('0 chiffre saisi sur 4'), findsOneWidget);
      expect(lock().status, LockStatus.locked);
    });

    testWidgets('should_showSingularAttempt_when_oneAttemptLeft',
        (tester) async {
      await pumpLockScreen(
        tester,
        useHarness: LockHarness(config: lockedConfig(failedPinAttempts: 3)),
      );

      await typePin(tester, '0000');

      expect(find.text('PIN incorrect. 1 essai restant'), findsOneWidget);
    });

    testWidgets('should_showMessageInExpenseColor_when_pinWrong',
        (tester) async {
      await pumpLockScreen(tester);

      await typePin(tester, '0000');

      final text = tester.widget<Text>(
        find.text('PIN incorrect. 4 essais restants'),
      );
      expect(
        text.style?.color,
        app_theme.AppTheme.light.extension<AppThemeExtension>()!.expenseColor,
      );
    });

    testWidgets('should_stayLockedAndReportError_when_attemptCannotBeSaved',
        (tester) async {
      await pumpLockScreen(tester);
      harness.repo.writeError = Exception('disk full');

      await typePin(tester, '0000');

      expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
      expect(lock().status, LockStatus.locked);
    });

    testWidgets('should_countOnce_when_digitsTypedWhileWrongPinIsChecked',
        (tester) async {
      await pumpLockScreen(tester);
      final gate = harness.repo.writeGate = Completer<void>();

      await typePin(tester, '0000');
      // The counter write is pending: these taps must not start a check.
      await typePin(tester, '00000');
      expect(harness.repo.writes, 1);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(harness.repo.config.failedPinAttempts, 1);
      expect(harness.repo.writes, 1);
      expect(find.text('PIN incorrect. 4 essais restants'), findsOneWidget);
    });

    testWidgets('should_acceptNewPin_when_wrongPinFollowedByRightOne',
        (tester) async {
      await pumpLockScreen(tester);

      await typePin(tester, '0000');
      await typePin(tester, '1234');

      expect(lock().status, LockStatus.unlocked);
      expect(harness.repo.config.failedPinAttempts, 0);
    });

    testWidgets('should_signOutAndResetLock_when_fifthWrongPin',
        (tester) async {
      await pumpLockScreen(tester);

      for (var i = 0; i < 5; i++) {
        await typePin(tester, '0000');
      }

      verify(harness.authRepo.logout()).called(1);
      expect(
        container.read(authNotifierProvider),
        const AuthState.unauthenticated(),
      );
      expect(harness.repo.config.lockEnabled, isFalse);
    });

    testWidgets('should_countDigitsOnly_when_digitsTyped', (tester) async {
      await pumpLockScreen(tester);

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();

      expect(find.bySemanticsLabel('2 chiffres saisis sur 4'), findsOneWidget);
      // Neither the digits nor the PIN are announced by the dots.
      expect(find.bySemanticsLabel('12'), findsNothing);
    });

    testWidgets('should_removeLastDigit_when_deleteTapped', (tester) async {
      await pumpLockScreen(tester);

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Effacer'));
      await tester.pump();

      expect(find.bySemanticsLabel('1 chiffre saisi sur 4'), findsOneWidget);
    });

    testWidgets('should_doNothing_when_deleteTappedOnEmptyPin',
        (tester) async {
      await pumpLockScreen(tester);

      await tester.tap(find.bySemanticsLabel('Effacer'));
      await tester.pump();

      expect(find.bySemanticsLabel('0 chiffre saisi sur 4'), findsOneWidget);
    });

    testWidgets('should_checkCorrectedPin_when_digitDeletedThenRetyped',
        (tester) async {
      await pumpLockScreen(tester);

      await typePin(tester, '12');
      await tester.tap(find.bySemanticsLabel('Effacer'));
      await tester.pump();
      await typePin(tester, '234');

      expect(lock().status, LockStatus.unlocked);
    });

    testWidgets('should_hideBiometricKey_when_biometricNotEnabled',
        (tester) async {
      await pumpLockScreen(tester);

      expect(find.bySemanticsLabel('Déverrouillage biométrique'), findsNothing);
      expect(harness.biometrics.authenticateCalls, 0);
    });

    testWidgets('should_askBiometricsOnDisplay_when_enabled', (tester) async {
      harness.repo.config = lockedConfig(method: LockMethod.biometric);
      harness.biometrics.succeeds = false;

      await pumpLockScreen(tester);
      await tester.pump();

      expect(harness.biometrics.authenticateCalls, 1);
      expect(
        find.bySemanticsLabel('Déverrouillage biométrique'),
        findsOneWidget,
      );
    });

    testWidgets('should_unlock_when_biometricsSucceedOnDisplay',
        (tester) async {
      harness.repo.config = lockedConfig(method: LockMethod.biometric);

      await pumpLockScreen(tester);
      await tester.pump();

      expect(lock().status, LockStatus.unlocked);
    });

    testWidgets('should_showErrorAndKeepPin_when_biometricsFail',
        (tester) async {
      harness.repo.config = lockedConfig(
        method: LockMethod.biometric,
        failedPinAttempts: 2,
      );
      harness.biometrics.succeeds = false;

      await pumpLockScreen(tester);
      await tester.pump();

      expect(
        find.text('Échec de la biométrie. Utilisez votre PIN.'),
        findsOneWidget,
      );
      expect(lock().status, LockStatus.locked);
      expect(harness.repo.config.failedPinAttempts, 2);

      await typePin(tester, '1234');
      expect(lock().status, LockStatus.unlocked);
    });

    testWidgets('should_askAgain_when_biometricKeyTapped', (tester) async {
      harness.repo.config = lockedConfig(method: LockMethod.biometric);
      harness.biometrics.succeeds = false;
      await pumpLockScreen(tester);
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Déverrouillage biométrique'));
      await tester.pump();

      expect(harness.biometrics.authenticateCalls, 2);
    });

    testWidgets('should_showFaceIcon_when_faceAvailable', (tester) async {
      harness = LockHarness(
        config: lockedConfig(method: LockMethod.biometric),
        kind: BiometricKind.face,
      )..biometrics.succeeds = false;

      await pumpLockScreen(tester);
      await tester.pump();

      bool isIcon(Widget widget, PhosphorIconData icon) =>
          widget is PhosphorIcon && widget.icon == icon;
      expect(
        find.byWidgetPredicate(
          (w) => isIcon(w, PhosphorIconsRegular.scanSmiley),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_showFingerprintIcon_when_noFace', (tester) async {
      harness.repo.config = lockedConfig(method: LockMethod.biometric);
      harness.biometrics.succeeds = false;

      await pumpLockScreen(tester);
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PhosphorIcon && w.icon == PhosphorIconsRegular.fingerprint,
        ),
        findsOneWidget,
      );
    });
  });

  group('forgot PIN', () {
    testWidgets('should_askConfirmation_when_forgotPinTapped', (tester) async {
      await pumpLockScreen(tester);

      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Vous serez déconnecté et le verrouillage sera désactivé. '
          'Reconnectez-vous avec votre mot de passe.',
        ),
        findsOneWidget,
      );
      expect(find.text('Déconnexion'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      verifyNever(harness.authRepo.logout());
    });

    testWidgets('should_keepLock_when_confirmationCancelled', (tester) async {
      await pumpLockScreen(tester);
      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(harness.authRepo.logout());
      expect(harness.repo.config.lockEnabled, isTrue);
      expect(lock().status, LockStatus.locked);
    });

    testWidgets('should_signOutAndResetLock_when_confirmed', (tester) async {
      await pumpLockScreen(tester);
      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Déconnexion'));
      await tester.pumpAndSettle();

      verify(harness.authRepo.logout()).called(1);
      expect(harness.repo.config.lockEnabled, isFalse);
      expect(harness.repo.config.hashedPin, isNull);
      expect(lock().status, LockStatus.unlocked);
    });

    testWidgets('should_showError_when_signOutFails', (tester) async {
      when(harness.authRepo.logout()).thenThrow(Exception('offline'));
      await pumpLockScreen(tester);
      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Déconnexion'));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
      expect(lock().status, LockStatus.locked);
      expect(harness.repo.config.lockEnabled, isTrue);
    });
  });

  group('LockScreen at 360 x 640', () {
    setUpAll(loadAppFonts);

    Future<void> pumpSmall(
      WidgetTester tester, {
      required double textScale,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpLockScreen(tester, textScale: textScale, theme: theme);
    }

    for (final scale in const [0.85, 1.0, 1.3]) {
      testWidgets('should_notOverflow_when_textScaleIs_$scale',
          (tester) async {
        await pumpSmall(tester, textScale: scale);
        await typePin(tester, '0000');

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('should_notOverflow_when_darkTheme', (tester) async {
      await pumpSmall(tester, textScale: 1.3, theme: app_theme.AppTheme.dark);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should_fitWithoutScrolling_when_defaultTextSize',
        (tester) async {
      await pumpSmall(tester, textScale: 1);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(LockScreen),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.maxScrollExtent, 0);
    });

    testWidgets('should_keepEveryKeyReachable_when_largestTextSize',
        (tester) async {
      await pumpSmall(tester, textScale: 1.3);

      await tester.ensureVisible(find.text('0'));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should_haveTouchTargetsOf48OrMore_when_rendered',
        (tester) async {
      await pumpSmall(tester, textScale: 1);

      final keys = tester.widgetList<InkWell>(
        find.descendant(
          of: find.byType(PinPad),
          matching: find.byType(InkWell),
        ),
      );
      expect(keys.length, 11);
      for (final key in find.descendant(
        of: find.byType(PinPad),
        matching: find.byType(InkWell),
      ).evaluate()) {
        final size = tester.getSize(find.byWidget(key.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      final forgot = tester.getSize(find.byType(TextButton));
      expect(forgot.height, greaterThanOrEqualTo(48));
    });
  });
}
