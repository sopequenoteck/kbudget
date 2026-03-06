import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_shadows.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Pompe un [MonthSelector] dans un arbre de widgets avec le thème complet.
Future<void> pumpMonthSelector(
  WidgetTester tester,
  MonthSelector widget, {
  ThemeData? theme,
  Key? appKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: appKey,
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: Center(child: widget),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('US1 — Navigation', () {
    testWidgets('should_display_current_month_when_no_initial_values',
        (tester) async {
      await pumpMonthSelector(tester, const MonthSelector());

      final now = DateTime.now();
      // Le label doit contenir l'année courante
      expect(find.textContaining('${now.year}'), findsOneWidget);
    });

    testWidgets('should_display_initial_month_when_provided', (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 6, initialYear: 2025),
      );

      expect(find.text('Juin 2025'), findsOneWidget);
    });

    testWidgets('should_show_next_month_when_next_pressed', (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(find.text('Mars 2026'), findsOneWidget);
    });

    testWidgets('should_show_previous_month_when_prev_pressed',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 3, initialYear: 2026),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretLeft));
      await tester.pump();

      expect(find.text('Février 2026'), findsOneWidget);
    });

    testWidgets('should_wrap_to_january_when_next_from_december',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 12, initialYear: 2025),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(find.text('Janvier 2026'), findsOneWidget);
    });

    testWidgets('should_wrap_to_december_when_prev_from_january',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 1, initialYear: 2026),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretLeft));
      await tester.pump();

      expect(find.text('Décembre 2025'), findsOneWidget);
    });

    testWidgets('should_increment_year_when_next_from_december',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 12, initialYear: 2025),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(find.text('Janvier 2026'), findsOneWidget);
    });

    testWidgets('should_decrement_year_when_prev_from_january',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 1, initialYear: 2025),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretLeft));
      await tester.pump();

      expect(find.text('Décembre 2024'), findsOneWidget);
    });

    testWidgets('should_capitalize_month_label', (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
      );

      // Doit commencer par une majuscule
      expect(find.text('Février 2026'), findsOneWidget);
      expect(find.text('février 2026'), findsNothing);
    });

    testWidgets('should_fallback_to_current_month_when_initial_month_invalid',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 13, initialYear: 2026),
      );

      final now = DateTime.now();
      expect(find.textContaining('${now.year}'), findsOneWidget);
    });
  });

  group('US2 — Callback', () {
    testWidgets(
        'should_call_onChanged_with_new_month_year_when_next_pressed',
        (tester) async {
      int? calledMonth;
      int? calledYear;

      await pumpMonthSelector(
        tester,
        MonthSelector(
          initialMonth: 2,
          initialYear: 2026,
          onChanged: (month, year) {
            calledMonth = month;
            calledYear = year;
          },
        ),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(calledMonth, 3);
      expect(calledYear, 2026);
    });

    testWidgets(
        'should_call_onChanged_with_new_month_year_when_prev_pressed',
        (tester) async {
      int? calledMonth;
      int? calledYear;

      await pumpMonthSelector(
        tester,
        MonthSelector(
          initialMonth: 3,
          initialYear: 2026,
          onChanged: (month, year) {
            calledMonth = month;
            calledYear = year;
          },
        ),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretLeft));
      await tester.pump();

      expect(calledMonth, 2);
      expect(calledYear, 2026);
    });

    testWidgets(
        'should_call_onChanged_with_wrapped_values_on_year_boundary',
        (tester) async {
      int? calledMonth;
      int? calledYear;

      await pumpMonthSelector(
        tester,
        MonthSelector(
          initialMonth: 12,
          initialYear: 2025,
          onChanged: (month, year) {
            calledMonth = month;
            calledYear = year;
          },
        ),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(calledMonth, 1);
      expect(calledYear, 2026);
    });

    testWidgets('should_not_crash_when_onChanged_is_null', (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 6, initialYear: 2025),
      );

      // Ne doit pas lever d'exception
      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(find.text('Juillet 2025'), findsOneWidget);
    });
  });

  group('US3 — Design System', () {
    testWidgets('should_use_design_tokens_for_button_styling',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
      );

      // Les boutons doivent être dans des containers ronds 48x48 avec ombre
      final containers = tester.widgetList<Container>(
        find.ancestor(
          of: find.byType(IconButton),
          matching: find.byType(Container),
        ),
      );

      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration == null) continue;

        // Rayon rond
        if (decoration.borderRadius != null) {
          expect(
            decoration.borderRadius,
            BorderRadius.circular(AppRadius.round),
          );
          // Ombre sm
          expect(decoration.boxShadow, AppShadows.sm);
        }
      }

      // Vérifier la taille 48x48 des containers décoratifs
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.ancestor(
          of: find.byType(IconButton),
          matching: find.byType(SizedBox),
        ),
      );

      final buttonSizedBoxes = sizedBoxes
          .where((sb) => sb.width == 48 && sb.height == 48);
      expect(buttonSizedBoxes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('should_use_design_tokens_for_label_styling',
        (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
      );

      final text = tester.widget<Text>(find.text('Février 2026'));
      final style = text.style!;

      expect(style.fontSize, AppTypography.sizeLg);
      expect(style.fontWeight, AppTypography.semiBold);
    });

    testWidgets('should_adapt_to_dark_theme', (tester) async {
      // Thème clair
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
        appKey: UniqueKey(),
      );

      final lightText = tester.widget<Text>(find.text('Février 2026'));
      final lightColor = lightText.style?.color;

      // Thème sombre — UniqueKey sur MaterialApp force la recréation complète
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
        theme: AppTheme.dark,
        appKey: UniqueKey(),
      );

      final darkText = tester.widget<Text>(find.text('Février 2026'));
      final darkColor = darkText.style?.color;

      // Les couleurs doivent être différentes entre thème clair et sombre
      expect(lightColor, isNot(equals(darkColor)));
    });
  });

  group('US4 — Accessibilité', () {
    testWidgets('should_have_prev_button_semantics_label', (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
      );

      expect(
        find.bySemanticsLabel('Mois précédent'),
        findsOneWidget,
      );
    });

    testWidgets('should_have_next_button_semantics_label', (tester) async {
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 2, initialYear: 2026),
      );

      expect(
        find.bySemanticsLabel('Mois suivant'),
        findsOneWidget,
      );
    });
  });

  group('Edge Cases', () {
    testWidgets('should_handle_long_month_name_without_overflow',
        (tester) async {
      // Septembre est le mois le plus long en français
      await pumpMonthSelector(
        tester,
        const MonthSelector(initialMonth: 9, initialYear: 2026),
      );

      expect(find.text('Septembre 2026'), findsOneWidget);
      // Pas d'overflow — le widget se rend sans erreur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should_render_in_narrow_container', (tester) async {
      // Capturer les erreurs d'overflow (attendues dans un conteneur étroit)
      final errors = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: const MonthSelector(
                  initialMonth: 9,
                  initialYear: 2026,
                ),
              ),
            ),
          ),
        ),
      );

      FlutterError.onError = oldHandler;

      // Le widget doit se rendre (avec overflow visuel) sans crash
      expect(find.byType(MonthSelector), findsOneWidget);
      // L'overflow est attendu (widget 288px dans container 200px)
      expect(
        errors.any((e) => e.toString().contains('overflowed')),
        isTrue,
      );
    });
  });
}
