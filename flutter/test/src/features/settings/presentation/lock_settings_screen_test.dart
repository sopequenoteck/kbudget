import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/application/pin_hashing.dart';
import 'package:k_budget/src/features/settings/presentation/lock_pin_screen.dart';
import 'package:k_budget/src/features/settings/presentation/lock_settings_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../helpers/app_fonts.dart';
import '../../../../helpers/lock_test_helpers.dart';

void main() {
  late LockHarness harness;
  late ProviderContainer container;
  late GoRouter router;

  AppLockState lock() => container.read(appLockNotifierProvider);

  Future<void> pumpSettings(
    WidgetTester tester, {
    LockHarness? useHarness,
    double textScale = 1,
  }) async {
    harness = useHarness ?? harness;
    container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    container.read(appLockNotifierProvider);
    await tester.pump();
    // The settings are only reachable once unlocked.
    await container.read(appLockNotifierProvider.notifier).unlockAfterLogin();
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Hub')),
          routes: [
            GoRoute(
              path: 'lock',
              builder: (context, state) => const LockSettingsScreen(),
              routes: [
                GoRoute(
                  path: 'pin/:flow',
                  builder: (context, state) => LockPinScreen(
                    flow: LockPinFlow.values.byName(
                      state.pathParameters['flow']!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: app_theme.AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push('/settings/lock'));
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Finder lockSwitch() => find.descendant(
    of: find.widgetWithText(SwitchListTile, 'Verrouiller l\'application'),
    matching: find.byType(Switch),
  );

  setUp(() => harness = LockHarness(config: lockedConfig()));

  group('LockSettingsScreen with the lock off', () {
    setUp(() => harness = LockHarness(config: const AppConfig()));

    testWidgets('should_showSwitchAndNote_when_lockDisabled', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Verrouillage'), findsOneWidget);
      expect(find.text('Verrouiller l\'application'), findsOneWidget);
      expect(
        find.text('PIN demandé au lancement et après 1 minute d\'absence'),
        findsOneWidget,
      );
      expect(
        find.text('PIN oublié : la déconnexion le réinitialise.'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(lockSwitch()).value, isFalse);
      expect(find.text('Changer le PIN'), findsNothing);
      expect(find.text('Déverrouillage biométrique'), findsNothing);
    });

    testWidgets('should_goBack_when_backArrowTapped', (tester) async {
      await pumpSettings(tester);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is PhosphorIcon && w.icon == PhosphorIconsRegular.arrowLeft,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hub'), findsOneWidget);
    });

    testWidgets('should_enableLock_when_pinChosenAndConfirmed', (tester) async {
      await pumpSettings(tester);

      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();
      expect(find.text('Choisissez un PIN'), findsOneWidget);

      await typePin(tester, '4827');
      expect(find.text('Confirmez le PIN'), findsOneWidget);
      // Nothing is stored before the confirmation.
      expect(harness.repo.writes, 0);
      expect(lock().enabled, isFalse);

      await typePin(tester, '4827');

      expect(find.byType(LockSettingsScreen), findsOneWidget);
      expect(tester.widget<Switch>(lockSwitch()).value, isTrue);
      expect(lock().enabled, isTrue);
      final config = harness.repo.config;
      expect(config.lockEnabled, isTrue);
      expect(config.hashedPin, hashPin(config.pinSalt!, '4827'));
      expect(harness.repo.writes, 1);
      expect(find.text('Changer le PIN'), findsOneWidget);
    });

    testWidgets('should_askAgainAndSaveNothing_when_pinsDiffer', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();
      await typePin(tester, '4827');

      await typePin(tester, '4828');

      expect(find.text('Les deux PIN ne correspondent pas'), findsOneWidget);
      expect(find.text('Choisissez un PIN'), findsOneWidget);
      expect(harness.repo.writes, 0);
      expect(lock().enabled, isFalse);

      await typePin(tester, '1111');
      await typePin(tester, '1111');
      expect(lock().enabled, isTrue);
      expect(
        harness.repo.config.hashedPin,
        hashPin(harness.repo.config.pinSalt!, '1111'),
      );
    });

    testWidgets('should_leaveLockOff_when_pinScreenClosed', (tester) async {
      await pumpSettings(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();
      await typePin(tester, '4827');

      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(LockSettingsScreen), findsOneWidget);
      expect(tester.widget<Switch>(lockSwitch()).value, isFalse);
      expect(harness.repo.writes, 0);
    });

    testWidgets('should_returnToSettings_when_pinScreenBackArrowTapped', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is PhosphorIcon && w.icon == PhosphorIconsRegular.arrowLeft,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LockSettingsScreen), findsOneWidget);
      expect(find.byType(LockPinScreen), findsNothing);
      expect(lock().enabled, isFalse);
    });

    testWidgets('should_openPinOnFullScreenPage_when_enabling', (tester) async {
      await pumpSettings(tester);

      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      expect(find.byType(LockPinScreen), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Verrouillage'), findsOneWidget);
    });
  });

  group('LockSettingsScreen with the lock on', () {
    testWidgets('should_showEverySetting_when_lockEnabledAndBiometricsExist', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(tester.widget<Switch>(lockSwitch()).value, isTrue);
      expect(find.text('Déverrouillage biométrique'), findsOneWidget);
      expect(find.text('Le PIN reste le recours'), findsOneWidget);
      expect(find.text('Changer le PIN'), findsOneWidget);
    });

    testWidgets('should_hideBiometricOption_when_biometricsUnavailable', (
      tester,
    ) async {
      harness.biometrics.kind = null;

      await pumpSettings(tester);

      expect(find.text('Déverrouillage biométrique'), findsNothing);
      expect(find.text('Changer le PIN'), findsOneWidget);
    });

    testWidgets('should_enableBiometrics_when_authenticationSucceeds', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Déverrouillage biométrique'),
          matching: find.byType(Switch),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.biometrics.authenticateCalls, 1);
      expect(harness.repo.config.lockMethod, LockMethod.biometric);
      expect(lock().biometricEnabled, isTrue);
    });

    testWidgets(
      'should_reportErrorAndKeepSwitchOff_when_settingCannotBeSaved',
      (tester) async {
        await pumpSettings(tester);
        harness.repo.writeError = Exception('disk full');

        await tester.tap(
          find.descendant(
            of: find.widgetWithText(
              SwitchListTile,
              'Déverrouillage biométrique',
            ),
            matching: find.byType(Switch),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
        expect(lock().biometricEnabled, isFalse);
        expect(harness.repo.config.lockMethod, LockMethod.pin);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should_showNoMessage_when_systemRefusesBiometrics',
      (tester) async {
        harness.biometrics.succeeds = false;
        await pumpSettings(tester);

        await tester.tap(
          find.descendant(
            of: find.widgetWithText(
              SwitchListTile,
              'Déverrouillage biométrique',
            ),
            matching: find.byType(Switch),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets('should_keepBiometricsOff_when_authenticationFails', (
      tester,
    ) async {
      harness.biometrics.succeeds = false;
      await pumpSettings(tester);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Déverrouillage biométrique'),
          matching: find.byType(Switch),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.repo.config.lockMethod, LockMethod.pin);
      expect(lock().biometricEnabled, isFalse);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.widgetWithText(
                  SwitchListTile,
                  'Déverrouillage biométrique',
                ),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('should_disableLock_when_currentPinRight', (tester) async {
      await pumpSettings(tester);

      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();
      expect(find.text('Saisissez votre PIN actuel'), findsOneWidget);
      await typePin(tester, '1234');

      expect(find.byType(LockSettingsScreen), findsOneWidget);
      expect(tester.widget<Switch>(lockSwitch()).value, isFalse);
      expect(harness.repo.config.lockEnabled, isFalse);
      expect(harness.repo.config.hashedPin, isNull);
      expect(harness.repo.config.pinSalt, isNull);
    });

    testWidgets('should_keepLockAndCountAttempt_when_currentPinWrong', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      await typePin(tester, '0000');

      expect(find.text('PIN incorrect. 4 essais restants'), findsOneWidget);
      expect(find.byType(LockPinScreen), findsOneWidget);
      expect(harness.repo.config.lockEnabled, isTrue);
      expect(harness.repo.config.failedPinAttempts, 1);
    });

    testWidgets('should_shareFailureCounterWithLockScreen_when_pinWrong', (
      tester,
    ) async {
      harness = LockHarness(config: lockedConfig(failedPinAttempts: 2));
      await pumpSettings(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      await typePin(tester, '0000');

      expect(find.text('PIN incorrect. 2 essais restants'), findsOneWidget);
      expect(harness.repo.config.failedPinAttempts, 3);
    });

    testWidgets('should_signOutAndResetLock_when_fifthWrongPinInSettings', (
      tester,
    ) async {
      harness = LockHarness(config: lockedConfig(failedPinAttempts: 4));
      await pumpSettings(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      await typePin(tester, '0000');

      verify(harness.authRepo.logout()).called(1);
      expect(
        container.read(authNotifierProvider),
        const AuthState.unauthenticated(),
      );
      expect(harness.repo.config.lockEnabled, isFalse);
      expect(harness.repo.config.hashedPin, isNull);
    });

    testWidgets('should_changePin_when_currentRightThenNewConfirmed', (
      tester,
    ) async {
      await pumpSettings(tester);
      final before = harness.repo.config;

      await tester.tap(find.text('Changer le PIN'));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez votre PIN actuel'), findsOneWidget);
      await typePin(tester, '1234');
      expect(find.text('Choisissez un PIN'), findsOneWidget);
      await typePin(tester, '5678');
      expect(find.text('Confirmez le PIN'), findsOneWidget);
      // Still the old PIN until the confirmation.
      expect(harness.repo.config.hashedPin, before.hashedPin);
      await typePin(tester, '5678');

      expect(find.byType(LockSettingsScreen), findsOneWidget);
      final after = harness.repo.config;
      expect(after.pinSalt, isNot(before.pinSalt));
      expect(after.hashedPin, hashPin(after.pinSalt!, '5678'));
      expect(after.lockEnabled, isTrue);
    });

    testWidgets('should_keepOldPin_when_changeCurrentPinWrong', (tester) async {
      await pumpSettings(tester);
      final before = harness.repo.config;
      await tester.tap(find.text('Changer le PIN'));
      await tester.pumpAndSettle();

      await typePin(tester, '9999');

      expect(find.text('PIN incorrect. 4 essais restants'), findsOneWidget);
      expect(find.text('Saisissez votre PIN actuel'), findsOneWidget);
      expect(harness.repo.config.hashedPin, before.hashedPin);
      expect(harness.repo.config.failedPinAttempts, 1);
    });

    testWidgets('should_goBackToNewPin_when_changeConfirmationDiffers', (
      tester,
    ) async {
      await pumpSettings(tester);
      final before = harness.repo.config;
      await tester.tap(find.text('Changer le PIN'));
      await tester.pumpAndSettle();
      await typePin(tester, '1234');
      await typePin(tester, '5678');

      await typePin(tester, '5679');

      expect(find.text('Les deux PIN ne correspondent pas'), findsOneWidget);
      expect(find.text('Choisissez un PIN'), findsOneWidget);
      expect(harness.repo.config.hashedPin, before.hashedPin);

      await typePin(tester, '2468');
      await typePin(tester, '2468');
      expect(
        harness.repo.config.hashedPin,
        hashPin(harness.repo.config.pinSalt!, '2468'),
      );
    });

    testWidgets('should_showErrorAndStay_when_counterCannotBeSaved', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Changer le PIN'));
      await tester.pumpAndSettle();
      harness.repo.writeError = Exception('disk full');

      // A wrong PIN must be counted, and the counter cannot be written.
      await typePin(tester, '0000');

      expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
      expect(find.text('Saisissez votre PIN actuel'), findsOneWidget);
    });
  });

  group('LockPinScreen at 360 x 640', () {
    setUpAll(loadAppFonts);

    for (final scale in const [1.0, 1.3]) {
      testWidgets('should_notOverflow_when_textScaleIs_$scale', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpSettings(tester, textScale: scale);

        await tester.tap(lockSwitch());
        await tester.pumpAndSettle();
        await typePin(tester, '0000');

        expect(find.byType(LockPinScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('should_notOverflow_when_settingsRendered', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpSettings(tester, textScale: 1.3);

      expect(tester.takeException(), isNull);
    });
  });

  test('should_describeFlow_when_pinScreenIsInspected', () {
    expect(
      const LockPinScreen(
        flow: LockPinFlow.change,
      ).toDiagnosticsNode().toStringDeep(),
      contains('flow: change'),
    );
  });
}
