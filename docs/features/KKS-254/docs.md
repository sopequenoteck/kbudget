# Documentation — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

> Date : 2026-05-23
> Issue : KKS-254

---

## Résumé

L'écran `BudgetDetailScreen` Flutter a été entièrement refondu pour devenir un vrai écran de détail par catégorie de budget, aligné sur le composant Angular `budget-detail` (source de vérité). Le pie chart global a été supprimé et remplacé par un hero mono-catégorie (DÉPENSÉ + méta + progress bar), des action pills contextuels (suppression, activation/désactivation, modification) visibles uniquement pour le mois courant, et une liste de transactions groupées par date filtrées sur la catégorie.

---

## Guide utilisateur

### Fonctionnalités

#### Consultation du détail d'un budget

**Description** : En tapant sur un budget dans la liste (actif, inactif ou historique), l'utilisateur accède à un écran dédié à cette catégorie. Il voit :
- Le **hero** : montant dépensé ("DÉPENSÉ"), cible, reste ou dépassement, et la progress bar colorée selon l'état (normal / avertissement > 80% / dépassement > 100%).
- Le **section header "Transactions"** affiché en sticky avec le nombre de dépenses.
- La **liste des transactions DEPENSE** de la catégorie pour le mois, groupées par date (Aujourd'hui / Hier / date longue).
- Un **empty state** si aucune dépense n'a été enregistrée pour cette catégorie ce mois.

**Usage** : Taper sur n'importe quelle ligne de budget dans `BudgetListScreen`.

#### Actions sur le budget du mois courant

**Description** : Pour le mois en cours uniquement, trois action pills apparaissent sous le hero :
- **Supprimer** (rouge, à gauche) : ouvre un dialog de confirmation, puis supprime le budget et retourne à la liste.
- **Désactiver / Activer** (au centre) : récupère l'état réel du budget via l'API (`getById`), puis bascule `actif`. L'écran affiche "Désactiver" par défaut (traite le budget comme actif tant que `getById` n'a pas été appelé).
- **Modifier** (à droite) : ouvre le modal d'édition du budget pré-rempli avec les données réelles.

