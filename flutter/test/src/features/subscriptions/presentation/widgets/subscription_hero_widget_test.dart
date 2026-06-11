import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/subscriptions/presentation/widgets/subscription_hero_widget.dart';

import '../../../../../helpers/theme_test_helpers.dart';

void main() {
  Future<void> pumpSubscriptionHero(
    WidgetTester tester,
    ThemeData theme, {
    Map<Currency, double> monthlyTotals = const {},
    int activeCount = 0,
    bool isLoading = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SubscriptionHeroWidget(
          monthlyTotals: monthlyTotals,
          activeCount: activeCount,
          isLoading: isLoading,
        ),
      ),
    ));
  }

  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_key_subscription_hero_when_not_loading_$themeName',
      (tester) async {
        await pumpSubscriptionHero(
          tester,
          theme,
          monthlyTotals: const {Currency.eur: 25.0},
          activeCount: 2,
          isLoading: false,
        );

        expect(find.byKey(const Key('subscription_hero')), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_skeleton_key_when_loading_$themeName',
      (tester) async {
        await pumpSubscriptionHero(
          tester,
          theme,
          monthlyTotals: const {Currency.eur: 25.0},
          isLoading: true,
        );

        expect(
          find.byKey(const Key('subscription_hero_skeleton')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('subscription_hero')), findsNothing);
      },
    );

    testWidgets(
      'should_render_shrink_when_monthly_totals_empty_$themeName',
      (tester) async {
        await pumpSubscriptionHero(
          tester,
          theme,
          monthlyTotals: const {},
          isLoading: false,
        );

        // monthlyTotals vide + pas de loading → SizedBox.shrink()
        expect(find.byKey(const Key('subscription_hero')), findsNothing);
        expect(find.byKey(const Key('subscription_hero_skeleton')), findsNothing);
        expect(find.byType(SizedBox), findsWidgets);
      },
    );
  });
}
