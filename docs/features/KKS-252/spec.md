# Spécification — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

**Issue** : KKS-252 | **Parent** : KKS-242  
**Branch** : `develop`  
**Date** : 2026-05-21  
**Statut** : Draft  
**Priorité** : High | **Estimation** : 3 points

---

## Contexte

L'écran `BudgetListScreen` Flutter (419 lignes) possède un `MonthSelector`, un `BudgetSummaryBar` et un `BudgetItem` avec barre 3 états. Il manque : le `DoughnutMini` dans le hero, la conversion devise en temps réel, le `CurrencyPillSelector`, le `SectionHeaderSticky`, la séparation actifs/inactifs conforme, et la persistance devise avec debounce.

**Source de vérité Angular** : `/features/budgets/components/budget-list/budget-list.html` + `budget-list.ts`

---

## User Stories

### US1 — Hero avec DoughnutMini, conversion devise et méta-ligne (Priority: P1)

L'utilisateur ouvre l'écran Budgets et voit dans le hero : le montant dépensé sur les budgets (hors non-budgété), converti dans la devise active, un DoughnutMini représentant la répartition par catégorie, une ligne de conversion dans la devise secondaire si applicable, et une méta-ligne avec le nombre de dépassements + le non-budgété cliquable.

**Why this priority** : Le hero est le bloc informatif principal. Le montant affiché actuellement est faux (inclut le non-budgété) et aucune conversion devise n'est appliquée. C'est la régression la plus impactante.

**Independent Test** : Tester en mockant un `BudgetOverview` avec totalSpent=150, unbudgetedTotal=50, 2 items en dépassement, et vérifier que le montant affiché est 100 (pas 150), converti si devise ≠ devise source.

**Acceptance Scenarios** :

1. **Given** un overview avec `totalSpent=150`, `unbudgetedTotal=50`, devise EUR, **When** le hero est rendu, **Then** le montant affiché est 100 (= totalSpent - unbudgetedTotal) converti en `activeCurrency`.
2. **Given** 2 devises configurées (EUR, CHF) et `activeCurrency=CHF`, **When** le hero est rendu, **Then** une ligne `≈ X EUR` apparaît sous le montant principal.
3. **Given** 2 items en dépassement et `unbudgetedTotal=45`, **When** le hero est rendu, **Then** la méta affiche "⚠ 2 en dépassement · 🥧 3 budgets" et une seconde ligne "📥 45 non budgété" cliquable (→ `UnbudgetedDetailSheet`).
4. **Given** `unbudgetedTotal=0`, **When** le hero est rendu, **Then** la ligne "non budgété" n'est pas rendue.
5. **Given** un `DoughnutMini` avec les segments des items actifs ayant `montantDepense > 0`, **When** le hero est rendu, **Then** le donut (fl_chart) s'affiche à droite du bloc montant.
6. **Given** un état de chargement, **When** les données ne sont pas encore disponibles, **Then** le hero affiche son skeleton shimmer.

---

### US2 — CurrencyPillSelector avec debounce 2s (Priority: P2)

L'utilisateur change la devise d'affichage via des pills dans le hero. Le changement est reflété immédiatement sur tous les montants (hero + liste). Après 2 secondes sans autre changement, la devise est persistée, les taux rechargés, et la liste rafraîchie.

**Why this priority** : Feature absente côté Flutter. Le debounce protège contre les appels API répétés. La conversion temps réel de tous les montants est un comportement Angular essentiel.

**Independent Test** : Tester en vérifiant que la conversion des montants bascule immédiatement à l'affichage, mais que `PreferenceService.update()` n'est appelé qu'après 2s.

**Acceptance Scenarios** :

1. **Given** un utilisateur avec EUR et CHF configurées, **When** l'écran s'ouvre, **Then** les pills EUR et CHF sont visibles dans le hero top-row, avec la devise primaire active.
2. **Given** l'utilisateur tape la pill CHF, **When** le changement est appliqué, **Then** tous les montants (hero + liste) sont immédiatement reconvertis en CHF.
3. **Given** l'utilisateur tape CHF puis EUR en moins de 2s, **When** 2s s'écoulent, **Then** un seul appel de persistance est effectué pour EUR + rechargement taux + rechargement données.
4. **Given** une seule devise configurée, **When** l'écran s'ouvre, **Then** aucune pill n'est affichée (`CurrencyPillSelector` retourne `SizedBox.shrink()`).

---

### US3 — SectionHeaderSticky + séparation actifs/inactifs (Priority: P2)