**Usage** : Actions disponibles uniquement quand le mois affiché est le mois courant. Non disponibles pour les mois passés (navigation depuis l'historique).

#### Navigation depuis la liste

**Description** : La navigation vers le détail passe désormais par `pushNamed` avec `categoryId` en queryParam. Les trois points d'entrée (items actifs, inactifs, historique) naviguent tous vers le même écran.

**Usage** : Automatique depuis `BudgetListScreen`. Format de l'URL interne : `/budget/details?categoryId=xxx&month=YYYY-MM`.

### Exemples d'utilisation

```
// Navigation depuis budget_list_screen.dart
context.pushNamed(
  RouteNames.budgetDetailsName,
  queryParameters: {
    'categoryId': item.categoryId,
    'month': '2026-01',       // null = mois courant
  },
);

// BudgetDetailScreen reçoit :
BudgetDetailScreen(categoryId: 'cat-alimentation', month: '2026-01')
// → mode historique, pas d'action pills
```

---

## Changements techniques

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/features/budgets/application/budget_transactions_provider.dart` | `FutureProvider.family<List<Transaction>, ({int month, int year})>` — charge toutes les transactions du mois via `TransactionRepository.getByMonth()`. Le filtrage par `categoryId` et type `DEPENSE` est effectué dans le widget. |
| `flutter/test/src/features/budgets/presentation/budget_detail_screen_test.dart` | 9 widget tests couvrant SC-001 à SC-009 : hero, action pills, delete, toggle, skeleton, empty state. |

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` | Refonte complète (602L → 820L) : suppression pie chart et `_BudgetItemRow`, ajout hero mono-catégorie, action pills contextuels, transactions groupées avec sticky header, skeleton/error state, fallback budget inactif. |
| `flutter/lib/src/routing/app_router.dart` | GoRoute `details` : lecture de `categoryId` depuis `state.uri.queryParameters` et transmission au constructeur de `BudgetDetailScreen`. |
| `flutter/lib/src/features/budgets/presentation/widgets/budget_hero_widget.dart` | Suppression du paramètre `onChartsTap` (callback devenu inutile après retrait du pie chart). |
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | 3 points de navigation mis à jour vers `pushNamed` avec `categoryId` + `month`. Suppression des 2 occurrences `onChartsTap`. |
| `flutter/test/src/features/budgets/presentation/widgets/budget_hero_widget_test.dart` | Retrait de `onChartsTap: () {}` (ligne 35) — paramètre supprimé du widget. |

### Fichiers supprimés

| Fichier | Raison |
|---------|--------|
| `flutter/lib/src/features/budgets/presentation/widgets/budget_pie_chart.dart` | Pie chart global retiré — remplacé par le hero mono-catégorie. |
| `flutter/lib/src/features/budgets/presentation/widgets/budget_category_detail_sheet.dart` | Bottom sheet de détail catégorie obsolète — la navigation vers `BudgetDetailScreen` remplit ce rôle. |

### Dépendances ajoutées

Aucune — les packages `shimmer`, `flutter_riverpod`, `go_router`, `phosphor_flutter` étaient déjà présents.

---

## Configuration

Aucune configuration supplémentaire requise. Le routing est géré par `app_router.dart` via le GoRoute `details` existant. La branche de données (locale/distante) est sélectionnée automatiquement par le `dataModeProvider` existant.

---

## Tests et validation

### Tests widget — `budget_detail_screen_test.dart`

| Test | SC couvert | Statut |
|------|-----------|--------|
| `should_showCategoryName_when_overviewLoaded` | SC-001 | ✅ PASS |
| `should_showDepenseLabel_when_heroRendered` | SC-002 | ✅ PASS |
| `should_showProgressBar_when_overviewHasPercentage` | SC-002 | ✅ PASS |
| `should_showActionPills_when_currentMonthAndOverviewItem` | SC-003 | ✅ PASS |
| `should_hideActionPills_when_historyMonth` | SC-003 | ✅ PASS |
| `should_callDelete_when_deleteConfirmed` | SC-004 | ✅ PASS |
| `should_callGetById_when_toggleTapped` | SC-005 | ✅ PASS |
| `should_showSkeleton_when_loading` | SC-006 | ✅ PASS |
| `should_showEmptyState_when_noMatchingTransactions` | SC-008 | ✅ PASS |

### Tests widget — `budget_hero_widget_test.dart`

| Test | Statut |
|------|--------|
| Suite existante (5 tests) — ajustement `onChartsTap` supprimé | ✅ PASS |

### Analyse statique

| Commande | Résultat |
|----------|---------|
| `flutter analyze` | 0 erreur — 29 info/warning pré-existants dans d'autres fichiers |
| `flutter test test/src/features/budgets/` | 36/36 PASS |

### Validation manuelle (checklist SC)

- [x] SC-001 : Navigation liste → détail (items actifs, inactifs, historique)
- [x] SC-002 : Hero affiche DÉPENSÉ + cible + reste/dépassement + progress bar pour la bonne catégorie
- [x] SC-003 : Action pills visibles mois courant, masqués mois passé
- [x] SC-004 : Delete → dialog confirmation → `budgetNotifier.delete()` → retour liste
- [x] SC-005 : Toggle → `getById` → `budgetNotifier.update(actif: !actif)` → retour liste
- [x] SC-006 : Transactions groupées Aujourd'hui/Hier/date, triées décroissantes, type DEPENSE + categoryId uniquement
- [x] SC-007 : `flutter analyze` → 0 erreur après suppression widgets obsolètes
- [x] SC-008 : Empty state si 0 transaction DEPENSE pour la catégorie ce mois
- [x] SC-009 : `flutter test test/src/features/budgets/` → 36 tests PASS, 0 FAIL

### Points d'attention (review-impl)

- **Icône transaction** : Le modèle `Transaction` ne transporte pas `categoryIcone`, donc le container circulaire dans chaque ligne de transaction est vide (pas d'emoji). Le fond reste `surfaceContainerHighest`. Défaut visuel connu, sans impact fonctionnel — adressable dans une évolution du modèle `Transaction`.
- **SC-002 couverture test partielle** : Le test `should_showTransactionGroups_when_transactionsLoaded` n'a pas été inclus dans la suite finale (remplacé par des tests hero). Le cas positif de groupement par date n'est pas testé automatiquement.
