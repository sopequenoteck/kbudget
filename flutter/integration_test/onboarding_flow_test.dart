import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:k_budget/app.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/data/app_config_repository_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow', () {
    testWidgets('should_complete_local_mode_onboarding',
        (WidgetTester tester) async {
      // Use a fresh AppConfigRepository for each test
      final freshRepo = AppConfigRepositoryImpl();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigRepositoryProvider.overrideWithValue(freshRepo),
          ],
          child: const KBudgetApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show onboarding screen
      expect(find.text('Bienvenue sur K-Budget'), findsOneWidget);

      // Select local mode
      await tester.tap(find.text('Mode local'));
      await tester.pumpAndSettle();

      // Confirm button should be enabled
      final confirmButton = find.widgetWithText(FilledButton, 'Confirmer');
      expect(confirmButton, findsOneWidget);

      // Tap confirm
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Should navigate to dashboard
      expect(find.text('Accueil'), findsWidgets);
    });
  });
}
