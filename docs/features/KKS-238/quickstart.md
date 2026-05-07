# Quickstart — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter

> Date : 2026-05-07
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)

Guide d'usage et de démarrage rapide pour les **développeurs Flutter** qui consommeront ces 8 composants en Étape 4-7.

---

## Pré-requis

- [x] Constitution lue (`.specify/memory/constitution.md` v3.0.0 — Trajectoire B)
- [x] Spec validée (`spec.md` — review PASS du 2026-05-07)
- [x] Research complétée (`research.md` — 14 décisions techniques)
- [x] Plan approuvé (`plan.md` — Constitution Check PASS, aucune dérogation)
- [ ] Tasks générées (`tasks.md`) — étape suivante
- [ ] KKS-237 mergé sur `develop` (livré)

---

## Phase 1 — Setup

```bash
cd flutter
git checkout -b feature/flutter-shared-components-v5
flutter pub get
flutter test  # baseline 713/713 tests OK (post-KKS-245)
```

**Vérification** : `flutter test` retourne `All tests passed!` avec ~713 tests verts.

---

## Phase 2 — Fondations

### Fichiers à créer (ordre suggéré)

| Ordre | Fichier | Description |
|-------|---------|-------------|
| 1 | `flutter/lib/src/utils/string_utils.dart` | Helper `normalizeForSearch` (RES-010) |
| 2 | `flutter/test/helpers/theme_test_helpers.dart` | Helper de tests `forEachTheme` (RES-012) |
| 3 | `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` | Extraction depuis `CategoryFormScreen` (FR-019) |
| 4-11 | `flutter/lib/src/common_widgets/*.dart` | 8 composants shared (cf. plan.md) |

### Étapes

1. Créer `string_utils.dart` (10 lignes) avec `String normalizeForSearch(String input)` basé sur `package:diacritic`.
2. Créer `theme_test_helpers.dart` avec `forEachTheme((theme, name) { ... })` qui itère `AppTheme.dark` + `AppTheme.light`.
3. Extraire `CategoryFormWidget` depuis `CategoryFormScreen` :
   - Créer `category_form_widget.dart` avec la logique form (sans Scaffold, sans AppBar).
   - State **publique** `class CategoryFormWidgetState extends ConsumerState<...>` avec méthode publique `Future<void> submit()`.
   - Refactor `category_form_screen.dart` en wrapper Scaffold de ~30 lignes utilisant `GlobalKey<CategoryFormWidgetState>`.
   - Adapter les tests existants `category_form_screen_test.dart`.
4. Vérifier que les tests existants passent (le refactor ne doit casser aucun test : R-1 du plan).

**Vérification** : `flutter test test/src/features/categories/` passe sans erreur. Le parcours `Liste catégories → + → CategoryFormScreen → Saisir nom → Valider → Retour liste` fonctionne en `flutter run`.

---

## Phase 3 — Implémentation User Stories

### Ordre suggéré (basé sur la criticité et les dépendances)

#### US-003 — `SectionHeaderSticky` (P1, le plus complexe — à prototyper en premier)

1. Créer `section_header_sticky.dart` avec :
   - Public `SectionHeaderSticky` `StatelessWidget`
   - Private `_SectionHeaderDelegate extends SliverPersistentHeaderDelegate`
   - `minExtent == maxExtent == 48.0`
   - `AnimatedContainer` sur bascule fond `shrinkOffset > 0`
2. Créer `section_header_sticky_test.dart` avec 5 tests (rendu, scroll programmatique, fond stuck, count, actions).

**Test** :
```dart
testWidgets('should_change_background_when_shrinkOffset_positive', (tester) async {
  // Arrange : CustomScrollView avec un hero + SectionHeaderSticky pinned
  // Act : tester.drag(Offset(0, -300))
  // Assert : couleur fond du AnimatedContainer == surfaceContainerHighest
});
```

#### US-004 — `ListGroup` (P1, simple)

1. Créer `list_group.dart` (~50 lignes) avec helper `_intersperse`.
2. Créer `list_group_test.dart` avec 3 tests (n-1 dividers, BorderRadius, couleur dividers).

**Test** : `ListGroup(children: List.generate(5, ...))` → 4 dividers, 1 BorderRadius extérieur.

#### US-001 — `InlineDatePicker` (P1, custom 250 lignes)

1. Créer `inline_date_picker.dart` avec :
   - Public `InlineDatePicker` `StatefulWidget`
   - Private model `_CalendarDay`
   - Private sub-widgets `_CalendarHeader`, `_CalendarGrid`, `_DayCell`
   - Helpers `_toIsoDate`, `_isoToDate`, `_computeDays`, `_normalizeStartOffset`
