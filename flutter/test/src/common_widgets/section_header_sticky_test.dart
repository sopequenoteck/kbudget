import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/section_header_sticky.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un [SectionHeaderSticky] dans un [CustomScrollView] minimal.
///
/// La taille du device est fixée à 400×800 pour garantir un layout stable
/// dans l'environnement de test (évite les contraintes de paintExtent
/// insuffisantes pour le [SliverPersistentHeader]).
Future<void> pumpSectionHeader(
  WidgetTester tester,
  ThemeData theme, {
  String title = 'Transactions',
  int? count,
  List<Widget>? actions,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SectionHeaderSticky(
              title: title,
              count: count,
              actions: actions,
            ),
            SliverToBoxAdapter(
              child: Container(height: 2000),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Retourne la couleur de fond courante de l'[AnimatedContainer] du header.
///
/// L'[AnimatedContainer] ne lie pas directement sa propriété [color] en
/// lecture — il faut inspecter le [DecoratedBox] rendu en interne.
Color? _getHeaderBackgroundColor(WidgetTester tester) {
  final decoratedBoxes = tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(AnimatedContainer),
      matching: find.byType(DecoratedBox),
    ),
  );
  for (final box in decoratedBoxes) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration) {
      return decoration.color;
    }
  }
  return null;
}

void main() {
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_title_when_given_title_$themeName',
      (tester) async {
        await pumpSectionHeader(tester, theme, title: 'Transactions');

        expect(find.text('Transactions'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_count_when_given_count_$themeName',
      (tester) async {
        await pumpSectionHeader(tester, theme, title: 'Transactions', count: 5);

        expect(find.text('Transactions'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_actions_when_given_actions_$themeName',
      (tester) async {
        await pumpSectionHeader(
          tester,
          theme,
          title: 'Transactions',
          actions: [
            const Icon(Icons.filter_list, key: Key('filter_action')),
          ],
        );

        expect(find.byKey(const Key('filter_action')), findsOneWidget);
      },
    );

    testWidgets(
      'should_change_background_when_shrinkOffset_positive_$themeName',
      (tester) async {
        await pumpSectionHeader(tester, theme, title: 'Transactions');

        // Avant scroll : AnimatedContainer avec Colors.transparent
        // (pas de DecoratedBox coloré ou couleur transparente)
        final colorBefore = _getHeaderBackgroundColor(tester);
        // Colors.transparent peut être rendu comme null ou transparent
        final isTransparentBefore =
            colorBefore == null || colorBefore == Colors.transparent;
        expect(isTransparentBefore, isTrue);

        // Simule un scroll vers le bas pour déclencher shrinkOffset > 0
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -300),
        );
        // Laisse l'animation se terminer
        await tester.pumpAndSettle();

        final colorAfter = _getHeaderBackgroundColor(tester);
        expect(colorAfter, equals(theme.colorScheme.surfaceContainerHighest));
      },
    );

    testWidgets(
      'should_have_pinned_persistent_header_when_built_$themeName',
      (tester) async {
        await pumpSectionHeader(tester, theme, title: 'Transactions');

        final sliverPersistentHeader = tester.widget<SliverPersistentHeader>(
          find.byType(SliverPersistentHeader),
        );
        expect(sliverPersistentHeader.pinned, isTrue);
      },
    );
  });
}