La liste est structurée avec un header sticky ("Budgets" + count actifs + bouton "+" + bouton Tray conditionnel). Les items inactifs sont toujours chargés et affichés sous un label "Inactifs", après tous les actifs, avec opacity 0.5 et sans barre de progression.

**Why this priority** : La structure visuelle de la liste est directement visible à l'ouverture. L'absence de section header et la représentation incorrecte des inactifs (barre visible, toggle explicite) créent un écart significatif avec Angular.

**Independent Test** : Tester avec une liste mixte actifs+inactifs et vérifier que le label "Inactifs" apparaît, que les items inactifs sont à opacity 0.5 sans barre, et que le header reste visible au scroll.

**Acceptance Scenarios** :

1. **Given** une liste chargée, **When** l'utilisateur scrolle, **Then** le `SectionHeaderSticky` reste visible avec "Budgets", le count d'actifs, et le bouton "+".
2. **Given** `isCurrentMonth=false`, **When** la liste est rendue, **Then** le bouton "+" n'est pas affiché dans le section header.
3. **Given** toutes les catégories ont déjà un budget, **When** la liste est rendue, **Then** le bouton "+" est désactivé (`disabled`).
4. **Given** `unbudgetedTotal > 0`, **When** la liste est rendue, **Then** un bouton Tray (icône `phosphorTray`) apparaît dans le section header et ouvre `UnbudgetedDetailSheet` au tap.
5. **Given** des budgets inactifs présents, **When** la liste est rendue, **Then** ils apparaissent après tous les actifs, précédés d'un label "Inactifs" (`date-label`), à opacity 0.5, sans barre de progression, avec seulement le montant budget affiché.
6. **Given** aucun budget inactif, **When** la liste est rendue, **Then** le label "Inactifs" n'est pas rendu.

---

### US4 — DoughnutMini (donut fl_chart) (Priority: P3)

Un widget `DoughnutMini` Flutter standalone est créé avec fl_chart (`PieChart` + `centerSpaceRadius`), avec l'interface `segments: List<DoughnutSegment>`, reproduisant fidèlement le comportement Angular (sections colorées avec opacity 0.7, centre vide).

**Why this priority** : Dépendance technique de US1, mais isolé en US distincte car c'est un nouveau composant générique. P3 car il dépend structurellement de US1 mais n'a pas de valeur autonome.

**Independent Test** : Tester en passant 3 segments de valeurs connues et vérifier que le widget est rendu en 80×80px avec un centre vide. Liste vide → `SizedBox.shrink()`.

**Acceptance Scenarios** :

1. **Given** une liste de segments non vide, **When** `DoughnutMini` est rendu à size=80, **Then** un donut fl_chart s'affiche avec les couleurs correspondantes et un espace central visible.
2. **Given** une liste vide, **When** `DoughnutMini` est rendu, **Then** `SizedBox.shrink()` est retourné.
3. **Given** un segment avec `montantDepense=0`, **When** les segments sont filtrés, **Then** ce segment est exclu du donut.

---

### Edge Cases

- **Mois historique** : l'overview provient de `BudgetHistory` — le hero et la liste fonctionnent identiquement, mais le bouton "+" est masqué (pas `isCurrentMonth`).
- **Aucun dépassement** : le fragment "N en dépassement ·" est omis de la méta-ligne (pas de "0 en dépassement").
- **Tous les montants = 0** : le DoughnutMini n'est pas rendu (`doughnutSegments` vide après filtre `montantDepense > 0`).
- **Devise identique** : si `activeCurrency == data.currency`, pas de conversion (no-op), pas de ligne `heroConverted`.
- **Liste vide** (aucun budget actif et unbudgetedTotal=0) : `EmptyStateWidget` avec CTA "Créer un budget".

---

## Requirements

### Functional Requirements

