import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:k_budget/src/features/settings/presentation/data_settings_screen.dart';

void main() {
  Widget buildApp({DataMode initialMode = DataMode.local, String? serverUrl}) {
    return ProviderScope(
      overrides: [
        dataSettingsNotifierProvider.overrideWith(() {
          final notifier = DataSettingsNotifier();
          return notifier;
        }),
      ],
      child: const MaterialApp(
        home: DataSettingsScreen(),
      ),
    );
  }

  group('DataSettingsScreen', () {
    testWidgets('should display current data source', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Données'), findsOneWidget);
      expect(find.text('Source de données'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Serveur'), findsOneWidget);
    });

    testWidgets('should display URL field', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('URL du serveur'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should show validation error on empty URL when switching to server',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap on "Serveur" segment
      await tester.tap(find.text('Serveur'));
      await tester.pumpAndSettle();

      // Should show snackbar with validation error
      expect(find.text("L'URL du serveur est requise"), findsOneWidget);
    });

    testWidgets('should show validation error on invalid URL scheme',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Enter invalid URL
      await tester.enterText(find.byType(TextField), 'ftp://example.com');
      await tester.pumpAndSettle();

      // Tap on "Serveur" segment
      await tester.tap(find.text('Serveur'));
      await tester.pumpAndSettle();

      // Should show snackbar with URL format error
      expect(find.text("L'URL doit commencer par https://"), findsOneWidget);
    });

    testWidgets('should show confirmation dialog on valid URL switch',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Enter valid URL
      await tester.enterText(
          find.byType(TextField), 'https://budget.example.com/api');
      await tester.pumpAndSettle();

      // Tap on "Serveur" segment
      await tester.tap(find.text('Serveur'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Changer de source ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });

    testWidgets('should dismiss dialog on cancel', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), 'https://budget.example.com/api');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Serveur'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed, still on data settings
      expect(find.text('Changer de source ?'), findsNothing);
      expect(find.text('Données'), findsOneWidget);
    });

    testWidgets('should not show dialog when selecting already active source',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap on "Local" (already active) — should do nothing
      await tester.tap(find.text('Local'));
      await tester.pumpAndSettle();

      // No confirmation dialog
      expect(find.text('Changer de source ?'), findsNothing);
    });

    testWidgets('should display save button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer'), findsOneWidget);
    });
  });
}
