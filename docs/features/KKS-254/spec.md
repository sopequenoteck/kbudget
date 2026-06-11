# Spécification — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

**Feature Branch** : `feature/kks-254-budget-detail-flutter`
**Créée** : 2026-05-22
**Statut** : Draft
**Priorité** : High (P2) | **Parent** : KKS-242

---

## Contexte

L'écran `BudgetDetailScreen` Flutter (602L) affiche actuellement un pie chart global de toutes les catégories de budget — une vue qui n'existe pas dans Angular. L'objectif est de transformer cet écran en **vue de détail d'une catégorie précise**, alignée sur le composant Angular `budget-detail` (source de vérité).

**Source de vérité Angular** : `app/src/app/features/budgets/components/budget-detail/budget-detail.{ts,html,scss}`

**Décisions techniques prises en amont** (non sujettes à clarification) :
- Le pie chart Flutter est **retiré**. Pas de migration, pas d'adaptation — suppression complète.
- `heroConverted` (multi-devise) est **hors scope V1** (jamais affiché en mono-devise, pas de `ConversionService` Flutter).
- La devise par transaction est résolue via `accountId → Account.currency` (accountNotifierProvider).
- `BudgetPieChart`, `BudgetCategoryDetailSheet`, `_BudgetItemRow` sont **supprimés** dans ce ticket.
- `UnbudgetedDetailSheet` est **conservé** (toujours utilisé par `budget_list_screen`) — uniquement débranché de `budget_detail_screen`.

---

## User Stories

### US-001 — Consultation du détail d'un budget (P1)

L'utilisateur tape sur une ligne de budget dans la liste (`BudgetListScreen`) et accède à un écran dédié montrant le hero du budget de cette catégorie (montant dépensé, cible, reste/dépassement) ainsi que la progress bar.

**Pourquoi P1** : C'est le parcours principal. Sans navigation fonctionnelle vers un écran de détail structuré, les US-002 et US-003 sont inaccessibles.

**Independent Test** : Naviguer depuis la liste → vérifier que l'écran affiche le bon nom de catégorie, le bon montant dépensé, et la progress bar. Testable en isolation avec un stub de données.

**Acceptance Scenarios** :

1. **Given** l'utilisateur est sur la liste des budgets du mois courant, **When** il tape sur une ligne de budget active (ex: "🛒 Courses"), **Then** il navigue vers l'écran de détail de cette catégorie, avec le titre "🛒 Courses" dans l'AppBar, le hero "DÉPENSÉ / montant", la méta-ligne (cible · reste/dépassement), et la progress bar.
2. **Given** l'utilisateur est sur la liste des budgets d'un mois passé, **When** il tape sur une ligne de budget historique, **Then** il navigue vers l'écran de détail du mois passé correspondant, sans action pills.
3. **Given** l'écran de détail est en cours de chargement, **When** les données ne sont pas encore disponibles, **Then** un skeleton hero (label + barre + méta) est affiché à la place du hero réel.
4. **Given** le chargement échoue, **When** une erreur réseau se produit, **Then** un `ErrorView` avec bouton "Réessayer" est affiché.

---

### US-002 — Transactions de la catégorie groupées par date (P1)

L'utilisateur voit, sous le hero, la liste des dépenses de la catégorie pour le mois sélectionné, groupées par date (Aujourd'hui / Hier / date longue). Si aucune dépense n'existe, un empty state est affiché.

**Pourquoi P1** : La raison d'être du détail budget est de comprendre comment l'argent a été dépensé dans cette catégorie.

**Independent Test** : Avec des transactions mockées pour le mois + la catégorie, vérifier que les groupes de dates s'affichent correctement, le filtrage fonctionne (seul type `DEPENSE` + `categoryId` correct), et l'empty state apparaît si aucune transaction ne correspond.

**Acceptance Scenarios** :