- **FR-001** : Le hero DOIT afficher le montant dépensé = `totalSpent - unbudgetedTotal`, converti dans `activeCurrency` si différent de la devise source des données. S'applique aussi en mode historique (`BudgetHistory.totalSpent - BudgetHistory.unbudgetedTotal`).
- **FR-002** : Le hero DOIT afficher une ligne de conversion `≈ X devise2` si l'utilisateur a ≥ 2 devises configurées et que `activeCurrency ≠ devise2`.
- **FR-003** : Le hero DOIT afficher un `DoughnutMini` (fl_chart) à droite du bloc montant, avec les segments des items actifs ayant `montantDepense > 0`, colorés par `categoryCouleur`. Si aucun segment : `SizedBox.shrink()`.
- **FR-004** : Le hero DOIT afficher une méta-ligne : si `overBudgetCount > 0`, afficher "N en dépassement ·" + toujours afficher "N budgets".
- **FR-005** : Si `unbudgetedTotal > 0`, le hero DOIT afficher une seconde ligne méta "X non budgété" cliquable (→ `UnbudgetedDetailSheet`). Le montant affiché est `unbudgetedTotal` converti en `activeCurrency`.
- **FR-006** : Le `MonthSelector` DOIT rester intégré dans le hero top-row (prev/next mois).
- **FR-007** : Un `CurrencyPillSelector` DOIT être affiché dans le hero top-row, avec la liste des devises de l'utilisateur et la devise active. Ne s'affiche pas si une seule devise.
- **FR-008** : Le changement de devise DOIT être reflété immédiatement sur tous les montants (hero + liste). La persistance (`PreferenceService.update`), le rechargement des taux et le rechargement des données DOIVENT être déclenchés avec un debounce de 2s via `dart:async Timer` cancelable (`_debounceTimer?.cancel(); _debounceTimer = Timer(Duration(seconds: 2), ...)`) — testable avec `fakeAsync` + `pump(Duration(seconds: 2))` dans les widget tests.
- **FR-009** : Tous les montants de la liste DOIVENT être convertis en `activeCurrency` en temps réel (montantDepense, montantBudget/montantBudgetNormalise).
- **FR-010** : La liste DOIT afficher un `SectionHeaderSticky` avec le titre "Budgets", le count des items actifs, et un bouton "+".
- **FR-011** : Le bouton "+" DOIT être masqué si `isCurrentMonth=false`. Il DOIT être désactivé (`onPressed: null`, apparence grisée) si toutes les catégories non-système (`isSystem=false`, ex : "Non catégorisé" est système) ont déjà un budget actif — calculé depuis `categoryNotifierProvider` (catégories non-système) croisé avec `budgetNotifierProvider.state.items` (budgets actifs).
- **FR-012** : Si `unbudgetedTotal > 0`, un bouton icône Tray DOIT apparaître dans le section header et ouvrir `UnbudgetedDetailSheet` au tap.
- **FR-013** : Les items inactifs DOIVENT toujours être chargés (pas de toggle). Ils s'affichent après tous les actifs, précédés d'un label "Inactifs", à opacity 0.5, sans barre de progression, avec seulement le montant budget (`Budget.montant`) converti en `activeCurrency`. **S'applique uniquement en mode mois courant** : `BudgetHistoryItem` ne porte pas de champ `actif` — en mode historique, tous les items sont traités comme actifs (pas de label "Inactifs").
- **FR-014** : La barre de progression des items actifs CONSERVE les 3 états : < 80% → `categoryCouleur` de l'item, 80–100% → `textWarning`, > 100% → `expenseColor`.
- **FR-015** : Le tap sur un item actif DOIT ouvrir la modal d'édition via `ModalType.budget` (comportement Flutter actuel conservé). `BudgetDetailScreen` ne supporte pas de paramètre `budgetId` — ce n'est pas dans le scope. Les items inactifs ne sont pas tappables (pas d'`onTap`).
- **FR-016** : L'écran DOIT afficher un skeleton (hero + 5 items) pendant le chargement.
- **FR-017** : L'écran DOIT afficher `EmptyStateWidget` quand `convertedItems` est vide et `unbudgetedTotal=0`.
- **FR-018** : L'écran DOIT afficher `EmptyStateWidget` avec bouton "Réessayer" en cas d'erreur.

### Non-Functional Requirements

- **NFR-001** : Les couches data/domain NE DOIVENT PAS être modifiées : `BudgetRepository`, `Budget`, `BudgetOverview`, `BudgetHistory`, DTOs.
- **NFR-002** : `CurrencyPillSelector` DOIT être importé depuis `features/dashboard/presentation/widgets/currency_pill_selector.dart` — pas de duplication.
- **NFR-003** : `DoughnutMini` DOIT être un widget `StatelessWidget` **indépendant** (pas un sous-classe de `BudgetPieChart`) utilisant fl_chart v0.70.2 directement — `PieChart(PieChartData(centerSpaceRadius: X, sections: [...]))` avec `showTitle: false`, `opacity=0.7` sur chaque section. Interface : `List<DoughnutSegment>` avec `{value: double, color: String}` — le champ `color` est un hex String (`categoryCouleur`) converti en `Color` via `parseHexColor()` (`color_utils.dart`) à l'intérieur du widget. Taille 80px par défaut. Aucune nouvelle dépendance.
- **NFR-004** : `SectionHeaderSticky` de `common_widgets/section_header_sticky.dart` DOIT être réutilisé.
- **NFR-005** : `CurrencyConverter` + `exchangeRateListProvider` DOIVENT être utilisés pour toutes les conversions (pattern existant dans `recurring_list_screen.dart` et `dashboard_screen.dart`).
- **NFR-006** : Design tokens exclusivement (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppThemeExtension`) — aucune valeur hardcodée.
- **NFR-007** : Tests widget adaptés avec overrides : `budgetNotifierProvider`, `dashboardNotifierProvider`, `exchangeRateListProvider`, `categoryNotifierProvider`.

---

## Key Entities

- **`BudgetOverview`** : `totalBudget`, `totalSpent`, `percentage`, `currency`, `items: List<BudgetOverviewItem>`, `unbudgetedTotal`, `unbudgetedItems` — source hero mois courant.
- **`BudgetHistory`** : mêmes champs exposés (`totalBudget`, `totalSpent`, `items`, `unbudgetedTotal`) — source hero mois passés.
- **`BudgetOverviewItem`** : `categoryNom`, `categoryIcone`, `categoryCouleur`, `montantBudgetNormalise`, `montantDepense`, `percentage`, `currency` — chaque segment du donut + chaque ligne de liste.
- **`Budget`** : `id`, `actif`, `category`, `montant`, `currency` — source pour `allBudgets` (calcul `allCategoriesHaveBudget` + items inactifs).
- **`Category`** : `id`, `isSystem` — source pour `allCategories` (calcul `allCategoriesHaveBudget`).
- **`DoughnutSegment`** : `{value: double, color: String}` — DTO interne du widget `DoughnutMini`.
- **`Currency`** (enum Flutter) : devise active (`activeCurrency`), gérée en état local `setState` dans le `ConsumerStatefulWidget` — même pattern que `_selectedMonth`/`_selectedYear`. Initialisée depuis `dashboardState.currencies.first` ; fallback `Currency.eur` si `currencies.isEmpty` au premier frame (même pattern que `DashboardScreen`). Liste de devises depuis `dashboardNotifierProvider`.

---

## Success Criteria

- **SC-001** : Le montant hero = `totalSpent - unbudgetedTotal` converti en `activeCurrency` — vérifiable en widget test avec mock `BudgetOverview` à valeurs connues.
- **SC-002** : Le `DoughnutMini` s'affiche avec les couleurs des catégories et disparaît si tous les segments ont `montantDepense=0` — vérifiable en widget test.
- **SC-003** : Le changement de devise déclenche exactement 1 persistance après 2s, même si l'utilisateur change 3 fois — vérifiable via mock `PreferenceService` en test.
- **SC-004** : Les items inactifs apparaissent toujours sous le label "Inactifs" sans barre ni montant dépensé — vérifiable en widget test.
- **SC-005** : Le bouton "+" est masqué hors mois courant et désactivé si `allCategoriesHaveBudget` — vérifiable en widget test.
- **SC-006** : `flutter analyze lib/src/features/budgets/ lib/src/common_widgets/` → No issues found.

---

## Assumptions

- **A-001** : `BudgetHistory` expose les mêmes champs clés que `BudgetOverview` (`totalSpent`, `unbudgetedTotal`, `items`) — **validée** : confirmé dans `budget_history.dart` Flutter (mêmes champs `totalBudget`, `totalSpent`, `percentage`, `currency`, `unbudgetedTotal`).
- **A-002** : `CurrencyPillSelector` Flutter accepte `List<Currency>` (enum), pas `List<String>` — il faudra convertir depuis les devises de `dashboardNotifierProvider` (pattern identique à `DashboardScreen`).
- **A-003** : `RouteNames.budgetDetails` accepte les queryParams `budgetId` et `month` — vérifié dans `app_router.dart:245`.
- **A-004** : Le toggle "afficher inactifs" Flutter existant est supprimé — les inactifs sont toujours chargés et affichés, conformément à l'Angular qui n'a pas de toggle.
- **A-005** : L'`UnbudgetedDetailSheet` Flutter (bottom sheet) est conservé pour le tap "non budgété" au lieu de la navigation Angular vers `/budgets/unbudgeted` — la sheet existe déjà et offre une meilleure UX mobile.
