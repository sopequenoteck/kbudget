import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/category_picker.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<void> pumpCategoryPicker(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Form(child: widget),
        ),
      ),
    ),
  );
}

const _testCategories = [
  Category(
    id: 'cat-1',
    nom: 'Alimentation',
    icone: '\u{1F354}',
    couleur: '#ef4444',
  ),
  Category(
    id: 'cat-2',
    nom: 'Transport',
    icone: '\u{1F68C}',
    couleur: '#3b82f6',
  ),
  Category(
    id: 'cat-3',
    nom: 'Loisirs',
    icone: '\u{1F3AE}',
    couleur: '#22c55e',
  ),
  Category(
    id: 'cat-4',
    nom: 'Sant\u00E9',
    icone: '\u{1FA7A}',
    couleur: '#a855f7',
  ),
  Category(
    id: 'cat-5',
    nom: 'Logement',
    icone: '\u{1F3E0}',
    couleur: '#f59e0b',
  ),
];

const _categorySansCouleur = Category(
  id: 'cat-no-color',
  nom: 'Divers',
  icone: '\u{1F4E6}',
  couleur: '',
);

void main() {
  // =====================================================
  // T004 [US1] — S\u00E9lection
  // =====================================================
  group('US1 - S\u00E9lection', () {
    testWidgets(
      'should_renderWithLabelAndPlaceholder_when_noSelection',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        expect(find.text('Cat\u00E9gorie'), findsOneWidget);
        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );

    testWidgets(
      'should_openModalWithAllCategories_when_triggerTapped',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('Alimentation'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
        expect(find.text('Loisirs'), findsOneWidget);
        expect(find.text('Sant\u00E9'), findsOneWidget);
        expect(find.text('Logement'), findsOneWidget);
      },
    );

    testWidgets(
      'should_callOnChangedWithId_when_categoryTapped',
      (tester) async {
        String? selectedId;

        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (id) => selectedId = id,
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Alimentation'));
        await tester.pumpAndSettle();

        expect(selectedId, 'cat-1');
      },
    );

    testWidgets(
      'should_showEmojiAndNameInTrigger_when_categorySelected',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-1',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        expect(find.text('\u{1F354}'), findsOneWidget);
        expect(find.text('Alimentation'), findsOneWidget);
        expect(find.text('S\u00E9lectionner...'), findsNothing);
      },
    );

    testWidgets(
      'should_updateTrigger_when_selectionChanges',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-1',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        expect(find.text('Alimentation'), findsOneWidget);

        // Rebuild with different selection
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-2',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Transport'), findsOneWidget);
      },
    );

    testWidgets(
      'should_notCallOnChanged_when_sameCategory_reTapped',
      (tester) async {
        String? changedId;

        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-1',
            onChanged: (id) => changedId = id,
            label: 'Cat\u00E9gorie',
          ),
        );

        // Open modal
        await tester.tap(find.text('Alimentation').first);
        await tester.pumpAndSettle();

        // Tap the same category in the modal
        await tester.tap(find.text('Alimentation').last);
        await tester.pumpAndSettle();

        expect(changedId, isNull);
      },
    );

    testWidgets(
      'should_highlightSelectedCategory_when_modalOpen',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-3',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        // Open modal
        await tester.tap(find.text('Loisirs').first);
        await tester.pumpAndSettle();

        final primaryColor = AppTheme.light.colorScheme.primary;
        final highlighted = tester.widgetList<Container>(
          find.byWidgetPredicate((widget) {
            if (widget is Container && widget.decoration is BoxDecoration) {
              final deco = widget.decoration as BoxDecoration;
              return deco.color == primaryColor.withValues(alpha: 0.08);
            }
            return false;
          }),
        );
        expect(highlighted, isNotEmpty);
      },
    );
  });

  // =====================================================
  // T005 [US2] — Recherche
  // =====================================================
  group('US2 - Recherche', () {
    testWidgets(
      'should_showSearch_when_categoriesAboveThreshold',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories, // 5 items, threshold = 5
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'should_hideSearch_when_categoriesBelowThreshold',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories.sublist(0, 3), // 3 items
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'should_filterByName_when_searchQueryEntered',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ali');
        await tester.pumpAndSettle();

        expect(find.text('Alimentation'), findsOneWidget);
        expect(find.text('Transport'), findsNothing);
        expect(find.text('Loisirs'), findsNothing);
      },
    );

    testWidgets(
      'should_showEmptyMessage_when_noMatchingCategories',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'zzzzz');
        await tester.pumpAndSettle();

        expect(find.text('Aucune cat\u00E9gorie'), findsOneWidget);
      },
    );

    testWidgets(
      'should_callOnSearchChanged_when_queryEntered',
      (tester) async {
        String? lastQuery;

        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            onSearchChanged: (query) => lastQuery = query,
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Transport');
        await tester.pumpAndSettle();

        expect(lastQuery, 'Transport');
      },
    );
  });

  // =====================================================
  // T006 [US3] — Affichage riche
  // =====================================================
  group('US3 - Affichage riche', () {
    testWidgets(
      'should_showEmojiInModal_when_categoryHasIcon',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('\u{1F354}'), findsOneWidget); // burger
        expect(find.text('\u{1F68C}'), findsOneWidget); // bus
        expect(find.text('\u{1F3AE}'), findsOneWidget); // game
      },
    );

    testWidgets(
      'should_showColorDot_when_categoryHasColor',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Check for color dot circles (ef4444 → 0xFFef4444)
        final colorDots = tester.widgetList<Container>(
          find.byWidgetPredicate((widget) {
            if (widget is Container && widget.decoration is BoxDecoration) {
              final deco = widget.decoration as BoxDecoration;
              return deco.shape == BoxShape.circle && deco.color != null;
            }
            return false;
          }),
        );
        // 5 categories, each with a color dot
        expect(colorDots.length, greaterThanOrEqualTo(5));
      },
    );

    testWidgets(
      'should_notShowColorDot_when_categoryHasNoColor',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: const [_categorySansCouleur],
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
            searchThreshold: 10,
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Emoji should be visible
        expect(find.text('\u{1F4E6}'), findsOneWidget);
        expect(find.text('Divers'), findsOneWidget);

        // No color dot circle should be present
        final colorDots = tester.widgetList<Container>(
          find.byWidgetPredicate((widget) {
            if (widget is Container && widget.decoration is BoxDecoration) {
              final deco = widget.decoration as BoxDecoration;
              return deco.shape == BoxShape.circle && deco.color != null;
            }
            return false;
          }),
        );
        expect(colorDots, isEmpty);
      },
    );

    testWidgets(
      'should_showEmojiAndNameInTrigger_when_selected',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-2',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        expect(find.text('\u{1F68C}'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
      },
    );
  });

  // =====================================================
  // T007 [US4] — Clearable
  // =====================================================
  group('US4 - Clearable', () {
    testWidgets(
      'should_showClearButton_when_clearableAndSelected',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-1',
            clearable: true,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        expect(
          find.byIcon(PhosphorIconsBold.x),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_hideClearButton_when_noSelection',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            clearable: true,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        expect(
          find.byIcon(PhosphorIconsRegular.caretDown),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_clearAndCallOnChanged_when_clearTapped',
      (tester) async {
        String? changedId = 'not-called';

        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-1',
            clearable: true,
            onChanged: (id) => changedId = id,
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.byIcon(PhosphorIconsBold.x));
        await tester.pumpAndSettle();

        expect(changedId, isNull);
        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );
  });

  // =====================================================
  // T008 [US5] — Validation
  // =====================================================
  group('US5 - Validation', () {
    testWidgets(
      'should_showError_when_validatorFailsAfterSubmit',
      (tester) async {
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: Form(
                  key: formKey,
                  child: CategoryPicker(
                    categories: _testCategories,
                    onChanged: (_) {},
                    label: 'Cat\u00E9gorie',
                    validator: (value) =>
                        value == null ? 'Cat\u00E9gorie requise' : null,
                    autovalidateMode: AutovalidateMode.disabled,
                  ),
                ),
              ),
            ),
          ),
        );

        formKey.currentState!.validate();
        await tester.pumpAndSettle();

        expect(find.text('Cat\u00E9gorie requise'), findsOneWidget);
      },
    );

    testWidgets(
      'should_hideError_when_categorySelected',
      (tester) async {
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: Form(
                  key: formKey,
                  child: CategoryPicker(
                    categories: _testCategories,
                    onChanged: (_) {},
                    label: 'Cat\u00E9gorie',
                    validator: (value) =>
                        value == null ? 'Cat\u00E9gorie requise' : null,
                    autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                  ),
                ),
              ),
            ),
          ),
        );

        // Trigger validation
        formKey.currentState!.validate();
        await tester.pumpAndSettle();
        expect(find.text('Cat\u00E9gorie requise'), findsOneWidget);

        // Select a category
        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Alimentation'));
        await tester.pumpAndSettle();

        expect(find.text('Cat\u00E9gorie requise'), findsNothing);
      },
    );

    testWidgets(
      'should_autoReset_when_selectedCategoryRemovedFromList',
      (tester) async {
        String? changedId = 'not-called';
        var categories = _testCategories.toList();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CategoryPicker(
                            categories: categories,
                            selectedId: 'cat-1',
                            onChanged: (id) => changedId = id,
                            label: 'Cat\u00E9gorie',
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                categories =
                                    _testCategories.sublist(1).toList();
                              });
                            },
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('Alimentation'), findsOneWidget);

        // Trigger rebuild without the selected category
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(changedId, isNull);
        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );
  });

  // =====================================================
  // T009 [US6] — Bouton "+ Cr\u00E9er"
  // =====================================================
  group('US6 - Bouton + Cr\u00E9er', () {
    testWidgets(
      'should_showCreateButton_when_onCreateRequestedAndNoResults',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
            onCreateRequested: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Voyages');
        await tester.pumpAndSettle();

        expect(
          find.text('+ Cr\u00E9er \u00AB Voyages \u00BB'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_callOnCreateAndCloseModal_when_createButtonTapped',
      (tester) async {
        String? createdTerm;

        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
            onCreateRequested: (term) => createdTerm = term,
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Voyages');
        await tester.pumpAndSettle();

        await tester.tap(
          find.text('+ Cr\u00E9er \u00AB Voyages \u00BB'),
        );
        await tester.pumpAndSettle();

        expect(createdTerm, 'Voyages');
        // Modal should be closed
        expect(
          find.text('+ Cr\u00E9er \u00AB Voyages \u00BB'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should_notShowCreateButton_when_partialResultsExist',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
            onCreateRequested: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ali');
        await tester.pumpAndSettle();

        expect(find.text('Alimentation'), findsOneWidget);
        expect(find.textContaining('+ Cr\u00E9er'), findsNothing);
      },
    );

    testWidgets(
      'should_showEmptyMessage_when_noCallbackAndNoResults',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
            // No onCreateRequested
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'zzzzz');
        await tester.pumpAndSettle();

        expect(find.text('Aucune cat\u00E9gorie'), findsOneWidget);
        expect(find.textContaining('+ Cr\u00E9er'), findsNothing);
      },
    );
  });

  // =====================================================
  // T010 [US7] — Accessibilit\u00E9
  // =====================================================
  group('US7 - Accessibilit\u00E9', () {
    testWidgets(
      'should_haveSemanticsButton_when_triggerRendered',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        final semanticsButtons = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) => s.properties.button == true)
            .toList();
        expect(semanticsButtons, isNotEmpty);
      },
    );

    testWidgets(
      'should_haveSemanticsOnCreateButton_when_createButtonVisible',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
            onCreateRequested: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Voyages');
        await tester.pumpAndSettle();

        final createSemantics = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) =>
                s.properties.button == true &&
                s.properties.label != null &&
                s.properties.label!.contains('Cr\u00E9er'))
            .toList();
        expect(createSemantics, isNotEmpty);
      },
    );
  });

  // =====================================================
  // T011 — Edge Cases
  // =====================================================
  group('Edge Cases', () {
    testWidgets(
      'should_beNonInteractive_when_disabled',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            enabled: false,
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        final opacity = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacity.opacity, 0.5);

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Modal should not open
        expect(find.text('Alimentation'), findsNothing);
      },
    );

    testWidgets(
      'should_renderWithoutError_when_darkTheme',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: _testCategories,
            selectedId: 'cat-1',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
          theme: AppTheme.dark,
        );

        expect(find.text('Alimentation'), findsOneWidget);
        expect(find.text('\u{1F354}'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showEmptyMessage_when_emptyList',
      (tester) async {
        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: const [],
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('Aucune cat\u00E9gorie'), findsOneWidget);
      },
    );

    testWidgets(
      'should_truncateWithEllipsis_when_categoryNameTooLong',
      (tester) async {
        final longName = 'A' * 200;

        await pumpCategoryPicker(
          tester,
          CategoryPicker(
            categories: [
              Category(
                id: 'cat-long',
                nom: longName,
                icone: '\u{1F4E6}',
                couleur: '#000000',
              ),
            ],
            selectedId: 'cat-long',
            onChanged: (_) {},
            label: 'Cat\u00E9gorie',
          ),
        );

        final texts = tester.widgetList<Text>(find.text(longName));
        for (final text in texts) {
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }
      },
    );
  });
}
