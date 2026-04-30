import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart' hide AppTheme;
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/features/user_profile/presentation/screens/profile_settings_screen.dart';
import 'package:k_budget/src/theme/app_theme.dart';

void main() {
  group('ProfileSettingsScreen', () {
    testWidgets('should_showAllSections_when_userLoaded', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Section Identité
      expect(find.text('Identité'), findsOneWidget);
      // Section Sécurité
      expect(find.text('Sécurité'), findsOneWidget);
      // Section Données (skipOffstage:false car peut être hors écran)
      expect(find.text('Données', skipOffstage: false), findsOneWidget);
      // Section Zone de danger — scroller pour rendre les items lazily
      await tester.scrollUntilVisible(
        find.text('Zone de danger'),
        500,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Zone de danger'), findsOneWidget);
    });

    testWidgets('should_showLogoutRow_when_userLoaded', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Déconnexion'),
        500,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Déconnexion'), findsOneWidget);
    });

    testWidgets('should_showChangePasswordRow_when_userLoaded', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
          find.text('Changer le mot de passe', skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('should_showAdminLabel_when_emailDisplayed', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Géré par l\'administrateur'), findsOneWidget);
    });

    testWidgets('should_showDataSection_when_userLoaded', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Données', skipOffstage: false), findsOneWidget);
    });

    testWidgets('should_showExportJsonRow_when_userLoaded', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Exporter mes données (JSON)', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('should_showExportCsvRow_when_userLoaded', (tester) async {
      const testUser = User(
        id: 'test-id',
        email: 'kelly@example.com',
        name: 'Kelly',
        defaultCurrency: Currency.eur,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _MockUserProfileNotifier(testUser),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Exporter mes transactions (CSV)', skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}

/// Mock notifier pour les tests.
class _MockUserProfileNotifier extends UserProfileNotifier {
  final User _user;
  _MockUserProfileNotifier(this._user);

  @override
  Future<User> build() async => _user;
}