1. **Given** il existe des transactions de type DEPENSE pour la catégorie ce mois, **When** l'écran est chargé, **Then** les transactions sont affichées groupées par date : "Aujourd'hui" pour les transactions du jour, "Hier" pour J-1, date longue (ex: "22 janvier") pour les autres — triées par date décroissante dans chaque groupe.
2. **Given** une transaction a un `accountId` associé, **When** la devise du compte est différente de la devise du budget, **Then** le montant est affiché dans la devise du compte (résolue via `accountId → Account.currency`).
3. **Given** aucune transaction DEPENSE n'existe pour cette catégorie ce mois, **When** l'écran est chargé, **Then** un empty state "Aucune transaction ce mois" est affiché sous le section header.
4. **Given** les transactions sont en cours de chargement, **When** la requête n'est pas encore résolue, **Then** des skeleton items (cercle + lignes shimmer) sont affichés à la place des vraies transactions.

---

### US-003 — Actions sur le budget du mois courant (P2)

L'utilisateur dispose de trois action pills sous le hero pour le mois courant : supprimer le budget, activer/désactiver le budget, modifier le budget. Ces actions sont invisibles pour les mois passés.

**Pourquoi P2** : Feature importante mais non bloquante — l'écran est utilisable sans les actions (lecture seule sur historique).

**Independent Test** : Tester chaque action pill séparément avec un mock de `budgetNotifier`. Tester l'absence des pills sur un mois passé.

**Acceptance Scenarios** :

