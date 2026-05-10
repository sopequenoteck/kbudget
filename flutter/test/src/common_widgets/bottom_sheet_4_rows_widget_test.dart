import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';
import 'package:k_budget/src/theme/app_theme.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un [BottomSheet4RowsWidget] dans un arbre de widgets minimal avec le thème fourni.
Future<void> pumpSheet(
  WidgetTester tester,
  ThemeData theme,
  BottomSheet4RowsWidget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: widget,
      ),
    ),
  );
}

/// Widget minimal servant de slot injecté dans les tests.
Widget _slot(String key) => Container(key: ValueKey(key));

void main() {
  // ---------------------------------------------------------------------------
  // SC-001 — 4 rows keys présentes avec slots minimaux
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_4_rows_keys_when_minimal_slots_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: [_slot('pill')],
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_top')), findsOneWidget);
        expect(find.byKey(const Key('bsheet_main_row')), findsOneWidget);
        expect(find.byKey(const Key('bsheet_meta_row')), findsOneWidget);
        expect(find.byKey(const Key('bsheet_bottom_row')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-001b — Row 3 absente quand metaPills vide et iconButtons null
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_hide_meta_row_when_empty_pills_and_no_icons_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_meta_row')), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-002 — Slots injectés présents inchangés (3 variantes)
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_find_injected_slots_when_all_optional_slots_provided_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('test-amount'),
            libelleField: _slot('test-libelle'),
            metaPills: [_slot('test-pill-1'), _slot('test-pill-2')],
            iconButtons: [_slot('test-icon')],
            topTrailing: _slot('test-trailing'),
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const ValueKey('test-amount')), findsOneWidget);
        expect(find.byKey(const ValueKey('test-libelle')), findsOneWidget);
        expect(find.byKey(const ValueKey('test-pill-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('test-pill-2')), findsOneWidget);
        expect(find.byKey(const ValueKey('test-icon')), findsOneWidget);
        expect(find.byKey(const ValueKey('test-trailing')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-003 — expandedContent null → bsheet_expand absent ; non-null → présent
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_show_bsheet_expand_when_expandedContent_not_null_$themeName',
      (tester) async {
        // Premier build : expandedContent null → bsheet_expand absent
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            onCancel: () {},
            onSubmit: () {},
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('bsheet_expand')), findsNothing);

        // Rebuild avec expandedContent non null → bsheet_expand présent
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            expandedContent: _slot('expand-content'),
            onCancel: () {},
            onSubmit: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('bsheet_expand')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-004 — loading: true → spinner présent + onSubmit non invoqué
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_show_spinner_and_block_onSubmit_when_loading_true_$themeName',
      (tester) async {
        int submitCount = 0;

        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            loading: true,
            onCancel: () {},
            onSubmit: () => submitCount++,
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byKey(const Key('bsheet_submit')));
        await tester.pump();

        expect(submitCount, equals(0));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-005 — errorMessage → bandeau bsheet_error_banner présent
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_show_error_banner_when_errorMessage_provided_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            errorMessage: 'Montant invalide',
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_error_banner')), findsOneWidget);
        expect(find.text('Montant invalide'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-006 — loading + errorMessage coexistent
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_show_spinner_and_error_banner_when_loading_and_error_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            loading: true,
            errorMessage: 'Erreur réseau',
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byKey(const Key('bsheet_error_banner')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-007 — footerLeading à gauche de Row 4
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_footerLeading_in_footer_when_provided_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            footerLeading: [_slot('test-leading')],
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const ValueKey('test-leading')), findsOneWidget);
        // bsheet_cancel absent car footerLeading non null
        expect(find.byKey(const Key('bsheet_cancel')), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-008 — footerEnabled: false → callbacks bloqués (submit + cancel)
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_block_submit_and_cancel_when_footerEnabled_false_$themeName',
      (tester) async {
        int submitCount = 0;
        int cancelCount = 0;

        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            footerEnabled: false,
            onCancel: () => cancelCount++,
            onSubmit: () => submitCount++,
          ),
        );

        await tester.tap(
          find.byKey(const Key('bsheet_submit')),
          warnIfMissed: false,
        );
        await tester.tap(
          find.byKey(const Key('bsheet_cancel')),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(submitCount, equals(0));
        expect(cancelCount, equals(0));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-010 — Thèmes dark + light : tous les tests passent (couvert via forEachTheme)
  // Les SC 001–008 et 012–014 utilisent déjà forEachTheme. Ce test explicite
  // vérifie que le widget se construit sans exception sur les 2 thèmes.
  // ---------------------------------------------------------------------------
  for (final entry in [
    (AppTheme.dark, 'dark'),
    (AppTheme.light, 'light'),
  ]) {
    final theme = entry.$1;
    final themeName = entry.$2;
    testWidgets(
      'should_build_without_exception_on_theme_$themeName',
      (tester) async {
        await expectLater(
          () async => pumpSheet(
            tester,
            theme,
            BottomSheet4RowsWidget(
              title: 'Thème $themeName',
              amountField: _slot('amount'),
              metaPills: [_slot('pill')],
              onCancel: () {},
              onSubmit: () {},
            ),
          ),
          returnsNormally,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SC-012 — 3 hauteurs sans overflow (320 / 600 / 900 px)
  // ---------------------------------------------------------------------------
  for (final height in [320.0, 600.0, 900.0]) {
    testWidgets(
      'should_render_without_overflow_when_height_${height.toInt()}px',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(400, height));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pumpSheet(
          tester,
          AppTheme.dark,
          BottomSheet4RowsWidget(
            title: 'Test overflow',
            amountField: _slot('amount'),
            metaPills: [_slot('pill')],
            onCancel: () {},
            onSubmit: () {},
          ),
        );
        await tester.pump();

        // Pas d'exception de rendu = pas d'overflow
        expect(tester.takeException(), isNull);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SC-013 — notePreview null vs non-null
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_hide_note_preview_when_notePreview_null_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_note_preview')), findsNothing);
      },
    );

    testWidgets(
      'should_show_note_preview_when_notePreview_provided_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            notePreview: _slot('note-content'),
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_note_preview')), findsOneWidget);
        expect(find.byKey(const ValueKey('note-content')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SC-014 — footerLeading : 3 cas
  //   (a) null → bouton Annuler rendu
  //   (b) [1 widget] → Annuler absent, widget présent
  //   (c) [2 widgets] → Annuler absent, 2 widgets présents
  // ---------------------------------------------------------------------------
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_cancel_button_when_footerLeading_null_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            footerLeading: null,
            onCancel: () {},
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_cancel')), findsOneWidget);
      },
    );

    testWidgets(
      'should_hide_cancel_when_footerLeading_has_one_widget_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            footerLeading: [_slot('leading-a')],
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_cancel')), findsNothing);
        expect(find.byKey(const ValueKey('leading-a')), findsOneWidget);
      },
    );

    testWidgets(
      'should_hide_cancel_when_footerLeading_has_two_widgets_$themeName',
      (tester) async {
        await pumpSheet(
          tester,
          theme,
          BottomSheet4RowsWidget(
            title: 'Test',
            amountField: _slot('amount'),
            metaPills: const [],
            footerLeading: [_slot('leading-x'), _slot('leading-y')],
            onSubmit: () {},
          ),
        );

        expect(find.byKey(const Key('bsheet_cancel')), findsNothing);
        expect(find.byKey(const ValueKey('leading-x')), findsOneWidget);
        expect(find.byKey(const ValueKey('leading-y')), findsOneWidget);
      },
    );
  });
}
