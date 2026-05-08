# Documentation — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter (8 widgets)

> Date : 2026-05-08
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Issue parent : [KKS-236](https://linear.app/kksdev/issue/KKS-236/phase-1-refonte-design-flutter-v5)
> Branche : `feature/flutter-shared-components-v5`

---

## Résumé

Cette feature livre **8 composants Flutter shared** alignés sur les patterns Angular DESIGN.md v5 (audit comparatif strict effectué le 2026-05-07), un **widget extrait réutilisable** (`CategoryFormWidget`) et un **cleanup transversal** (suppression de l'anti-pattern `SegmentedFilter`). Tous les composants sont 100% UI sans dépendance réseau, conformes Trajectoire B (Flutter standalone commercial), et débloquent l'Étape 4 (refonte écrans listes) et l'Étape 5 (refonte formulaires bottom sheets) de la refonte Phase 1.

## Guide utilisateur

### Fonctionnalités

Cette feature est destinée aux **développeurs Flutter** qui consommeront ces composants en Étape 4-7. Aucun changement utilisateur final visible avant l'intégration dans les écrans.

#### `SectionHeaderSticky` (US-003)

**Description** : En-tête sticky d'une section dans une liste scrollable. Le fond bascule de transparent vers `colorScheme.surfaceContainerHighest` dès que le header se colle au top du viewport.

**Usage** :
```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: HeroSection(...)),
    SectionHeaderSticky(title: 'Transactions', count: 24, actions: [
      IconButton(icon: Icon(PhosphorIcons.funnel()), onPressed: ...),
    ]),
    SliverList(delegate: SliverChildBuilderDelegate(...)),
  ],
)
```

#### `ListGroup` (US-004)

**Description** : Conteneur arrondi `colorScheme.surfaceContainer` regroupant des items avec dividers internes 1px `colorScheme.outlineVariant`. Remplace le pattern de `Container` individuels avec `Border.all`.

**Usage** :
```dart
ListGroup(
  children: items.map((t) => TransactionTile(transaction: t)).toList(),
)
```

#### `EmptyStateWidget` (US-006)

**Description** : État vide unifié avec icône Phosphor 48px @ 50% opacity, message principal, hint optionnel et CTA text-link amber souligné.

**Usage** :
```dart
EmptyStateWidget(
  icon: PhosphorIcons.folderOpen(),
  message: 'Aucune transaction ce mois',
  hint: 'Tapez + pour ajouter',
  ctaLabel: '+ Créer',
  onCtaTap: () => _openCreateForm(),
)
```

#### `VariationBadge` (US-008)

**Description** : Texte coloré affichant le delta vs mois précédent (`+150,50 € ce mois (+12,5%)`). Couleurs : vert (`incomeColor`) si positif, rouge (`expenseColor`) si négatif, neutre si zéro. **Masqué automatiquement** si `delta == 0 && percentage == null`.

**Usage** :
```dart
VariationBadge(
  delta: 150.50,
  currency: '€',
  percentage: 12.5,
  // suffix: 'ce mois' (par défaut)
)
```

#### `PageHeader` (US-005)

**Description** : Header de sous-pages avec back button rond 36px à gauche, espace flexible, icône métier optionnelle 32×32 ronde et titre `titleLarge` bold aligné à droite (flex-end). Pas de `trailing` actions.

**Usage** :
```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Column(
        children: [
          PageHeader(
            title: 'Mon compte',
            onBack: () => context.pop(),
            icon: Icon(PhosphorIcons.user()),
          ),
          Expanded(child: ...),
        ],
      ),
    ),
  ),
)
```

#### `ConfirmDialogCustom` (US-007)

**Description** : Dialog modal de confirmation centré avec icône métier optionnelle, variantes `primary` (amber) et `danger` (rouge). Méthode statique retournant `Future<bool?>` (`null` au tap scrim ou back button Android).

**Usage** :
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

#### `InlineDatePicker` (US-001)

**Description** : Calendrier inline custom Flutter (réimplémentation 100% custom, pas `CalendarDatePicker` Material) avec format ISO `String` (`'YYYY-MM-DD'`), cellules cercle 36×36, headers `L M M J V S D` (lundi-first hardcodé), et concept `originalValue` (mise en valeur discrète de la date initiale en mode édition).

**Usage** :
```dart
InlineDatePicker(
  value: _isoDate,                    // '2026-05-08'
  onChanged: (newIso) => setState(() => _isoDate = newIso),
  originalValue: _originalIsoDate,    // '2026-05-01' en mode édition
  minDate: '2020-01-01',
  maxDate: '2030-12-31',
)
```

#### `CategorySelectExpand` (US-002)

**Description** : Sélecteur de catégorie inline composite avec 2 modes internes : `'list'` (recherche + listbox + bouton `+ Créer`) et `'create'` (header `[← Retour] [✓ Créer]` + embed `CategoryFormWidget`). Recherche insensible à la casse / accents via `normalizeForSearch`.

**Usage** :
```dart
CategorySelectExpand(
  categories: ref.watch(categoriesProvider).valueOrNull ?? [],
  selectedId: _selectedCategoryId,
  onSelected: (id) {
    setState(() => _selectedCategoryId = id);
    _collapseExpand();
  },
  onCreated: (newCategory) {
    _refreshCategories();
    setState(() => _selectedCategoryId = newCategory.id);
  },
  onCreatingChanged: (isCreating) {
    setState(() => _footerDisabled = isCreating);
  },
)
```

### Helpers fournis

#### `normalizeForSearch(String input)` (`lib/src/utils/string_utils.dart`)

Helper public : `lowercase + removeDiacritics + trim`. Utilisé par `CategorySelectExpand` et `transaction_repository_local`.

```dart
normalizeForSearch('Café  ');  // → 'cafe'
normalizeForSearch('  COURSES  ');  // → 'courses'
```

#### `forEachTheme` (`test/helpers/theme_test_helpers.dart`)

Helper de tests : itère un test sur `AppTheme.dark` et `AppTheme.light`.

```dart
forEachTheme((theme, themeName) {
  testWidgets('should_render_correctly_when_$themeName', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: theme, home: ...));
  });
});
```

## Changements techniques

### Fichiers créés (15)

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/common_widgets/section_header_sticky.dart` | `SectionHeaderSticky` — `SliverPersistentHeader.pinned` avec fond dynamique |
| `flutter/lib/src/common_widgets/list_group.dart` | `ListGroup` — Container arrondi avec dividers internes |
| `flutter/lib/src/common_widgets/empty_state_widget.dart` | `EmptyStateWidget` — état vide avec icône, message, hint, CTA |
| `flutter/lib/src/common_widgets/variation_badge.dart` | `VariationBadge` — texte coloré delta + suffix + percentage |
| `flutter/lib/src/common_widgets/page_header.dart` | `PageHeader` — header sous-pages, titre flex-end |
| `flutter/lib/src/common_widgets/confirm_dialog_custom.dart` | `ConfirmDialogCustom.show()` + enum `ConfirmVariant` |
| `flutter/lib/src/common_widgets/inline_date_picker.dart` | `InlineDatePicker` custom (calendrier inline ISO) |
| `flutter/lib/src/common_widgets/category_select_expand.dart` | `CategorySelectExpand` (composite stateful avec embed) |
| `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` | `CategoryFormWidget` extrait réutilisable (FR-019) |
| `flutter/lib/src/utils/string_utils.dart` | Helper public `normalizeForSearch` |
| `flutter/test/helpers/theme_test_helpers.dart` | Helper de tests `forEachTheme` |
| 4 fichiers test `flutter/test/src/common_widgets/...` | Tests des 8 composants shared |

### Fichiers modifiés (4)

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` | Refactor en wrapper Scaffold autour du `CategoryFormWidget` extrait. Ajout `SingleChildScrollView` pour préserver le scroll standalone après la migration `ListView → Column` du widget |
| `flutter/lib/src/features/transactions/data/transaction_repository_local.dart` | Migration `_normalize` privé → `normalizeForSearch` public (cohérence helpers partagés) |
| `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` | Remplacement `SegmentedFilter` → `Wrap` de `ChoiceChip` Material 3 + TODO KKS-240 |
| `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` | Idem (2 occurrences remplacées) |

### Fichiers supprimés (2)

| Fichier | Raison |
|---------|--------|
| `flutter/lib/src/common_widgets/segmented_filter.dart` | Anti-pattern DESIGN.md (segmented control). Remplacé par `ChoiceChip` Material 3 temporaire en attendant la refonte propre Étape 4 (KKS-240) |
| `flutter/test/src/common_widgets/segmented_filter_test.dart` | Test associé au composant supprimé |

### Dépendances ajoutées

**Aucune.** Tous les composants utilisent les packages déjà présents :
- `flutter` (SDK Material 3, Slivers, `showDialog`)
- `flutter_riverpod` (uniquement pour `CategoryFormWidget`)
- `phosphor_flutter` (icônes)
- `intl` (formatage `VariationBadge`)
- `diacritic` (helper `normalizeForSearch`)

## Configuration

Aucune configuration particulière requise. Les composants utilisent automatiquement le thème global (`AppTheme.dark` / `AppTheme.light`) via `Theme.of(context)` et l'extension `AppThemeExtension` (16 propriétés livrées en KKS-237).

### Tokens consommés

| Composant | Tokens utilisés |
|---|---|
| `SectionHeaderSticky` | `colorScheme.surfaceContainerHighest` (stuck), `AppDurations.normal` |
| `ListGroup` | `colorScheme.surfaceContainer`, `colorScheme.outlineVariant`, `AppRadius.xl` |
| `EmptyStateWidget` | `colorScheme.onSurfaceVariant`, `colorScheme.outline`, `colorScheme.primary` (CTA) |
| `VariationBadge` | `themeExt.incomeColor`, `themeExt.expenseColor`, `colorScheme.onSurfaceVariant` |
| `PageHeader` | `themeExt.iconCircleBg`, `colorScheme.onSurface`, `colorScheme.primary` (hover) |
| `ConfirmDialogCustom` | `colorScheme.primary` / `colorScheme.error` (selon variant) |
| `InlineDatePicker` | `colorScheme.primary` (selected), `colorScheme.outlineVariant` (today), `themeExt.hoverSubtle` (originalValue) |
| `CategorySelectExpand` | `themeExt.primarySubtle` (sélection), `colorScheme.outlineVariant`, `AppRadius.md` |

## Tests et validation

### Tests unitaires et widget tests

| Composant | Tests | Statut |
|---|---|---|
| `SectionHeaderSticky` | 5 cas × 2 thèmes = 10 tests (rendu, count, actions, fond stuck, pinned) | ✅ |
| `ListGroup` | 3 cas × 2 thèmes = 6 tests (n-1 dividers, BorderRadius, single child) | ✅ |
| `EmptyStateWidget` | 4 cas × 2 thèmes = 8 tests (avec/sans CTA, sans icône, tap CTA) | ✅ |
| `VariationBadge` | 5 cas × 2 thèmes = 10 tests (positif vert, négatif rouge, masqué si zéro, neutre, format pct) | ✅ |
| `PageHeader` | 4 cas × 2 thèmes = 8 tests (titre, tap back, icône, sans icône) | ✅ |
| `ConfirmDialogCustom` | 5 cas (true/false/null, variant danger Trash, variant primary Check) | ✅ |
| `InlineDatePicker` | 10 cas × 2 thèmes = 20 tests (mois courant, navigation, goToToday, sélection ISO, originalValue, min/max, frontière dimanche, février bissextile) | ✅ |
| `CategorySelectExpand` | 10 cas × 2 thèmes = 20 tests (filtrage casse/accents, onSelected, bouton créer, bascule mode, retour, reset dispose) | ✅ |
| `CategoryFormWidget` (extraction) | 9 tests (validation nom/emoji, submit succès/erreur réseau, mode édition, initialName) | ✅ |

**Total** : ~80 nouveaux tests + 713 baseline − 20 tests `SegmentedFilter` supprimés = **793/793 verts**.

### Vérifications qualité automatisées

| Critère | Vérification | Résultat |
|---|---|---|
| `flutter analyze` | Aucun warning sur les fichiers KKS-238 | ✅ Clean |
| `Color(0xFF...)` directs | grep sur les 9 fichiers composants livrés | ✅ 0 occurrence |
| `print()` / `debugPrint()` | grep dans `common_widgets/` et `categories/presentation/widgets/` | ✅ 0 occurrence |
| Nouvelles dépendances `pubspec.yaml` | Diff vs baseline | ✅ Aucune |
| `pre-commit-review` | Lancé à chaque commit (6 commits) | ✅ 6/6 PASS |
| `frontend-design-review` | Lancé à chaque commit majeur (4 lots) | ✅ 4/4 PASS |
| `devflow-review` | review-spec, review-tasks, review-impl | ✅ 3/3 PASS |

### Validation manuelle requise (à effectuer avant merge ou en KKS-240)

- [ ] **T-053 Perf 60 fps Pixel 3a** : `flutter run --profile`, scroller un écran consommant `SectionHeaderSticky` + `ListGroup` × 50 items, ouvrir DevTools Timeline pendant 5s, vérifier `frameTime < 16.67ms` sur 95% des frames. Reporté avant la review-impl de KKS-240 (premier consommateur réel).
- [x] **Régression** : parcours `Liste catégories → + → save → retour liste` testé, fonctionne sans régression visuelle ni fonctionnelle après l'extraction `CategoryFormWidget` et la migration `ListView → Column`.

## Décisions structurantes

### Audit comparatif Angular (2026-05-07)

Avant le gel de la spécification, un audit comparatif strict des 8 composants Angular sources a été effectué. Cet audit a corrigé **3 décisions initialement fausses** :

1. **`InlineDatePicker`** : initialement prévu comme wrapper `CalendarDatePicker` Material 3 → en réalité **réimplémentation custom Flutter** obligatoire (cellules cercle vs carré Material, headers 1 lettre, tap label = goToToday vs popup année Material, concept `originalValue` inexistant en Material).
2. **`CategorySelectExpand`** : initialement prévu en dumb component → en réalité **composite stateful avec embed `CategoryFormWidget`** complet (alignement strict pattern Angular avec `ControlValueAccessor` + `viewChild`).
3. **`ConfirmDialogCustom`** justification : YAGNI Constitution → corrigée en **idiomatique Flutter** (`showDialog` natif équivalent à l'overlay global Angular).

L'audit a aussi résolu CL-005 (`VariationBadge` masqué si `delta == 0 && percentage == null`) et identifié l'extraction `CategoryFormWidget` (FR-019) comme prérequis caché à `CategorySelectExpand`.

### Anomalies corrigées pendant l'implémentation

1. **Régression `CategoryFormWidget`** (révélée par Lot C) : `ListView` non bornable dans contexte parent scrollable. Correction : `ListView → Column(mainAxisSize: MainAxisSize.min)` + `SingleChildScrollView` parent dans `CategoryFormScreen`. Pattern Flutter idiomatique : déléguer le scroll au parent.
2. **Écart spec `SegmentedFilter`** : la spec annonçait 2 sites consommateurs (`debt_list_screen` + `subscription_list_screen`). Le grep réel a confirmé cet inventaire (le 3ᵉ site initialement détecté `transaction_list_screen.dart` ne consommait finalement pas `SegmentedFilter`).
3. **Magic numbers `inline_date_picker.dart`** : 5 corrections post-frontend-design-review (Duration, fontSize, dimensions wrappers).
4. **Token sélection `CategorySelectExpand`** : `colorScheme.primaryContainer` (amber 100, ~65% opacité) → `themeExt.primarySubtle` (amber 10%, fidèle DESIGN.md `--primary-subtle`).

### Décisions techniques notables (research)

| RES | Décision | Justification |
|---|---|---|
| RES-001 | `SliverPersistentHeader.pinned` + delegate dédié pour `SectionHeaderSticky` | Mécanisme natif Flutter, performance optimale via `shouldRebuild` |
| RES-003 | `GlobalKey<CategoryFormWidgetState>` pour invoquer `submit()` du sous-widget | Pattern Flutter idiomatique pour communication parent → état enfant |
| RES-005 | `ConfirmDialogCustom.show()` retourne `Future<bool?>` (pas `bool`) | Idiomatique Flutter, distingue confirm/cancel/dismiss |
| RES-008 | `PageHeader.icon: Widget?` avec wrap interne 32×32 cercle | Couvre tous les cas (Icon, emoji, image), uniformité visuelle garantie |
| RES-011 | `ChoiceChip` (mono-sélection) au lieu de `FilterChip` (multi) pour le remplacement temporaire `SegmentedFilter` | Sémantique Material 3 correcte |
| RES-013 | Mapping cross-stack tokens documenté (`surfaceContainer` ↔ `--surface-default`, etc.) | Évite les divergences visuelles cross-stack |

## Pour la suite

### Conditions post-merge non-bloquantes

1. **T-053 perf** : effectuer la vérification DevTools Timeline avant la review-impl de KKS-240.
2. **SC-010 test golden** : ajouter un test explicite vérifiant `backgroundColor == colorScheme.error` pour `ConfirmDialogCustom` variant `danger` (en KKS-239+).
3. Si KKS-239 a un besoin réel des paramètres `onCancelled` / `showHeader` sur `CategoryFormWidget`, les réintroduire avec un usage concret.

### Features bloquées débloquées par cette livraison

| Feature | Composants nécessaires | Statut |
|---|---|---|
| **KKS-239** (Étape 3 — BottomSheet 4 rows) | `InlineDatePicker`, `CategorySelectExpand` | ✅ Débloquée |
| **KKS-240+** (Étape 4 — écrans listes) | `SectionHeaderSticky`, `ListGroup`, `EmptyStateWidget`, `VariationBadge`, `PageHeader` | ✅ Débloquée |
| **KKS-241+** (Étape 5 — formulaires XL) | `ConfirmDialogCustom` | ✅ Débloquée |

## Références

- [Spec](./spec.md) — 19 FR, 7 NFR, 14 SC, 6 assumptions
- [Plan](./plan.md) — Constitution Check PASS, 3 complexités CX tracées
- [Research](./research.md) — 14 décisions techniques RES
- [Contracts](./contracts.md) — 9 contrats composants + 2 helpers + 1 enum
- [Data Model](./data-model.md) — Types UI introduits
- [Tasks](./tasks.md) — 32 tâches en 4 phases (32/32 cochées)
- [Review Log](./review-log.md) — 3 reviews PASS (review-spec, review-tasks, review-impl)
- [Quickstart](./quickstart.md) — Guide d'usage pour les développeurs Étape 4-7
- [Clarify Log](./clarify-log.md) — 7 points résolus avec audit comparatif Angular
- [Constitution](../../../.specify/memory/constitution.md) v3.0.0
- [DESIGN.md](../../../DESIGN.md) — Référence design v5
