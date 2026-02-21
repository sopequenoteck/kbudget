import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/segmented_filter.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_shadows.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme.dart';

/// Pompe un [SegmentedFilter] dans un arbre de widgets avec le thème complet.
Future<void> pumpSegmentedFilter(
  WidgetTester tester,
  Widget widget, {
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
  // --- Setup smoke test ---
  group('Setup - Smoke', () {
    testWidgets(
      'should_render_when_validItemsProvided',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'all', label: 'Tous'),
              SegmentedFilterItem(value: 'dep', label: 'Dépenses'),
              SegmentedFilterItem(value: 'rec', label: 'Recettes'),
            ],
            selectedValue: 'all',
            onChanged: (_) {},
          ),
        );

        expect(find.text('Tous'), findsOneWidget);
        expect(find.text('Dépenses'), findsOneWidget);
        expect(find.text('Recettes'), findsOneWidget);
      },
    );
  });

  // --- US1: Filtrage ---
  group('US1 - Filtrage', () {
    testWidgets(
      'should_callOnChanged_when_inactiveSegmentTapped',
      (tester) async {
        String? changedValue;

        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'all', label: 'Tous'),
              SegmentedFilterItem(value: 'dep', label: 'Dépenses'),
              SegmentedFilterItem(value: 'rec', label: 'Recettes'),
            ],
            selectedValue: 'all',
            onChanged: (value) => changedValue = value,
          ),
        );

        await tester.tap(find.text('Dépenses'));
        expect(changedValue, 'dep');
      },
    );

    testWidgets(
      'should_notCallOnChanged_when_activeSegmentTapped',
      (tester) async {
        String? changedValue;

        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'all', label: 'Tous'),
              SegmentedFilterItem(value: 'dep', label: 'Dépenses'),
              SegmentedFilterItem(value: 'rec', label: 'Recettes'),
            ],
            selectedValue: 'dep',
            onChanged: (value) => changedValue = value,
          ),
        );

        await tester.tap(find.text('Dépenses'));
        expect(changedValue, isNull);
      },
    );

    testWidgets(
      'should_callOnChangedWithCorrectValue_when_thirdSegmentTapped',
      (tester) async {
        String? changedValue;

        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'all', label: 'Tous'),
              SegmentedFilterItem(value: 'dep', label: 'Dépenses'),
              SegmentedFilterItem(value: 'rec', label: 'Recettes'),
            ],
            selectedValue: 'all',
            onChanged: (value) => changedValue = value,
          ),
        );

        await tester.tap(find.text('Recettes'));
        expect(changedValue, 'rec');
      },
    );
  });

  // --- US2: Design ---
  group('US2 - Design', () {
    testWidgets(
      'should_useCorrectContainerStyle_when_lightTheme',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, AppTheme.light.colorScheme.surfaceContainerHighest);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(AppRadius.lg),
        );
        expect(container.padding, const EdgeInsets.all(AppSpacing.space1));
      },
    );

    testWidgets(
      'should_useCorrectActiveSegmentStyle_when_lightTheme',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        // Le premier AnimatedContainer est le segment actif
        final animatedContainers =
            tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
        final activeContainer = animatedContainers.first;
        final decoration = activeContainer.decoration as BoxDecoration;

        expect(decoration.color, AppTheme.light.colorScheme.surface);
        expect(decoration.boxShadow, AppShadows.sm);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(AppRadius.md),
        );
      },
    );

    testWidgets(
      'should_useCorrectTextStyle_when_segmentActive',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final activeAnimated = tester.widget<AnimatedDefaultTextStyle>(
          find.ancestor(
            of: find.text('A'),
            matching: find.byType(AnimatedDefaultTextStyle),
          ).first,
        );

        expect(activeAnimated.style.color, AppTheme.light.colorScheme.onSurface);
        expect(activeAnimated.style.fontWeight, AppTypography.semiBold);
        expect(activeAnimated.style.fontSize, AppTypography.sizeSm);
      },
    );

    testWidgets(
      'should_useCorrectTextStyle_when_segmentInactive',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final inactiveAnimated = tester.widget<AnimatedDefaultTextStyle>(
          find.ancestor(
            of: find.text('B'),
            matching: find.byType(AnimatedDefaultTextStyle),
          ).first,
        );

        expect(inactiveAnimated.style.color, AppTheme.light.colorScheme.onSurfaceVariant);
        expect(inactiveAnimated.style.fontWeight, AppTypography.medium);
      },
    );

    testWidgets(
      'should_adaptColors_when_darkTheme',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
          theme: AppTheme.dark,
        );

        // Container principal
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final containerDecoration = container.decoration as BoxDecoration;
        expect(
          containerDecoration.color,
          AppTheme.dark.colorScheme.surfaceContainerHighest,
        );

        // Segment actif
        final activeContainer = tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .first;
        final activeDecoration = activeContainer.decoration as BoxDecoration;
        expect(activeDecoration.color, AppTheme.dark.colorScheme.surface);

        // Texte actif
        final activeStyle = tester
            .widgetList<AnimatedDefaultTextStyle>(
                find.byType(AnimatedDefaultTextStyle))
            .first
            .style;
        expect(activeStyle.color, AppTheme.dark.colorScheme.onSurface);
      },
    );
  });

  // --- US3: Adaptabilité ---
  group('US3 - Adaptabilité', () {
    testWidgets(
      'should_renderCorrectly_when_twoSegments',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'Oui'),
              SegmentedFilterItem(value: 'b', label: 'Non'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        expect(find.text('Oui'), findsOneWidget);
        expect(find.text('Non'), findsOneWidget);
      },
    );

    testWidgets(
      'should_renderCorrectly_when_fiveSegments',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<int>(
            items: const [
              SegmentedFilterItem(value: 1, label: 'Un'),
              SegmentedFilterItem(value: 2, label: 'Deux'),
              SegmentedFilterItem(value: 3, label: 'Trois'),
              SegmentedFilterItem(value: 4, label: 'Quatre'),
              SegmentedFilterItem(value: 5, label: 'Cinq'),
            ],
            selectedValue: 1,
            onChanged: (_) {},
          ),
        );

        expect(find.text('Un'), findsOneWidget);
        expect(find.text('Deux'), findsOneWidget);
        expect(find.text('Trois'), findsOneWidget);
        expect(find.text('Quatre'), findsOneWidget);
        expect(find.text('Cinq'), findsOneWidget);
      },
    );

    testWidgets(
      'should_distributeEqualWidth_when_multipleSegments',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
              SegmentedFilterItem(value: 'c', label: 'C'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final expandedWidgets = tester.widgetList<Expanded>(
          find.byType(Expanded),
        );
        expect(expandedWidgets.length, 3);
        // Tous les Expanded ont le même flex (1 par défaut)
        for (final expanded in expandedWidgets) {
          expect(expanded.flex, 1);
        }
      },
    );

    testWidgets(
      'should_truncateWithEllipsis_when_labelTooLong',
      (tester) async {
        final longLabel = 'A' * 100;

        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: [
              SegmentedFilterItem(value: 'a', label: longLabel),
              const SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final text = tester.widget<Text>(find.text(longLabel));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'should_workWithEnumType_when_enumValuesProvided',
      (tester) async {
        _TestEnum? changedValue;

        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<_TestEnum>(
            items: const [
              SegmentedFilterItem(value: _TestEnum.all, label: 'Tous'),
              SegmentedFilterItem(value: _TestEnum.active, label: 'Actifs'),
              SegmentedFilterItem(value: _TestEnum.inactive, label: 'Inactifs'),
            ],
            selectedValue: _TestEnum.all,
            onChanged: (value) => changedValue = value,
          ),
        );

        await tester.tap(find.text('Actifs'));
        expect(changedValue, _TestEnum.active);
      },
    );

    testWidgets(
      'should_throwAssertionError_when_lessThanTwoItems',
      (tester) async {
        expect(
          () => SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets(
      'should_throwAssertionError_when_moreThanFiveItems',
      (tester) async {
        expect(
          () => SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: '1', label: '1'),
              SegmentedFilterItem(value: '2', label: '2'),
              SegmentedFilterItem(value: '3', label: '3'),
              SegmentedFilterItem(value: '4', label: '4'),
              SegmentedFilterItem(value: '5', label: '5'),
              SegmentedFilterItem(value: '6', label: '6'),
            ],
            selectedValue: '1',
            onChanged: (_) {},
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets(
      'should_selectFirstItem_when_selectedValueNotInItems',
      (tester) async {
        String? changedValue;

        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'A'),
              SegmentedFilterItem(value: 'b', label: 'B'),
            ],
            selectedValue: 'unknown',
            onChanged: (value) => changedValue = value,
          ),
        );

        // Le premier segment est sélectionné par défaut,
        // donc taper dessus ne doit pas déclencher le callback
        await tester.tap(find.text('A'));
        expect(changedValue, isNull);

        // Taper sur le second doit fonctionner
        await tester.tap(find.text('B'));
        expect(changedValue, 'b');
      },
    );
  });

  // --- US4: Accessibilité ---
  group('US4 - Accessibilité', () {
    testWidgets(
      'should_haveSemanticsLabel_when_segmentRendered',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'Alpha'),
              SegmentedFilterItem(value: 'b', label: 'Beta'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final semanticsWidgets = tester.widgetList<Semantics>(
          find.byType(Semantics),
        );

        final labels = semanticsWidgets
            .where((s) => s.properties.label != null)
            .map((s) => s.properties.label)
            .toList();

        expect(labels, contains('Alpha'));
        expect(labels, contains('Beta'));
      },
    );

    testWidgets(
      'should_haveToggledTrue_when_segmentActive',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'Alpha'),
              SegmentedFilterItem(value: 'b', label: 'Beta'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) => s.properties.label == 'Alpha')
            .toList();

        expect(semanticsWidgets, hasLength(1));
        expect(semanticsWidgets.first.properties.toggled, isTrue);
      },
    );

    testWidgets(
      'should_haveToggledFalse_when_segmentInactive',
      (tester) async {
        await pumpSegmentedFilter(
          tester,
          SegmentedFilter<String>(
            items: const [
              SegmentedFilterItem(value: 'a', label: 'Alpha'),
              SegmentedFilterItem(value: 'b', label: 'Beta'),
            ],
            selectedValue: 'a',
            onChanged: (_) {},
          ),
        );

        final semanticsWidgets = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((s) => s.properties.label == 'Beta')
            .toList();

        expect(semanticsWidgets, hasLength(1));
        expect(semanticsWidgets.first.properties.toggled, isFalse);
      },
    );
  });
}

/// Enum de test pour vérifier le support des types génériques.
enum _TestEnum { all, active, inactive }
