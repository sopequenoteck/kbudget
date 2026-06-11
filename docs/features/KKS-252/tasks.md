# Tasks — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

> Date : 2026-05-21  
> Issue : KKS-252  
> Spec : [spec.md](./spec.md)  
> Plan : [plan.md](./plan.md)

---

## Phase 1 : Setup

- [x] [T-001] [P1] Lire les fichiers existants avant modification : `budget_list_screen.dart`, `budget_item.dart`, `budget_notifier.dart`, `category_notifier.dart`, `currency_converter.dart`, `currency_pill_selector.dart` — Réf: plan §2
- [x] [T-002] [P1] Vérifier `flutter analyze lib/src/features/budgets/` et `flutter test test/src/features/budgets/` → baseline propre — Réf: SC-006

**Checkpoint** : Fichiers lus, API connues (signature `loadOverview()`, `CurrencyConverter.convert()`, `loadItems()` categoryNotifier). `flutter analyze` → No issues. Tests → PASS ou SKIP (aucune régression avant modification).

---

## Phase 2 : Fondations (bloquantes)

- [x] [T-010] [P] [P1] Ajouter `DoughnutSegment` (classe) + `_DoughnutMini` (widget privé, ~40L) dans `budget_list_screen.dart` : fl_chart `PieChart(centerSpaceRadius: 26, radius: 14)`, `parseHexColor().withValues(alpha: 0.7)`, `SizedBox.shrink()` si segments vide — Réf: FR-003, NFR-003, US4, RES-003
- [x] [T-011] [P] [P1] Étendre l'interface `BudgetItem` pour supporter les items inactifs : ajouter `showProgressBar: bool = true`, vérifier `onTap: VoidCallback?` nullable, ajouter `convertedDepense: double` et `convertedBudget: double` — Réf: FR-009, FR-013, FR-014, FR-015
- [x] [T-012] [P] [P1] Enrichir `_BudgetListScreenState` : ajouter `_activeCurrency: Currency`, `_debounceTimer: Timer?` ; supprimer `_showInactive: bool` ; enrichir `initState()` (init `_activeCurrency` depuis `dashboardNotifierProvider`, charger `categoryNotifierProvider` si vide, `loadItems(includeInactive: true)` systématique) ; ajouter `dispose()` avec `_debounceTimer?.cancel()` — Réf: NFR-001, FR-007, FR-008, CL-005, A-004, RES-001

**Checkpoint** : `_DoughnutMini` compile (fl_chart import OK). `BudgetItem` compile avec nouveaux params. State screen compile (Timer import dart:async, Currency init).

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

- [x] [T-020] [P1] [US1] Ajouter helper `_convertAmount(double, String)` dans le state + ajouter les 4 providers watchés dans `build()` (budgetNotifierProvider, dashboardNotifierProvider, exchangeRateListProvider, categoryNotifierProvider) — Réf: FR-001, FR-009, NFR-005, RES-001
- [x] [T-021] [P1] [US1] Ajouter calculs dérivés dans `build()` : `budgetedSpent`, `heroConverted`/`heroConvertedCurrency`, `doughnutSegments`, `convertedItems`, `inactiveItems` (mois courant seulement), `allCategoriesHaveBudget` — Réf: FR-001, FR-002, FR-003, FR-011, FR-013, RES-001, RES-002, RES-004
- [x] [T-022] [P1] [US1] Créer `_BudgetHeroWidget` (widget privé StatelessWidget) : top-row (MonthSelector + CurrencyPillSelector placeholder), hero row (montant `budgetedSpent` + `_DoughnutMini`), ligne `heroConverted` conditionnelle, méta-ligne dépassements + count budgets, méta non budgété (`GestureDetector`, si `unbudgetedTotal > 0`) — Réf: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007
- [x] [T-023] [P1] [US1] Remplacer `BudgetSummaryBar` par `_BudgetHeroWidget` dans le scaffold ; retirer l'import `budget_summary_bar.dart` ; gérer loading (skeleton) et error (`EmptyStateWidget` + "Réessayer") — Réf: FR-016, FR-017, FR-018

### P2 — Importantes

