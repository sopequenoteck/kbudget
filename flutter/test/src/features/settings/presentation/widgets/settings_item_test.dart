import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/settings/presentation/widgets/settings_item.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  Widget buildItem({
    bool isPlaceholder = false,
    VoidCallback? onTap,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SettingsItem(
          icon: PhosphorIconsRegular.user,
          iconColor: Colors.blue,
          title: 'Profil',
          description: 'Nom, email, devise',
          isPlaceholder: isPlaceholder,
          onTap: onTap,
        ),
      ),
    );
  }

  group('SettingsItem', () {
    testWidgets('active item should display chevron and no badge',
        (tester) async {
      await tester.pumpWidget(buildItem(onTap: () {}));
      await tester.pumpAndSettle();

      expect(find.byIcon(PhosphorIconsRegular.caretRight), findsOneWidget);
      expect(find.text('À venir'), findsNothing);
    });

    testWidgets('placeholder item should display badge and no chevron',
        (tester) async {
      await tester.pumpWidget(buildItem(isPlaceholder: true));
      await tester.pumpAndSettle();

      expect(find.text('À venir'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.caretRight), findsNothing);
    });

    testWidgets('placeholder item should have reduced opacity',
        (tester) async {
      await tester.pumpWidget(buildItem(isPlaceholder: true));
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 0.5);
    });

    testWidgets('active item should trigger onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildItem(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SettingsItem));
      expect(tapped, isTrue);
    });

    testWidgets('placeholder item should not have InkWell', (tester) async {
      await tester.pumpWidget(buildItem(isPlaceholder: true));
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('should render in dark theme without error', (tester) async {
      await tester.pumpWidget(buildItem(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Nom, email, devise'), findsOneWidget);
    });

    testWidgets('should render in light theme without error', (tester) async {
      await tester.pumpWidget(buildItem(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Nom, email, devise'), findsOneWidget);
    });

    // Accessibility tests (US4)
    testWidgets('active item should have Semantics with button and label',
        (tester) async {
      await tester.pumpWidget(buildItem(onTap: () {}));
      await tester.pumpAndSettle();

      final semanticsWidget = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      );
      expect(semanticsWidget.properties.label, 'Profil, Nom, email, devise');
    });

    testWidgets(
        'placeholder item should have Semantics without button and with À venir label',
        (tester) async {
      await tester.pumpWidget(buildItem(isPlaceholder: true));
      await tester.pumpAndSettle();

      final semanticsWidget = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label != null &&
              w.properties.label!.contains('À venir'),
        ),
      );
      expect(semanticsWidget.properties.button, isNot(true));
      expect(semanticsWidget.properties.label,
          'Profil, Nom, email, devise, À venir');
    });
  });
}
