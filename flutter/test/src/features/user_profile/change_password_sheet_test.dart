import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/change_password_sheet.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/localization/app_localizations_fr.dart';
import 'package:k_budget/src/theme/app_theme.dart' show AppTheme;
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

void main() {
  group('ChangePasswordSheet', () {
    late MockUserProfileRepository mockUserProfileRepo;

    setUp(() {
      mockUserProfileRepo = MockUserProfileRepository();
    });
    testWidgets('should_showThreeFields_when_rendered', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => ChangePasswordSheet.show(context),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe actuel'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('should_showValidationError_when_newPasswordTooShort', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => ChangePasswordSheet.show(context),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Remplir mot de passe actuel
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'),
        'ancien_mdp',
      );
      // Remplir nouveau mot de passe trop court
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
        'court',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'),
        'court',
      );

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(
        find.text('12 caractères minimum'),
        findsOneWidget,
      );
    });

    testWidgets('should_showValidationError_when_passwordsDoNotMatch', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => ChangePasswordSheet.show(context),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'),
        'ancien_mdp',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
        'nouveau_mdp_valide_12chars',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'),
        'autre_mdp_different',
      );

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });

    testWidgets('should_dismissSheet_when_cancelTapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => ChangePasswordSheet.show(context),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Changer le mot de passe'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Changer le mot de passe'), findsNothing);
    });

    testWidgets(
      'should_showOverriddenLabel_when_changeFailsWithPasswordIncorrect',
      (tester) async {
        // KKS-324 : PASSWORD_INCORRECT est en override sur cet ecran — il
        // designe l'ancien mot de passe, le libelle du catalogue serait
        // ambigu ("Mot de passe incorrect" tout court).
        when(mockUserProfileRepo.changePassword(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 401,
              data: {'error': 'PASSWORD_INCORRECT', 'message': 'peu importe'},
            ),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileRepositoryProvider.overrideWith(
                (_) async => mockUserProfileRepo,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('fr'),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => ChangePasswordSheet.show(context),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe actuel'),
          'ancien_mdp',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
          'nouveau_mdp_valide_12chars',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Confirmer le nouveau mot de passe',
          ),
          'nouveau_mdp_valide_12chars',
        );

        await tester.tap(find.text('Modifier'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizationsFr();
        expect(
          find.text(l10n.usersFeedbackCurrentPasswordIncorrect),
          findsOneWidget,
        );
        expect(find.text(l10n.errorsApiPasswordIncorrect), findsNothing);
      },
    );

    Future<void> openFilledSheet(
      WidgetTester tester, {
      List<Override> overrides = const [],
      bool fill = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => ChangePasswordSheet.show(context),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      if (fill) {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe actuel'),
          'ancien_mdp',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
          'nouveau_mdp_valide_12chars',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Confirmer le nouveau mot de passe',
          ),
          'nouveau_mdp_valide_12chars',
        );
      }
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
    }

    testWidgets('should_requireEveryField_when_submittedEmpty',
        (tester) async {
      await openFilledSheet(tester, fill: false);

      expect(find.text('Ce champ est requis.'), findsNWidgets(3));
    });

    testWidgets('should_confirmAndClose_when_passwordChanged', (tester) async {
      final mockAuthRepo = MockAuthRepository();
      when(mockUserProfileRepo.changePassword(any)).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'access',
          refreshToken: 'refresh',
          email: 'kelly@example.com',
        ),
      );
      when(mockAuthRepo.saveTokens(any, any)).thenAnswer((_) async {});

      await openFilledSheet(
        tester,
        overrides: [
          userProfileRepositoryProvider
              .overrideWith((_) async => mockUserProfileRepo),
          authRepositoryProvider.overrideWith((_) async => mockAuthRepo),
        ],
      );

      verify(mockAuthRepo.saveTokens('access', 'refresh')).called(1);
      expect(find.text('Mot de passe modifié avec succès'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsNothing);
    });

    testWidgets('should_showNetworkError_when_changeFailsOffline',
        (tester) async {
      when(mockUserProfileRepo.changePassword(any))
          .thenThrow(Exception('offline'));

      await openFilledSheet(
        tester,
        overrides: [
          userProfileRepositoryProvider
              .overrideWith((_) async => mockUserProfileRepo),
        ],
      );

      expect(find.text('Impossible de contacter le serveur'), findsOneWidget);
    });
  });
}
