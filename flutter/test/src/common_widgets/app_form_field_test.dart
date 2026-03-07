import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Pompe un [AppFormField] dans un arbre de widgets avec le thème complet.
Future<void> pumpFormField(
  WidgetTester tester,
  AppFormField widget, {
  ThemeData? theme,
  double width = 400,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: widget,
        ),
      ),
    ),
  );
}

void main() {
  // ──────────────────────────────────────────────
  // US1 — Affichage avec label et focus
  // ──────────────────────────────────────────────

  group('AppFormField - US1 (Rendu de base)', () {
    testWidgets(
      'should_renderLabelAboveChild_when_allDataProvided',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Ex: 42.50'),
            ),
          ),
        );

        expect(find.text('Montant'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'should_applyLabelStyle_when_rendered',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
        );

        final labelText = tester.widget<Text>(find.text('Montant'));
        expect(labelText.style?.fontSize, AppTypography.sizeSm);
        expect(labelText.style?.fontWeight, AppTypography.medium);
        expect(
          labelText.style?.color,
          AppTheme.light.colorScheme.onSurfaceVariant,
        );
      },
    );

    testWidgets(
      'should_applyContainerStyle_when_rendered',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = animatedContainer.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.light.colorScheme.surfaceContainerHighest);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(AppRadius.xl),
        );
      },
    );

    testWidgets(
      'should_applyContainerPadding_when_rendered',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(
          animatedContainer.padding,
          const EdgeInsets.symmetric(
            vertical: AppSpacing.space3,
            horizontal: AppSpacing.space4,
          ),
        );
      },
    );

    testWidgets(
      'should_notShowError_when_defaultState',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
        );

        // Seul le label est un Text visible (pas de message d'erreur)
        final texts = tester.widgetList<Text>(find.byType(Text));
        expect(texts.length, 1);
        expect(texts.first.data, 'Montant');
      },
    );

    testWidgets(
      'should_takeFullParentWidth_when_rendered',
      (tester) async {
        const parentWidth = 320.0;
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
          width: parentWidth,
        );

        final columnBox = tester.renderObject<RenderBox>(
          find.byType(Column).first,
        );
        expect(columnBox.size.width, parentWidth);
      },
    );

    testWidgets(
      'should_truncateLabelWithEllipsis_when_labelVeryLong',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Un label extrêmement long qui dépasse la largeur disponible du conteneur parent',
            child: SizedBox(),
          ),
          width: 200,
        );

        final labelText = tester.widget<Text>(find.textContaining('Un label'));
        expect(labelText.maxLines, 1);
        expect(labelText.overflow, TextOverflow.ellipsis);
      },
    );
  });

  group('AppFormField - US1 (Thème sombre)', () {
    testWidgets(
      'should_useDarkSurfaceColor_when_darkThemeActive',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
          theme: AppTheme.dark,
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = animatedContainer.decoration as BoxDecoration;
        expect(
          decoration.color,
          AppTheme.dark.colorScheme.surfaceContainerHighest,
        );
      },
    );

    testWidgets(
      'should_useDarkLabelColor_when_darkThemeActive',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
          theme: AppTheme.dark,
        );

        final labelText = tester.widget<Text>(find.text('Montant'));
        expect(
          labelText.style?.color,
          AppTheme.dark.colorScheme.onSurfaceVariant,
        );
      },
    );
  });

  group('AppFormField - US1 (Focus)', () {
    testWidgets(
      'should_showPrimaryBorder_when_childHasFocus',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'test'),
            ),
          ),
        );

        // Focus le TextField
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = animatedContainer.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
        final border = decoration.border as Border;
        expect(border.top.color, AppTheme.light.colorScheme.primary);
        expect(border.top.width, 1.5);
      },
    );

    testWidgets(
      'should_hidesBorder_when_childLosesFocus',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: Column(
                children: [
                  AppFormField(
                    label: 'Montant',
                    child: TextField(
                      decoration: InputDecoration.collapsed(hintText: 'test'),
                    ),
                  ),
                  TextField(
                    key: Key('other'),
                    decoration: InputDecoration.collapsed(hintText: 'autre'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Focus le TextField dans AppFormField
        await tester.tap(find.byType(TextField).first);
        await tester.pumpAndSettle();

        // Focus un autre champ pour perdre le focus
        await tester.tap(find.byKey(const Key('other')));
        await tester.pumpAndSettle();

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = animatedContainer.decoration as BoxDecoration;
        final border = decoration.border as Border;
        expect(border.top.color, Colors.transparent);
      },
    );

    testWidgets(
      'should_useAnimatedContainer_when_rendered',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: SizedBox(),
          ),
        );

        expect(find.byType(AnimatedContainer), findsOneWidget);
      },
    );
  });

  // ──────────────────────────────────────────────
  // US2 — Affichage des erreurs
  // ──────────────────────────────────────────────

  group('AppFormField - US2 (Erreurs)', () {
    testWidgets(
      'should_showErrorMessage_when_showErrorTrue',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            showError: true,
            errorMessage: 'Ce champ est requis',
            child: SizedBox(),
          ),
        );

        expect(find.text('Ce champ est requis'), findsOneWidget);
      },
    );

    testWidgets(
      'should_hideErrorMessage_when_showErrorFalse',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            showError: false,
            errorMessage: 'Ce champ est requis',
            child: SizedBox(),
          ),
        );

        expect(find.text('Ce champ est requis'), findsNothing);
      },
    );

    testWidgets(
      'should_hideErrorMessage_when_errorMessageEmpty',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            showError: true,
            errorMessage: '',
            child: SizedBox(),
          ),
        );

        // Seul le label est visible
        final texts = tester.widgetList<Text>(find.byType(Text));
        expect(texts.length, 1);
      },
    );

    testWidgets(
      'should_applyErrorColor_when_errorDisplayed',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            showError: true,
            errorMessage: 'Format invalide',
            child: SizedBox(),
          ),
        );

        final errorText = tester.widget<Text>(find.text('Format invalide'));
        expect(errorText.style?.color, AppTheme.light.colorScheme.error);
      },
    );

    testWidgets(
      'should_applyErrorFontSize_when_errorDisplayed',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            showError: true,
            errorMessage: 'Format invalide',
            child: SizedBox(),
          ),
        );

        final errorText = tester.widget<Text>(find.text('Format invalide'));
        expect(errorText.style?.fontSize, AppTypography.sizeXs);
      },
    );

    testWidgets(
      'should_useAnimatedSize_when_errorTransition',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            child: SizedBox(),
          ),
        );

        expect(find.byType(AnimatedSize), findsOneWidget);
      },
    );
  });

  // ──────────────────────────────────────────────
  // US3 — Composition multi-types
  // ──────────────────────────────────────────────

  group('AppFormField - US3 (Composition)', () {
    testWidgets(
      'should_renderTextField_when_textFieldChild',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Montant',
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Ex: 42.50'),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Montant'), findsOneWidget);
      },
    );

    testWidgets(
      'should_renderDropdownButton_when_dropdownChild',
      (tester) async {
        await pumpFormField(
          tester,
          AppFormField(
            label: 'Catégorie',
            child: DropdownButton<String>(
              value: 'A',
              items: const [
                DropdownMenuItem(value: 'A', child: Text('Option A')),
                DropdownMenuItem(value: 'B', child: Text('Option B')),
              ],
              onChanged: (_) {},
            ),
          ),
        );

        expect(find.byType(DropdownButton<String>), findsOneWidget);
        expect(find.text('Catégorie'), findsOneWidget);
      },
    );

    testWidgets(
      'should_renderSwitch_when_switchChild',
      (tester) async {
        await pumpFormField(
          tester,
          AppFormField(
            label: 'Actif',
            child: Switch(value: true, onChanged: (_) {}),
          ),
        );

        expect(find.byType(Switch), findsOneWidget);
        expect(find.text('Actif'), findsOneWidget);
      },
    );

    testWidgets(
      'should_renderCustomWidget_when_rowChild',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Sélection',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.calendar),
                SizedBox(width: 8),
                Text('Choisir une date'),
              ],
            ),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.text('Choisir une date'), findsOneWidget);
        expect(
          find.byIcon(PhosphorIconsRegular.calendar),
          findsOneWidget,
        );
      },
    );
  });

  // ──────────────────────────────────────────────
  // Edge Cases
  // ──────────────────────────────────────────────

  group('AppFormField - Edge Cases', () {
    testWidgets(
      'should_renderWithoutError_when_labelEmpty',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: '',
            child: SizedBox(),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should_truncateLabel_when_labelLongerThan50Chars',
      (tester) async {
        const longLabel =
            'Un label extrêmement long qui dépasse cinquante caractères facilement pour tester le cas limite';
        await pumpFormField(
          tester,
          const AppFormField(
            label: longLabel,
            child: SizedBox(),
          ),
          width: 200,
        );

        final labelText = tester.widget<Text>(find.text(longLabel));
        expect(labelText.maxLines, 1);
        expect(labelText.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'should_wrapErrorMessage_when_errorLongerThan100Chars',
      (tester) async {
        const longError =
            'Un message d\'erreur très long qui dépasse cent caractères pour vérifier que le texte s\'affiche sur plusieurs lignes sans débordement du conteneur';
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Champ',
            showError: true,
            errorMessage: longError,
            child: SizedBox(),
          ),
        );

        expect(find.text(longError), findsOneWidget);
        // Le message d'erreur n'a pas de maxLines (multi-lignes autorisé)
        final errorText = tester.widget<Text>(find.text(longError));
        expect(errorText.maxLines, isNull);
      },
    );

    testWidgets(
      'should_adaptHeight_when_childHasVariableHeight',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Notes',
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Écrire...'),
              maxLines: 5,
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should_remainUsable_when_containerNarrow',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Test',
            child: SizedBox(height: 20),
          ),
          width: 150,
        );

        expect(find.text('Test'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ──────────────────────────────────────────────
  // US4 — Accessibilité
  // ──────────────────────────────────────────────

  group('AppFormField - US4 (Accessibilité)', () {
    testWidgets(
      'should_haveMergeSemantics_when_rendered',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            child: SizedBox(),
          ),
        );

        expect(find.byType(MergeSemantics), findsOneWidget);
      },
    );

    testWidgets(
      'should_haveSemanticsLabel_when_rendered',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            child: SizedBox(),
          ),
        );

        expect(find.byType(Semantics), findsWidgets);
        // Le Semantics wrapper porte le label du champ
        final semanticsWidget = tester.widgetList<Semantics>(
          find.byType(Semantics),
        );
        final labelSemantics = semanticsWidget.where(
          (s) => s.properties.label == 'Email',
        );
        expect(labelSemantics, isNotEmpty);
      },
    );

    testWidgets(
      'should_haveLiveRegion_when_errorShown',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            showError: true,
            errorMessage: 'Format invalide',
            child: SizedBox(),
          ),
        );

        final semanticsWidgets = tester.widgetList<Semantics>(
          find.byType(Semantics),
        );
        final liveRegionSemantics = semanticsWidgets.where(
          (s) => s.properties.liveRegion == true,
        );
        expect(liveRegionSemantics, isNotEmpty);
      },
    );

    testWidgets(
      'should_notHaveLiveRegion_when_noError',
      (tester) async {
        await pumpFormField(
          tester,
          const AppFormField(
            label: 'Email',
            child: SizedBox(),
          ),
        );

        final semanticsWidgets = tester.widgetList<Semantics>(
          find.byType(Semantics),
        );
        final liveRegionSemantics = semanticsWidgets.where(
          (s) => s.properties.liveRegion == true,
        );
        expect(liveRegionSemantics, isEmpty);
      },
    );
  });
}
