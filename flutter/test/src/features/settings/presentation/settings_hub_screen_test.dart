import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';

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
              path: 'appearance',
              builder: (context, state) {
                lastPushedLocation = '/settings/appearance';
                return const Scaffold(body: Text('Appearance'));
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
      ),
    );
  }

  group('SettingsHubScreen', () {
    testWidgets('should display 8 items with correct titles', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Fonctionnalités & Navigation'), findsOneWidget);
      expect(find.text('Apparence'), findsOneWidget);
      expect(find.text('Comptes'), findsOneWidget);
      expect(find.text('Catégories'), findsOneWidget);
      expect(find.text('Données'), findsOneWidget);

      // Scroll down to reveal remaining items
      await tester.scrollUntilVisible(find.text('Sécurité'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Sécurité'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('À propos'), 100);
      await tester.pumpAndSettle();
      expect(find.text('À propos'), findsOneWidget);
    });

    testWidgets('should display 3 group titles', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Général'), findsOneWidget);
      expect(find.text('Gestion'), findsOneWidget);
      expect(find.text('Autre'), findsOneWidget);
    });

    testWidgets('should display Réglages in AppBar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Réglages'), findsOneWidget);
    });

    testWidgets('should navigate to /settings/accounts on tap',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comptes'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/accounts');
    });

    testWidgets('should navigate to /settings/profile on tap',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/profile');
    });

    testWidgets('should not navigate on placeholder tap', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll to reveal placeholder "Sécurité"
      await tester.scrollUntilVisible(find.text('Sécurité'), 100);
      await tester.pumpAndSettle();

      // Tap on placeholder "Sécurité"
      await tester.tap(find.text('Sécurité'));
      await tester.pumpAndSettle();

      // Should still be on settings hub (no navigation happened)
      expect(lastPushedLocation, '');
      expect(find.text('Réglages'), findsOneWidget);
    });
  });
}
