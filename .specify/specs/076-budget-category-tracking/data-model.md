# Data Model — 076-budget-category-tracking

## Entités existantes (inchangées en schéma)

### Budget
Aucune modification de schéma. L'entité et la table `budgets` restent identiques (KKS-073, Flyway V17).

### BudgetSnapshot
Aucune modification de schéma. La table `budget_snapshots` reste identique.

### Notification
Aucune modification de schéma. La table `notifications` est réutilisée avec les nouveaux types.

## Modifications d'enums

### NotificationType (Java)
```
+ BUDGET_THRESHOLD    // Seuil configuré atteint (ex: 80%)
+ BUDGET_EXCEEDED     // Budget dépassé (100%)
```

### EntityType (Java)
```
+ BUDGET              // Référence à l'entité Budget
```

## Nouveaux DTOs / Modèles

### UnbudgetedItem (réponse API)

Représente une catégorie sans budget avec ses dépenses du mois.

| Champ | Type | Description |
|-------|------|-------------|
| categoryId | UUID | ID de la catégorie |
| categoryNom | String | Nom de la catégorie |
| categoryIcone | String | Icône de la catégorie |
| categoryCouleur | String | Couleur de la catégorie |
| montantDepense | BigDecimal | Total dépensé dans cette catégorie pour le mois |

### BudgetOverviewResponse (enrichi)

Champs ajoutés :
| Champ | Type | Description |
|-------|------|-------------|
| unbudgetedItems | List\<UnbudgetedItem\> | Détail des catégories non budgétées |
| unbudgetedTotal | BigDecimal | Total des dépenses non budgétées (en devise principale) |

### BudgetHistoryResponse (enrichi)

Champs ajoutés :
| Champ | Type | Description |
|-------|------|-------------|
| unbudgetedItems | List\<UnbudgetedItem\> | Détail des catégories non budgétées pour ce mois |
| unbudgetedTotal | BigDecimal | Total des dépenses non budgétées pour ce mois |

## Modèles Flutter (Freezed)

### BudgetOverview (enrichi)
```dart
+ List<UnbudgetedItem> unbudgetedItems
+ double unbudgetedTotal
```

### BudgetHistory (enrichi)
```dart
+ List<UnbudgetedItem> unbudgetedItems
+ double unbudgetedTotal
```

### UnbudgetedItem (nouveau)
```dart
@freezed
class UnbudgetedItem with _$UnbudgetedItem {
  const factory UnbudgetedItem({
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantDepense,
  }) = _UnbudgetedItem;
}
```

## Modèles Angular (TypeScript)

### UnbudgetedItem (nouveau)
```typescript
export interface UnbudgetedItem {
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantDepense: number;
}
```

### BudgetOverview (enrichi)
```typescript
+ unbudgetedItems: UnbudgetedItem[];
+ unbudgetedTotal: number;
```

### BudgetHistory (enrichi)
```typescript
+ unbudgetedItems: UnbudgetedItem[];
+ unbudgetedTotal: number;
```

## Queries nouvelles

### TransactionRepository (Spring Data JPA)

```java
// Dépenses par catégorie non budgétée pour un mois donné
@Query("SELECT t.category.id, t.category.nom, t.category.icone, t.category.couleur, SUM(t.montant) " +
       "FROM Transaction t " +
       "WHERE t.user = :user AND t.type = 'DEPENSE' " +
       "AND t.date >= :startDate AND t.date < :endDate " +
       "AND t.category.id NOT IN (SELECT b.category.id FROM Budget b WHERE b.user = :user AND b.actif = true) " +
       "GROUP BY t.category.id, t.category.nom, t.category.icone, t.category.couleur")
```

### NotificationRepository (Spring Data JPA)

```java
// Vérifier si une notification de seuil existe déjà pour ce budget ce mois
boolean existsByTypeAndEntityTypeAndEntityIdAndCreatedAtBetween(
    NotificationType type, EntityType entityType, UUID entityId,
    LocalDateTime start, LocalDateTime end);
```

### BudgetDao (Drift — Flutter local)

```sql
-- Dépenses par catégorie non budgétée
SELECT c.id, c.nom, c.icone, c.couleur, SUM(t.montant) as total
FROM transactions t
JOIN categories c ON t.category_id = c.id
WHERE t.type = 'depense'
  AND t.date >= ? AND t.date < ?
  AND t.category_id NOT IN (SELECT category_id FROM budgets WHERE actif = 1)
GROUP BY c.id, c.nom, c.icone, c.couleur
```

## Relations

```
Budget ──1:N──> BudgetSnapshot (via category_id + user_id)
Budget ──N:1──> Category
Budget ──N:1──> User
Notification ──ref──> Budget (via entityType=BUDGET, entityId=budget.id)
Transaction ──trigger──> BudgetService.checkThresholds() (après CRUD)
```

## Flux de notification

```
TransactionService.create/update/delete(transaction DEPENSE)
  └─> BudgetService.checkThresholdsForCategory(userId, categoryId)
        ├─> Trouver le budget actif pour cette catégorie
        ├─> Calculer les dépenses du mois courant
        ├─> Si dépenses >= seuil% ET pas de notification BUDGET_THRESHOLD ce mois
        │     └─> NotificationService.create(BUDGET_THRESHOLD, BUDGET, budgetId, ...)
        └─> Si dépenses >= 100% ET pas de notification BUDGET_EXCEEDED ce mois
              └─> NotificationService.create(BUDGET_EXCEEDED, BUDGET, budgetId, ...)
```
