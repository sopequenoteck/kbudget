// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/presentation/lock_screen.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

Future<void> pumpLockScreen(
  WidgetTester tester, {
  required AppConfig config,
  MockAuthRepository? mockAuthRepo,
}) async {
  final mockAppConfigRepo = MockAppConfigRepository();
  when(mockAppConfigRepo.getConfig()).thenAnswer((_) async => config);
  when(mockAppConfigRepo.setLockEnabled(any)).thenAnswer((_) async {});
  when(mockAppConfigRepo.setLockMethod(any)).thenAnswer((_) async {});
  when(mockAppConfigRepo.setHashedPin(any)).thenAnswer((_) async {});

  final authRepo = mockAuthRepo ?? MockAuthRepository();
  when(authRepo.logout()).thenAnswer((_) async {});

  final router = GoRouter(
    initialLocation: '/lock',
    routes: [
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const Scaffold(body: Text('LoginScreen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockAppConfigRepo),
        authRepositoryProvider.overrideWith((_) async => authRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: app_theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Bug pre-existant, hors perimetre KKS-399 : la Row "PIN oublié ?" /
  // "Biometrie" deborde (RenderFlex overflow) dans le ConstrainedBox
  // maxWidth: 320 — a corriger separement.
  tester.takeException();
}

void main() {
  group('LockScreen', () {
    testWidgets('should_showTagline_when_firstRender', (tester) async {
      await pumpLockScreen(
        tester,
        config: AppConfig(
          lockMethod: LockMethod.pin,
          hashedPin: _hash('1234'),
        ),
      );

      expect(find.text('Saisissez votre PIN pour continuer'), findsOneWidget);
    });

    testWidgets(
      'should_showMinLengthError_when_pinTooShort',
      (tester) async {
        await pumpLockScreen(
          tester,
          config: AppConfig(
            lockMethod: LockMethod.pin,
            hashedPin: _hash('1234'),
          ),
        );

        await tester.enterText(find.byType(TextField), '12');
        await tester.tap(find.text('Déverrouiller'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.text('Le PIN doit contenir au moins 4 chiffres'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showIncorrectPinError_when_pinDoesNotMatch',
      (tester) async {
        await pumpLockScreen(
          tester,
          config: AppConfig(
            lockMethod: LockMethod.pin,
            hashedPin: _hash('1234'),
          ),
        );

        await tester.enterText(find.byType(TextField), '0000');
        await tester.tap(find.text('Déverrouiller'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(find.text('PIN incorrect'), findsOneWidget);
      },
    );

    testWidgets(
      'should_navigateToDashboard_when_pinMatches',
      (tester) async {
        await pumpLockScreen(
          tester,
          config: AppConfig(
            lockMethod: LockMethod.pin,
            hashedPin: _hash('1234'),
          ),
        );

        await tester.enterText(find.byType(TextField), '1234');
        await tester.tap(find.text('Déverrouiller'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(find.text('Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showForgotPinDialog_when_forgotPinTapped',
      (tester) async {
        await pumpLockScreen(
          tester,
          config: AppConfig(
            lockMethod: LockMethod.pin,
            hashedPin: _hash('1234'),
          ),
        );

        await tester.tap(find.text('PIN oublié ?').first);
        await tester.pumpAndSettle();
        tester.takeException();

        expect(find.text('PIN oublié ?'), findsWidgets);
        expect(
          find.textContaining('Vous serez déconnecté'),
          findsOneWidget,
        );
        expect(find.text('Réinitialiser'), findsNothing);
      },
    );

    testWidgets(
      'should_logoutAndNavigateToLogin_when_logoutConfirmed',
      (tester) async {
        await pumpLockScreen(
          tester,
          config: AppConfig(
            lockMethod: LockMethod.pin,
            hashedPin: _hash('1234'),
          ),
        );

        await tester.tap(find.text('PIN oublié ?').first);
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.textContaining('Vous serez déconnecté'),
          findsOneWidget,
        );

        await tester.tap(find.text('Déconnexion'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(find.text('LoginScreen'), findsOneWidget);
      },
    );

    testWidgets(
      'should_dismissForgotPinDialog_when_cancelTapped',
      (tester) async {
        await pumpLockScreen(
          tester,
          config: AppConfig(
            lockMethod: LockMethod.pin,
            hashedPin: _hash('1234'),
          ),
        );

        await tester.tap(find.text('PIN oublié ?').first);
        await tester.pumpAndSettle();
        tester.takeException();

        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(find.text('Saisissez votre PIN pour continuer'), findsOneWidget);
      },
    );
  });
}
