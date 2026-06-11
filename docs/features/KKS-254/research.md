# Research — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

> Date : 2026-05-23 | Issue : KKS-254
> Recherche effectuée avant la rédaction de spec.md — décisions techniques prises sur la base de l'analyse croisée Angular ↔ Flutter.

---

## Source de vérité analysée

| Fichier | Lignes clés |
|---------|-------------|
| `app/src/app/features/budgets/components/budget-detail/budget-detail.html` | Structure complète (hero, pills, transactions groupées) |
| `app/src/app/features/budgets/components/budget-detail/budget-detail.ts` | Logique (categoryId via queryParam, isCurrentMonth, getById pour toggle, IntersectionObserver sticky) |
| `app/src/app/features/budgets/components/budget-list/budget-list.ts` | Navigation : `onBudgetPressed` → `/budgets/details?budgetId=categoryId&month=YYYY-MM` |
| `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` | État actuel Flutter (602L, pie chart, BudgetItemRow, MonthSelector) |
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | Déclencheurs navigation actuels (`onChartsTap`, `onTap: modal`) |
| `flutter/lib/src/features/budgets/application/budget_notifier.dart` | `update()`, `delete()` disponibles |
| `flutter/lib/src/domain/repositories/transaction_repository.dart` | `getByMonth(int month, int year)` disponible |
| `flutter/lib/src/domain/models/budget_overview.dart` | `BudgetOverviewItem` — pas de champ `actif` |
| `flutter/lib/src/domain/models/transaction.dart` | Modèle plat : `categoryId: String?`, `accountId: String?` |
| `flutter/lib/src/features/accounts/application/account_notifier.dart` | `loadItems()` disponible |

---

## Décisions techniques (RES-XXX)

### RES-001 — Suppression du pie chart : pas de migration

**Décision** : `BudgetPieChart`, `BudgetCategoryDetailSheet`, `_BudgetItemRow` sont supprimés. `UnbudgetedDetailSheet` est conservé (utilisé par `budget_list_screen`).

**Justification** : L'écran Angular ne possède pas de pie chart. La vue détail Flutter était une vue parallèle non alignée sur Angular. Constitution Principe III (YAGNI) : ne pas adapter ce qui doit être remplacé.

**Impact** : 3 fichiers widget supprimés. `budget_hero_widget_test.dart:35` à mettre à jour (suppression paramètre `onChartsTap`).

---

### RES-002 — Routing : paramètre `categoryId` ajouté

**Décision** : Le router GoRoute `details` est modifié pour parser `categoryId` (= `item.categoryId`, nommé `budgetId` côté Angular). Le constructeur `BudgetDetailScreen` reçoit `required String categoryId`.

**Justification** : Angular navigue avec `{ budgetId: item.categoryId, month }` depuis `onBudgetPressed`. Flutter doit adopter le même pattern. Le "vrai" `budgetId` (pour delete/toggle/edit) est dérivé de l'item overview (`item.budgetId`) — distinct du `categoryId` de navigation.

**Impact** : `app_router.dart` modifié, constructeur `BudgetDetailScreen` modifié, `budget_list_screen.dart` mis à jour (3 points de navigation).

---

### RES-003 — Navigation depuis budget_list_screen : tap ligne → détail (remplace modal édition)

**Décision** : Le `onTap` des items actifs (mois courant) passe de "ouvrir modal édition" à "naviguer vers détail avec categoryId + month". Items inactifs : `onTap` vers détail (actuellement `null`). Items historique : `onTap` vers détail (actuellement absent).

**Justification** : Angular `onBudgetPressed` s'applique à tous les items (actifs et inactifs). L'édition se fait depuis le détail (action pill "Modifier"). `budget-list.html:147` : les inactifs sont cliquables via `button.clickable`.

