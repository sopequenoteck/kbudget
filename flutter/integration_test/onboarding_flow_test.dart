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
    testWidgets('should_open_server_setup_when_app_not_configured',
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

      // No data mode choice: the server setup is the only way in
      expect(find.text('Configuration serveur'), findsOneWidget);
      expect(find.text('Mode local'), findsNothing);

      // Confirm stays disabled until the server has been checked
      final confirmButton = find.widgetWithText(ElevatedButton, 'Confirmer');
      expect(confirmButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    });
  });
}
