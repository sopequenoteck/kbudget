import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/variation_badge.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

import '../../helpers/theme_test_helpers.dart';

/// Pompe un [VariationBadge] dans un arbre de widgets minimal avec le thème fourni.
Future<void> pumpVariationBadge(
  WidgetTester tester,
  ThemeData theme, {
  required num delta,
  String? currency,
  num? percentage,
  String suffix = 'ce mois',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: VariationBadge(
            delta: delta,
            currency: currency,
            percentage: percentage,
            suffix: suffix,
          ),
        ),
      ),
    ),
  );
}

void main() {
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_positive_with_green_when_delta_positive_$themeName',
      (tester) async {
        await pumpVariationBadge(
          tester,
          theme,
          delta: 150.50,
          currency: '€',
          percentage: 12.5,
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        final textContent = textWidget.data ?? '';

        // Vérifier que le signe + est présent et la valeur
        expect(textContent, contains('+'));
        expect(textContent, contains('150'));
        expect(textContent, contains('(+12,5%)'));

        // Vérifier la couleur incomeColor
        final themeExt = theme.extension<AppThemeExtension>()!;
        final style = textWidget.style;
        expect(style?.color, equals(themeExt.incomeColor));
      },
    );

    testWidgets(
      'should_render_negative_with_red_when_delta_negative_$themeName',
      (tester) async {
        await pumpVariationBadge(
          tester,
          theme,
          delta: -8.0,
          currency: '€',
          percentage: -3.2,
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        final textContent = textWidget.data ?? '';

        // Vérifier le signe négatif et la valeur
        expect(textContent, contains('-'));
        expect(textContent, contains('8'));
        expect(textContent, contains('(-3,2%)'));

        // Vérifier la couleur expenseColor
        final themeExt = theme.extension<AppThemeExtension>()!;
        final style = textWidget.style;
        expect(style?.color, equals(themeExt.expenseColor));
      },
    );

    testWidgets(
      'should_hide_when_delta_zero_and_percentage_null_$themeName',
      (tester) async {
        await pumpVariationBadge(
          tester,
          theme,
          delta: 0,
        );

        // Le widget doit être masqué — SizedBox.shrink, donc pas de Text visible
        expect(find.byType(Text), findsNothing);
      },
    );

    testWidgets(
      'should_render_neutral_when_delta_zero_and_percentage_present_$themeName',
      (tester) async {
        await pumpVariationBadge(
          tester,
          theme,
          delta: 0,
          percentage: 0.0,
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        final style = textWidget.style;

        // Couleur onSurfaceVariant (text-secondary)
        expect(style?.color, equals(theme.colorScheme.onSurfaceVariant));
      },
    );

    testWidgets(
      'should_format_percentage_with_one_decimal_$themeName',
      (tester) async {
        await pumpVariationBadge(
          tester,
          theme,
          delta: 100.0,
          percentage: 12.456,
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        final textContent = textWidget.data ?? '';

        // Vérifier que le pourcentage est formaté avec 1 décimale
        expect(textContent, contains('(+12,5%)'));
      },
    );
  });
}
