# Clarify Log — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

> Date : 2026-05-21
> Issue : KKS-252
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md NFR-003 | Implémentation DoughnutMini : CustomPaint vs fl_chart | 7-Contraintes | H | H | CRITIQUE | fl_chart avec centerSpaceRadius | Auto |
| CL-002 | spec.md FR-013 | Items inactifs en mode historique (BudgetHistoryItem sans champ `actif`) | 1-Scope | M | H | HAUT | Mois courant uniquement | Auto |
| CL-003 | spec.md FR-013 | Champ montant items inactifs + conversion devise | 2-Modèle de données | M | M | MOYEN | `Budget.montant` converti en activeCurrency | Auto |
| CL-004 | spec.md FR-011 | `allCategoriesHaveBudget` : source des catégories côté Flutter | 5-Intégrations | M | M | MOYEN | `categoryNotifierProvider` existant | Auto |
| CL-005 | spec.md Key Entities | `activeCurrency` : state Riverpod vs local setState | 7-Contraintes | M | M | MOYEN | setState local, pattern identique à `_selectedMonth` | Auto |
| CL-006 | spec.md FR-008 | Debounce Flutter : mécanisme (Timer vs autre) | 7-Contraintes | B | M | BAS | — | Différé |
| CL-007 | spec.md FR-015 | Tap item actif : budgetDetails (navigation) vs modal (actuel) | 3-UX | M | B | BAS | — | Différé |

---

## Résolutions détaillées

### CL-001 — DoughnutMini : fl_chart avec centerSpaceRadius

- **Catégorie** : 7-Contraintes
- **Score** : CRITIQUE
- **Contexte** : La spec indiquait "SVG pur via CustomPaint", mais Flutter n'a pas de SVG natif (CustomPaint utilise Canvas API). L'Angular utilise du HTML SVG natif avec `stroke-dasharray`. La question était : reproduire en Canvas Flutter, ou utiliser fl_chart déjà présent.
- **Analyse** : `fl_chart v0.70.2` est déclaré dans `flutter/pubspec.yaml` (ligne 48). `BudgetPieChart` l'utilise déjà dans le projet. L'Angular génère un donut via cercles SVG avec `stroke-dasharray` — l'équivalent en fl_chart est `PieChartData(centerSpaceRadius: X)` avec `PieChartSectionData(showTitle: false)`. Principe III de la constitution (Simplicité & YAGNI) : réutiliser la dépendance existante.
- **Décision** : Dériver de `BudgetPieChart` (fl_chart) avec `centerSpaceRadius` non nul. Interface : `List<DoughnutSegment>` avec `{value: double, color: String}`, taille 80px, sections à opacity 0.7. Aucune nouvelle dépendance.
- **Impact sur spec.md** : NFR-003 corrigé — "SVG pur via CustomPaint" → "dérivé de BudgetPieChart (fl_chart v0.70.2) avec centerSpaceRadius".

---

### CL-002 — Items inactifs : mois courant uniquement

- **Catégorie** : 1-Scope fonctionnel
- **Score** : HAUT
- **Contexte** : FR-013 décrivait la séparation actifs/inactifs sans préciser si elle s'applique aussi aux mois historiques. L'Angular calcule `inactiveItems` via `actif === false` sur les items, mais les items historiques viennent d'un endpoint différent.
- **Analyse** : `BudgetHistoryItem` (Flutter) n'a pas de champ `actif`. Seul `BudgetOverviewItem` est enrichi avec les items inactifs via `budgetService.getAll(true)` dans Angular (côté Flutter : `budgetNotifierProvider.state.items` porte les budgets avec `Budget.actif`). En mode historique, tous les items viennent du backend historialisé — il n'y a pas d'inactifs à séparer.
- **Décision** : Séparation actifs/inactifs (label "Inactifs", opacity 0.5, pas de barre) s'applique **uniquement au mois courant**. En mode historique, tous les `BudgetHistoryItem` sont affichés comme actifs, sans label.
- **Impact sur spec.md** : FR-013 complété avec la précision "S'applique uniquement en mode mois courant".

---

