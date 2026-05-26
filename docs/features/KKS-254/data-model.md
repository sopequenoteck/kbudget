# Data Model — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

> Feature purement présentationnelle + provider additionnel. Aucun nouveau modèle Freezed, aucune migration Drift, aucun nouveau DTO réseau.

---

## Entités impliquées (lecture seule)

### `BudgetOverviewItem`

**Fichier** : `flutter/lib/src/domain/models/budget_overview.dart`  
**Usage** : Source principale de données du hero (mois courant)

| Champ | Type | Usage dans l'écran |
|-------|------|--------------------|
| `budgetId` | `String?` | Clé pour actions (delete/toggle/edit) — null si budget inactif |
| `categoryId` | `String` | Clé de navigation + filtrage transactions |
| `categoryNom` | `String` | Titre AppBar + hero |
| `categoryIcone` | `String` | Icône AppBar |
| `categoryCouleur` | `String` | Couleur badge catégorie |
| `montantBudget` | `double` | Cible dans la méta-ligne |
| `montantBudgetNormalise` | `double` | Cible normalisée (multi-devise, hors scope V1) |
| `currency` | `Currency` | Devise affichée dans le hero |
| `montantDepense` | `double` | Montant principal du hero |
| `percentage` | `double` | Progress bar (0–n, dépassement > 1.0) |
| `frequence` | `String` | Label fréquence dans la méta-ligne |

> Note : `actif` est **absent** de ce modèle. Traité comme `true` par défaut. Valeur réelle lue via `budgetRepository.getById()` avant toggle/edit.

---

### `Budget`

**Fichier** : `flutter/lib/src/domain/models/budget.dart`  
**Usage** : Entité complète retournée par `getById()` — nécessaire pour toggle et edit

| Champ | Type | Usage dans l'écran |
|-------|------|--------------------|
| `id` | `String` | Identifiant pour update/delete |
| `actif` | `bool` | Valeur fraîche pour toggle (lue après `getById`) |
| `category` | `Category` | Nom + icône (fallback si overview absent) |
| Autres champs | — | Passés à `modalNotifier.open(entity: budget)` pour l'édition |

---

### `Transaction`

**Fichier** : `flutter/lib/src/domain/models/transaction.dart`  
**Usage** : Liste des dépenses de la catégorie, filtrée et groupée

| Champ | Type | Usage dans l'écran |
|-------|------|--------------------|
| `categoryId` | `String?` | Filtre : `== widget.categoryId` |
| `type` | `TransactionType` | Filtre : `== TransactionType.depense` |
| `date` | `DateTime` | Tri décroissant + groupement (Aujourd'hui/Hier/date) |
| `libelle` | `String` | Libellé de la ligne transaction |
| `montant` | `double` | Montant affiché |
| `accountId` | `String?` | Résolution devise via `Account.currency` |

> Modèle plat — pas d'objet `category` ou `account` imbriqué (écart E-001 et E-002 avec Angular).

---

### `Account`

**Fichier** : `flutter/lib/src/domain/models/account.dart`  
**Usage** : Résolution devise par transaction (RES-007)

| Champ | Type | Usage dans l'écran |
|-------|------|--------------------|
| `id` | `String` | Clé de correspondance avec `tx.accountId` |
| `currency` | `Currency` | Devise affichée pour la transaction |

---

## Nouveau provider — `budgetTransactionsProvider`

**Fichier** : `flutter/lib/src/features/budgets/application/budget_transactions_provider.dart`  
**Type** : `FutureProvider.family` (pas un modèle — provider de données)

```dart
final budgetTransactionsProvider =
    FutureProvider.family<List<Transaction>, ({int month, int year})>(
  (ref, params) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getByMonth(params.month, params.year);
  },
);
```

**Pattern** : identique à `debtPaymentsProvider` et `subscriptionPaymentsProvider`  
**Filtrage** : côté widget (categoryId + type DEPENSE) — pas dans le provider  
**Paramètre** : record Dart `({int month, int year})` — compatible Riverpod `.family`

---

## Entités non modifiées

| Entité | Fichier | Statut |
|--------|---------|--------|
| `BudgetOverviewItem` | `domain/models/budget_overview.dart` | Lu, non modifié |
| `Budget` | `domain/models/budget.dart` | Lu via `getById()`, non modifié |
| `Transaction` | `domain/models/transaction.dart` | Lu, non modifié |
| `Account` | `domain/models/account.dart` | Lu, non modifié |

## Schéma Drift

Aucune migration requise. Aucun nouveau champ, aucune nouvelle table.

## Backend

Aucun endpoint nouveau. Endpoints existants utilisés :
- `GET /api/budgets/overview?month=YYYY-MM` → `BudgetOverviewItem[]`
- `GET /api/budgets/{id}` → `Budget` (pour toggle/edit)
- `GET /api/transactions?month=M&year=Y` → `Transaction[]`
- `GET /api/accounts` → `Account[]`
