// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/presentation/login_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWith((_) async => mockAuthRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: app_theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'), 'password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
  }

  group('LoginScreen', () {
    testWidgets('should_showNoErrorMessage_when_firstRender', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Erreur de connexion réseau'), findsNothing);
      expect(find.text('Email ou mot de passe incorrect'), findsNothing);
    });

    testWidgets(
        'should_showNetworkErrorMessage_when_loginFailsWithoutErrorCode',
        (tester) async {
      // Serveur injoignable : DioException sans corps de reponse
      // exploitable, donc sans code (KKS-324 avait laisse ce cas muet).
      when(mockAuthRepo.login('test@test.com', 'password')).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await fillAndSubmit(tester);

      expect(find.text('Erreur de connexion réseau'), findsOneWidget);
    });
  });
}