2. Créer `inline_date_picker_test.dart` avec 8+ tests :
   - Rendu mois courant
   - Navigation prev / next
   - Tap label mois → goToToday
   - Sélection jour → onChanged ISO
   - originalValue mode édition (cell discrète)
   - minDate / maxDate disabled
   - Frontière mois (1er = dimanche, février bissextile 2024)
   - Lundi-first hardcodé

**Test** : sélectionner le 15 mai 2026 → `onChanged('2026-05-15')`.

#### US-002 — `CategorySelectExpand` (P1, dépend de FR-019)

⚠️ Prérequis : Phase 2 step 3 (`CategoryFormWidget` extrait) doit être terminée.

1. Créer `category_select_expand.dart` avec :
   - Public `CategorySelectExpand` `StatefulWidget`
   - Private `_SelectMode` enum
   - `GlobalKey<CategoryFormWidgetState> _formKey`
2. Créer `category_select_expand_test.dart` avec 6+ tests :
   - Filtrage avec `normalizeForSearch`
   - Tap option → `onSelected(id)`
   - Bouton `+ Créer` apparaît si pas de match exact
   - Tap `+ Créer` bascule mode `'create'` (vérifier `CategoryFormWidget` rendu)
   - Tap `[✓ Créer]` header → `_formKey.currentState!.submit()` invoqué
   - Reset au `dispose` (mode `list`)

**Test** : injecter 5 catégories, taper « cou » → 1 match (« Courses ») ; taper « xyz » → 0 match + bouton `+ Créer « xyz »`.

#### US-005 — `PageHeader` (P2)

1. Créer `page_header.dart` (~60 lignes).
2. Créer `page_header_test.dart` avec 4 tests (rendu titre, tap back, icône optionnelle, sans icône).

**Test** : `PageHeader(title: 'Test', onBack: callback)` → tap flèche → `callback` invoqué.

#### US-006 — `EmptyStateWidget` (P2)

1. Créer `empty_state_widget.dart` (~70 lignes).
2. Créer `empty_state_widget_test.dart` avec 4 tests (avec/sans CTA, tap CTA).

#### US-007 — `ConfirmDialogCustom` (P2)

1. Créer `confirm_dialog_custom.dart` (~100 lignes).
2. Créer `confirm_dialog_custom_test.dart` avec 5 tests :
   - `show()` retourne `true` au tap Confirmer
   - `show()` retourne `false` au tap Annuler
   - `show()` retourne `null` au tap scrim (`barrierDismissible`)
   - Variant `danger` → couleur error + icône Trash
   - Back button Android → `null`

**Test** :
```dart
testWidgets('should_return_true_when_confirm_tapped', (tester) async {
  late Future<bool?> futureResult;
  await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) => ElevatedButton(
    onPressed: () => futureResult = ConfirmDialogCustom.show(context: ctx, title: 'Test'),
    child: const Text('Open'),
  ))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirmer'));
  await tester.pumpAndSettle();
  expect(await futureResult, isTrue);
});
```

#### US-008 — `VariationBadge` (P2)

1. Créer `variation_badge.dart` (~80 lignes).
2. Créer `variation_badge_test.dart` avec 5 tests :
   - delta > 0 → vert + signe `+`
   - delta < 0 → rouge + signe `-`
   - delta == 0, pas de pct → masqué (`SizedBox.shrink()`)
   - delta == 0, pct != null → neutral
   - Pourcentage formaté `1,5%` (1 décimale, locale `fr_FR`)

### Cleanup transversal — Suppression `SegmentedFilter`

1. Supprimer `flutter/lib/src/common_widgets/segmented_filter.dart`.
2. Supprimer le test `segmented_filter_test.dart` s'il existe.
3. Dans `debt_list_screen.dart` et `subscription_list_screen.dart` :
   - Retirer l'import.
   - Remplacer le widget par `Wrap` de `ChoiceChip` (RES-011) avec commentaire `// TODO KKS-240`.
4. Adapter les tests `debt_list_screen_test.dart` et `subscription_list_screen_test.dart`.

---

## Phase 4 — Polish

1. Exécuter les tests : `cd flutter && flutter test`
2. Vérifier l'analyse statique : `cd flutter && flutter analyze`
3. Vérifier qu'aucun `print()` ne traîne (NFR-008) : `grep -rn "print(" flutter/lib/src/common_widgets/ flutter/lib/src/features/categories/presentation/widgets/`
4. Vérifier qu'aucune valeur hex `Color(0xFF...)` n'est dans les nouveaux composants (SC-012) : `grep -rn "Color(0x" flutter/lib/src/common_widgets/section_header_sticky.dart flutter/lib/src/common_widgets/list_group.dart flutter/lib/src/common_widgets/empty_state_widget.dart flutter/lib/src/common_widgets/variation_badge.dart flutter/lib/src/common_widgets/page_header.dart flutter/lib/src/common_widgets/confirm_dialog_custom.dart flutter/lib/src/common_widgets/inline_date_picker.dart flutter/lib/src/common_widgets/category_select_expand.dart flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart`
5. Vérification visuelle (perf NFR-003) :
   - `cd flutter && flutter run --profile`
   - Naviguer sur un écran consommant `SectionHeaderSticky` + `ListGroup` × 50 items (à créer dans une preview/playground)
   - Ouvrir DevTools Timeline, scroller continu pendant 5s, vérifier `frameTime < 16.67ms` sur 95% des frames
   - Capturer un screencast pour le review-impl
