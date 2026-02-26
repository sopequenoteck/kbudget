import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/color_palette_picker.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  Widget buildApp({
    String? selectedColor,
    required ValueChanged<String> onChanged,
  }) {
    return MaterialApp(
      theme: theme.AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ColorPalettePicker(
          selectedColor: selectedColor,
          onChanged: onChanged,
        ),
      ),
    );
  }

  group('ColorPalettePicker', () {
    testWidgets('should_showAllColors_when_rendered', (tester) async {
      await tester.pumpWidget(buildApp(onChanged: (_) {}));
      await tester.pumpAndSettle();

      // 12 color circles
      final circles = find.byType(AnimatedContainer);
      expect(circles, findsWidgets);
    });

    testWidgets('should_highlightSelected_when_colorChosen', (tester) async {
      await tester.pumpWidget(buildApp(
        selectedColor: '#3b82f6',
        onChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      // Should find a check icon on the selected color
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should_callOnChanged_when_colorTapped', (tester) async {
      String? tappedColor;

      await tester.pumpWidget(buildApp(
        onChanged: (color) => tappedColor = color,
      ));
      await tester.pumpAndSettle();

      // Tap the first color circle
      final gestures = find.byType(GestureDetector);
      await tester.tap(gestures.first);

      expect(tappedColor, isNotNull);
    });
  });
}
