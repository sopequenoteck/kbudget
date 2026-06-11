import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

void main() {
  late GoRouter router;
  late String lastPushedLocation;

  setUp(() {
    lastPushedLocation = '';
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsHubScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) {
                lastPushedLocation = '/settings/profile';
                return const Scaffold(body: Text('Profile'));
              },
            ),
            GoRoute(
              path: 'accounts',
              builder: (context, state) {
                lastPushedLocation = '/settings/accounts';
                return const Scaffold(body: Text('Accounts'));
              },
            ),
            GoRoute(
              path: 'categories',
              builder: (context, state) {
                lastPushedLocation = '/settings/categories';
                return const Scaffold(body: Text('Categories'));
              },
            ),
            GoRoute(
              path: 'data',
              builder: (context, state) {
                lastPushedLocation = '/settings/data';
                return const Scaffold(body: Text('Data'));
              },
            ),
          ],
        ),
      ],
    );
  });

  Widget buildApp() {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        theme: app_theme.AppTheme.light,
      ),
    );
  }

  group('SettingsHubScreen', () {
    testWidgets('should_display_management_items_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Items visibles sans scroll dans la section Gestion
      expect(find.text('Mon compte'), findsOneWidget);
      expect(find.text('Comptes & Devises'), findsOneWidget);
      expect(find.text('Catégories'), findsOneWidget);
    });

    testWidgets('should_display_section_labels_when_rendered', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Sections visibles
      expect(find.text('GESTION'), findsOneWidget);
      expect(find.text('APPARENCE'), findsOneWidget);
    });

    testWidgets('should_display_Réglages_in_AppBar_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Réglages'), findsOneWidget);
    });

    testWidgets('should_navigate_to_settings_accounts_when_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comptes & Devises'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/accounts');
    });

    testWidgets('should_navigate_to_settings_profile_when_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mon compte'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/profile');
    });

    testWidgets('should_navigate_to_settings_categories_when_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catégories'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/categories');
    });
  });
}
