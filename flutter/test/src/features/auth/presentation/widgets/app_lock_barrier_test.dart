import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/presentation/lock_screen.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/app_lock_barrier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/lock_test_helpers.dart';

void main() {
  late LockHarness harness;
  late ProviderContainer container;
  late FocusNode fieldFocus;
  late GoRouter router;
  var taps = 0;

  AuthNotifier auth() => container.read(authNotifierProvider.notifier);

  AppLockState lock() => container.read(appLockNotifierProvider);

  Future<void> pumpBarrier(WidgetTester tester) async {
    container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    // The router has no redirect of its own: a sign-out held by the barrier
    // ends when the barrier itself sends the router to the sign-in screen.
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Connexion')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                const Text('Contenu financier'),
                TextField(focusNode: fieldFocus),
                ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('Action'),
                ),
              ],
            ),
          ),
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
          builder: (context, child) =>
              AppLockBarrier(router: router, child: child!),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> signIn(WidgetTester tester) async {
    when(harness.authRepo.hasValidToken()).thenAnswer((_) async => true);
    await auth().checkAuth();
    await tester.pump();
  }

  /// Lets the hold run out: the barrier sends the router to the sign-in
  /// screen, which ends the hold.
  Future<void> endHold(WidgetTester tester) async {
    await tester.pump(lockHoldTimeout);
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump();
  }

  setUp(() {
    harness = LockHarness();
    fieldFocus = FocusNode();
    taps = 0;
  });

  tearDown(() => fieldFocus.dispose());

  final content = find.text('Contenu financier');
  final contentEvenHidden = find.text('Contenu financier', skipOffstage: false);

  group('AppLockBarrier cover', () {
    testWidgets(
      'should_hideContentAndShowLockScreen_when_authenticatedAndLocked',
      (tester) async {
        await pumpBarrier(tester);
        await signIn(tester);

        expect(lock().status, LockStatus.locked);
        expect(content, findsNothing);
        expect(find.byType(LockScreen), findsOneWidget);
      },
    );

    testWidgets('should_keepContentMounted_when_covered', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);

      expect(contentEvenHidden, findsOneWidget);
    });

    testWidgets('should_showPlainBackgroundOnly_when_stateUnknown', (
      tester,
    ) async {
      harness.repo.readGate = Completer<void>();
      await pumpBarrier(tester);
      await signIn(tester);

      expect(lock().status, LockStatus.unknown);
      expect(content, findsNothing);
      expect(find.byType(LockScreen), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ColoredBox &&
              w.color == app_theme.AppTheme.light.scaffoldBackgroundColor,
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_showLockScreen_when_unknownStateResolvesToLocked', (
      tester,
    ) async {
      final gate = harness.repo.readGate = Completer<void>();
      await pumpBarrier(tester);
      await signIn(tester);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(content, findsNothing);
      expect(find.byType(LockScreen), findsOneWidget);
    });

    testWidgets('should_showContent_when_stateResolvesToUnlocked', (
      tester,
    ) async {
      harness.repo.config = lockedConfig().copyWith(lockEnabled: false);
      final gate = harness.repo.readGate = Completer<void>();
      await pumpBarrier(tester);
      await signIn(tester);
      expect(content, findsNothing);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(content, findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('should_showContent_when_configurationUnreadable', (
      tester,
    ) async {
      harness.repo.readError = const FormatException('corrupted');
      await pumpBarrier(tester);
      await signIn(tester);

      expect(lock().status, LockStatus.unlocked);
      expect(content, findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('should_showContent_when_notAuthenticatedEvenIfLocked', (
      tester,
    ) async {
      await pumpBarrier(tester);
      await tester.pump();

      expect(lock().status, LockStatus.locked);
      expect(container.read(authNotifierProvider), isA<AuthInitial>());
      expect(content, findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('should_showSignInOnceHeldNoMore_when_sessionEndsWhileLocked', (
      tester,
    ) async {
      await pumpBarrier(tester);
      await signIn(tester);
      expect(content, findsNothing);

      auth().forceUnauthenticated();
      await tester.pump();

      // Held behind the plain background while the router has not moved.
      expect(content, findsNothing);
      expect(find.byType(LockScreen), findsNothing);
      await endHold(tester);

      expect(content, findsNothing);
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
      expect(lock().status, LockStatus.locked);
    });

    testWidgets(
      'should_coverFirstLoginScreen_when_passwordResetRequiredAndLocked',
      (tester) async {
        await pumpBarrier(tester);

        // Cold start: the tokens are valid, the credentials must be reset.
        auth().requirePasswordReset();
        await tester.pump();
        await tester.pump();

        expect(lock().status, LockStatus.locked);
        expect(content, findsNothing);
        expect(find.byType(LockScreen), findsOneWidget);

        await typePin(tester, '1234');

        expect(content, findsOneWidget);
        expect(find.byType(LockScreen), findsNothing);
      },
    );

    testWidgets(
      'should_keepCover_when_authenticatedBecomesPasswordResetRequired',
      (tester) async {
        await pumpBarrier(tester);
        await signIn(tester);

        auth().requirePasswordReset();
        await tester.pump();
        await tester.pump(lockHoldTimeout);

        expect(content, findsNothing);
        expect(find.byType(LockScreen), findsOneWidget);
        expect(router.routerDelegate.currentConfiguration.uri.path, '/');
      },
    );

    testWidgets(
      'should_excludeContentFromSemantics_when_passwordResetRequired',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpBarrier(tester);
        auth().requirePasswordReset();
        await tester.pump();
        await tester.pump();

        expect(find.bySemanticsLabel('Contenu financier'), findsNothing);
        handle.dispose();
      },
    );

    testWidgets('should_hold_when_passwordResetSessionEnds', (tester) async {
      await pumpBarrier(tester);
      auth().requirePasswordReset();
      await tester.pump();
      await tester.pump();

      auth().forceUnauthenticated();
      await tester.pump();

      expect(content, findsNothing);
      expect(find.byType(LockScreen), findsNothing);
      await endHold(tester);
      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('should_showContent_when_unlocked', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);

      await typePin(tester, '1234');

      expect(content, findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('should_showContent_when_lockNeverEnabled', (tester) async {
      harness.repo.config = lockedConfig().copyWith(lockEnabled: false);
      await pumpBarrier(tester);
      await signIn(tester);

      expect(content, findsOneWidget);
    });
  });

  group('AppLockBarrier isolation', () {
    testWidgets('should_excludeContentFromSemantics_when_covered', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpBarrier(tester);
      await signIn(tester);

      expect(find.bySemanticsLabel('Contenu financier'), findsNothing);
      expect(find.bySemanticsLabel('Action'), findsNothing);
      expect(find.bySemanticsLabel('PIN oublié ?'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('should_exposeContentToSemantics_when_unlocked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      harness.repo.config = lockedConfig().copyWith(lockEnabled: false);
      await pumpBarrier(tester);
      await signIn(tester);

      expect(find.bySemanticsLabel('Contenu financier'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('should_notReceiveTaps_when_covered', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);

      await tester.tapAt(const Offset(60, 120));
      await tester.tap(
        find.text('Action', skipOffstage: false),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('should_receiveTaps_when_unlocked', (tester) async {
      harness.repo.config = lockedConfig().copyWith(lockEnabled: false);
      await pumpBarrier(tester);
      await signIn(tester);

      await tester.tap(find.text('Action'));

      expect(taps, 1);
    });

    testWidgets('should_dropKeyboardFocus_when_appLocks', (tester) async {
      harness.repo.config = lockedConfig().copyWith(lockEnabled: false);
      await pumpBarrier(tester);
      await signIn(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(fieldFocus.hasFocus, isTrue);

      await container.read(appLockNotifierProvider.notifier).enable('1234');
      container
          .read(appLockNotifierProvider.notifier)
          .onLifecycleChanged(AppLifecycleState.paused);
      harness.now = harness.now.add(const Duration(minutes: 2));
      container
          .read(appLockNotifierProvider.notifier)
          .onLifecycleChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(lock().status, LockStatus.locked);
      expect(fieldFocus.hasFocus, isFalse);
    });

    testWidgets('should_openForgotPinDialog_when_coverIsAboveTheApp', (
      tester,
    ) async {
      await pumpBarrier(tester);
      await signIn(tester);

      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();

      expect(find.text('Déconnexion'), findsOneWidget);
    });
  });

  group('AppLockBarrier lifecycle', () {
    Future<void> sendToBackground(
      WidgetTester tester,
      Duration away, {
      AppLifecycleState leaving = AppLifecycleState.paused,
    }) async {
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(leaving);
      harness.now = harness.now.add(away);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    }

    testWidgets('should_lockAndRestoreScreen_when_backAfterOneMinute', (
      tester,
    ) async {
      await pumpBarrier(tester);
      await signIn(tester);
      await typePin(tester, '1234');
      await tester.enterText(find.byType(TextField), 'brouillon');

      await sendToBackground(tester, const Duration(seconds: 60));

      expect(content, findsNothing);
      expect(find.byType(LockScreen), findsOneWidget);

      await typePin(tester, '1234');

      expect(content, findsOneWidget);
      expect(find.text('brouillon'), findsOneWidget);
    });

    testWidgets('should_stayUnlocked_when_backAfter59Seconds', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);
      await typePin(tester, '1234');

      await sendToBackground(tester, const Duration(seconds: 59));

      expect(content, findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('should_stayUnlocked_when_onlyInactive', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);
      await typePin(tester, '1234');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      harness.now = harness.now.add(const Duration(hours: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(content, findsOneWidget);
    });

    testWidgets('should_lock_when_clockWentBackwards', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);
      await typePin(tester, '1234');

      await sendToBackground(tester, const Duration(seconds: -30));

      expect(content, findsNothing);
      expect(find.byType(LockScreen), findsOneWidget);
    });

    testWidgets('should_stopObserving_when_barrierRemoved', (tester) async {
      await pumpBarrier(tester);
      await signIn(tester);
      await typePin(tester, '1234');
      await tester.pumpWidget(const SizedBox());

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      harness.now = harness.now.add(const Duration(hours: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(lock().status, LockStatus.unlocked);
    });
  });

  group('AppLockBarrier sign-out', () {
    testWidgets(
      'should_neverPaintUnlockedAppWithOpenSession_when_fifthWrongPin',
      (tester) async {
        await pumpBarrier(tester);
        await signIn(tester);
        final frames = <(bool, LockStatus)>[];
        var recording = true;
        addTearDown(() => recording = false);
        tester.binding.addPersistentFrameCallback((_) {
          if (!recording) {
            return;
          }
          frames.add((
            container.read(authNotifierProvider) is AuthAuthenticated,
            container.read(appLockNotifierProvider).status,
          ));
        });

        for (var i = 0; i < 5; i++) {
          await typePin(tester, '0000');
        }

        expect(
          container.read(authNotifierProvider),
          isA<AuthUnauthenticated>(),
        );
        expect(lock().status, LockStatus.unlocked);
        expect(frames, isNotEmpty);
        expect(
          frames.where((f) => f.$1 && f.$2 == LockStatus.unlocked),
          isEmpty,
        );
        expect(
          frames.where((f) => f.$1 && f.$2 == LockStatus.locked),
          isNotEmpty,
        );
      },
    );

    testWidgets(
      'should_keepCoverBetweenFrames_when_resetWriteIsSlowAtFifthWrongPin',
      (tester) async {
        await pumpBarrier(tester);
        await signIn(tester);
        final frames = <(bool, LockStatus)>[];
        var recording = true;
        addTearDown(() => recording = false);
        tester.binding.addPersistentFrameCallback((_) {
          if (!recording) {
            return;
          }
          frames.add((
            container.read(authNotifierProvider) is AuthAuthenticated,
            container.read(appLockNotifierProvider).status,
          ));
        });
        harness.repo.config = lockedConfig(failedPinAttempts: 4);
        final counterWrite = Completer<void>();
        final resetWrite = Completer<void>();
        harness.repo.writeGateQueue.addAll([counterWrite, resetWrite]);

        await typePin(tester, '0000');
        counterWrite.complete();
        await tester.pump();
        // The reset is being written: real frames happen meanwhile.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
        expect(lock().status, LockStatus.locked);
        expect(content, findsNothing);
        expect(find.byType(LockScreen), findsOneWidget);

        resetWrite.complete();
        await tester.pump();

        expect(
          frames.where((f) => f.$1 && f.$2 == LockStatus.unlocked),
          isEmpty,
        );
        expect(
          container.read(authNotifierProvider),
          isA<AuthUnauthenticated>(),
        );
        expect(lock().status, LockStatus.unlocked);
        expect(content, findsNothing);
        await endHold(tester);
        expect(find.text('Connexion'), findsOneWidget);
      },
    );

    testWidgets('should_neverPaintUnlockedAppWithOpenSession_when_forgotPin', (
      tester,
    ) async {
      await pumpBarrier(tester);
      await signIn(tester);
      final frames = <(bool, LockStatus)>[];
      var recording = true;
      addTearDown(() => recording = false);
      tester.binding.addPersistentFrameCallback((_) {
        if (!recording) {
          return;
        }
        frames.add((
          container.read(authNotifierProvider) is AuthAuthenticated,
          container.read(appLockNotifierProvider).status,
        ));
      });

      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déconnexion'));
      await tester.pumpAndSettle();

      expect(frames.where((f) => f.$1 && f.$2 == LockStatus.unlocked), isEmpty);
      expect(harness.repo.config.lockEnabled, isFalse);
      expect(content, findsNothing);
      await endHold(tester);
      expect(find.text('Connexion'), findsOneWidget);
    });
  });

  test('should_describeChildAndRouter_when_barrierIsInspected', () {
    router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('x'))],
    );
    expect(
      AppLockBarrier(
        router: router,
        child: const Text('x'),
      ).toDiagnosticsNode().toStringDeep(),
      allOf(contains('child'), contains('router')),
    );
  });
}
