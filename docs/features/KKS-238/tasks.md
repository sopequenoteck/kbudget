# Tasks — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter (8 widgets)

> Date : 2026-05-07
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Spec : [spec.md](./spec.md) — Plan : [plan.md](./plan.md) — Research : [research.md](./research.md) — Contracts : [contracts.md](./contracts.md)

---

## Phase 1 : Setup

- [x] [T-001] [P1] Créer la branche `feature/flutter-shared-components-v5` depuis `develop` — Réf: setup
- [x] [T-002] [P1] Vérifier baseline tests verts (`cd flutter && flutter test` → ~713 tests OK) — Réf: setup, NFR-001

**Checkpoint** : Branche créée, baseline tests verts confirmée. Prêt pour les fondations.

---

## Phase 2 : Fondations (bloquantes)

- [x] [T-010] [P] [P1] Créer le helper public `normalizeForSearch(String input)` dans `flutter/lib/src/utils/string_utils.dart` (lowercase + `removeDiacritics` + trim) avec doc `///` — Réf: FR-005, RES-010
- [x] [T-011] [P] [P1] Créer le helper de tests `forEachTheme` + `wrapWithTheme` dans `flutter/test/helpers/theme_test_helpers.dart` — Réf: NFR-001, FR-018, RES-012
- [x] [T-012] [P1] Extraire `CategoryFormWidget` (state class **publique** `CategoryFormWidgetState` exposant `Future<void> submit()`) depuis `category_form_screen.dart` ; refactor `CategoryFormScreen` en wrapper Scaffold de ~30 lignes utilisant `GlobalKey<CategoryFormWidgetState>` ; **créer `flutter/test/src/features/categories/presentation/widgets/category_form_widget_test.dart`** avec les tests propres au widget extrait (validation nom, validation emoji, submit succès → onSaved, submit erreur réseau → SnackBar, mode edit) ; adapter `category_form_screen_test.dart` (M) ; vérifier le parcours `Liste catégories → + → save → retour liste` en `flutter run` — Réf: FR-019, CX-002, RES-004

**Checkpoint** : `flutter test` toujours vert. `CategoryFormWidget` est embeddable sans Scaffold. Le parcours navigable existant (`CategoryFormScreen`) fonctionne sans régression visuelle ni fonctionnelle.

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

#### US-003 — `SectionHeaderSticky` (à prototyper en premier — le plus complexe)

- [x] [T-020] [P] [P1] [US3] Créer `flutter/lib/src/common_widgets/section_header_sticky.dart` : public `SectionHeaderSticky` (`StatelessWidget` retournant `SliverPersistentHeader.pinned`) + private `_SectionHeaderDelegate extends SliverPersistentHeaderDelegate` (minExtent == maxExtent == 48.0, `AnimatedContainer` 300ms basculant fond `Colors.transparent` → `colorScheme.surfaceContainerHighest` quand `shrinkOffset > 0`) — Réf: FR-007, FR-017, FR-018, RES-001
- [x] [T-021] [P] [P1] [US3] Créer `flutter/test/src/common_widgets/section_header_sticky_test.dart` (5 tests via `forEachTheme` : rendu nominal, count affiché, actions affichées, scroll → fond stuck, `shouldRebuild` correct) — Réf: NFR-001, SC-005

#### US-004 — `ListGroup`

- [x] [T-022] [P] [P1] [US4] Créer `flutter/lib/src/common_widgets/list_group.dart` (`StatelessWidget` avec helper privé `_intersperse<Widget>` insérant `Divider(height: 1, color: colorScheme.outlineVariant)` entre enfants, `Container(clipBehavior: antiAlias, borderRadius: AppRadius.xl, color: colorScheme.surfaceContainer)`) — Réf: FR-008, FR-009, RES-009, RES-013
- [x] [T-023] [P] [P1] [US4] Créer `flutter/test/src/common_widgets/list_group_test.dart` (3 tests via `forEachTheme` : `n - 1` dividers pour `n` enfants, BorderRadius parent unique, couleur dividers `outlineVariant`) — Réf: NFR-001, SC-006

