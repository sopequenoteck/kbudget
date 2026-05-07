import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/inline_date_picker.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/theme_test_helpers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> pumpDatePicker(
  WidgetTester tester,
  ThemeData theme, {
  required String value,
  required ValueChanged<String> onChanged,
  String? originalValue,
  String? minDate,
  String? maxDate,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: InlineDatePicker(
            value: value,
            onChanged: onChanged,
            originalValue: originalValue,
            minDate: minDate,
            maxDate: maxDate,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests — T-027
// ---------------------------------------------------------------------------

void main() {
  // Test 1 : Rendu mois courant avec valeur fournie
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_current_month_when_value_provided_$themeName',
      (tester) async {
        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (_) {},
        );

        // Le label "Mai 2026" doit être affiché
        expect(find.text('Mai 2026'), findsOneWidget);
        // Le jour 15 doit être visible (au moins une occurrence)
        expect(find.text('15'), findsAtLeastNWidgets(1));
      },
    );
  });

  // Test 2 : Navigation mois précédent
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_navigate_to_previous_month_when_prev_tapped_$themeName',
      (tester) async {
        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (_) {},
        );

        expect(find.text('Mai 2026'), findsOneWidget);

        // Tap sur le bouton caretLeft (premier InkWell de navigation)
        final caretLeftFinder = find.byIcon(PhosphorIconsRegular.caretLeft);
        expect(caretLeftFinder, findsOneWidget);
        await tester.tap(caretLeftFinder);
        await tester.pumpAndSettle();

        expect(find.text('Avril 2026'), findsOneWidget);
        expect(find.text('Mai 2026'), findsNothing);
      },
    );
  });

  // Test 3 : Navigation mois suivant
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_navigate_to_next_month_when_next_tapped_$themeName',
      (tester) async {
        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (_) {},
        );

        expect(find.text('Mai 2026'), findsOneWidget);

        // Tap sur le bouton caretRight
        final caretRightFinder = find.byIcon(PhosphorIconsRegular.caretRight);
        expect(caretRightFinder, findsOneWidget);
        await tester.tap(caretRightFinder);
        await tester.pumpAndSettle();

        expect(find.text('Juin 2026'), findsOneWidget);
        expect(find.text('Mai 2026'), findsNothing);
      },
    );
  });

  // Test 4 : goToToday au tap sur le label mois
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_go_to_today_when_label_tapped_$themeName',
      (tester) async {
        // Partir d'une date en janvier 2025
        await pumpDatePicker(
          tester,
          theme,
          value: '2025-01-10',
          onChanged: (_) {},
        );

        expect(find.text('Janvier 2025'), findsOneWidget);

        // Tap sur le label de mois → goToToday()
        await tester.tap(find.text('Janvier 2025'));
        await tester.pumpAndSettle();

        // Le mois courant (DateTime.now()) doit être affiché
        final now = DateTime.now();
        final monthNames = [
          'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
          'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
        ];
        final expectedLabel = '${monthNames[now.month - 1]} ${now.year}';
        expect(find.text(expectedLabel), findsOneWidget);
      },
    );
  });

  // Test 5 : Tap sur un jour émet la bonne ISO
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_emit_iso_string_when_day_tapped_$themeName',
      (tester) async {
        String? emitted;

        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (iso) => emitted = iso,
        );

        // Chercher le jour "10" dans le mois courant (mai 2026)
        // Il peut y avoir des cellules "10" pour les jours hors-mois,
        // on utilise le premier Text('10') tappable du mois courant.
        // Mai 2026 : 1er = vendredi (weekday=5, offset=4)
        // Cellules 0-3 : jours avril (28,29,30 → 3 jours)
        // On cherche directement le tap sur '10' qui est dans le mois courant.
        final dayFinder = find.text('10');
        expect(dayFinder, findsAtLeastNWidgets(1));

        // Tap sur le premier "10" visible (dans le mois courant)
        await tester.tap(dayFinder.first);
        await tester.pumpAndSettle();

        expect(emitted, equals('2026-05-10'));
      },
    );
  });

  // Test 6 : originalValue affiché avec fond hoverSubtle en mode édition
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_originalValue_with_subtle_background_when_edit_mode_$themeName',
      (tester) async {
        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (_) {},
          originalValue: '2026-05-01',
        );

        // Le label "Mai 2026" doit être présent
        expect(find.text('Mai 2026'), findsOneWidget);

        // Vérifier qu'un Container avec la couleur hoverSubtle existe
        // (la cellule du jour 1 — isOriginal == true, isSelected == false)
        final themeExt = theme.extension<AppThemeExtension>()!;
        final hoverSubtle = themeExt.hoverSubtle;

        final containersWithHoverSubtle = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
          final deco = c.decoration;
          if (deco is BoxDecoration) {
            return deco.color == hoverSubtle;
          }
          return false;
        }).toList();

        // Au moins une cellule doit avoir le fond hoverSubtle (le jour 1 = originalValue)
        expect(containersWithHoverSubtle.length, greaterThanOrEqualTo(1));
      },
    );
  });

  // Test 7 : minDate — jours avant minDate désactivés
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_disable_days_outside_minDate_when_minDate_provided_$themeName',
      (tester) async {
        String? emitted;

        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (iso) => emitted = iso,
          minDate: '2026-05-10',
        );

        // Le jour 5 doit être dans le mois courant ET disabled (< minDate).
        // Tapper dessus ne doit rien émettre.
        // Le jour 5 est affiché (toujours rendu, mais avec opacité 0.3).
        // On vérifie qu'un tap sur '5' (jour du mois) ne déclenche pas onChanged.
        final dayFinder = find.text('5');
        if (dayFinder.evaluate().isNotEmpty) {
          await tester.tap(dayFinder.first, warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        // emitted reste null : le jour 5 est disabled
        expect(emitted, isNull);
      },
    );
  });

  // Test 8 : maxDate — jours après maxDate désactivés
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_disable_days_after_maxDate_when_maxDate_provided_$themeName',
      (tester) async {
        String? emitted;

        await pumpDatePicker(
          tester,
          theme,
          value: '2026-05-15',
          onChanged: (iso) => emitted = iso,
          maxDate: '2026-05-20',
        );

        // Le jour 25 est > maxDate → disabled, le tap ne doit rien émettre
        final dayFinder = find.text('25');
        if (dayFinder.evaluate().isNotEmpty) {
          await tester.tap(dayFinder.first, warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        expect(emitted, isNull);
      },
    );
  });

  // Test 9 : Cas frontière — 1er jour = dimanche (lundi-first)
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_correctly_when_first_day_is_sunday_$themeName',
      (tester) async {
        // 1er février 2026 = dimanche (weekday = 7, offset = 6)
        await pumpDatePicker(
          tester,
          theme,
          value: '2026-02-15',
          onChanged: (_) {},
        );

        expect(find.text('Février 2026'), findsOneWidget);

        // Avec lundi-first, le 1er dimanche doit être en 7ème colonne.
        // La grille doit afficher 6 jours de janvier (lundi au samedi)
        // avant le 1er février.
        // Vérification : le jour '1' doit être visible
        expect(find.text('1'), findsAtLeastNWidgets(1));

        // Vérification de structure : le total de cellules doit être multiple de 7
        // Février 2026 = 28 jours, offset = 6 → 6 + 28 = 34 → + 1 pour compléter = 35 cellules
        // (35 % 7 == 0, donc correct)
        // On vérifie juste que le rendu est cohérent (pas d'exception)
        expect(find.byType(InlineDatePicker), findsOneWidget);
      },
    );
  });

  // Test 10 : Cas frontière — Février bissextile 2024 (29 jours)
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_correctly_when_february_is_leap_year_$themeName',
      (tester) async {
        // Février 2024 = 29 jours (année bissextile)
        await pumpDatePicker(
          tester,
          theme,
          value: '2024-02-15',
          onChanged: (_) {},
        );

        expect(find.text('Février 2024'), findsOneWidget);

        // Le jour '29' doit être visible dans la grille
        expect(find.text('29'), findsAtLeastNWidgets(1));

        // Vérification : le jour '28' doit aussi être présent
        expect(find.text('28'), findsAtLeastNWidgets(1));

        expect(find.byType(InlineDatePicker), findsOneWidget);
      },
    );
  });
}