6. Review du code via `pre-commit-review` puis `frontend-design-review`.

---

## Commandes utiles

| Action | Commande |
|--------|----------|
| Lancer les tests Flutter | `cd flutter && flutter test` |
| Tests d'un seul fichier | `cd flutter && flutter test test/src/common_widgets/inline_date_picker_test.dart` |
| Analyse statique | `cd flutter && flutter analyze` |
| Lancer l'app en profile mode (perf) | `cd flutter && flutter run --profile` |
| Code generation (si Drift / Freezed touché — pas le cas ici) | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |
| Vérifier baseline tests verts | `cd flutter && flutter test 2>&1 \| tail -5` |

---

## Exemples d'usage des composants (pour Étape 4-7)

### `SectionHeaderSticky`

```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: HeroSection(...)),
    SectionHeaderSticky(title: 'Transactions', count: 24),
    SliverList(delegate: SliverChildBuilderDelegate(...)),
  ],
)
```

### `ListGroup` + `EmptyStateWidget`

```dart
items.isEmpty
  ? EmptyStateWidget(
      icon: PhosphorIcons.folderOpen(),
      message: 'Aucune transaction ce mois',
      hint: 'Tapez + pour ajouter',
      ctaLabel: '+ Créer',
      onCtaTap: () => _openCreateForm(),
    )
  : ListGroup(children: items.map((t) => TransactionTile(transaction: t)).toList())
```

### `InlineDatePicker` (dans bottom sheet)

```dart
InlineDatePicker(
  value: _isoDate,                    // '2026-05-07'
  onChanged: (newIso) => setState(() => _isoDate = newIso),
  originalValue: _originalIsoDate,    // '2026-05-01' en mode édition
  minDate: '2020-01-01',
  maxDate: '2030-12-31',
)
```

### `CategorySelectExpand` (dans bottom sheet)

```dart
CategorySelectExpand(
  categories: ref.watch(categoriesProvider).valueOrNull ?? [],
  selectedId: _selectedCategoryId,
  onSelected: (id) {
    setState(() => _selectedCategoryId = id);
    _collapseExpand();
  },
  onCreated: (newCategory) {
    // Le notifier a déjà été appelé par CategoryFormWidget — ici on met juste à jour la liste UI
    _refreshCategories();
    setState(() => _selectedCategoryId = newCategory.id);
  },
  onCreatingChanged: (isCreating) {
    setState(() => _footerDisabled = isCreating);
  },
)
```

### `ConfirmDialogCustom`

```dart
final confirmed = await ConfirmDialogCustom.show(
  context: context,
  icon: PhosphorIcons.trash(),
  title: 'Supprimer "Courses 42 €"',
  message: 'Cette action est irréversible.',
  variant: ConfirmVariant.danger,
);
if (confirmed == true) {
  await ref.read(transactionNotifierProvider.notifier).delete(id);
}
```

### `PageHeader`

```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        children: [
          PageHeader(
            title: 'Mon compte',
            onBack: () => context.pop(),
            icon: Icon(PhosphorIcons.user()),  // optionnel
          ),
          Expanded(child: ...),
        ],
      ),
    ),
  ),
)
```

### `VariationBadge`

```dart
VariationBadge(
  delta: 150.50,
  currency: '€',
  percentage: 12.5,
  // suffix: 'ce mois',  // valeur par défaut
)
// Rendu : "+150,50 € ce mois (+12,5%)" en vert
```

---

## Checklist finale

- [ ] Tous les tests passent (≥ 713 baseline + nouveaux tests des composants)
- [ ] `flutter analyze` exit 0
- [ ] Aucun `print()` dans les composants livrés
- [ ] Aucune valeur hex `Color(0xFF...)` dans les composants livrés (SC-012)
- [ ] Tests dark + light via `forEachTheme` pour chaque composant
- [ ] Vérification perf manuelle DevTools Timeline pour `SectionHeaderSticky` + `ListGroup` (NFR-003)
- [ ] `SegmentedFilter` supprimé + 2 sites consommateurs adaptés
- [ ] `CategoryFormWidget` extrait, `CategoryFormScreen` refactor, parcours liste catégories OK
- [ ] Documentation `///` sur chaque classe publique + paramètre public (NFR-006)
- [ ] Review `frontend-design-review` PASS
- [ ] Review `pre-commit-review` PASS
- [ ] `/devflow.review-impl` PASS
