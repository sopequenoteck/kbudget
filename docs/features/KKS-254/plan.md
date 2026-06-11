# Plan d'implémentation — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

**Branch** : `feature/kks-254-budget-detail-flutter` | **Date** : 2026-05-23 | **Spec** : [spec.md](./spec.md)

---

## Résumé

Transformer `BudgetDetailScreen` Flutter (602L, vue pie-chart globale) en écran de détail d'une catégorie budget unique, aligné sur Angular `budget-detail`. Approche : refonte in-place du screen existant + suppression de 2 widgets obsolètes + ajout d'un `FutureProvider.family` pour les transactions + mise à jour du routing et de la navigation depuis la liste.

**Décisions techniques clés (research.md)** : RES-001 (suppression pie chart), RES-002 (categoryId router), RES-003 (navigation liste → détail), RES-004 (getById avant toggle), RES-005 (fallback state.items), RES-006 (FutureProvider.family), RES-007 (devise via accountNotifier), RES-008 (onChartsTap supprimé), RES-010 (SliverPersistentHeader sticky).

---

## Contexte technique

**Langage** : Dart >= 3.6 | **Framework** : Flutter >= 3.27  
**State** : Riverpod (`Notifier`, `FutureProvider.family`)  
**Routing** : go_router  
**Tests** : flutter_test + shimmer  
**Modèles** : Freezed + json_serializable (build_runner non requis — aucun modèle nouveau)  
**Dépendances ajoutées** : Aucune

---

## Constitution Check

| Principe | Gate | Statut | Justification |
|----------|------|--------|---------------|
| I — API-First / Local-First | Données via repository (remote/local) | ✅ PASS | `BudgetRepository.getById`, `TransactionRepository.getByMonth`, `AccountRepository.getAll` — interfaces existantes, pas de bypass |
| II — Sécurité par défaut | Filtrage par user authentifié | ✅ PASS | Les repositories filtrent par user JWT — l'écran ne gère pas l'auth |
| III — Simplicité & YAGNI | Solution minimale, pas d'abstraction prématurée | ✅ PASS | `FutureProvider.family` (pattern existant dans le projet), suppression de code mort, pas de nouveau pattern inventé |
| IV — Mobile-First UX | Navigation touch, scroll fluide | ✅ PASS | `CustomScrollView` + slivers, action pills accessibles, pas de modal pour les données principales |
| V — Testabilité | ≥ 8 widget tests | ✅ PASS | NFR-006 respecté, mock repositories via ProviderContainer overrides |
| VI — Observabilité | N/A (Flutter — pas de logging serveur) | ✅ N/A | Écran UI pur, pas d'action serveur critique à logger |
| VII — Two Distribution Trajectories | Pas de modification backend | ✅ PASS | 0 fichier modifié côté `api/` — trajectoire B (Flutter standalone) uniquement |

**Résultat** : 7/7 PASS — aucune dérogation.

---

## Architecture — Fichiers impactés

### Fichiers à supprimer (D)

| Fichier | Raison |
|---------|--------|
| `flutter/lib/src/features/budgets/presentation/widgets/budget_pie_chart.dart` | RES-001 — pie chart supprimé |
| `flutter/lib/src/features/budgets/presentation/widgets/budget_category_detail_sheet.dart` | RES-001 — rendu obsolète par le nouvel écran détail |

### Fichiers à créer (C)

| Fichier | Contenu |
|---------|---------|
| `flutter/lib/src/features/budgets/application/budget_transactions_provider.dart` | `FutureProvider.family<List<Transaction>, ({int month, int year})>` — charge + filtre les transactions du mois (RES-006) |

### Fichiers à modifier (M)

