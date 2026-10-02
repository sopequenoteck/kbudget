import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/password_policy.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/presentation/first_login_reset_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  final l10n = lookupAppLocalizations(const Locale('fr'));

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/first-login-reset',
      routes: [
        GoRoute(
          path: '/first-login-reset',
          builder: (context, state) => const FirstLoginResetScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
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
        locale: const Locale('fr'),
      ),
    );
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String email = 'test@test.com',
    String displayName = 'Test User',
    String password = 'a-very-long-password',
    String confirmPassword = 'a-very-long-password',
  }) async {
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom d\'affichage'), displayName);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'), password);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        confirmPassword);
  }

  group('FirstLoginResetScreen', () {
    testWidgets('should_showTitleAndNotice_when_firstRender', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Premier accès'), findsOneWidget);
      expect(
        find.textContaining('identifiants initiaux générés par le système'),
        findsOneWidget,
      );
    });

    testWidgets(
      'should_showDisplayNameRequiredError_when_nameEmpty',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await fillForm(tester, displayName: '');
        await tester.ensureVisible(find.text('Confirmer'));
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(
          find.text('Nom requis (100 caractères max)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showDisplayNameRequiredError_when_nameExceeds100Chars',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await fillForm(tester, displayName: 'A' * 101);
        await tester.ensureVisible(find.text('Confirmer'));
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(
          find.text('Nom requis (100 caractères max)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showPasswordConfirmRequiredError_when_confirmEmpty',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await fillForm(tester, confirmPassword: '');
        await tester.ensureVisible(find.text('Confirmer'));
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(
          find.text('Veuillez confirmer votre mot de passe'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should_showValidationError_when_emailInvalid',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await fillForm(tester, email: 'not-an-email');
      await tester.ensureVisible(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(find.text('Email invalide'), findsOneWidget);
      verifyNever(mockAuthRepo.firstLoginReset(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      ));
    });

    testWidgets('should_showValidationError_when_passwordTooShort',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await fillForm(tester, password: 'short', confirmPassword: 'short');
      await tester.ensureVisible(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(
        find.text(PasswordPolicy.tooShortMessage(l10n)),
        findsOneWidget,
      );
      verifyNever(mockAuthRepo.firstLoginReset(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      ));
    });

    testWidgets(
        'should_showValidationError_when_confirmPasswordDoesNotMatch',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await fillForm(
        tester,
        password: 'a-very-long-password',
        confirmPassword: 'a-different-password',
      );
      await tester.ensureVisible(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(find.text('Les mots de passe ne correspondent pas'),
          findsOneWidget);
      verifyNever(mockAuthRepo.firstLoginReset(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      ));
    });

    testWidgets(
        'should_callFirstLoginReset_when_formValid',
        (tester) async {
      when(mockAuthRepo.firstLoginReset(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      )).thenAnswer((_) async => const AuthResult(
            accessToken: 'access',
            refreshToken: 'refresh',
            email: 'test@test.com',
            name: 'Test User',
          ));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await fillForm(tester);
      await tester.ensureVisible(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      verify(mockAuthRepo.firstLoginReset(
        email: 'test@test.com',
        password: 'a-very-long-password',
        displayName: 'Test User',
      )).called(1);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets(
      'should_showResetError_when_dioExceptionWithoutBadRequest',
      (tester) async {
        when(mockAuthRepo.firstLoginReset(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 500,
            ),
          ),
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await fillForm(tester);
        await tester.ensureVisible(find.text('Confirmer'));
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Erreur lors de la mise à jour de vos identifiants. '
            'Veuillez réessayer.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showGenericValidationError_when_dioExceptionIsBadRequest',
      (tester) async {
        when(mockAuthRepo.firstLoginReset(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 400,
            ),
          ),
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await fillForm(tester);
        await tester.ensureVisible(find.text('Confirmer'));
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(
          find.text('Veuillez vérifier les informations saisies.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_showUnknownError_when_genericExceptionThrown',
      (tester) async {
        when(mockAuthRepo.firstLoginReset(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenThrow(Exception('boom'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await fillForm(tester);
        await tester.ensureVisible(find.text('Confirmer'));
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(find.text('Erreur inattendue'), findsOneWidget);
      },
    );
  });
}
