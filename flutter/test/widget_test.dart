import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/app.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/mockito.dart';

import 'helpers/mocks.mocks.dart';

void main() {
  testWidgets('App renders correctly and shows onboarding',
      (WidgetTester tester) async {
    final mockRepo = MockAppConfigRepository();
    when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => false);
    when(mockRepo.getTheme()).thenAnswer((_) async => AppTheme.light);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const KBudgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app should redirect to onboarding since it's not completed
    expect(find.text('Bienvenue sur K-Budget'), findsOneWidget);
  });
}