1. **Given** le mois affiché est le mois courant ET l'item est un overview item, **When** l'écran est rendu, **Then** trois action pills sont visibles : danger pill "Supprimer" (gauche), pill "Désactiver" (centre — label par défaut car `actif` est absent de l'overview, traité comme `true` conformément à A-002), pill "Modifier" (droite). Le label du pill bascule en "Activer" uniquement après qu'un `getById` ait confirmé `actif == false`.
2. **Given** l'utilisateur tape "Supprimer", **When** il confirme dans le dialog de confirmation, **Then** `budgetNotifier.delete(budgetId)` est appelé et l'écran retourne vers la liste.
3. **Given** l'utilisateur tape "Désactiver" ou "Activer", **When** l'action est confirmée, **Then** `budgetNotifier.update(budget.copyWith(actif: !budget.actif))` est appelé (après un `getById` pour lire la valeur fraîche) et l'écran retourne vers la liste.
4. **Given** l'utilisateur tape "Modifier", **When** il tape le pill Edit, **Then** le modal d'édition budget s'ouvre (via `modalNotifierProvider.open(ModalType.budget, entity: budget)`).
5. **Given** le mois affiché est un mois passé (BudgetHistoryItem, sans `budgetId`), **When** l'écran est rendu, **Then** aucun action pill n'est affiché.

---

### US-004 — Nettoyage des widgets devenus redondants (P2)

Les widgets et classes liés à l'ancienne vision "pie chart global" sont supprimés du codebase : `BudgetPieChart`, `BudgetCategoryDetailSheet`, `_BudgetItemRow`. `UnbudgetedDetailSheet` est conservé (utilisé par `budget_list_screen`).

**Pourquoi P2** : Prévient la confusion future et supprime le code mort. Lié structurellement à US-001 (le refactoring de l'écran implique de retirer ces widgets).

**Independent Test** : `flutter analyze` passe sans erreur. Aucun import cassé. `flutter test` passe sur tous les tests budgets.

**Acceptance Scenarios** :

1. **Given** la refonte est terminée, **When** on cherche `BudgetPieChart` ou `BudgetCategoryDetailSheet` dans le codebase, **Then** ces classes n'existent plus.
2. **Given** `budget_list_screen.dart`, **When** on l'analyse, **Then** `UnbudgetedDetailSheet` est toujours importé et fonctionnel (non supprimé).
3. **Given** `budget_list_screen.dart`, **When** une ligne de budget est tappée, **Then** la navigation vers `budget_detail_screen` avec `categoryId` + `month` est déclenchée (remplace l'ancienne ouverture du modal d'édition depuis la liste).
4. **Given** `flutter/test/.../budget_hero_widget_test.dart`, **When** `onChartsTap` est supprimé de `BudgetHeroWidget`, **Then** le test existant (ligne 35, `onChartsTap: () {}`) est mis à jour pour supprimer ce paramètre — le test passe sans régression.

---

### Cas limites

- Budget inactif naviguant vers le détail : l'item n'est pas dans l'overview API. Fallback : chercher dans `budgetNotifierProvider.state.items` (déjà chargé avec `includeInactive: true` par `budget_list_screen`) via `categoryId` — aucune requête API supplémentaire. Aligne avec Angular (`budget-detail.ts:229-250`). Si toujours introuvable → "Budget introuvable".
- Mois courant sans transactions DEPENSE pour la catégorie : empty state "Aucune transaction ce mois" (non un skeleton).
- `percentage == 0` : progress bar non affichée (alignement Angular : `@if (budgetItem()!.percentage > 0)`).
- `montantDepense == 0` : hero affiché normalement avec montant 0 (pas de masquage).
- `BudgetHistoryItem` : pas de `budgetId` → action pills masqués. Les données de montant utilisent `montantBudget` (non normalisé, contrairement à l'overview qui utilise `montantBudgetNormalise`).

---

## Requirements fonctionnels

### Navigation et routing

- **FR-001** : Modifier `app_router.dart` (GoRoute `details`) pour parser les queryParams `categoryId` (= id de la catégorie) et `month` (format `YYYY-MM`, optionnel — défaut = mois courant), et les transmettre à `BudgetDetailScreen`. Modifier le constructeur de `BudgetDetailScreen` pour accepter `required String categoryId` en plus du `String? month` existant.
- **FR-002** : Le tap sur une ligne de budget active dans `budget_list_screen` (mois courant) doit naviguer vers `/budgets/details?categoryId=X&month=YYYY-MM` — remplace l'ancienne ouverture du modal d'édition depuis la liste.
- **FR-003** : Le tap sur une ligne de budget inactive dans `budget_list_screen` (mois courant) doit naviguer vers `/budgets/details?categoryId=X&month=YYYY-MM`. Les items inactifs conservent leur opacity 0.5 visuelle mais sont cliquables (aligné Angular : `budget-list.html:147` applique `onBudgetPressed` aux inactifs).
- **FR-004** : Le tap sur une ligne de budget historique dans `budget_list_screen` doit naviguer vers `/budgets/details?categoryId=X&month=YYYY-MM` (mois de l'historique).
- **FR-005** : Le bouton retour (AppBar leading natif) doit naviguer vers `/budgets`.

### Page header

- **FR-006** : L'AppBar affiche l'emoji icône catégorie + le nom de catégorie (chargés dynamiquement depuis l'item budget). Pendant le loading, le titre est générique ("Budget").
- **FR-007** : L'icône catégorie est affichée dans un conteneur circulaire ou arrondi avec couleur de fond `categoryCouleur + '26'` (opacité 15%), aligné sur Angular.

### Hero section

- **FR-008** : Le hero affiche le label "DÉPENSÉ" en uppercase, puis `montantDepense` formaté (couleur `expenseColor` si `percentage > 100`, sinon `onSurface`).
- **FR-009** : La méta-ligne du hero contient : icône cible (PhosphorTarget) + montant budgété formaté + séparateur "·" + icône (PhosphorWarning si dépassement, sinon PhosphorChartPie) + label "reste" ou "dépassement" + valeur absolue du reste formatée.
- **FR-010** : La progress bar est affichée uniquement si `percentage > 0`. États : normal (couleur catégorie), warning (80-100%, `textWarning`), exceeded (>100%, `expenseColor`).
- **FR-011** : Le section header "Transactions" est sticky (reste visible au scroll). Affiche le count de transactions filtrées.

### Action pills (mois courant + overview item uniquement)

- **FR-012** : Les action pills sont rendus si et seulement si `isCurrentMonth == true` AND l'item est un `BudgetOverviewItem` (a un `budgetId` non null).
- **FR-013** : Action pill "Supprimer" (variante danger, icône `PhosphorTrash`) → dialog de confirmation (`ConfirmDialog`) → `budgetNotifier.delete(budgetId)` → `context.go(RouteNames.budgets)`.
- **FR-014** : Action pill "Désactiver"/"Activer" (icône `PhosphorPause`/`PhosphorPlay`) → `getById(budgetId)` → `budgetNotifier.update(budget.copyWith(actif: !budget.actif))` → `context.go(RouteNames.budgets)`.
- **FR-015** : Action pill "Modifier" (icône `PhosphorPencilSimple`) → `modalNotifierProvider.open(ModalType.budget, entity: budget)` (récupéré via `getById`).

### Transactions

- **FR-016** : Charger les transactions via `transactionRepository.getByMonth(month, year)` — à exposer via un `FutureProvider.family<List<Transaction>, ({int month, int year})>` dédié (pas de modification du `TransactionNotifier` existant).
- **FR-017** : Filtrer les transactions : `tx.categoryId == categoryId && tx.type == TransactionType.depense`.
- **FR-018** : Trier les transactions filtrées par date décroissante.
- **FR-019** : Grouper les transactions par date : "Aujourd'hui" (= jour courant), "Hier" (= J-1), sinon date longue locale (ex: "22 janvier").
- **FR-020** : Chaque row transaction affiche : icône catégorie (couleur bg), libelle, date sous-titre formatée, montant dans la devise du compte (`Account.currency` résolu via `accountId`, sinon devise du budget).
- **FR-021** : Empty state "Aucune transaction ce mois" si la liste filtrée est vide (icône `PhosphorReceipt`).
- **FR-022** : Skeleton items (4 rows shimmer) pendant le chargement des transactions.

### Nettoyage

- **FR-023** : Supprimer le fichier `flutter/lib/src/features/budgets/presentation/widgets/budget_pie_chart.dart` et toutes ses références.
- **FR-024** : Supprimer le fichier `flutter/lib/src/features/budgets/presentation/widgets/budget_category_detail_sheet.dart` et toutes ses références.
- **FR-025** : Supprimer la classe privée `_BudgetItemRow` de `budget_detail_screen.dart`.
- **FR-026** : Retirer `UnbudgetedDetailSheet` des imports de `budget_detail_screen.dart` (le fichier reste, utilisé par `budget_list_screen`).
- **FR-027** : Retirer `MonthSelector` et le mixin `BudgetMonthHelpers` de `budget_detail_screen.dart` (remplacés par la logique de parsing du param `month`).
- **FR-028** : Supprimer le callback `onChartsTap` de `BudgetHeroWidget` (Constitution Principe III — YAGNI : le pie chart global n'existe plus). Les deux usages dans `budget_list_screen.dart` (lignes 364 et 525) sont retirés dans ce ticket (inclus dans US-004).

---

## Requirements non-fonctionnels

- **NFR-001** : Aucune modification des couches `domain/`, `data/` existantes sauf l'ajout d'un `FutureProvider.family` pour `transactionsByMonth` dans la couche application (nouveau provider, non-destructif).
- **NFR-002** : Tous les tokens design doivent venir de `AppThemeExtension`, `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography` — pas de valeurs hardcodées.
- **NFR-003** : `mounted` vérifié après chaque `await` dans les méthodes asynchrones du state.
- **NFR-004** : Le skeleton loading utilise le package `shimmer` (cohérent avec les autres écrans Flutter).
- **NFR-005** : Le `ConfirmDialog` commun (`common_widgets/confirm_dialog.dart`) est utilisé pour la confirmation de suppression (pas de `showDialog` inline).
- **NFR-006** : ≥ 8 widget tests couvrant les SC principaux (navigation, hero, transactions, action pills, empty state, skeleton).

---

## Key Entities

- **BudgetOverviewItem** : Item budget du mois courant (`budgetId`, `categoryId`, `categoryNom`, `categoryIcone`, `categoryCouleur`, `montantDepense`, `montantBudgetNormalise`, `percentage`, `currency`, `frequence`). `actif` absent — default `true`.
- **BudgetHistoryItem** : Item budget d'un mois passé (`categoryId`, `categoryNom`, `categoryIcone`, `categoryCouleur`, `montantDepense`, `montantBudget`, `percentage`, `currency`). Pas de `budgetId` → actions impossibles.
- **Transaction** : Transaction financière (`id`, `libelle`, `type: TransactionType`, `date: DateTime`, `montant`, `categoryId: String?`, `accountId: String?`).
- **Account** : Compte financier (`id`, `currency: Currency`). Utilisé pour résoudre `accountId → devise` par transaction.
- **Budget** : Budget complet (`id`, `category`, `montant`, `currency`, `frequence`, `actif`). Chargé via `getById` pour les actions Toggle et Edit.

---

## Success Criteria

| SC | Vérification | Méthode |
|----|-------------|---------|
| SC-001 | Tap sur ligne active → écran détail avec hero DÉPENSÉ + progress bar + AppBar catégorie | Widget test + manuel |
| SC-002 | Transactions groupées par date, filtrées DEPENSE + categoryId | Widget test |
| SC-003 | Action pills visibles mois courant/overview, invisibles mois passé/history | Widget test |
| SC-004 | Suppression → dialog → delete() → navigation `/budgets` | Widget test |
| SC-005 | Toggle → update(actif inversé) → navigation `/budgets` | Widget test |
| SC-006 | Loading → skeleton ; erreur → ErrorView avec retry | Widget test |
| SC-007 | `BudgetPieChart` et `BudgetCategoryDetailSheet` absents du codebase | `flutter analyze` + grep |
| SC-008 | Empty state "Aucune transaction ce mois" si liste filtrée vide | Widget test |
| SC-009 | Tap ligne historique → écran détail mois passé, action pills absents | Widget test + manuel |

---

## Assumptions

| ID | Hypothèse | Impact si fausse |
|----|-----------|------------------|
| A-001 | `TransactionRepository.getByMonth(month, year)` est opérationnel côté API et Flutter (déjà présent dans l'interface) | Transactions non chargeables par mois → fallback `getAll()` avec filtre date |
| A-002 | `actif` absent de l'API overview → géré via `getById` avant toggle ; par défaut l'item est traité comme actif | Bouton toggle affiche un état potentiellement incorrect avant l'appel `getById` |
| A-003 | `UnbudgetedDetailSheet` est toujours utilisé par `budget_list_screen.dart` → conservé | Si supprimé, `budget_list_screen` casse à la compilation |
| A-004 | Accounts chargés via `accountNotifierProvider.loadItems()` à l'`initState` de l'écran si `state.items.isEmpty` (même pattern que les autres écrans). Fallback : devise du budget si `accountId == null` ou compte introuvable. | Devise du budget affichée pour toutes les transactions (dégradé acceptable) |
| A-005 | `ConfirmDialog` existe dans `common_widgets/` et son API est compatible avec la confirmation de suppression | Remplacement par `showDialog` inline si absent |

---

## Questions ouvertes

| ID | Question | Impact | Statut | Réponse |
|----|----------|--------|--------|---------|
| CL-001 | Budget inactif → fallback `getAll(includeInactive:true)` ou "Budget introuvable" ? | Détermine si un appel API supplémentaire est nécessaire en mode mois courant pour les inactifs | **Résolu** | Fallback sur `budgetNotifierProvider.state.items` (déjà chargé) — aucune requête supplémentaire |
| CL-002 | Items inactifs dans la liste : `onTap` vers détail ou garder `null` ? (Angular : cliquables) | Modifie le `onTap` des items inactifs dans `budget_list_screen` | **Résolu** | `onTap` vers détail, opacity 0.5 conservée (aligné Angular) |
| CL-003 | `onChartsTap` dans `BudgetHeroWidget` : supprimer le callback entièrement ou le remplacer par un no-op ? | Impacte `budget_list_screen.dart` lignes 364 et 525, et l'API publique de `BudgetHeroWidget` | **Résolu** | Supprimer le callback (YAGNI — pie chart global supprimé) |