- [x] [T-030] [P] [P2] [US2] Ajouter `_onCurrencyChanged(Currency)` dans `_BudgetListScreenState` : `setState(_activeCurrency)` immédiat + Timer 2s cancelable pour persistance + rechargement taux + rechargement overview — Réf: FR-008, CX-002
- [x] [T-031] [P2] [US2] Intégrer `CurrencyPillSelector` dans `_BudgetHeroWidget` top-row : import depuis `features/dashboard/presentation/widgets/currency_pill_selector.dart`, passer `currencies` + `activeCurrency` + `onCurrencyChanged` — Réf: FR-007, NFR-002, RES-005
- [x] [T-032] [P2] [US3] Restructurer `_buildBody()` en `CustomScrollView` avec `SliverList` pour les items actifs (depuis `convertedItems`) ; vérifier que `BudgetItem` reçoit `convertedDepense` et `convertedBudget` — Réf: FR-009, FR-014, FR-015
- [x] [T-033] [P2] [US3] Ajouter `SectionHeaderSticky` avec actions conditionnelles : bouton Tray (si `unbudgetedTotal > 0`) → `UnbudgetedDetailSheet` ; bouton "+" (si `isCurrentMonth`) masqué/désactivé (`onPressed: null`) selon `allCategoriesHaveBudget` — Réf: FR-010, FR-011, FR-012, NFR-004, RES-004
- [x] [T-034] [P2] [US3] Ajouter section items inactifs (mois courant uniquement) : widget privé `_InactiveLabel` (style `date-label`, texte "Inactifs") + `SliverList` avec `Opacity(0.5)` + `BudgetItem(showProgressBar: false, onTap: null, convertedDepense: 0)` — Réf: FR-013, RES-002

### P3 — Nice to have

- [x] [T-040] [P3] [US4] Écrire les 3 tests autonomes `_DoughnutMini` (US4/S1 : rendu si segments non vides, US4/S2 : SizedBox.shrink si vide, US4/S3 : segment `montantDepense=0` exclu) — Réf: FR-003, NFR-003, SC-002

**Checkpoint** : `flutter analyze lib/src/features/budgets/` → No issues. `flutter run` sur device → hero + liste + inactifs visibles. Changement devise → recalcul immédiat.

---

## Phase 4 : Polish

- [x] [T-050] [P] [P2] Adapter les tests existants `budget_list_screen_test.dart` : ajouter les 4 overrides (budgetNotifierProvider, dashboardNotifierProvider, exchangeRateListProvider, categoryNotifierProvider) dans `buildApp()` ; supprimer les assertions sur `BudgetSummaryBar` — Réf: NFR-007
- [x] [T-051] [P] [P2] Écrire les nouveaux tests widget SC-001 → SC-005 : montant hero `totalSpent - unbudgetedTotal` (SC-001), DoughnutMini affiché/masqué (SC-002), debounce `fakeAsync + pump(2s)` (SC-003), label "Inactifs" visible/absent (SC-004), bouton "+" masqué/désactivé (SC-005) — Réf: SC-001, SC-002, SC-003, SC-004, SC-005, NFR-007
- [x] [T-052] [P2] Vérification finale : `flutter analyze lib/src/features/budgets/ lib/src/common_widgets/` → No issues (SC-006) ; grep `_showInactive` → 0 occurrence ; grep `budget_summary_bar` import → 0 occurrence dans `budget_list_screen.dart` — Réf: SC-006, A-004
- [x] [T-053] [P3] Lancer `flutter test` complet → tous les tests PASS (no regression) — Réf: NFR-007

**Checkpoint** : `flutter test` → PASS. `flutter analyze` → No issues. Checklist `quickstart.md` complète.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
T-001
├── T-010 [P] ──────────────────────── T-022 → T-023
├── T-011 [P] ───────────────────── T-032 → T-033 → T-034
└── T-012 [P]
     ├── T-020 [P] → T-021 → T-022
     └── T-030 [P] → T-031 (se branche sur _BudgetHeroWidget de T-022)

T-040 (après T-010, indépendant du reste)