| Fichier | Nature |
|---------|--------|
| `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` | Refonte complète (602L → ~400L) |
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | Navigation + suppression onChartsTap (RES-003, RES-008) |
| `flutter/lib/src/features/budgets/presentation/widgets/budget_hero_widget.dart` | Supprimer paramètre `onChartsTap` (RES-008) |
| `flutter/lib/src/routing/app_router.dart` | Ajout queryParam `categoryId` (RES-002) |
| `flutter/test/src/features/budgets/presentation/budget_detail_screen_test.dart` | Refonte complète des tests |
| `flutter/test/src/features/budgets/presentation/widgets/budget_hero_widget_test.dart` | Retirer `onChartsTap: () {}` (ligne 35) |

---

## Approche détaillée par composant

### Composant 1 — Router + Navigation (FR-001 à FR-005, RES-002, RES-003)

**`app_router.dart`** : Modifier le GoRoute `details` pour lire `categoryId` en queryParam et le transmettre :
```dart
GoRoute(
  path: 'details',
  name: RouteNames.budgetDetailsName,
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) {
    final categoryId = state.uri.queryParameters['categoryId'] ?? '';
    final month = state.uri.queryParameters['month'];
    return BudgetDetailScreen(categoryId: categoryId, month: month);
  },
),
```

**`budget_list_screen.dart`** — 3 points de navigation à mettre à jour :

1. **Items actifs (mois courant)** — remplace `modalNotifierProvider.open(...)` par :
```dart
onTap: () {
  final month = '${_selectedYear}-${_selectedMonth.toString().padLeft(2, '0')}';
  context.pushNamed(RouteNames.budgetDetailsName,
      queryParameters: {'categoryId': item.categoryId, 'month': month});
},
```

2. **Items inactifs** — actuellement `onTap: null` → même navigation que les actifs (RES-003, CL-002).

3. **Items historique** — actuellement pas de `onTap` → ajouter le même pattern avec le mois de l'historique sélectionné.

4. **`onChartsTap`** — retirer le callback des deux appels `BudgetHeroWidget(...)` (lignes 364 et 525).

---

### Composant 2 — BudgetHeroWidget nettoyage (FR-028, RES-008)

Supprimer le paramètre `onChartsTap: VoidCallback` de `BudgetHeroWidget` :
- Retirer la déclaration (`final VoidCallback onChartsTap;`)
- Retirer l'usage interne (bouton ou GestureDetector associé)
- Mettre à jour `budget_hero_widget_test.dart:35`

> Note : `_DoughnutMini` et `fl_chart` restent — le doughnut est toujours affiché dans le hero de la liste. Seul `onChartsTap` est retiré.

---

### Composant 3 — budget_transactions_provider.dart (FR-016, RES-006)

Pattern `FutureProvider.family` identique à `debtPaymentsProvider` (dette) et `subscriptionPaymentsProvider` (abonnements) :

```dart
// flutter/lib/src/features/budgets/application/budget_transactions_provider.dart

final budgetTransactionsProvider =
    FutureProvider.family<List<Transaction>, ({int month, int year})>(
  (ref, params) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getByMonth(params.month, params.year);
  },
);
```

Le filtrage (`categoryId + type DEPENSE`) et le tri/groupement par date sont faits dans le widget (computed depuis `ref.watch(budgetTransactionsProvider(...))`).

---

### Composant 4 — BudgetDetailScreen refonte (tous les FR, RES-002 à RES-007, RES-010)

#### Constructeur
```dart
class BudgetDetailScreen extends ConsumerStatefulWidget {
  const BudgetDetailScreen({super.key, required this.categoryId, this.month});
  final String categoryId;
  final String? month; // format YYYY-MM, null = mois courant
}
```
Suppression : mixin `BudgetMonthHelpers`, `MonthSelector`, logique `_onMonthChanged`.

#### Chargement des données (FR-001, RES-005)

`initState` → `addPostFrameCallback` :
1. Parser `month` → `_selectedMonth`, `_selectedYear`
2. Appeler `budgetNotifier.loadOverview()` (mois courant) ou `loadHistory(month)` (mois passé)
3. Charger accounts si `accountNotifierProvider.state.items.isEmpty` → `loadItems()`