#### US-001 — `InlineDatePicker`

- [x] [T-024] [P] [P1] [US1] Créer model privé `_CalendarDay` + helpers privés `_toIsoDate(DateTime)`, `_isoToDate(String)`, `_normalizeStartOffset` (lundi-first hardcodé) dans `inline_date_picker.dart` — Réf: FR-001, RES-002, DC-004
- [x] [T-025] [P1] [US1] Créer sub-widgets privés `_CalendarHeader` (`[‹] [Mai 2026 cliquable] [›]`), `_CalendarGrid` (7 colonnes, gap 2px), `_DayCell` (36×36 cercle avec états sélectionné / aujourd'hui / original / disabled / hors-mois) dans `inline_date_picker.dart` — Réf: FR-003, RES-002
- [x] [T-026] [P1] [US1] Créer public `InlineDatePicker` `StatefulWidget` (`value: String`, `onChanged: ValueChanged<String>`, `originalValue?`, `minDate?`, `maxDate?`) avec state local `_currentMonth`, `_currentYear` + méthodes `_prevMonth`, `_nextMonth`, `_goToToday`, `_selectDay` ; `_computeDays()` calcule la liste de `_CalendarDay` selon FR-003 — Réf: FR-001, FR-002, RES-002
- [x] [T-027] [P1] [US1] Créer `flutter/test/src/common_widgets/inline_date_picker_test.dart` (8+ tests via `forEachTheme` : rendu mois courant, navigation prev/next, tap label = goToToday, tap jour → `onChanged('2026-05-15')` ISO, originalValue mode édition, minDate/maxDate disabled, frontière mois 1er = dimanche, février bissextile 2024) — Réf: NFR-001, SC-001, SC-002, R-4

> Note parallélisme intra-US-001 : T-024/T-025/T-026/T-027 sont **séquentielles entre elles** (modèle → sub-widgets → widget public → tests) mais **parallélisables avec d'autres US P1** (US-003, US-004) et avec US-002. Le marqueur `[P]` sur T-024 indique cette parallélisabilité inter-US, pas intra-US.

#### US-002 — `CategorySelectExpand` (dépend de T-012)

- [x] [T-028] [US2] Créer `flutter/lib/src/common_widgets/category_select_expand.dart` mode `'list'` : `StatefulWidget` avec `_searchController`, `_mode: _SelectMode`, `_formKey: GlobalKey<CategoryFormWidgetState>`, filtrage via `normalizeForSearch`, listbox `Category` (icon + nom), bouton `+ Créer « terme »` quand pas de match exact — Réf: FR-004, FR-005, CX-001, RES-003, DC-003
- [x] [T-029] [US2] Implémenter mode `'create'` dans `category_select_expand.dart` : header `[← Retour] [✓ Créer]` (avec `_formKey.currentState?.submit()` au tap), embed `CategoryFormWidget(key: _formKey, initialName: _searchController.text, onSaved: _onCreated)` ; basculement `_setMode(create/list)` notifiant `onCreatingChanged` ; recherche conservée au retour ; reset au `dispose()` — Réf: FR-006, RES-003
- [x] [T-030] [US2] Créer `flutter/test/src/common_widgets/category_select_expand_test.dart` (10 cas × 2 thèmes = 20 tests : filtrage `normalizeForSearch`, tap option → `onSelected(id)`, bouton `+ Créer` apparition/masquage, bascule mode `'create'` + `CategoryFormWidget` rendu, retour mode list avec recherche conservée, reset au dispose) — Réf: NFR-001, SC-003, SC-004

> **Régression révélée par Lot C** : `CategoryFormWidget` (Phase 2) utilisait un `ListView` qui exigeait une hauteur bornée. Quand embedded dans `CategorySelectExpand` à l'intérieur d'un parent scrollable, l'assertion `debugCheckHasBoundedAxis` levait `Vertical viewport was given unbounded height`. Correction : `ListView` → `Column(mainAxisSize: MainAxisSize.min)` dans `CategoryFormWidget`, et `CategoryFormScreen` enveloppe désormais le widget dans un `SingleChildScrollView`. Pattern Flutter idiomatique : déléguer le scroll au parent.

### P2 — Importantes

#### US-005 — `PageHeader`

- [x] [T-031] [P] [P2] [US5] Créer `flutter/lib/src/common_widgets/page_header.dart` (`StatelessWidget`, layout `Row` : back rond 36×36 + `Spacer` + icône optionnelle 32×32 wrappée + titre flex-end `titleLarge` bold, **pas de trailing**) — Réf: FR-010, RES-008
- [x] [T-032] [P] [P2] [US5] Créer `flutter/test/src/common_widgets/page_header_test.dart` (4 tests via `forEachTheme` : rendu titre, tap back → callback invoqué, icône optionnelle wrappée 32×32, sans icône) — Réf: NFR-001, SC-007

#### US-006 — `EmptyStateWidget`

- [x] [T-033] [P] [P2] [US6] Créer `flutter/lib/src/common_widgets/empty_state_widget.dart` (`StatelessWidget`, paramètres `icon?`, `message`, `hint?`, `ctaLabel?`, `onCtaTap?` ; `Center > Column` avec icône 48px opacity 0.5, message `bodyMedium` `onSurfaceVariant`, hint `bodySmall` tertiary, CTA `TextButton` text-link amber souligné) — Réf: FR-011, RES-007
- [x] [T-034] [P] [P2] [US6] Créer `flutter/test/src/common_widgets/empty_state_widget_test.dart` (4 tests via `forEachTheme` : rendu sans CTA, rendu avec CTA, tap CTA → callback, sans icône) — Réf: NFR-001, SC-008

#### US-007 — `ConfirmDialogCustom`

- [x] [T-035] [P] [P2] [US7] Créer `flutter/lib/src/common_widgets/confirm_dialog_custom.dart` : enum public `ConfirmVariant { primary, danger }` + classe `ConfirmDialogCustom` (constructeur privé `_()` + méthode statique `Future<bool?> show({context, icon?, title, message?, confirmLabel, cancelLabel, variant})` qui appelle `showDialog<bool>` avec `barrierDismissible: true` et un widget privé `_ConfirmDialogContent`) ; bouton Annuler `OutlinedButton.icon` (X 14px) ; bouton Confirmer `FilledButton.icon` (Check ou Trash 14px selon variant, couleur primary ou error) — Réf: FR-012, FR-013, RES-005, DC-005, NFR-007
- [x] [T-036] [P] [P2] [US7] Créer `flutter/test/src/common_widgets/confirm_dialog_custom_test.dart` (5 tests via `forEachTheme` : `show()` → `true` au tap Confirmer, `show()` → `false` au tap Annuler, `show()` → `null` au tap scrim, variant danger → couleur error + icône Trash, back button Android → `null`) — Réf: NFR-001, NFR-007, SC-009, SC-010

#### US-008 — `VariationBadge`

- [x] [T-037] [P] [P2] [US8] Créer `flutter/lib/src/common_widgets/variation_badge.dart` (`StatelessWidget`, paramètres `delta`, `currency?`, `percentage?`, `suffix='ce mois'` ; helper privé `_formatVariation` utilisant `intl.NumberFormat.currency(locale: 'fr_FR')` pour le montant + format manuel signe/pourcentage 1 décimale ; couleur via `themeExt.incomeColor` / `expenseColor` / `colorScheme.onSurfaceVariant` ; rendu `SizedBox.shrink()` si `delta == 0 && percentage == null`) — Réf: FR-014, RES-006, CL-005
- [x] [T-038] [P] [P2] [US8] Créer `flutter/test/src/common_widgets/variation_badge_test.dart` (5 tests via `forEachTheme` : delta > 0 → vert + `+`, delta < 0 → rouge + `-`, `delta == 0 && percentage == null` → masqué, `delta == 0 && percentage != null` → neutral, format pourcentage `+12,5%`) — Réf: NFR-001, SC-011

### Cleanup transversal — Suppression `SegmentedFilter`

- [x] [T-040] [P] [P1] Supprimer `flutter/lib/src/common_widgets/segmented_filter.dart` et son test associé `segmented_filter_test.dart` (s'il existe) — Réf: FR-015
- [x] [T-041] [P] [P1] Adapter `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` : retirer l'import `SegmentedFilter`, remplacer par `Wrap(spacing: AppSpacing.s2, children: items.map((i) => ChoiceChip(label: ..., selected: ..., onSelected: ...)).toList())` avec commentaire `// TODO KKS-240 : remplacer par groupement + sections (DESIGN.md anti-pattern segmented control)` — Réf: FR-016, RES-011
- [x] [T-042] [P] [P1] Adapter `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` : même remplacement que T-041 (`ChoiceChip` + TODO) — Réf: FR-016, RES-011
- [x] [T-043] [P] [P1] Adapter ou supprimer les tests `debt_list_screen_test.dart` et `subscription_list_screen_test.dart` qui dépendent de `SegmentedFilter` ; s'assurer que `flutter test` reste vert — Réf: A-004, R-5

**Checkpoint** : Tous les composants livrés (`section_header_sticky.dart`, `list_group.dart`, `inline_date_picker.dart`, `category_select_expand.dart`, `page_header.dart`, `empty_state_widget.dart`, `confirm_dialog_custom.dart`, `variation_badge.dart`, `category_form_widget.dart`). `SegmentedFilter` supprimé, sites consommateurs adaptés. `flutter test` passe (≥ 713 baseline + ~40 nouveaux tests).

---

## Phase 4 : Polish

- [ ] [T-050] [P1] `cd flutter && flutter analyze` exit 0 (aucun warning lint) — Réf: NFR-001
- [ ] [T-051] [P] [P1] `grep -rn "Color(0x" flutter/lib/src/common_widgets/section_header_sticky.dart flutter/lib/src/common_widgets/list_group.dart flutter/lib/src/common_widgets/empty_state_widget.dart flutter/lib/src/common_widgets/variation_badge.dart flutter/lib/src/common_widgets/page_header.dart flutter/lib/src/common_widgets/confirm_dialog_custom.dart flutter/lib/src/common_widgets/inline_date_picker.dart flutter/lib/src/common_widgets/category_select_expand.dart flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` → 0 occurrence (SC-012 corrigé : 9 fichiers, pas 8) — Réf: SC-012, FR-017, DC-001
- [ ] [T-052] [P] [P1] `grep -rn "print(" flutter/lib/src/common_widgets/ flutter/lib/src/features/categories/presentation/widgets/` → 0 occurrence dans les composants livrés — Réf: NFR-008, DC-006
- [ ] [T-053] [P2] Vérification perf manuelle : `cd flutter && flutter run --profile`, scroller un écran consommant `SectionHeaderSticky` + `ListGroup` × 50 items, ouvrir DevTools Timeline pendant 5s, vérifier `frameTime < 16.67ms` sur 95% des frames, capturer screencast pour le review-impl — Réf: NFR-003, RES-014
- [ ] [T-054] [P3] [optionnel] Refactor cohérence : migrer `transaction_repository_local.dart:71` (`_normalize` privé) vers le helper public `normalizeForSearch` — Réf: RES-010 (différable hors scope)
- [ ] [T-055] [P1] Lancer `cd flutter && flutter test` — toute la suite verte (713 baseline + ~40 nouveaux ≈ 753 tests) — Réf: NFR-001
- [ ] [T-056] [P1] Agent `frontend-design-review` PASS — Réf: convention CLAUDE.md
- [ ] [T-057] [P1] Agent `pre-commit-review` PASS sur les fichiers staged — Réf: convention CLAUDE.md

**Checkpoint** : `flutter analyze` clean, tests verts, aucun `Color(0xFF...)` dans les composants livrés, aucun `print()`, perf vérifiée manuellement, agents review PASS. Prêt pour `/devflow.review-impl`.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
T-001 (branche)
  └─→ T-002 (baseline tests)
        ├─→ T-010 (normalizeForSearch) [P]
        ├─→ T-011 (forEachTheme helper) [P]
        └─→ T-012 (extract CategoryFormWidget)
              │
              ├─→ T-020 → T-021 (US-003 SectionHeaderSticky) [P après T-012/T-011]
              │
              ├─→ T-022 → T-023 (US-004 ListGroup) [P après T-012/T-011]
              │
              ├─→ T-024 → T-025 → T-026 → T-027 (US-001 InlineDatePicker) [P après T-012/T-011]
              │
              ├─→ T-028 → T-029 → T-030 (US-002 CategorySelectExpand)
              │      ↑ requiert T-010 + T-012
              │
              ├─→ T-031 → T-032 (US-005 PageHeader) [P]
              ├─→ T-033 → T-034 (US-006 EmptyStateWidget) [P]
              ├─→ T-035 → T-036 (US-007 ConfirmDialogCustom) [P]
              ├─→ T-037 → T-038 (US-008 VariationBadge) [P]
              │
              └─→ T-040 → T-041 [P], T-042 [P], T-043 [P] (cleanup SegmentedFilter)
                    │
                    ↓ (toutes US complétées + cleanup)
                    T-050 (analyze) → T-051 [P], T-052 [P], T-053, T-055
                                                                  │
                                                                  ↓
                                                       T-056 → T-057 → review-impl
```

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US-001 (InlineDatePicker) | T-024, T-025, T-026, T-027 | T-002 (baseline), T-011 (forEachTheme pour T-027) |
| US-002 (CategorySelectExpand) | T-028, T-029, T-030 | **T-010 (normalizeForSearch), T-012 (CategoryFormWidget extrait)**, T-011 |
| US-003 (SectionHeaderSticky) | T-020, T-021 | T-002, T-011 |
| US-004 (ListGroup) | T-022, T-023 | T-002, T-011 |
| US-005 (PageHeader) | T-031, T-032 | T-002, T-011 |
| US-006 (EmptyStateWidget) | T-033, T-034 | T-002, T-011 |
| US-007 (ConfirmDialogCustom) | T-035, T-036 | T-002, T-011 |
| US-008 (VariationBadge) | T-037, T-038 | T-002, T-011 |
| Cleanup `SegmentedFilter` | T-040, T-041, T-042, T-043 | T-002 |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| **G1 — Fondations** | T-010, T-011 | T-002 complété |
| **G2 — US P1 (sauf US-002)** | US-003 (T-020/T-021) // US-004 (T-022/T-023) // US-001 (T-024-027) | T-010 + T-011 + T-012 complétés |
| **G3 — US-002 (séquentielle)** | T-028 → T-029 → T-030 | T-010 + T-012 complétés |
| **G4 — US P2 (toutes parallélisables)** | US-005 // US-006 // US-007 // US-008 | T-011 complété |
| **G5 — Cleanup `SegmentedFilter`** | T-041, T-042, T-043 (après T-040) | T-040 complété |
| **G6 — Polish vérifications** | T-051, T-052 | T-050 complété |

⚠️ **Charge cognitive** : malgré le potentiel de parallélisme, l'implémentation par un seul développeur (Kelly) doit suivre un ordre cohérent : G1 → G2 (1 US à la fois) → G3 → G4 (1 US à la fois) → G5 → G6.

---

## Implementation Strategy

### MVP First

**MVP** (livraison atomique — pas de valeur partielle pour l'utilisateur, mais valeur immédiate pour les étapes suivantes Phase 1) :

- T-001, T-002 (setup)
- T-010, T-011, T-012 (fondations)
- T-020, T-021 (US-003 `SectionHeaderSticky`)
- T-022, T-023 (US-004 `ListGroup`)
- T-024, T-025, T-026, T-027 (US-001 `InlineDatePicker`)
- T-028, T-029, T-030 (US-002 `CategorySelectExpand`)
- T-040, T-041, T-042, T-043 (cleanup `SegmentedFilter`)
- T-050, T-051, T-052, T-055 (polish minimum)

→ Avec ce MVP, **les Étapes 4 (écrans listes) et 5 (formulaires bottom sheets) peuvent commencer**. C'est la valeur immédiate.

**Itération 2** (composants P2 — non bloquants) :
- US-005 `PageHeader`, US-006 `EmptyStateWidget`, US-007 `ConfirmDialogCustom`, US-008 `VariationBadge`
- T-053, T-054, T-056, T-057

**Itération 3** : aucune (pas de P3 dans cette feature).

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| **L1 — Setup + Fondations** | T-001 → T-012 | Branche prête, helpers en place, `CategoryFormWidget` extrait (prérequis US-002) |
| **L2 — Composants P1 listes (Étape 4 débloquée)** | T-020 → T-027 + T-040 → T-043 | `SectionHeaderSticky`, `ListGroup`, `InlineDatePicker` livrés, `SegmentedFilter` supprimé. **Étape 4 (écrans listes) peut démarrer** |
| **L3 — `CategorySelectExpand` (Étape 5 débloquée)** | T-028 → T-030 | `CategorySelectExpand` livré. **Étape 5 (formulaires bottom sheets) peut démarrer** |
| **L4 — Composants P2** | T-031 → T-038 | Composants secondaires (`PageHeader`, `EmptyStateWidget`, `ConfirmDialogCustom`, `VariationBadge`) — utilisables progressivement |
| **L5 — Polish + review** | T-050 → T-057 | Vérifications qualité complètes, prêt pour `review-impl` |

→ **Un commit par livraison** est l'idéal (5 commits propres). En pratique, regrouper L1+L2 et L3 en un commit chacun est acceptable si la feature est livrée sur une seule branche.

---

## Mapping Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| **FR-001** (InlineDatePicker custom, ISO String, originalValue) | T-024, T-025, T-026, T-027 |
| **FR-002** (pas d'overlay/dialog inline) | T-026, T-027 |
| **FR-003** (cellules cercle, jour sélectionné, today, original, etc.) | T-024, T-025, T-027 |
| **FR-004** (CategorySelectExpand composite stateful, typing String) | T-028, T-030 |
| **FR-005** (filtrage normalizeForSearch) | T-010, T-028, T-030 |
| **FR-006** (mode list/create, embed CategoryFormWidget, recherche conservée, reset dispose) | T-029, T-030 |
| **FR-007** (SectionHeaderSticky pinned + bascule fond) | T-020, T-021 |
| **FR-008** (ListGroup dividers entre enfants) | T-022, T-023 |
| **FR-009** (ListGroup BorderRadius parent, surfaceContainer) | T-022, T-023 |
| **FR-010** (PageHeader back + icône optionnelle + titre flex-end, pas de trailing) | T-031, T-032 |
| **FR-011** (EmptyStateWidget avec icône / message / hint / CTA text-link) | T-033, T-034 |
| **FR-012** (ConfirmDialogCustom méthode statique Future<bool?>, paramètres) | T-035, T-036 |
| **FR-013** (showDialog Material avec child custom + icônes X/Check/Trash) | T-035, T-036 |
| **FR-014** (VariationBadge texte coloré + masquage conditionnel) | T-037, T-038 |
| **FR-015** (suppression SegmentedFilter) | T-040 |
| **FR-016** (remplacement par ChoiceChip + TODO KKS-240) | T-041, T-042, T-043 |
| **FR-017** (tokens uniquement, aucun hex) | T-051 (vérification) + tous les composants |
| **FR-018** (support dark + light via tests) | T-011 + tous les tests T-021/T-023/T-027/T-030/T-032/T-034/T-036/T-038 |
| **FR-019** (extraction CategoryFormWidget) | T-012 |
| **NFR-001** (testabilité, widget tests par composant) | T-011 + tous les tests + T-055 |
| **NFR-002** (composants pure UI sans dépendance réseau) | Architecture (tous les composants) |
| **NFR-003** (60 fps Pixel 3a) | T-053 (vérification manuelle) |
| **NFR-004** (StatelessWidget / StatefulWidget local strict, pas de Notifier interne) | Architecture (tous les composants) |
| **NFR-005** (aucune dépendance externe nouvelle) | Vérifié en research, aucune tâche |
| **NFR-006** (doc `///` triple-slash) | Convention transversale, vérifiée en review |
| **NFR-007** (back button Android — `ConfirmDialogCustom` uniquement) | T-036 |
| **NFR-008** (aucun `print()`) | T-052 (vérification) |
| **SC-001** (tap jour → `String` ISO correcte) | T-027 |
| **SC-002** (pas de showDatePicker / Navigator.push) | T-026 (code review) |
| **SC-003** (filtrage 50 catégories) | T-030 |
| **SC-004** (bouton `+ Créer` bascule mode `'create'` + embed CategoryFormWidget) | T-030 |
| **SC-005** (SectionHeaderSticky bascule fond `shrinkOffset > 0`) | T-021 |
| **SC-006** (ListGroup `n - 1` dividers) | T-023 |
| **SC-007** (PageHeader flèche + onBack) | T-032 |
| **SC-008** (EmptyStateWidget rendu avec/sans CTA) | T-034 |
| **SC-009** (ConfirmDialogCustom retours bool? selon action) | T-036 |
| **SC-010** (variant danger → error + Trash) | T-036 |
| **SC-011** (VariationBadge 3 états couleur + masquage) | T-038 |
| **SC-012** (aucun `Color(0xFF` dans les **9** fichiers — corrigé après WARNING-04) | T-051 |
| **SC-013** (suppression effective SegmentedFilter + retrait imports) | T-040, T-041, T-042 |
| **SC-014** (tests dark + light passants) | T-055 |

**Couverture** : 19/19 FR, 7/7 NFR, 14/14 SC. **100%**.

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables `[P]` |
|-------|-------|----|----|----|----------------------|
| Phase 1 — Setup | 2 | 2 | 0 | 0 | 0 |
| Phase 2 — Fondations | 3 | 3 | 0 | 0 | 2 (T-010, T-011) |
| Phase 3 — User Stories | 19 | 19 | 8 (US P2) | 0 | 11 |
| Phase 4 — Polish | 8 | 6 | 1 | 1 | 3 |
| **Total** | **32** | — | — | — | **16** |

> Note : la colonne « P1/P2/P3 » de la Phase 3 totalise 19 (4 tâches P1 sur le cleanup transversal + 11 tâches P1 sur US P1 + 8 tâches P2 sur US P2 = 19 ; certaines tâches sont à la fois P1 et liées à US P1 ce qui explique le chevauchement de comptage).

### Décompte par composant

| Composant | Tâches impl | Tâches test | Total |
|-----------|-------------|-------------|-------|
| `SectionHeaderSticky` | 1 (T-020) | 1 (T-021) | 2 |
| `ListGroup` | 1 (T-022) | 1 (T-023) | 2 |
| `InlineDatePicker` | 3 (T-024, T-025, T-026) | 1 (T-027) | 4 |
| `CategorySelectExpand` | 2 (T-028, T-029) | 1 (T-030) | 3 |
| `PageHeader` | 1 (T-031) | 1 (T-032) | 2 |
| `EmptyStateWidget` | 1 (T-033) | 1 (T-034) | 2 |
| `ConfirmDialogCustom` | 1 (T-035) | 1 (T-036) | 2 |
| `VariationBadge` | 1 (T-037) | 1 (T-038) | 2 |
| `CategoryFormWidget` (extraction) | 1 (T-012) | (couvert dans T-012) | 1 |
| Cleanup `SegmentedFilter` | 4 (T-040 à T-043) | — | 4 |
| Helpers + setup | 5 (T-001/2/10/11) | — | 4 (note: T-011 est un test helper) |
| Polish | 8 (T-050 à T-057) | — | 8 |
| **Total** | **30** | **8** | **38** |

> Note : décompte révisé en regroupant les sous-tâches d'un même composant — total réel 32 lignes de tâches dans le fichier (vu le découpage).
