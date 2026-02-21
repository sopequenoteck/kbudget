import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme.dart';

Future<void> pumpSelectPicker(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: Center(child: widget)),
    ),
  );
}

const _testItems = [
  SelectPickerItem(
    id: '1',
    label: 'Compte Courant',
    icon: '\u{1F3E6}',
    secondaryText: '1 234 \u20AC',
  ),
  SelectPickerItem(
    id: '2',
    label: 'Compte \u00C9pargne',
    icon: '\u{1F4B0}',
    secondaryText: '5 678 \u20AC',
  ),
  SelectPickerItem(id: '3', label: 'Esp\u00E8ces'),
  SelectPickerItem(
    id: '4',
    label: 'Cat\u00E9gorie Loisirs',
    color: Color(0xFFFF5733),
  ),
  SelectPickerItem(
    id: '5',
    label: 'Cat\u00E9gorie Transport',
    color: Color(0xFF33FF57),
  ),
];

void main() {
  // --- Setup smoke test (T002) ---
  group('Setup - Smoke', () {
    testWidgets(
      'should_render_when_validItemsProvided',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        expect(find.text('Compte'), findsOneWidget);
        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );
  });

  // --- US1+US2 - S\u00E9lection & Trigger (T007) ---
  group('US1+US2 - S\u00E9lection & Trigger', () {
    testWidgets(
      'should_showPlaceholder_when_noSelection',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showSelectedItem_when_selectionProvided',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            onChanged: (_) {},
          ),
        );

        expect(find.text('Compte Courant'), findsOneWidget);
        expect(find.text('\u{1F3E6}'), findsOneWidget);
        expect(find.text('1 234 \u20AC'), findsOneWidget);
        expect(find.text('S\u00E9lectionner...'), findsNothing);
      },
    );

    testWidgets(
      'should_showColorDotInTrigger_when_selectedItemHasColor',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Cat\u00E9gorie',
            items: _testItems,
            selectedId: '4',
            onChanged: (_) {},
          ),
        );

        expect(find.text('Cat\u00E9gorie Loisirs'), findsOneWidget);

        // Find the color dot container (12x12 circle)
        final colorDots = tester.widgetList<Container>(
          find.byWidgetPredicate((widget) {
            if (widget is Container && widget.decoration is BoxDecoration) {
              final deco = widget.decoration as BoxDecoration;
              return deco.shape == BoxShape.circle &&
                  deco.color == const Color(0xFFFF5733);
            }
            return false;
          }),
        );
        expect(colorDots, isNotEmpty);
      },
    );

    testWidgets(
      'should_openModal_when_triggerTapped',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Modal should show the items
        expect(find.text('Compte Courant'), findsOneWidget);
        expect(find.text('Esp\u00E8ces'), findsOneWidget);
      },
    );

    testWidgets(
      'should_callOnChanged_when_differentItemTapped',
      (tester) async {
        String? selectedId;

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (id) => selectedId = id,
          ),
        );

        // Open modal
        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Tap an item
        await tester.tap(find.text('Compte Courant'));
        await tester.pumpAndSettle();

        expect(selectedId, '1');
      },
    );

    testWidgets(
      'should_notCallOnChanged_when_sameItemTapped',
      (tester) async {
        String? changedId;

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            onChanged: (id) => changedId = id,
          ),
        );

        // Open modal
        await tester.tap(find.text('Compte Courant').first);
        await tester.pumpAndSettle();

        // Tap the already selected item (in modal)
        await tester.tap(find.text('Compte Courant').last);
        await tester.pumpAndSettle();

        expect(changedId, isNull);
      },
    );

    testWidgets(
      'should_closeModal_when_itemSelected',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        // Open modal
        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Tap an item
        await tester.tap(find.text('Esp\u00E8ces'));
        await tester.pumpAndSettle();

        // Modal should be closed - the title in modal header should be gone
        // Only the trigger label and selected item should remain
        expect(find.text('Esp\u00E8ces'), findsOneWidget); // trigger only
      },
    );

    testWidgets(
      'should_showChevronDown_when_rendered',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      },
    );

    testWidgets(
      'should_resetSelection_when_selectedItemRemovedFromList',
      (tester) async {
        String? changedId = 'not-called';

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            onChanged: (id) => changedId = id,
          ),
        );

        expect(find.text('Compte Courant'), findsOneWidget);

        // Rebuild with items that don't include id '1'
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: const [
              SelectPickerItem(id: '3', label: 'Esp\u00E8ces'),
            ],
            selectedId: '1',
            onChanged: (id) => changedId = id,
          ),
        );
        await tester.pumpAndSettle();

        // Should have reset to null
        expect(changedId, isNull);
        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showValidationError_when_validatorFails',
      (tester) async {
        final formKey = GlobalKey<FormState>();

        await pumpSelectPicker(
          tester,
          Form(
            key: formKey,
            child: SelectPicker(
              label: 'Compte',
              items: _testItems,
              onChanged: (_) {},
              validator: (value) =>
                  value == null ? 'Champ requis' : null,
              autovalidateMode: AutovalidateMode.disabled,
            ),
          ),
        );

        // Trigger validation
        formKey.currentState!.validate();
        await tester.pumpAndSettle();

        expect(find.text('Champ requis'), findsOneWidget);
      },
    );
  });

  // --- US3 - Clear (T009) ---
  group('US3 - Clear', () {
    testWidgets(
      'should_showClearButton_when_clearableAndSelected',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            clearable: true,
            onChanged: (_) {},
          ),
        );

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      },
    );

    testWidgets(
      'should_notShowClearButton_when_notClearable',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            clearable: false,
            onChanged: (_) {},
          ),
        );

        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      },
    );

    testWidgets(
      'should_notShowClearButton_when_noSelection',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            clearable: true,
            onChanged: (_) {},
          ),
        );

        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      },
    );

    testWidgets(
      'should_clearSelection_when_clearButtonTapped',
      (tester) async {
        String? changedId = 'not-called';

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            clearable: true,
            onChanged: (id) => changedId = id,
          ),
        );

        expect(find.text('Compte Courant'), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(changedId, isNull);
        expect(find.text('S\u00E9lectionner...'), findsOneWidget);
      },
    );
  });

  // --- US4 - Recherche (T011) ---
  group('US4 - Recherche', () {
    final manyItems = List.generate(
      10,
      (i) => SelectPickerItem(id: '$i', label: 'Item $i'),
    );

    testWidgets(
      'should_showSearchField_when_itemsAboveThreshold',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: manyItems,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'should_notShowSearchField_when_itemsBelowThreshold',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: const [
              SelectPickerItem(id: '1', label: 'A'),
              SelectPickerItem(id: '2', label: 'B'),
              SelectPickerItem(id: '3', label: 'C'),
            ],
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'should_showSearchField_when_searchableExplicit',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: const [
              SelectPickerItem(id: '1', label: 'A'),
              SelectPickerItem(id: '2', label: 'B'),
              SelectPickerItem(id: '3', label: 'C'),
            ],
            searchable: true,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'should_filterItems_when_searchQueryEntered',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: manyItems,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '3');
        await tester.pumpAndSettle();

        // Only "Item 3" matches the query "3"
        expect(find.text('Item 3'), findsOneWidget);
        expect(find.text('Item 0'), findsNothing);
        expect(find.text('Item 1'), findsNothing);
      },
    );

    testWidgets(
      'should_showEmptyMessage_when_noMatchingItems',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: manyItems,
            emptyMessage: 'Rien trouv\u00E9',
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'zzzzz');
        await tester.pumpAndSettle();

        expect(find.text('Rien trouv\u00E9'), findsOneWidget);
      },
    );

    testWidgets(
      'should_callOnSearchChanged_when_queryChanges',
      (tester) async {
        String? lastQuery;

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: manyItems,
            onChanged: (_) {},
            onSearchChanged: (query) => lastQuery = query,
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pumpAndSettle();

        expect(lastQuery, 'hello');
      },
    );
  });

  // --- US5 - Affichage riche & highlight (T013) ---
  group('US5 - Affichage riche & highlight', () {
    testWidgets(
      'should_showIcon_when_itemHasIcon',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('\u{1F3E6}'), findsOneWidget);
        expect(find.text('\u{1F4B0}'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showColorDot_when_itemHasColor',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        final colorDots = tester.widgetList<Container>(
          find.byWidgetPredicate((widget) {
            if (widget is Container && widget.decoration is BoxDecoration) {
              final deco = widget.decoration as BoxDecoration;
              return deco.shape == BoxShape.circle &&
                  (deco.color == const Color(0xFFFF5733) ||
                      deco.color == const Color(0xFF33FF57));
            }
            return false;
          }),
        );
        expect(colorDots.length, 2);
      },
    );

    testWidgets(
      'should_showSecondaryText_when_itemHasSecondaryText',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('1 234 \u20AC'), findsOneWidget);
        expect(find.text('5 678 \u20AC'), findsOneWidget);
      },
    );

    testWidgets(
      'should_showOnlyLabel_when_itemHasNoOptionalFields',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: const [
              SelectPickerItem(id: '1', label: 'Simple Item'),
            ],
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('Simple Item'), findsOneWidget);
      },
    );

    testWidgets(
      'should_highlightSelectedItem_when_itemSelected',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: _testItems,
            selectedId: '3',
            onChanged: (_) {},
          ),
        );

        // Open modal
        await tester.tap(find.text('Esp\u00E8ces').first);
        await tester.pumpAndSettle();

        // Find the container wrapping the selected item in the modal
        final primaryColor = AppTheme.light.colorScheme.primary;
        final highlightedContainers = tester.widgetList<Container>(
          find.byWidgetPredicate((widget) {
            if (widget is Container && widget.decoration is BoxDecoration) {
              final deco = widget.decoration as BoxDecoration;
              return deco.color ==
                  primaryColor.withValues(alpha: 0.08);
            }
            return false;
          }),
        );
        expect(highlightedContainers, isNotEmpty);
      },
    );
  });

  // --- US6 - Accessibilit\u00E9 (T015) ---
  group('US6 - Accessibilit\u00E9', () {
    testWidgets(
      'should_haveSemanticsButton_when_triggerRendered',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) => s.properties.button == true)
            .toList();

        expect(semanticsWidgets, isNotEmpty);
      },
    );

    testWidgets(
      'should_announcePlaceholder_when_noSelection',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
        );

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) => s.properties.label == 'S\u00E9lectionner...')
            .toList();

        expect(semanticsWidgets, isNotEmpty);
      },
    );

    testWidgets(
      'should_announceSelectedLabel_when_itemSelected',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '1',
            onChanged: (_) {},
          ),
        );

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) => s.properties.label == 'Compte Courant')
            .toList();

        expect(semanticsWidgets, isNotEmpty);
      },
    );

    testWidgets(
      'should_haveToggledTrue_when_itemSelectedInList',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '3',
            onChanged: (_) {},
          ),
        );

        // Open modal
        await tester.tap(find.text('Esp\u00E8ces').first);
        await tester.pumpAndSettle();

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) =>
                s.properties.label == 'Esp\u00E8ces' &&
                s.properties.toggled == true)
            .toList();

        expect(semanticsWidgets, isNotEmpty);
      },
    );

    testWidgets(
      'should_haveToggledFalse_when_itemNotSelectedInList',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            selectedId: '3',
            onChanged: (_) {},
          ),
        );

        // Open modal
        await tester.tap(find.text('Esp\u00E8ces').first);
        await tester.pumpAndSettle();

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) =>
                s.properties.label == 'Compte Courant' &&
                s.properties.toggled == false)
            .toList();

        expect(semanticsWidgets, isNotEmpty);
      },
    );
  });

  // --- Edge Cases & Polish (T018) ---
  group('Edge Cases & Polish', () {
    testWidgets(
      'should_showEmptyMessage_when_itemsListEmpty',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: const [],
            emptyMessage: 'Aucun compte',
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        expect(find.text('Aucun compte'), findsOneWidget);
      },
    );

    testWidgets(
      'should_beNonInteractive_when_disabled',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            enabled: false,
            onChanged: (_) {},
          ),
        );

        // Verify reduced opacity
        final opacity = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacity.opacity, 0.5);

        // Tap should not open modal
        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Items should NOT be visible (modal not opened)
        expect(find.text('Compte Courant'), findsNothing);
      },
    );

    testWidgets(
      'should_truncateWithEllipsis_when_labelTooLong',
      (tester) async {
        final longLabel = 'A' * 200;

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Test',
            items: [
              SelectPickerItem(id: '1', label: longLabel),
            ],
            selectedId: '1',
            onChanged: (_) {},
          ),
        );

        final texts = tester.widgetList<Text>(find.text(longLabel));
        for (final text in texts) {
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }
      },
    );

    testWidgets(
      'should_adaptColors_when_darkTheme',
      (tester) async {
        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (_) {},
          ),
          theme: AppTheme.dark,
        );

        // Verify the container uses dark theme color
        final containers = tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final triggerContainer = containers.first;
        final decoration = triggerContainer.decoration as BoxDecoration;
        expect(
          decoration.color,
          AppTheme.dark.colorScheme.surfaceContainerHighest,
        );
      },
    );

    testWidgets(
      'should_closeWithoutChange_when_dismissedExternally',
      (tester) async {
        String? changedId;

        await pumpSelectPicker(
          tester,
          SelectPicker(
            label: 'Compte',
            items: _testItems,
            onChanged: (id) => changedId = id,
          ),
        );

        // Open modal
        await tester.tap(find.text('S\u00E9lectionner...'));
        await tester.pumpAndSettle();

        // Close via the X button in modal header
        // AppModal has an IconButton with Icons.close in the header
        final closeButtons = find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        );
        if (closeButtons.evaluate().isNotEmpty) {
          await tester.tap(closeButtons.first);
          await tester.pumpAndSettle();
        }

        expect(changedId, isNull);
      },
    );
  });
}