Trouver l'item budget :
```dart
BudgetOverviewItem? _findOverviewItem(BudgetNotifierState state) {
  return state.overview?.items.firstWhereOrNull((i) => i.categoryId == widget.categoryId);
}

Budget? _findFallbackBudget(BudgetNotifierState state) {
  // Pour les budgets inactifs absents de l'overview (RES-005)
  return state.items.firstWhereOrNull((b) => b.category.id == widget.categoryId);
}
```

#### Structure de l'écran

```
Scaffold
  AppBar(title: _buildTitle())   // icône catégorie + nom (FR-006, FR-007)
  body: CustomScrollView(slivers: [
    SliverToBoxAdapter: _buildHero()        // Hero DÉPENSÉ + méta + progress bar
    SliverToBoxAdapter: _buildActionPills() // conditionnel (FR-012)
    SliverPersistentHeader: _SectionHeader  // "Transactions" sticky + count (FR-011)
    _buildTransactionSlivers()              // groupes ou empty state
  ])
```

#### Hero (FR-008 à FR-010)

```
Column
  Text("DÉPENSÉ")               // label uppercase, bodySmall, onSurfaceVariant
  Text(montantDepense formaté)  // titleLarge, expenseColor si >100%
  Row(méta)                     // PhosphorTarget + budget + · + PhosphorWarning/ChartPie + reste/dépassement
  LinearProgressIndicator       // si percentage > 0 (normal/warning/exceeded)
```

#### Action pills (FR-012 à FR-015)

Conditionnels : `isCurrentMonth && overviewItem != null && overviewItem.budgetId != null`

```
Row(
  _ActionPill(danger, PhosphorTrash, onDelete)
  Spacer()
  _ActionPill(PhosphorPause/Play, onToggle)   // label "Désactiver" par défaut, bascule après getById
  _ActionPill(PhosphorPencilSimple, onEdit)
)
```

`onDelete` → `ConfirmDialogCustom.show()` → `budgetNotifier.delete(budgetId)` → `context.go(budgets)`
`onToggle` → `budgetRepository.getById(budgetId)` → `budgetNotifier.update(budget.copyWith(actif: !actif))` → `context.go(budgets)`
`onEdit` → `budgetRepository.getById(budgetId)` → `modalNotifier.open(ModalType.budget, entity: budget)`

Note : `budgetRepository` est accessible via `ref.read(budgetRepositoryProvider)` (data_mode_provider pattern).

#### Transactions groupées (FR-017 à FR-021)

```dart
// Dans le widget : filter + group depuis le FutureProvider
final txAsync = ref.watch(budgetTransactionsProvider((month: _selectedMonth, year: _selectedYear)));
txAsync.when(
  loading: () => [SliverList(skeleton × 4)],
  error: (e, _) => [SliverFillRemaining(ErrorView)],
  data: (allTx) {
    final filtered = allTx
        .where((tx) => tx.categoryId == widget.categoryId && tx.type == TransactionType.depense)
        .sorted((a, b) => b.date.compareTo(a.date));
    if (filtered.isEmpty) return [SliverFillRemaining(EmptyStateWidget)];
    final groups = _groupByDate(filtered);
    return groups.expand((group) => [
      SliverToBoxAdapter(child: _DateLabel(group.label)),
      SliverList(delegate: ...group.transactions → _TransactionRow),
    ]).toList();
  }
);
```

#### Row transaction (FR-020, RES-007)

```
InkWell (non cliquable pour l'instant — lecture seule)
  Row
    Container(36px circle, couleur catégorie bg) { emoji }
    Column(libelle, date sous-titre)
    Text(montant, devise résolue via accountId → Account.currency, fallback devise budget)
```

Résolution devise : `final account = accounts.firstWhereOrNull((a) => a.id == tx.accountId);`

#### Section header sticky (FR-011, RES-010)

`SliverPersistentHeader` avec un delegate minimal :

