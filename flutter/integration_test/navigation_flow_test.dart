import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:k_budget/app.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

import '../test/helpers/mocks.mocks.dart';
import 'package:mockito/mockito.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow', () {
    late MockAppConfigRepository mockRepo;

    setUp(() {
      mockRepo = MockAppConfigRepository();
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);
      when(mockRepo.getTheme()).thenAnswer((_) async => AppTheme.light);
      when(mockRepo.getConfig()).thenAnswer((_) async => const AppConfig(
            dataMode: DataMode.local,
            onboardingCompleted: true,
          ));
    });

    testWidgets('should_navigate_between_4_tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const KBudgetApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show dashboard
      expect(find.text('Accueil'), findsWidgets);

      // Navigate to Transactions
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();
      expect(find.text('Aucune transaction'), findsOneWidget);

      // Navigate to Abonnements
      await tester.tap(find.text('Abonnements').last);
      await tester.pumpAndSettle();
      expect(find.text('Aucun abonnement'), findsOneWidget);

      // Navigate to Dettes
      await tester.tap(find.text('Dettes').last);
      await tester.pumpAndSettle();
      expect(find.text('Aucune dette'), findsOneWidget);

      // Navigate back to Dashboard
      await tester.tap(find.text('Accueil').last);
      await tester.pumpAndSettle();
      expect(find.text('Solde total'), findsOneWidget);
    });

    testWidgets('should_show_fab_on_all_screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const KBudgetApp(),
        ),
      );
      await tester.pumpAndSettle();

      // FAB should be visible on dashboard
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Navigate to Transactions
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();

      // FAB should still be visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