**Impact** : `budget_list_screen.dart` — 3 types d'items mis à jour. L'édition depuis la liste est supprimée (seul point d'entrée : action pill depuis le détail).

---

### RES-004 — Champ `actif` : getById avant toggle

**Décision** : `actif` est absent de l'API overview (`BudgetOverviewItemResponse` — 11 champs, confirmé par analyse du backend). Le pill toggle affiche "Désactiver" par défaut (actif = true implicite). La valeur réelle est lue via `budgetNotifier.getById(budgetId)` juste avant l'appel `update(actif: !actif)`.

**Justification** : Aligné Angular `budget-detail.ts:297-316` (`onToggleActive` fait un `getById` frais). Flutter `BudgetNotifier` a déjà `update()` et `delete()`.

**Impact** : Pas de modification modèle. Un `getById` est nécessaire pour Toggle et Edit — à implémenter comme méthode dans `BudgetNotifier` ou via `budgetRepository.getById()` directement.

---

### RES-005 — Budget inactif : fallback sur budgetNotifier.state.items

**Décision** : Si l'item n'est pas trouvé dans l'overview (budget inactif), le fallback utilise `budgetNotifierProvider.state.items` (déjà chargé avec `includeInactive: true` par `budget_list_screen`). Aucune requête API supplémentaire.

**Justification** : Angular `budget-detail.ts:229-250` fait un fallback `getAll(true)`. En Flutter, `budget_list_screen` appelle `loadItems(includeInactive: true)` (ligne 63) avant la navigation — les données sont déjà disponibles.

**Impact** : Logique de chargement dans `initState` : chercher d'abord dans overview, puis dans `state.items` par `categoryId`.

---

### RES-006 — Transactions : FutureProvider.family dédié

**Décision** : Les transactions du mois sont chargées via un nouveau `FutureProvider.family<List<Transaction>, ({int month, int year})>` dédié — distinct de `transactionNotifierProvider` (qui gère un état global avec pagination, filtres, etc.).

**Justification** : `TransactionRepository.getByMonth(int month, int year)` existe dans l'interface et les deux implémentations. `TransactionNotifier` gère un état global non adapté à ce besoin ponctuel. Un `FutureProvider.family` est plus léger et idiomatique Riverpod pour ce cas.

**Impact** : Nouveau fichier `features/budgets/application/budget_transactions_provider.dart`. Filtre côté client : `tx.categoryId == categoryId && tx.type == TransactionType.depense`, tri date décroissante, groupe Aujourd'hui/Hier/date.

---

### RES-007 — Devise transaction : résolution via accountId

**Décision** : La devise de chaque transaction est résolue via `accountId → Account.currency` (accountNotifierProvider). Fallback : devise du budget si `accountId == null` ou compte introuvable.

**Justification** : Angular `budget-detail.html:135` utilise `tx.account?.currency || currency()`. Le modèle Flutter `Transaction` est plat (`accountId: String?` sans objet imbriqué), mais `Account` (avec `currency`) est accessible via `accountNotifierProvider`. L'écran charge les accounts à l'`initState` si la liste est vide.

**Impact** : `accountNotifierProvider` dépendance ajoutée à l'écran détail.

---

### RES-008 — onChartsTap : suppression (YAGNI)

**Décision** : Le callback `onChartsTap` est supprimé de `BudgetHeroWidget`. Les deux usages dans `budget_list_screen.dart` (lignes 364 et 525) sont retirés.

**Justification** : Constitution Principe III (YAGNI). Le pie chart global qui était la cible de ce callback est supprimé. Garder un callback sans cible = code mort.

**Impact** : `BudgetHeroWidget` — paramètre retiré. `budget_list_screen.dart` — 2 callsites mises à jour. `budget_hero_widget_test.dart:35` — test mis à jour.

---

### RES-009 — heroConverted (multi-devise) : hors scope V1

**Décision** : La conversion multi-devise (`heroConverted`) est hors scope V1. Flutter n'a pas de `ConversionService`.

**Justification** : Angular `heroConverted` retourne `null` si moins de 2 devises configurées (cas par défaut `['EUR']`). Jamais affiché en mono-devise. Surcoût significatif pour une feature périphérique.

**Impact** : Aucun. Documenté comme ticket futur.

---

### RES-010 — Sticky header : SliverPersistentHeader pinned

**Décision** : Le section header sticky "Transactions" est implémenté via `SliverPersistentHeader` avec `pinned: true` (ou `SliverAppBar` pinned). Remplace l'`IntersectionObserver` web d'Angular.

**Justification** : Pattern standard Flutter pour les headers persistants dans un `CustomScrollView`. `SectionHeaderSticky` (widget commun) est déjà utilisé dans l'app — à vérifier si compatible avec le contexte `Sliver`.

**Impact** : Utiliser `SliverPersistentHeader` ou adapter `SectionHeaderSticky` pour le contexte sliver.

---

## Écarts Angular ↔ Flutter documentés

| # | Angular | Flutter après KKS-254 |
|---|---------|----------------------|
| E-001 | `tx.category?.id` (objet imbriqué) | `tx.categoryId` (plat) — filtre adapté |
| E-002 | `tx.account?.currency` (objet imbriqué) | Résolution `accountId → Account.currency` via notifier |
| E-003 | `IntersectionObserver` pour sticky header | `SliverPersistentHeader pinned` |
| E-004 | `ConversionService` / `heroConverted` | Hors scope V1 |
| E-005 | `queryParam budgetId` = categoryId | `queryParam categoryId` (nommage clarifié) |
| E-006 | `isOverviewItem()` discriminant TypeScript | Vérification `budgetId != null` sur `BudgetOverviewItem` |