```dart
class _StickyTransactionHeader extends SliverPersistentHeaderDelegate {
  final int count;
  @override double get minExtent => 44;
  @override double get maxExtent => 44;
  @override Widget build(...) => SectionHeaderContent(title: 'Transactions', count: count);
  @override bool shouldRebuild(_) => true;
}
```

> Note : `SectionHeaderSticky` existant n'est pas compatible sliver (widget standard, pas delegate). Un delegate minimal est créé en privé dans le fichier — pas d'extraction dans common_widgets (YAGNI).

---

### Composant 5 — Suppression des widgets obsolètes (FR-023, FR-024, RES-001)

Ordre de suppression (éviter les erreurs de compilation en cascade) :
1. Retirer tous les imports de `budget_pie_chart.dart` et `budget_category_detail_sheet.dart` de `budget_detail_screen.dart`
2. Supprimer les fichiers
3. Vérifier `flutter analyze` — 0 erreur

`UnbudgetedDetailSheet` : retirer son import de `budget_detail_screen.dart` uniquement. Le fichier reste.

---

### Composant 6 — Tests (NFR-006)

**`budget_detail_screen_test.dart`** — refonte avec 8+ tests :

| Test | SC |
|------|----|
| `should_navigateToDetail_when_budgetItemTapped` | SC-001 |
| `should_showHero_when_budgetItemLoaded` | SC-001 |
| `should_showTransactionGroups_when_transactionsLoaded` | SC-002 |
| `should_showActionPills_when_currentMonth` | SC-003 |
| `should_hideActionPills_when_historyMonth` | SC-003 |
| `should_callDelete_when_deleteConfirmed` | SC-004 |
| `should_callUpdate_when_toggleConfirmed` | SC-005 |
| `should_showSkeleton_when_loading` | SC-006 |
| `should_showEmptyState_when_noTransactions` | SC-008 |

Mocks : `_MockBudgetNotifier`, `_MockTransactionRepository`, `_MockAccountNotifier`

**`budget_hero_widget_test.dart`** : Retirer `onChartsTap: () {}` (1 ligne, SC-007 partiel).

---

## Risques

| ID | Risque | Probabilité | Mitigation |
|----|--------|-------------|------------|
| R-001 | `BudgetHeroWidget.onChartsTap` utilisé dans d'autres fichiers non identifiés | Faible | `grep -r "onChartsTap"` avant suppression — 2 usages confirmés dans `budget_list_screen.dart` uniquement |
| R-002 | `budgetNotifierProvider` état partagé : `loadHistory()` depuis le détail écrase l'overview de la liste | Moyen | Pattern actuel identique — acceptable tant que retour liste refresh l'état. Pas de régression par rapport à l'existant. |
| R-003 | `BudgetMonthHelpers` mixin retiré du détail mais toujours nécessaire dans la liste | Faible | `BudgetMonthHelpers` non supprimé — uniquement détaché de `budget_detail_screen` |
| R-004 | `transactionRepositoryProvider` non exposé via `data_mode_provider` | Faible | Vérifier le pattern avant implémentation (même que `budgetRepositoryProvider`) |
| R-005 | Tests cassés par la suppression de `onChartsTap` dans `budget_hero_widget_test.dart` | Certain | Couvert dans US-004 scénario 4 — à faire en premier dans la phase tests |

---

## Hors scope

- `heroConverted` (multi-devise) — RES-009, différé
- Modification du sélecteur de mois dans le détail (retiré intentionnellement)
- Pagination des transactions (toutes chargées en mémoire, volume raisonnable)
- Modification du modèle `BudgetOverviewItem` (pas de champ `actif` ajouté)
- Endpoint backend

---

## Complexity Tracking

Aucune violation de la constitution. Aucune complexité justifiée requise.

---

## Artefacts complémentaires

- [research.md](./research.md) — 10 décisions techniques (RES-001 → RES-010), 6 écarts Angular↔Flutter
- [data-model.md](./data-model.md) — entités impliquées et leurs relations
- [quickstart.md](./quickstart.md) — guide de démarrage pour l'implémenteur
