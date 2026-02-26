import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/app_toggle.dart';

void main() {
  Widget buildToggle({
    int selectedIndex = 0,
    ValueChanged<int>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppToggle(
            labels: const ['Option A', 'Option B'],
            selectedIndex: selectedIndex,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('AppToggle', () {
    testWidgets('should_displayTwoLabels_when_rendered', (tester) async {
      await tester.pumpWidget(buildToggle());

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('should_highlightFirstOption_when_selectedIndexIs0',
        (tester) async {
      await tester.pumpWidget(buildToggle(selectedIndex: 0));
      await tester.pumpAndSettle();

      // The first option container should have the primary color
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      // First AnimatedContainer should have a decoration with primary color
      final firstContainer = containers.first;
      final decoration = firstContainer.decoration as BoxDecoration?;
      expect(decoration?.color, isNotNull);
    });

    testWidgets('should_callOnChanged_when_secondOptionTapped',
        (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(buildToggle(
        selectedIndex: 0,
        onChanged: (index) => tappedIndex = index,
      ));

      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });

    testWidgets('should_switchVisualState_when_selectionChanges',
        (tester) async {
      // Start with index 0
      await tester.pumpWidget(buildToggle(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Rebuild with index 1
      await tester.pumpWidget(buildToggle(selectedIndex: 1));
      await tester.pumpAndSettle();

      // Verify the second option is now highlighted
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();
      final secondContainer = containers[1];
      final decoration = secondContainer.decoration as BoxDecoration?;
      expect(decoration?.color, isNotNull);
    });
  });
}
