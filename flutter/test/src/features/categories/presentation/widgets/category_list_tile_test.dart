import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_list_tile.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  const userCategory = Category(
    id: '1',
    nom: 'Alimentation',
    icone: '\u{1F34E}',
    couleur: '#22c55e',
    isSystem: false,
  );

  Widget buildApp(Category category, {VoidCallback? onTap}) {
    return MaterialApp(
      theme: theme.AppTheme.light,
      home: Scaffold(
        body: CategoryListTile(
          category: category,
          onTap: onTap,
        ),
      ),
    );
  }

  group('CategoryListTile', () {
    testWidgets('should_display_name_emoji_color_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp(userCategory));
      await tester.pumpAndSettle();

      expect(find.text('Alimentation'), findsOneWidget);
      expect(find.text('\u{1F34E}'), findsOneWidget);
    });

    testWidgets('should_trigger_onTap_when_tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildApp(
        userCategory,
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });
}