T-023 + T-034 → T-050 [P]
T-023 + T-034 → T-051 [P]
T-050 + T-051 → T-052 → T-053
```

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US1 — Hero | T-020, T-021, T-022, T-023 | T-010 (DoughnutMini), T-012 (state) |
| US2 — CurrencyPillSelector | T-030, T-031 | T-012 (state), T-022 (HeroWidget) |
| US3 — SectionHeaderSticky + inactifs | T-032, T-033, T-034 | T-011 (BudgetItem API) |
| US4 — DoughnutMini test | T-040 | T-010 (fondation) |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| G1 | T-010, T-011, T-012 | T-001 + T-002 complétés |
| G2 | T-020, T-030 | T-012 complété |
| G3 | T-040 | T-010 complété (indépendant de G2) |
| G4 | T-050, T-051 | T-023 + T-034 complétés |

---

## Implementation Strategy

### MVP First

**MVP** (valeur minimale — hero correct + liste fonctionnelle) :
T-001 → T-002 → T-010 + T-011 + T-012 → T-020 → T-021 → T-022 → T-023 → T-032

- Montant hero correct (`totalSpent - unbudgetedTotal` converti)
- DoughnutMini visible
- Liste en `CustomScrollView` avec montants convertis

**Itération 2** (liste complète + devises) :
T-030 → T-031 → T-033 → T-034

- CurrencyPillSelector + debounce 2s
- SectionHeaderSticky avec actions
- Section inactifs

**Itération 3** (tests + polish) :
T-040 → T-050 → T-051 → T-052 → T-053

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| L1 — MVP | T-001 → T-023, T-032 | Hero avec montant correct + DoughnutMini + liste convertie |
| L2 — Devise | T-030, T-031, T-033, T-034 | Sélection devise en temps réel + structure liste complète |
| L3 — Polish | T-040 → T-053 | Couverture tests complète + no lint issues |

---

## Mapping Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (budgetedSpent = totalSpent − unbudgetedTotal) | T-021, T-022 |
| FR-002 (ligne heroConverted devise2) | T-021, T-022 |
| FR-003 (DoughnutMini fl_chart) | T-010, T-022, T-040 |
| FR-004 (méta-ligne dépassements + count) | T-022 |
| FR-005 (méta non budgété cliquable) | T-022 |
| FR-006 (MonthSelector conservé) | T-022 |
| FR-007 (CurrencyPillSelector dans hero) | T-022, T-031 |
| FR-008 (debounce 2s Timer cancelable) | T-030 |
| FR-009 (montants liste convertis) | T-020, T-021, T-032 |
| FR-010 (SectionHeaderSticky) | T-033 |
| FR-011 (bouton "+" conditionnel) | T-021, T-033 |
| FR-012 (bouton Tray si unbudgetedTotal > 0) | T-033 |
| FR-013 (inactifs mois courant, Budget.montant, sans barre) | T-034 |
| FR-014 (barre 3 états couleur) | T-011 |
| FR-015 (tap item → modal ModalType.budget, inactifs non-tappables) | T-011, T-032 |
| FR-016 (skeleton loading) | T-023 |
| FR-017 (EmptyStateWidget liste vide) | T-023 |
| FR-018 (EmptyStateWidget erreur + Réessayer) | T-023 |
| NFR-001 (aucune modification data/domain) | T-012, T-020 |
| NFR-002 (import CurrencyPillSelector cross-feature) | T-031 |
| NFR-003 (_DoughnutMini standalone fl_chart) | T-010 |
| NFR-004 (SectionHeaderSticky de common_widgets) | T-033 |
| NFR-005 (CurrencyConverter + exchangeRateListProvider) | T-020 |
| NFR-006 (design tokens uniquement) | T-022, T-033, T-034 |
| NFR-007 (tests widget 4 overrides) | T-050, T-051 |

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| Setup | 2 | 2 | 0 | 0 | 0 |
| Fondations | 3 | 3 | 0 | 0 | 3 |
| User Stories | 10 | 4 | 5 | 1 | 2 |
| Polish | 4 | 0 | 3 | 1 | 2 |
| **Total** | **19** | **9** | **8** | **2** | **7** |
