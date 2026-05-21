# Quickstart — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

> Date : 2026-05-21  
> Issue : KKS-252

---

## Pré-requis

- [x] Constitution lue (`docs/constitution.md`)
- [x] Spec validée (`spec.md` — review PASS, itération 1)
- [x] Research complétée (`research.md`)
- [x] Plan approuvé (`plan.md`)
- [ ] Tasks générées (`tasks.md`)

---

## Phase 1 — Setup

```bash
# Vérifier que flutter analyze est propre avant de commencer
cd flutter && flutter analyze lib/src/features/budgets/

# Vérifier les tests existants passent
cd flutter && flutter test test/src/features/budgets/
```

**Vérification** : `flutter analyze` → "No issues found". Tests existants → PASS ou SKIP (pas de régression avant modification).

---

## Phase 2 — Fondations

### Fichiers à lire avant de modifier

| Fichier | Pourquoi |
|---------|----------|
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | Fichier principal à refactorer (419 lignes) |
| `flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart` | Interface actuelle — étendre avec `showProgressBar`, `onTap nullable`, `convertedDepense/Budget` |
| `flutter/lib/src/features/budgets/application/budget_notifier.dart` | Vérifier signature de `loadOverview(month, year)` |
| `flutter/lib/src/features/categories/application/category_notifier.dart` | Vérifier signature de `loadItems()` |
| `flutter/lib/src/utils/currency_converter.dart` | Vérifier signature de `CurrencyConverter.convert()` |
| `flutter/lib/src/features/dashboard/presentation/widgets/currency_pill_selector.dart` | Interface exacte du widget |

### Étapes

1. Lire `budget_list_screen.dart` en entier — repérer les blocs à remplacer
2. Lire `budget_item.dart` — déterminer les paramètres à ajouter
3. Vérifier la signature de `loadOverview()` dans `budget_notifier.dart`

**Vérification** : Tous les fichiers lus, API connues. Prêt à modifier.

---

## Phase 3 — Implémentation User Stories

### US4 — DoughnutMini (P3, dépendance technique de US1)

1. Ajouter `DoughnutSegment` en bas de `budget_list_screen.dart` (avant les widgets privés)
2. Ajouter `_DoughnutMini` : `SizedBox(80×80)` + `PieChart(centerSpaceRadius: 26, radius: 14, showTitle: false)`
3. Imports à ajouter : `fl_chart/fl_chart.dart`, `color_utils.dart`

**Test** : `flutter analyze` → No issues. Widget test : 3 segments → donut rendu. Liste vide → `SizedBox.shrink()`.

---

### US1 — Hero avec DoughnutMini, conversion devise et méta-ligne (P1)

1. Ajouter `_activeCurrency: Currency` et `_debounceTimer: Timer?` dans `_BudgetListScreenState`
2. Enrichir `initState()` : `loadItems(includeInactive: true)`, init `_activeCurrency`, charger `categoryNotifierProvider`
3. Ajouter `dispose()` avec `_debounceTimer?.cancel()`
4. Ajouter helper `_convertAmount(double, String)` dans `_BudgetListScreenState`
5. Ajouter les 4 providers watchés dans `build()` (budgetNotifierProvider, dashboardNotifierProvider, exchangeRateListProvider, categoryNotifierProvider)
6. Ajouter les calculs dans `build()` : `budgetedSpent`, `heroConverted`, `doughnutSegments`, `convertedItems`, `inactiveItems`, `allCategoriesHaveBudget`
7. Créer `_BudgetHeroWidget` private — top-row (MonthSelector + CurrencyPillSelector), hero row (montant + DoughnutMini), méta-lignes
8. Remplacer `BudgetSummaryBar` par `_BudgetHeroWidget` dans le scaffold

**Test** : Widget test avec mock `BudgetOverview(totalSpent: 150, unbudgetedTotal: 50)` → montant affiché = 100.

---

### US2 — CurrencyPillSelector avec debounce 2s (P2)

1. Ajouter `_onCurrencyChanged(Currency)` dans `_BudgetListScreenState` avec Timer cancelable 2s
2. Passer `onCurrencyChanged: _onCurrencyChanged` à `_BudgetHeroWidget`
3. Dans `_BudgetHeroWidget.build()` : inclure `CurrencyPillSelector` dans la top-row

**Test** : `fakeAsync` + `pump(Duration(seconds: 2))` → 1 seul appel persistance même après 3 changements rapides.

---

### US3 — SectionHeaderSticky + séparation actifs/inactifs (P2)

1. Restructurer `_buildBody()` en `CustomScrollView` avec `SliverList`
2. Remplacer le header actuel par `SectionHeaderSticky` avec actions conditionnelles (Tray + bouton "+")
3. Ajouter `_InactiveLabel` widget privé (style `date-label`, texte "Inactifs")
4. Ajouter la section inactifs conditionnelle (mois courant uniquement, `Opacity(0.5)`, `showProgressBar: false`)
5. Adapter `BudgetItem` si interface insuffisante (`showProgressBar`, `onTap nullable`)

**Test** : Widget test avec actifs + inactifs → label "Inactifs" présent. Mode historique → label absent.

---

## Phase 4 — Polish et tests

```bash
# Analyse statique (SC-006)
cd flutter && flutter analyze lib/src/features/budgets/ lib/src/common_widgets/

# Tests widget complets
cd flutter && flutter test test/src/features/budgets/presentation/budget_list_screen_test.dart --verbose

# Tous les tests (no regression)
cd flutter && flutter test
```

1. Vérifier que `BudgetSummaryBar` n'est plus utilisé dans `budget_list_screen.dart` (import à retirer)
2. Vérifier que `_showInactive` est complètement supprimé (grep dans le fichier)
3. Ajouter les nouveaux tests widget pour SC-001 → SC-005
4. Lancer `frontend-design-review` avant commit

---

## Commandes utiles

| Action | Commande |
|--------|----------|
| Analyse statique budgets | `cd flutter && flutter analyze lib/src/features/budgets/` |
| Tests widget budgets | `cd flutter && flutter test test/src/features/budgets/` |
| Tous les tests | `cd flutter && flutter test` |
| Build runner (si Freezed modifié) | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |

---

## Checklist finale

- [ ] `flutter analyze lib/src/features/budgets/ lib/src/common_widgets/` → No issues found (SC-006)
- [ ] Montant hero = `totalSpent - unbudgetedTotal` converti (SC-001)
- [ ] DoughnutMini affiché / masqué selon segments > 0 (SC-002)
- [ ] Debounce 2s testé via `fakeAsync` (SC-003)
- [ ] Label "Inactifs" visible en mois courant, absent en historique (SC-004)
- [ ] Bouton "+" masqué hors mois courant + désactivé si `allCategoriesHaveBudget` (SC-005)
- [ ] `_showInactive` supprimé
- [ ] `BudgetSummaryBar` import retiré du screen
- [ ] `loadItems(includeInactive: true)` systématique (sans toggle)
- [ ] pre-commit-review → no CRITIQUE
- [ ] frontend-design-review → no CRITIQUE
- [ ] review-impl PASS
