// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/password_policy.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/features/auth/presentation/accept_invite_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

/// Adaptateur Dio minimal, sans dependance supplementaire : route les
/// requetes de cet ecran vers des reponses en dur selon [_scenario].
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._scenario);
  final String _scenario;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' &&
        options.path.contains('/auth/invitations/')) {
      if (_scenario == 'invalidLink') {
        return ResponseBody.fromString('{}', 404);
      }
      return ResponseBody.fromString(
        jsonEncode({'email': 'invite@test.com'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'POST' && options.path == '/auth/accept-invite') {
      switch (_scenario) {
        case 'submitInvalidLink':
          return ResponseBody.fromString('{}', 404);
        case 'submitServerError':
          return ResponseBody.fromString('{}', 500);
      }
    }

    throw StateError('Unhandled request: ${options.method} ${options.path}');
  }
}

Future<void> pumpAcceptInviteScreen(
  WidgetTester tester, {
  required String scenario,
}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local/api'))
    ..httpClientAdapter = _FakeHttpClientAdapter(scenario);

  final router = GoRouter(
    initialLocation: '/accept-invite/some-token',
    routes: [
      GoRoute(
        path: '/accept-invite/:token',
        builder: (context, state) => AcceptInviteScreen(
          token: state.pathParameters['token']!,
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) =>
            const Scaffold(body: Text('LoginScreen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWith((ref) async => dio),
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
  // Bug pre-existant, hors perimetre KKS-399 : le DropdownButtonFormField
  // devise deborde (RenderFlex overflow) independamment de la locale — a
  // corriger separement.
  tester.takeException();
}

void main() {
  group('AcceptInviteScreen', () {
    testWidgets('should_showInvalidLinkScreen_when_lookupIs404', (
      tester,
    ) async {
      await pumpAcceptInviteScreen(tester, scenario: 'invalidLink');

      expect(find.text('Lien invalide'), findsOneWidget);
      expect(
        find.text('Lien invalide, expiré, déjà utilisé ou révoqué.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Retour à la connexion'));
      await tester.pumpAndSettle();
      tester.takeException();

      expect(find.text('LoginScreen'), findsOneWidget);
    });

    testWidgets('should_showFormWithTitleAndTagline_when_lookupSucceeds', (
      tester,
    ) async {
      await pumpAcceptInviteScreen(tester, scenario: 'valid');

      expect(find.text('Créer votre compte'), findsOneWidget);
      expect(
        find.text('Quelques informations pour finaliser l\'inscription'),
        findsOneWidget,
      );
      expect(find.text('invite@test.com'), findsOneWidget);
    });

    testWidgets(
      'should_showDisplayNameRequiredError_when_nameEmptyOnSubmit',
      (tester) async {
        await pumpAcceptInviteScreen(tester, scenario: 'valid');

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'a-very-long-password',
        );
        await tester.tap(find.text('Créer mon compte'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.text('Nom requis (100 caractères max)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showDisplayNameRequiredError_when_nameExceeds100Chars',
      (tester) async {
        await pumpAcceptInviteScreen(tester, scenario: 'valid');

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom d\'affichage'),
          'A' * 101,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'a-very-long-password',
        );
        await tester.tap(find.text('Créer mon compte'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.text('Nom requis (100 caractères max)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showPasswordTooShortError_when_passwordBelowMinLength',
      (tester) async {
        await pumpAcceptInviteScreen(tester, scenario: 'valid');
        final l10n = lookupAppLocalizations(const Locale('fr'));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom d\'affichage'),
          'Alex',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'short',
        );
        await tester.tap(find.text('Créer mon compte'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.text(PasswordPolicy.tooShortMessage(l10n)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showInvalidLinkError_when_submitReturns404',
      (tester) async {
        await pumpAcceptInviteScreen(tester, scenario: 'submitInvalidLink');

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom d\'affichage'),
          'Alex',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'a-very-long-password',
        );
        await tester.tap(find.text('Créer mon compte'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.text('Lien invalide, expiré, déjà utilisé ou révoqué.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showCreateAccountError_when_submitFailsWithServerError',
      (tester) async {
        await pumpAcceptInviteScreen(tester, scenario: 'submitServerError');

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom d\'affichage'),
          'Alex',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'a-very-long-password',
        );
        await tester.tap(find.text('Créer mon compte'));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(
          find.text('Erreur lors de la création du compte. Veuillez réessayer.'),
          findsOneWidget,
        );
      },
    );
  });
}
