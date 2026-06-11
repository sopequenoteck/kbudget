import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/list_group.dart';
import 'package:k_budget/src/constants/app_radius.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un [ListGroup] dans un arbre de widgets avec le thème fourni.
Future<void> pumpListGroup(
  WidgetTester tester,
  ThemeData theme, {
  required List<Widget> children,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ListGroup(children: children),
        ),
      ),
    ),
  );
}

void main() {
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_n_minus_1_dividers_for_n_children_$themeName',
      (tester) async {
        const childCount = 5;
        await pumpListGroup(
          tester,
          theme,
          children: List.generate(
            childCount,
            (i) => Container(key: ValueKey('child_$i'), height: 40),
          ),
        );

        // 5 enfants → 4 dividers entre eux
        expect(find.byType(Divider), findsNWidgets(childCount - 1));
      },
    );

    testWidgets(
      'should_render_single_borderRadius_parent_$themeName',
      (tester) async {
        await pumpListGroup(
          tester,
          theme,
          children: [
            Container(key: const Key('child_0'), height: 40),
            Container(key: const Key('child_1'), height: 40),
          ],
        );

        // Un seul Container parent avec le BorderRadius attendu
        final containers = tester.widgetList<Container>(find.byType(Container));
        final containersWithBorderRadius = containers.where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            final borderRadius = decoration.borderRadius;
            if (borderRadius is BorderRadius) {
              return borderRadius.topLeft.x == AppRadius.xl;
            }
          }
          return false;
        }).toList();

        expect(containersWithBorderRadius.length, equals(1));
      },
    );

    testWidgets(
      'should_render_no_divider_when_single_child_$themeName',
      (tester) async {
        await pumpListGroup(
          tester,
          theme,
          children: [
            Container(key: const Key('only_child'), height: 40),
          ],
        );

        // 1 enfant → 0 divider
        expect(find.byType(Divider), findsNothing);
      },
    );
  });
}
