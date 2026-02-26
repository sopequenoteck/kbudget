import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_preview_card.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  Widget buildApp({String? emoji, String? name, String? colorHex}) {
    return MaterialApp(
      theme: theme.AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CategoryPreviewCard(
          emoji: emoji,
          name: name,
          colorHex: colorHex,
        ),
      ),
    );
  }

  group('CategoryPreviewCard', () {
    testWidgets('should_display_emoji_name_color_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp(
        emoji: '\u{1F34E}',
        name: 'Alimentation',
        colorHex: '#22c55e',
      ));
      await tester.pumpAndSettle();

      expect(find.text('\u{1F34E}'), findsOneWidget);
      expect(find.text('Alimentation'), findsOneWidget);
    });

    testWidgets('should_show_placeholder_when_empty', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aperçu de la catégorie'), findsOneWidget);
    });

    testWidgets('should_update_preview_when_props_change', (tester) async {
      await tester.pumpWidget(buildApp(name: 'Avant'));
      await tester.pumpAndSettle();

      expect(find.text('Avant'), findsOneWidget);

      await tester.pumpWidget(buildApp(name: 'Après'));
      await tester.pumpAndSettle();

      expect(find.text('Après'), findsOneWidget);
      expect(find.text('Avant'), findsNothing);
    });
  });
}
