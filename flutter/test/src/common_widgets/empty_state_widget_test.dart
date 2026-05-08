import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/empty_state_widget.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un [EmptyStateWidget] dans un arbre de widgets minimal avec le thème fourni.
Future<void> pumpEmptyStateWidget(
  WidgetTester tester,
  ThemeData theme, {
  IconData? icon,
  String message = 'Aucune transaction',
  String? hint,
  String? ctaLabel,
  VoidCallback? onCtaTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: EmptyStateWidget(
          icon: icon,
          message: message,
          hint: hint,
          ctaLabel: ctaLabel,
          onCtaTap: onCtaTap,
        ),
      ),
    ),
  );
}

void main() {
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_message_when_built_$themeName',
      (tester) async {
        await pumpEmptyStateWidget(
          tester,
          theme,
          message: 'Aucune transaction',
        );

        expect(find.text('Aucune transaction'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_icon_when_icon_provided_$themeName',
      (tester) async {
        await pumpEmptyStateWidget(
          tester,
          theme,
          icon: Icons.folder,
          message: 'Aucun dossier',
        );

        expect(find.byIcon(Icons.folder), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_hint_when_hint_provided_$themeName',
      (tester) async {
        await pumpEmptyStateWidget(
          tester,
          theme,
          message: 'Aucune catégorie',
          hint: 'Tapez + pour ajouter',
        );

        expect(find.text('Aucune catégorie'), findsOneWidget);
        expect(find.text('Tapez + pour ajouter'), findsOneWidget);
      },
    );

    testWidgets(
      'should_call_onCtaTap_when_cta_tapped_$themeName',
      (tester) async {
        var ctaTapped = false;
        await pumpEmptyStateWidget(
          tester,
          theme,
          message: 'Aucune transaction',
          ctaLabel: '+ Créer',
          onCtaTap: () => ctaTapped = true,
        );

        expect(find.text('+ Créer'), findsOneWidget);
        await tester.tap(find.text('+ Créer'));
        await tester.pump();

        expect(ctaTapped, isTrue);
      },
    );
  });
}
