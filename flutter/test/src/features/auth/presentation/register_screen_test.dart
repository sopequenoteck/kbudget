import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/presentation/register_screen.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAppConfigRepository mockConfigRepo;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockConfigRepo = MockAppConfigRepository();
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildRegisterScreen({String? invitationToken}) {
    return ProviderScope(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockConfigRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(
        home: RegisterScreen(invitationToken: invitationToken),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('should_showFormFields_when_rendered', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Nom (optionnel)'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      expect(find.text("S'inscrire"), findsOneWidget);
    });

    testWidgets('should_showInvitationBanner_when_tokenPresent',
        (tester) async {
      await tester.pumpWidget(
          buildRegisterScreen(invitationToken: 'test-token'));
      await tester.pumpAndSettle();

      expect(find.text('Invitation valide. Completez votre inscription.'),
          findsOneWidget);
    });

    testWidgets('should_showValidationError_when_emailEmpty',
        (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text("S'inscrire"));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez saisir votre email'), findsOneWidget);
    });

    testWidgets('should_showValidationError_when_passwordTooShort',
        (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'), '123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
          '123');
      await tester.tap(find.text("S'inscrire"));
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Le mot de passe doit contenir au moins 6 caracteres'),
          findsOneWidget);
    });

    testWidgets('should_showMismatchError_when_passwordsDiffer',
        (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'), 'password1');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
          'password2');
      await tester.tap(find.text("S'inscrire"));
      await tester.pumpAndSettle();

      expect(find.text('Les mots de passe ne correspondent pas'),
          findsOneWidget);
    });

    testWidgets('should_showLoginLink_when_rendered', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Deja un compte ? Se connecter'), findsOneWidget);
    });
  });
}
