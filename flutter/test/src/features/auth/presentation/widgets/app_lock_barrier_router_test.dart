import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
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

/// The barrier above a real router whose redirect is asynchronous, like the
/// app's: after a sign-out from the lock screen the authenticated screen is
/// still mounted until the redirect to the sign-in screen has finished, and
/// must not be revealed meanwhile.
void main() {
  const sentinel = 'Sentinelle financiere';

  late LockHarness harness;
  late ProviderContainer container;
  late GoRouter router;
  Completer<void>? redirectGate;
  final redirected = <String>[];

  AuthNotifier auth() => container.read(authNotifierProvider.notifier);

  final sentinelFinder = find.text(sentinel);
  final sentinelEvenHidden = find.text(sentinel, skipOffstage: false);

  Future<void> pumpApp(WidgetTester tester) async {
    container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    router = GoRouter(
      initialLocation: '/protected',
      refreshListenable: auth(),
      redirect: (context, state) async {
        redirected.add(state.matchedLocation);
        await redirectGate?.future;
        final authenticated =
            container.read(authNotifierProvider) is AuthAuthenticated;
        final onLogin = state.matchedLocation == '/login';
        if (!authenticated && !onLogin) {
          return '/login';
        }
        if (authenticated && onLogin) {
          return '/protected';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/protected',
          builder: (context, state) => const Scaffold(body: Text(sentinel)),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Column(children: [Text('Connexion'), TextField()]),
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
    await tester.pumpAndSettle();
    when(harness.authRepo.hasValidToken()).thenAnswer((_) async => true);
    await auth().checkAuth();
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
  }

  /// Pumps frames and checks, at each one, that the authenticated screen is
  /// neither painted nor exposed to the semantics tree.
  Future<void> pumpHidden(WidgetTester tester, {int frames = 10}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(sentinelFinder, findsNothing, reason: 'frame $i');
      expect(find.bySemanticsLabel(sentinel), findsNothing, reason: 'frame $i');
    }
  }

  setUp(() {
    harness = LockHarness();
    redirectGate = null;
    redirected.clear();
  });

  group('sign-out from the lock screen, slow redirect', () {
    testWidgets(
      'should_neverRevealScreen_when_fifthWrongPinAndRedirectPending',
      (tester) async {
        final handle = tester.ensureSemantics();
        harness.repo.config = lockedConfig(failedPinAttempts: 4);
        await pumpApp(tester);
        expect(sentinelFinder, findsNothing);
        expect(find.byType(LockScreen), findsOneWidget);
        final gate = redirectGate = Completer<void>();

        await typePin(tester, '0000');
        await tester.pump();

        expect(
          container.read(authNotifierProvider),
          isA<AuthUnauthenticated>(),
        );
        expect(
          container.read(appLockNotifierProvider).status,
          LockStatus.unlocked,
        );
        expect(find.byType(LockScreen), findsNothing);
        await pumpHidden(tester);

        gate.complete();
        await tester.pumpAndSettle();

        expect(find.text('Connexion'), findsOneWidget);
        expect(sentinelEvenHidden, findsNothing);
        await tester.enterText(find.byType(TextField), 'a@b.c');
        expect(find.text('a@b.c'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('should_neverRevealScreen_when_forgotPinAndRedirectPending', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);
      final gate = redirectGate = Completer<void>();

      await tester.tap(find.text('PIN oublié ?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déconnexion'));
      await tester.pump();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      await pumpHidden(tester);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Connexion'), findsOneWidget);
      expect(sentinelEvenHidden, findsNothing);
      handle.dispose();
    });
  });

  group('hold limits', () {
    testWidgets('should_keepHidingAndSendToSignIn_when_routerNeverMoves', (
      tester,
    ) async {
      harness.repo.config = lockedConfig(failedPinAttempts: 4);
      await pumpApp(tester);
      final gate = redirectGate = Completer<void>();
      redirected.clear();

      await typePin(tester, '0000');
      await tester.pump();
      await tester.pump(lockHoldTimeout - const Duration(milliseconds: 100));

      expect(sentinelFinder, findsNothing);
      expect(redirected, isNot(contains('/login')));

      await tester.pump(const Duration(milliseconds: 200));

      // The router was told to go to the sign-in screen, but is stuck: the
      // app stays hidden.
      expect(redirected, contains('/login'));
      expect(sentinelFinder, findsNothing);
      await pumpHidden(tester, frames: 5);
      await tester.pump(lockHoldTimeout * 3);
      expect(sentinelFinder, findsNothing);
      expect(find.byType(LockScreen), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Connexion'), findsOneWidget);
      expect(sentinelEvenHidden, findsNothing);
    });

    testWidgets('should_notHold_when_signedOutWhileNotCovered', (tester) async {
      harness.repo.config = const AppConfig();
      await pumpApp(tester);
      expect(sentinelFinder, findsOneWidget);
      redirectGate = Completer<void>();

      await auth().logout();
      await tester.pump();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(sentinelFinder, findsOneWidget);
    });

    testWidgets('should_notHold_when_signedOutFromUnlockedLockedApp', (
      tester,
    ) async {
      await pumpApp(tester);
      await typePin(tester, '1234');
      await tester.pump();
      expect(sentinelFinder, findsOneWidget);
      redirectGate = Completer<void>();

      await auth().logout();
      await tester.pump();

      expect(sentinelFinder, findsOneWidget);
    });

    testWidgets('should_stopHolding_when_sessionAuthenticatedAgain', (
      tester,
    ) async {
      harness.repo.config = lockedConfig(failedPinAttempts: 4);
      await pumpApp(tester);
      redirectGate = Completer<void>();
      await typePin(tester, '0000');
      await tester.pump();
      expect(sentinelFinder, findsNothing);
      when(harness.authRepo.login('a@b.c', 'secret')).thenAnswer(
        (_) async => const AuthResult(
          accessToken: 'a',
          refreshToken: 'r',
          email: 'a@b.c',
        ),
      );

      await auth().login('a@b.c', 'secret');
      await tester.pump();

      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      expect(sentinelFinder, findsOneWidget);
    });

    testWidgets('should_showSignIn_when_holdEndedByLocationChange', (
      tester,
    ) async {
      harness.repo.config = lockedConfig(failedPinAttempts: 4);
      await pumpApp(tester);
      final gate = redirectGate = Completer<void>();
      await typePin(tester, '0000');
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Connexion'), findsOneWidget);
      redirectGate = null;

      // The hold is over: the sign-in screen is not covered by anything.
      await tester.pump(lockHoldTimeout);

      expect(find.text('Connexion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
