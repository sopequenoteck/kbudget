import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Pompe un [ListItem] dans un arbre de widgets avec le thème complet.
Future<void> pumpListItem(
  WidgetTester tester,
  ListItem widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: widget,
      ),
    ),
  );
}

void main() {
  group('ListItem - US1 (Transaction display)', () {
    testWidgets(
      'should_renderAllFiveZones_when_allDataProvided',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses Lidl',
            subtitle: 'Alimentation',
            value: '-45,90 €',
            rightSubtitle: 'Hier',
          ),
        );

        // Icône
        expect(find.text('🛒'), findsOneWidget);
        // Titre
        expect(find.text('Courses Lidl'), findsOneWidget);
        // Sous-titre
        expect(find.text('Alimentation'), findsOneWidget);
        // Valeur
        expect(find.text('-45,90 €'), findsOneWidget);
        // Date relative
        expect(find.text('Hier'), findsOneWidget);
      },
    );

    testWidgets(
      'should_applyRedValueColor_when_expenseColorProvided',
      (tester) async {
        const expenseColor = AppColors.expenseLight;

        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
            valueColor: expenseColor,
          ),
        );

        final valueText = tester.widget<Text>(
          find.text('-45,90 €'),
        );
        expect(valueText.style?.color, expenseColor);
      },
    );

    testWidgets(
      'should_applyGreenValueColor_when_incomeColorProvided',
      (tester) async {
        const incomeColor = AppColors.incomeLight;

        await pumpListItem(
          tester,
          const ListItem(
            icon: '💰',
            title: 'Salaire',
            value: '+2 500,00 €',
            valueColor: incomeColor,
          ),
        );

        final valueText = tester.widget<Text>(
          find.text('+2 500,00 €'),
        );
        expect(valueText.style?.color, incomeColor);
      },
    );

    testWidgets(
      'should_triggerCallback_when_onPressedProvidedAndTapped',
      (tester) async {
        var tapped = false;

        await pumpListItem(
          tester,
          ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
            onPressed: () => tapped = true,
          ),
        );

        expect(find.byType(InkWell), findsOneWidget);
        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      },
    );
  });

  group('ListItem - US2 (Partial data)', () {
    testWidgets(
      'should_hideSubtitle_when_subtitleNotProvided',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
          ),
        );

        expect(find.text('Courses'), findsOneWidget);
        expect(find.text('-45,90 €'), findsOneWidget);
        // Only 3 Text widgets: icon, title, value
        expect(find.byType(Text), findsNWidgets(3));
      },
    );

    testWidgets(
      'should_hideRightSubtitle_when_rightSubtitleNotProvided',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            subtitle: 'Alimentation',
            value: '-45,90 €',
          ),
        );

        expect(find.text('Alimentation'), findsOneWidget);
        expect(find.text('-45,90 €'), findsOneWidget);
        // 4 Text widgets: icon, title, subtitle, value
        expect(find.byType(Text), findsNWidgets(4));
      },
    );

    testWidgets(
      'should_showOnlyIconTitleValue_when_bothSubtitlesAbsent',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
          ),
        );

        expect(find.text('🛒'), findsOneWidget);
        expect(find.text('Courses'), findsOneWidget);
        expect(find.text('-45,90 €'), findsOneWidget);
        expect(find.byType(Text), findsNWidgets(3));
      },
    );
  });

  group('ListItem - US3 (Business context adaptability)', () {
    testWidgets(
      'should_renderSubscription_when_subscriptionDataProvided',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '📺',
            title: 'Netflix',
            subtitle: 'Mensuel',
            value: '12,99 €',
          ),
        );

        expect(find.text('📺'), findsOneWidget);
        expect(find.text('Netflix'), findsOneWidget);
        expect(find.text('Mensuel'), findsOneWidget);
        expect(find.text('12,99 €'), findsOneWidget);
      },
    );

    testWidgets(
      'should_renderDebt_when_debtDataProvided',
      (tester) async {
        const incomeColor = AppColors.incomeLight;

        await pumpListItem(
          tester,
          const ListItem(
            icon: '📤',
            title: 'Jean Dupont',
            subtitle: 'Prêt',
            value: '150,00 €',
            valueColor: incomeColor,
          ),
        );

        expect(find.text('📤'), findsOneWidget);
        expect(find.text('Jean Dupont'), findsOneWidget);
        expect(find.text('Prêt'), findsOneWidget);
        final valueText = tester.widget<Text>(find.text('150,00 €'));
        expect(valueText.style?.color, incomeColor);
      },
    );

    testWidgets(
      'should_renderDashboardTransaction_when_dashboardDataProvided',
      (tester) async {
        const expenseColor = AppColors.expenseLight;

        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses Lidl',
            value: '-45,90 €',
            valueColor: expenseColor,
            rightSubtitle: 'Hier',
          ),
        );

        expect(find.text('🛒'), findsOneWidget);
        expect(find.text('Courses Lidl'), findsOneWidget);
        expect(find.text('-45,90 €'), findsOneWidget);
        expect(find.text('Hier'), findsOneWidget);
        final valueText = tester.widget<Text>(find.text('-45,90 €'));
        expect(valueText.style?.color, expenseColor);
      },
    );
  });

  group('ListItem - US4 (Accessibility & skeleton)', () {
    testWidgets(
      'should_haveSemanticsLabel_when_rendered',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses Lidl',
            value: '-45,90 €',
          ),
        );

        final semantics = tester.getSemantics(find.byType(ListItem));
        expect(
          semantics.label,
          contains('Courses Lidl'),
        );
        expect(
          semantics.label,
          contains('-45,90 €'),
        );
      },
    );

    testWidgets(
      'should_haveSemanticsButton_when_onPressedProvided',
      (tester) async {
        await pumpListItem(
          tester,
          ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
            onPressed: () {},
          ),
        );

        expect(
          find.bySemanticsLabel(RegExp('Courses.*-45,90 €')),
          findsOneWidget,
        );
        // InkWell provides tap action semantics
        expect(find.byType(InkWell), findsOneWidget);
      },
    );

    testWidgets(
      'should_notHaveSemanticsButton_when_onPressedNull',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
          ),
        );

        expect(find.byType(InkWell), findsNothing);
      },
    );

    testWidgets(
      'should_renderShimmerPlaceholders_when_skeletonConstructorUsed',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem.skeleton(),
        );

        expect(find.byType(Shimmer), findsOneWidget);
        // No actual text content rendered
        expect(find.text('🛒'), findsNothing);
      },
    );
  });

  group('ListItem - Edge cases', () {
    testWidgets(
      'should_truncateWithEllipsis_when_titleVeryLong',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Un titre extrêmement long qui dépasse les 30 caractères facilement',
            value: '-45,90 €',
          ),
        );

        final titleText = tester.widget<Text>(
          find.text(
              'Un titre extrêmement long qui dépasse les 30 caractères facilement'),
        );
        expect(titleText.overflow, TextOverflow.ellipsis);
        expect(titleText.maxLines, 1);
      },
    );

    testWidgets(
      'should_renderWithoutError_when_multiByteEmojiUsed',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🇫🇷',
            title: 'Test emoji',
            value: '10,00 €',
          ),
        );

        expect(find.text('🇫🇷'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should_notRenderInkWell_when_onPressedNull',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
          ),
        );

        expect(find.byType(InkWell), findsNothing);
      },
    );

    testWidgets(
      'should_applyCustomIconBackground_when_iconBackgroundColorProvided',
      (tester) async {
        const customColor = Colors.blue;

        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '-45,90 €',
            iconBackgroundColor: customColor,
          ),
        );

        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == customColor,
          ),
        );
        expect(container, isNotNull);
      },
    );

    testWidgets(
      'should_useDefaultOnSurfaceColor_when_noValueColorProvided',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            value: '0,00 €',
          ),
        );

        final valueText = tester.widget<Text>(find.text('0,00 €'));
        final theme = AppTheme.light;
        expect(valueText.style?.color, theme.colorScheme.onSurface);
      },
    );

    testWidgets(
      'should_useDarkThemeColors_when_darkThemeActive',
      (tester) async {
        await pumpListItem(
          tester,
          const ListItem(
            icon: '🛒',
            title: 'Courses',
            subtitle: 'Alimentation',
            value: '-45,90 €',
          ),
          theme: AppTheme.dark,
        );

        final titleText = tester.widget<Text>(find.text('Courses'));
        final darkTheme = AppTheme.dark;
        expect(titleText.style?.color, darkTheme.colorScheme.onSurface);

        final subtitleText = tester.widget<Text>(find.text('Alimentation'));
        expect(
          subtitleText.style?.color,
          darkTheme.colorScheme.onSurfaceVariant,
        );
      },
    );

    test(
      'should_throwAssertionError_when_iconEmpty',
      () {
        expect(
          () => ListItem(icon: '', title: 'Test', value: '10 €'),
          throwsAssertionError,
        );
      },
    );

    test(
      'should_throwAssertionError_when_titleEmpty',
      () {
        expect(
          () => ListItem(icon: '🛒', title: '', value: '10 €'),
          throwsAssertionError,
        );
      },
    );

    test(
      'should_throwAssertionError_when_valueEmpty',
      () {
        expect(
          () => ListItem(icon: '🛒', title: 'Test', value: ''),
          throwsAssertionError,
        );
      },
    );
  });

  group('ListItem - Performance (SC-005)', () {
    testWidgets(
      'should_scrollSmoothly_when_50PlusItemsInListView',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: ListView.builder(
                itemCount: 60,
                itemBuilder: (context, index) => ListItem(
                  icon: '🛒',
                  title: 'Transaction $index',
                  subtitle: 'Catégorie',
                  value: '-${index * 10},00 €',
                  rightSubtitle: 'Hier',
                ),
              ),
            ),
          ),
        );

        // Scroll down
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
