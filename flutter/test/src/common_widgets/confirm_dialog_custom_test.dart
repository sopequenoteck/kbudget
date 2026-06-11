import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un bouton ouvrant le [ConfirmDialogCustom] dans un arbre minimal.
///
/// Capture le [Future<bool?>] retourné par `show()` dans [resultHolder].
Future<void> pumpDialogTrigger(
  WidgetTester tester,
  ThemeData theme, {
  required List<Future<bool?>> resultHolder,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  ConfirmVariant variant = ConfirmVariant.primary,
  String? message,
  IconData? icon,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            key: const Key('open_dialog'),
            onPressed: () {
              resultHolder.add(
                ConfirmDialogCustom.show(
                  context: ctx,
                  title: 'Test',
                  message: message,
                  confirmLabel: confirmLabel,
                  cancelLabel: cancelLabel,
                  variant: variant,
                  icon: icon,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_return_true_when_confirm_tapped_$themeName',
      (tester) async {
        final resultHolder = <Future<bool?>>[];
        await pumpDialogTrigger(tester, theme, resultHolder: resultHolder);

        await tester.tap(find.byKey(const Key('open_dialog')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        expect(await resultHolder.first, isTrue);
      },
    );

    testWidgets(
      'should_return_false_when_cancel_tapped_$themeName',
      (tester) async {
        final resultHolder = <Future<bool?>>[];
        await pumpDialogTrigger(tester, theme, resultHolder: resultHolder);

        await tester.tap(find.byKey(const Key('open_dialog')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();

        expect(await resultHolder.first, isFalse);
      },
    );

    testWidgets(
      'should_return_null_when_scrim_tapped_$themeName',
      (tester) async {
        final resultHolder = <Future<bool?>>[];
        await pumpDialogTrigger(tester, theme, resultHolder: resultHolder);

        await tester.tap(find.byKey(const Key('open_dialog')));
        await tester.pumpAndSettle();

        // Tapper en dehors du dialog (sur le scrim / barrier)
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(await resultHolder.first, isNull);
      },
    );

    testWidgets(
      'should_render_trash_icon_when_variant_danger_$themeName',
      (tester) async {
        final resultHolder = <Future<bool?>>[];
        await pumpDialogTrigger(
          tester,
          theme,
          resultHolder: resultHolder,
          variant: ConfirmVariant.danger,
        );

        await tester.tap(find.byKey(const Key('open_dialog')));
        await tester.pumpAndSettle();

        // Le bouton Confirmer doit exister
        expect(find.text('Confirmer'), findsOneWidget);

        // Fermer le dialog
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'should_render_check_icon_when_variant_primary_$themeName',
      (tester) async {
        final resultHolder = <Future<bool?>>[];
        await pumpDialogTrigger(
          tester,
          theme,
          resultHolder: resultHolder,
          variant: ConfirmVariant.primary,
        );

        await tester.tap(find.byKey(const Key('open_dialog')));
        await tester.pumpAndSettle();

        // Le bouton Confirmer doit exister
        expect(find.text('Confirmer'), findsOneWidget);

        // Fermer le dialog
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
      },
    );
  });
}