### CL-003 — Montant items inactifs : Budget.montant converti

- **Catégorie** : 2-Modèle de données
- **Score** : MOYEN
- **Contexte** : FR-013 disait "seulement le montant budget affiché" sans préciser quel champ (`montantBudget`, `montantBudgetNormalise`, `Budget.montant`) ni si ce montant est converti en `activeCurrency`.
- **Analyse** : Les items inactifs dans Angular sont construits depuis `Budget` : `montantBudget: b.montant`, `montantBudgetNormalise: b.montant`. La fonction `budgetAmount(item)` retourne `item.montantBudgetNormalise ?? item.montantBudget`. Côté Flutter, les items inactifs viendront de `budgetNotifierProvider.state.items` (List<Budget>). Le champ pertinent est `Budget.montant`. Les montants de la liste sont tous convertis en `activeCurrency` (FR-009), donc les inactifs aussi.
- **Décision** : Afficher `Budget.montant` converti en `activeCurrency`. Pas de montant dépensé.
- **Impact sur spec.md** : FR-013 précisé avec "`Budget.montant` converti en `activeCurrency`".

---

### CL-004 — allCategoriesHaveBudget : categoryNotifierProvider

- **Catégorie** : 5-Intégrations
- **Score** : MOYEN
- **Contexte** : FR-011 mentionnait le calcul `allCategoriesHaveBudget` sans préciser la source des catégories côté Flutter. Angular charge `allCategories` via un service dédié.
- **Analyse** : `categoryNotifierProvider` existe dans `features/categories/application/category_notifier.dart` et est déjà utilisé dans `category_list_screen.dart`. Il expose `ListState<Category>` avec le champ `items`. `budgetNotifierProvider.state.items` (List<Budget>) porte les budgets actifs. Le calcul peut être fait localement dans le screen : catégories non-système (celles dont `category.isSystem == false`) qui n'ont pas toutes un budget actif dans la liste.
- **Décision** : `ref.watch(categoryNotifierProvider)` utilisé dans `BudgetListScreen` pour le calcul `allCategoriesHaveBudget`. Pas de nouveau provider à créer.
- **Impact sur spec.md** : FR-011 précisé avec la source `categoryNotifierProvider`.

---

### CL-005 — activeCurrency : setState local

- **Catégorie** : 7-Contraintes
- **Score** : MOYEN
- **Contexte** : La spec n'indiquait pas si `activeCurrency` devait être dans `BudgetListState` (Riverpod) ou en état local du widget. Un état Riverpod est partageable entre screens, un setState local est plus simple.
- **Analyse** : `activeCurrency` est un état purement UI, propre à cet écran, non partagé. Le screen utilise déjà `ConsumerStatefulWidget` avec `_selectedMonth`, `_selectedYear` en setState local. Même pattern ici. Constitution Principe III (Simplicité) : éviter d'alourdir le state Riverpod avec des variables UI locales.
- **Décision** : `activeCurrency` géré en `setState` local (type `Currency`), initialisé depuis `dashboardState.currencies.first`. Pas de modification de `BudgetListState`.
- **Impact sur spec.md** : Key Entities — `Currency` précisée avec "état local setState, pattern identique à `_selectedMonth`".

---

## Points différés

> Points non résolus dans cette session, à traiter lors d'une prochaine itération si besoin.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| CL-006 | spec.md FR-008 | Debounce 2s Flutter : `dart:async Timer` ou `RxDart debounce` | 7-Contraintes | B | M | BAS | Impact faible, `dart:async Timer` est le pattern évident (utilisé dans d'autres screens) |
| CL-007 | spec.md FR-015 | Tap item actif : `budgetDetails` (nav) vs modal `ModalType.budget` (actuel Flutter) | 3-UX | M | B | BAS | Incertitude basse — spec dit `budgetDetails` (alignement Angular), pas de décision contraire. Confirmé au plan. |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 7 |
| Catégories couvertes | 4/11 (Contraintes, Scope, Modèle de données, Intégrations) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 2 |
| Modifications spec.md | 5 (NFR-003, FR-011, FR-013, Key Entities Currency, A-001) |
