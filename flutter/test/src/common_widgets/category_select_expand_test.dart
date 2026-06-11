import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/category_select_expand.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_form_widget.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart';

import '../../helpers/mocks.mocks.dart';
import '../../helpers/theme_test_helpers.dart';

// ---------------------------------------------------------------------------
// Données mock
// ---------------------------------------------------------------------------

const _testCategories = [
  Category(
    id: '1',
    nom: 'Courses',
    icone: '🛒',
    couleur: '#22c55e',
    isSystem: false,
  ),
  Category(
    id: '2',
    nom: 'Café',
    icone: '☕',
    couleur: '#a3a3a3',
    isSystem: false,
  ),
  Category(
    id: '3',
    nom: 'Loyer',
    icone: '🏠',
    couleur: '#3b82f6',
    isSystem: false,
  ),
  Category(
    id: '4',
    nom: 'Transport',
    icone: '🚌',
    couleur: '#f59e0b',
    isSystem: false,
  ),
  Category(
    id: '5',
    nom: 'Restaurant',
    icone: '🍽️',
    couleur: '#dc2626',
    isSystem: false,
  ),
];

// ---------------------------------------------------------------------------
// Helper de pompage
// ---------------------------------------------------------------------------

Future<void> pumpCategorySelect(
  WidgetTester tester,
  ThemeData theme, {
  List<Category> categories = _testCategories,
  String? selectedId,
  ValueChanged<String>? onSelected,
  ValueChanged<Category>? onCreated,
  ValueChanged<bool>? onCreatingChanged,
  MockCategoryRepository? mockRepo,
}) async {
  final repo = mockRepo ?? MockCategoryRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategorySelectExpand(
              categories: categories,
              selectedId: selectedId,
              onSelected: onSelected ?? (_) {},
              onCreated: onCreated,
              onCreatingChanged: onCreatingChanged,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests — T-030
// ---------------------------------------------------------------------------

void main() {
  // Test 1 : Toutes les catégories sont rendues quand la recherche est vide
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_render_all_categories_when_search_empty_$themeName',
      (tester) async {
        await pumpCategorySelect(tester, theme);

        for (final cat in _testCategories) {
          expect(find.text(cat.nom), findsOneWidget);
        }
      },
    );
  });

  // Test 2 : Filtrage insensible à la casse (minuscules)
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_filter_categories_when_search_typed_$themeName',
      (tester) async {
        await pumpCategorySelect(tester, theme);

        await tester.enterText(find.byType(TextField), 'cou');
        await tester.pumpAndSettle();

        // Seul « Courses » correspond
        expect(find.text('Courses'), findsOneWidget);
        // Les autres ne doivent pas être visibles
        expect(find.text('Café'), findsNothing);
        expect(find.text('Loyer'), findsNothing);
        expect(find.text('Transport'), findsNothing);
        expect(find.text('Restaurant'), findsNothing);
      },
    );
  });

  // Test 3 : Filtrage insensible à la casse (majuscules)
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_filter_case_insensitive_when_search_typed_$themeName',
      (tester) async {
        await pumpCategorySelect(tester, theme);

        await tester.enterText(find.byType(TextField), 'COU');
        await tester.pumpAndSettle();

        expect(find.text('Courses'), findsOneWidget);
        expect(find.text('Café'), findsNothing);
      },
    );
  });

  // Test 4 : Filtrage insensible aux diacritiques (normalizeForSearch)
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_filter_diacritics_insensitive_when_search_typed_$themeName',
      (tester) async {
        await pumpCategorySelect(tester, theme);

        // « cafe » sans accent doit matcher « Café »
        await tester.enterText(find.byType(TextField), 'cafe');
        await tester.pumpAndSettle();

        expect(find.text('Café'), findsOneWidget);
        expect(find.text('Courses'), findsNothing);
      },
    );
  });

  // Test 5 : onSelected émis au tap sur une catégorie
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_emit_onSelected_when_category_tapped_$themeName',
      (tester) async {
        String? selectedId;

        await pumpCategorySelect(
          tester,
          theme,
          onSelected: (id) => selectedId = id,
        );

        await tester.tap(find.text('Courses'));
        await tester.pumpAndSettle();

        expect(selectedId, '1');
      },
    );
  });

  // Test 6 : Bouton + Créer visible quand pas de match exact
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_show_create_button_when_no_exact_match_$themeName',
      (tester) async {
        await pumpCategorySelect(tester, theme);

        await tester.enterText(find.byType(TextField), 'xyz');
        await tester.pumpAndSettle();

        expect(find.textContaining('+ Créer « xyz »'), findsOneWidget);
      },
    );
  });

  // Test 7 : Bouton + Créer absent quand match exact (insensible à la casse)
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_hide_create_button_when_exact_match_$themeName',
      (tester) async {
        await pumpCategorySelect(tester, theme);

        // « courses » (minuscule) doit matcher « Courses » → pas de bouton créer
        await tester.enterText(find.byType(TextField), 'courses');
        await tester.pumpAndSettle();

        expect(find.textContaining('+ Créer «'), findsNothing);
      },
    );
  });

  // Test 8 : Tap + Créer → bascule mode create + CategoryFormWidget rendu
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_switch_to_create_mode_when_create_button_tapped_$themeName',
      (tester) async {
        bool? creatingState;

        await pumpCategorySelect(
          tester,
          theme,
          onCreatingChanged: (v) => creatingState = v,
        );

        await tester.enterText(find.byType(TextField), 'xyz');
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('+ Créer « xyz »'));
        await tester.pumpAndSettle();

        // En mode create : CategoryFormWidget doit être présent
        expect(find.byType(CategoryFormWidget), findsOneWidget);
        // onCreatingChanged(true) doit avoir été émis
        expect(creatingState, isTrue);
        // Le bouton Retour doit être visible
        expect(find.text('Retour'), findsOneWidget);
      },
    );
  });

  // Test 9 : Tap ← Retour → retour mode list, recherche conservée
  forEachTheme((theme, themeName) {
    testWidgets(
      'should_return_to_list_mode_when_back_tapped_$themeName',
      (tester) async {
        bool? creatingState;

        await pumpCategorySelect(
          tester,
          theme,
          onCreatingChanged: (v) => creatingState = v,
        );

        // Passer en mode create
        await tester.enterText(find.byType(TextField), 'xyz');
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('+ Créer « xyz »'));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryFormWidget), findsOneWidget);

        // Tap ← Retour
        await tester.tap(find.text('Retour'));
        await tester.pumpAndSettle();

        // Retour en mode list : CategoryFormWidget absent
        expect(find.byType(CategoryFormWidget), findsNothing);
        // onCreatingChanged(false) doit avoir été émis
        expect(creatingState, isFalse);
        // Le terme de recherche « xyz » doit être conservé dans le TextField
        expect(
          (tester.widget<TextField>(find.byType(TextField))).controller?.text,
          'xyz',
        );
      },
    );
  });

  // Test 10 : Reset au dispose — test indirect via StatefulWidget lifecycle
  //
  // Note : tester directement le mode interne après dispose() n'est pas
  // possible en widget test (le state est détruit). Ce test vérifie que le
  // widget peut être reconstruit après avoir été supprimé de l'arbre (cas
  // identique au dispose + recréation qui doit partir en mode list).
  testWidgets(
    'should_start_in_list_mode_when_widget_recreated_after_dispose',
    (tester) async {
      // Première instance
      await pumpCategorySelect(tester, AppTheme.light);

      // Passer en mode create
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('+ Créer « xyz »'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryFormWidget), findsOneWidget);

      // Reconstruire avec un widget différent (simule le dispose de l'ancien)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              MockCategoryRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remettre le widget en mode list (nouvelle instance)
      await pumpCategorySelect(tester, AppTheme.light);

      // La nouvelle instance doit partir en mode list
      expect(find.byType(CategoryFormWidget), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
