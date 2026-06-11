import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un [PageHeader] dans un arbre de widgets minimal avec le thème fourni.
Future<void> pumpPageHeader(
  WidgetTester tester,
  ThemeData theme, {
  String title = 'Mon compte',
  VoidCallback? onBack,
  Widget? icon,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PageHeader(
            title: title,
            onBack: onBack,
            icon: icon,
          ),
        ),
      ),
    ),
  );
}

void main() {
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_title_when_built_$themeName',
      (tester) async {
        await pumpPageHeader(tester, theme, title: 'Mon compte');

        expect(find.text('Mon compte'), findsOneWidget);
      },
    );

    testWidgets(
      'should_call_onBack_when_back_tapped_$themeName',
      (tester) async {
        var backCalled = false;
        await pumpPageHeader(
          tester,
          theme,
          onBack: () => backCalled = true,
        );

        await tester.tap(find.byType(IconButton));
        await tester.pump();

        expect(backCalled, isTrue);
      },
    );

    testWidgets(
      'should_render_icon_wrapped_in_circle_when_icon_provided_$themeName',
      (tester) async {
        await pumpPageHeader(
          tester,
          theme,
          icon: const Icon(Icons.star, key: Key('test_icon')),
        );

        // L'icône doit être présente
        expect(find.byKey(const Key('test_icon')), findsOneWidget);

        // Le Container ronde 32×32 wrappant l'icône doit être présent
        // (BoxShape.circle compilé en BorderRadius via la décoration interne)
        final circleContainers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            final borderRadius = decoration.borderRadius;
            if (borderRadius is BorderRadius) {
              return borderRadius.topLeft.x >= 100;
            }
            return decoration.shape == BoxShape.circle;
          }
          return false;
        }).toList();

        expect(circleContainers.length, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'should_render_without_icon_when_icon_null_$themeName',
      (tester) async {
        await pumpPageHeader(tester, theme, title: 'Sans icône');

        // Vérifier que le titre est bien affiché
        expect(find.text('Sans icône'), findsOneWidget);

        // Aucun Container avec un grand radius (cercle d'icône 32×32) ne doit exister
        final sizedContainers = tester.widgetList<Container>(
          find.byType(Container),
        ).where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            final borderRadius = decoration.borderRadius;
            if (borderRadius is BorderRadius) {
              return borderRadius.topLeft.x >= 100;
            }
          }
          return false;
        }).toList();

        expect(sizedContainers.length, equals(0));
      },
    );
  });
}
