# Research — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

> Date : 2026-05-21
> Issue : KKS-252
> Spec : [spec.md](./spec.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Architecture | Conversion temps réel des montants avec `activeCurrency` local | Haute |
| RES-002 | Architecture | Construction de la liste items inactifs (mois courant) | Haute |
| RES-003 | UI / fl_chart | Interface et paramètres exacts du widget `DoughnutMini` | Haute |
| RES-004 | Logique métier | Calcul `allCategoriesHaveBudget` avec `Budget.categoryId` | Moyenne |
| RES-005 | Architecture | Import `CurrencyPillSelector` cross-feature | Basse |

---

## Décisions techniques

### RES-001 — Conversion temps réel des montants avec activeCurrency local

- **Contexte** : `activeCurrency` est un `setState` local (résolu en CL-005). Quand l'utilisateur change de devise, tous les montants (hero + liste) doivent se recalculer. La question est de savoir où et comment effectuer cette conversion, sans modifier le state Riverpod.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Calcul dans `build()` depuis données brutes | 0 overhead, setState suffit, identique à `_MonthlySummaryCard` (KKS-251) | Code verbeux dans `build()` | ✅ Retenu |
| B — Items convertis dans `BudgetListState` | Conversion centralisée | Modifie le state Riverpod (CL-005 exclut cette option), NFR-001 | ❌ |
| C — Provider `convertedItemsProvider` dérivé | Separation of concerns | Nouveau provider = complexité, non nécessaire pour un écran | ❌ |

- **Décision** : Option A — recalcul dans `build()` de `BudgetListScreen`.
- **Rationale** : Chaque `setState` (`activeCurrency`) déclenche un rebuild. Dans `build()`, calculer `convertedItems` à la volée depuis `state.overview.items` + `activeCurrency` + `ref.watch(exchangeRateListProvider).items`. Pattern identique à `_MonthlySummaryCard` dans `recurring_list_screen.dart` (KKS-251). Constitution Principe III (YAGNI) : pas de nouveau provider pour un calcul local à un seul écran.
- **Alternatives rejetées** : B viole NFR-001 (ne pas modifier les layers data/state Riverpod). C est prématuré — aucun autre écran ne consomme ces items convertis.
- **Impact sur le plan** :
  - `BudgetListScreen` watch : `budgetNotifierProvider` + `exchangeRateListProvider` + `dashboardNotifierProvider` + `categoryNotifierProvider`
  - Helper privé `_convertAmount(double amount, String fromCurrency)` utilisant `CurrencyConverter.convert(amount: X, from: from, to: activeCurrency.name.toUpperCase(), rates: rates)`
  - `budgetedSpent = (data.totalSpent - data.unbudgetedTotal)` converti
  - `convertedUnbudgetedTotal = data.unbudgetedTotal` converti
  - `convertedItems` = `data.items.map((item) => item avec montantDepense et montantBudgetNormalise convertis)`

---

### RES-002 — Construction des items inactifs (mois courant)

- **Contexte** : En mode mois courant, `state.overview.items` contient les `BudgetOverviewItem` (budgets actifs avec montantDepense calculé par le backend). Les budgets inactifs ne sont pas dans l'overview mais dans `state.items` (List<Budget>, chargé avec `includeInactive: true`). Angular construit manuellement des items inactifs synthétiques et les ajoute à la liste. Il faut reproduire ce comportement côté Flutter.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Construire items inactifs dans `build()` depuis `state.items.where(!actif)` | Pas de modification state, calcul local | Items inactifs n'ont pas de `montantDepense` (affichent seulement `Budget.montant`) | ✅ Retenu |
| B — Ajouter les inactifs dans `BudgetListState` via `loadOverview()` enrichi | Items complets | Modifie le notifier (NFR-001), plus de complexité API | ❌ |

- **Décision** : Option A — items inactifs construits dans `build()` depuis `budgetNotifierProvider.state.items.where((b) => !b.actif)`.
- **Rationale** : Les items inactifs n'ont pas de `montantDepense` dans le contexte de cette feature (FR-013 : afficher seulement `Budget.montant`). Angular fait la même chose (`montantDepense: b.spent ?? 0`). Le screen actuel a déjà `state.items` disponible. Aucune modification du notifier ni du repository.
- **Alternatives rejetées** : B viole NFR-001.
- **Impact sur le plan** :
  - `loadItems(includeInactive: true)` toujours (remplace le toggle)
  - En mode mois courant : `_activeItems = state.overview!.items` (convertis) + `_inactiveItems = state.items.where(!actif)` (affichés séparément, montant = `Budget.montant` converti)
  - En mode historique : `_allItems = state.history!.items` (convertis), pas de séparation
  - Suppression du `_showInactive` booléen local

---

### RES-003 — DoughnutMini : interface et paramètres fl_chart

- **Contexte** : NFR-003 prescrit un widget `DoughnutMini` standalone utilisant fl_chart avec `centerSpaceRadius`. Les paramètres exacts (taille, ratio centre/arc) doivent être déterminés pour obtenir visuellement un donut 80px compact.

- **Options évaluées** :

| Option | centerSpaceRadius | radius (arc) | Total | Rendu |
|--------|------------------|--------------|-------|-------|
| A — ratio 65% centre | 26 | 14 | 40 (= 80/2) | ✅ Compact, centre visible |
| B — ratio 50% centre | 20 | 20 | 40 | Arc trop épais pour 80px |
| C — ratio 75% centre | 30 | 10 | 40 | Centre trop grand, arc trop fin |

- **Décision** : Widget `_DoughnutMini` privé dans `budget_list_screen.dart` (pas de fichier séparé — widget simple, ~40 lignes). Paramètres : `size=80px`, `centerSpaceRadius=26`, `radius=14`, `showTitle=false`, `color.withValues(alpha:0.7)`. `DoughnutSegment` = classe locale `{value: double, color: String}`. Fallback couleur : `colorScheme.surfaceContainerHighest`.

- **Rationale** : Ratio 65% centre donne un donut visuellement proche de l'Angular (stroke étroit). Widget privé car non réutilisé ailleurs (YAGNI). `parseHexColor()` de `color_utils.dart` déjà importé dans `budget_item.dart` — même import possible.

- **Alternatives rejetées** : Fichier séparé serait prématuré pour ~40 lignes. Angular utilise SVG pur mais Flutter n'a pas de SVG natif — fl_chart déjà présent est le choix naturel.

- **Impact sur le plan** :
  ```dart
  class DoughnutSegment {
    final double value;
    final String color; // hex String, converti via parseHexColor()
    const DoughnutSegment({required this.value, required this.color});
  }

  class _DoughnutMini extends StatelessWidget {
    final List<DoughnutSegment> segments;
    // PieChart(PieChartData(centerSpaceRadius: 26, sections: [
    //   PieChartSectionData(value: s.value, color: parseHexColor(s.color)?.withValues(alpha: 0.7) ?? fallback,
    //                       showTitle: false, radius: 14)
    // ]))
  }
  ```
  `doughnutSegments` = `activeItems.where(montantDepense > 0).map((i) => DoughnutSegment(value: i.montantDepense, color: i.categoryCouleur ?? ''))`.

---

### RES-004 — allCategoriesHaveBudget avec Budget.categoryId

- **Contexte** : `Budget` ne contient pas d'objet `Category` embarqué — seulement `categoryId: String`. Le calcul nécessite les deux listes.

- **Analyse** :
  - `categoryNotifierProvider` expose `ListState<Category>` avec `Category.id`, `Category.isSystem`
  - `budgetNotifierProvider.state.items` expose `List<Budget>` avec `Budget.actif`, `Budget.categoryId`
  - `categoryNotifierProvider` doit être chargé dans `initState` (si vide) via `addPostFrameCallback`

- **Décision** : Calcul local dans `build()` :
  ```dart
  bool get _allCategoriesHaveBudget {
    final cats = ref.watch(categoryNotifierProvider).items.where((c) => !c.isSystem).toList();
    if (cats.isEmpty) return false;
    final budgetedIds = ref.watch(budgetNotifierProvider).items
        .where((b) => b.actif).map((b) => b.categoryId).toSet();
    return cats.every((c) => budgetedIds.contains(c.id));
  }
  ```
- **Impact sur le plan** : `categoryNotifierProvider` ajouté aux providers watchés. Chargement dans `initState` via `addPostFrameCallback` si `categoryState.items.isEmpty`.

---

### RES-005 — CurrencyPillSelector import cross-feature

- **Contexte** : `CurrencyPillSelector` est dans `features/dashboard/presentation/widgets/`. Peut-on l'importer depuis `features/budgets/` ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Import direct cross-feature | Simple, YAGNI, 0 fichier déplacé | Couplage inter-feature | ✅ Retenu |
| B — Déplacer vers `common_widgets/` | Architecture propre | Hors scope, risque de regression | ❌ |

- **Décision** : Import direct. La constitution n'interdit pas les imports cross-feature — la codebase le fait déjà (ex: `budget_category_detail_sheet.dart` importé dans `budget_list_screen.dart`). Angular fait de même : `CurrencyPillSelector` importé depuis `features/dashboard/` dans `budget-list.ts`.
- **Alternatives rejetées** : B est hors scope KKS-252, risque de casser l'import dans `dashboard_screen.dart`.
- **Impact sur le plan** : Simple import, aucune modification de fichier source.

---

## Analyse du codebase

### Patterns existants identifiés

- **Conversion devise dans `build()`** : `recurring_list_screen.dart` `_MonthlySummaryCard` — `CurrencyConverter.convert(amount, from, to, rates)` + `exchangeRateListProvider`
- **activeCurrency en setState local** : `dashboard_screen.dart` — `Timer` cancelable pour debounce, `_debounceTimer?.cancel()` dans `dispose()`
- **SectionHeaderSticky** : `common_widgets/section_header_sticky.dart` — `SliverPersistentHeader(pinned: true)`, API : `title`, `count`, `actions: List<Widget>`
- **Items inactifs Opacity** : `budget_list_screen.dart` actuel utilise `Opacity(opacity: 0.5, child: BudgetItem)` — à adapter (sans barre, sans montantDepense)
- **loadItems(includeInactive)** : `budget_notifier.dart` — paramètre booléen, passer `true` systématiquement
- **parseHexColor** : `color_utils.dart` — utilisé dans `budget_item.dart` et `recurring_list_item.dart`
- **CurrencyPillSelector** : `dashboard_screen.dart` — `CurrencyPillSelector(currencies: state.currencies, activeCurrency: state.activeCurrency, onCurrencyChanged: _onCurrencyPillTapped)`
- **categoryNotifierProvider** : `category_list_screen.dart` — `ref.read(categoryNotifierProvider.notifier).loadItems()` dans `addPostFrameCallback`

### BudgetSummaryBar — sort du scope

`BudgetSummaryBar` est utilisé **uniquement** dans `budget_list_screen.dart`. Il sera retiré du screen et remplacé par le `_BudgetHeroWidget`. Le fichier `budget_summary_bar.dart` reste en place (pas supprimé — non orphelin si déplacé hors screen).

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `fl_chart` | ^0.70.2 | `_DoughnutMini` — PieChart avec centerSpaceRadius | Aucun — déjà présente |
| `CurrencyConverter` | interne | Conversion montants hero + liste | Aucun — pattern existant |
| `CurrencyPillSelector` | interne (features/dashboard) | Pills devise dans hero | Aucun — import direct |
| `SectionHeaderSticky` | interne (common_widgets) | Header sticky liste | Aucun — déjà utilisé sur autres écrans |
| `dart:async Timer` | SDK Dart | Debounce 2s sur changement devise | Aucun — pattern existant dans dashboard_screen |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 5 |
| Décisions prises | 5 |
| Nouvelles dépendances | 0 |
| Patterns réutilisés | 7 (CurrencyConverter, Timer debounce, SectionHeaderSticky, parseHexColor, CurrencyPillSelector, categoryNotifierProvider, build()-conversion) |
