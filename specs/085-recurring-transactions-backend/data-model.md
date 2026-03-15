# Data Model: Transactions Recurrentes & Paiements Abonnements (Backend)

**Date**: 2026-03-14 | **Branch**: `085-recurring-transactions-backend`

## Migration Flyway V20

### Enrichissement table `transactions`

```sql
-- V20__add_recurring_to_transactions.sql

ALTER TABLE transactions ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE transactions ADD COLUMN frequency VARCHAR(20);
ALTER TABLE transactions ADD COLUMN next_occurrence DATE;
ALTER TABLE transactions ADD COLUMN recurring_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE transactions ADD COLUMN subscription_id UUID REFERENCES subscriptions(id);

-- Index pour le scheduler (recurrences actives par user)
CREATE INDEX idx_transactions_recurring_active
    ON transactions (user_id, next_occurrence)
    WHERE is_recurring = true AND recurring_active = true;

-- Index pour les paiements d'abonnements
CREATE INDEX idx_transactions_subscription_id
    ON transactions (subscription_id)
    WHERE subscription_id IS NOT NULL;
```

## Entites

### Transaction (enrichie)

| Champ | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `isRecurring` | Boolean | Non | `false` | Marque la transaction comme recurrente |
| `frequency` | Frequency (enum) | Oui | `null` | Frequence de recurrence (HEBDOMADAIRE, MENSUEL, ANNUEL) |
| `nextOccurrence` | LocalDate | Oui | `null` | Date de la prochaine echeance |
| `recurringActive` | Boolean | Non | `true` | Si la recurrence est encore active |
| `subscription` | Subscription (FK) | Oui | `null` | Lien vers l'abonnement source (pour les paiements) |

**Contraintes**:
- Si `isRecurring = true` alors `frequency` et `nextOccurrence` DOIVENT etre non-null
- Si `isRecurring = false` alors `frequency`, `nextOccurrence` et `recurringActive` sont ignores
- `subscription_id` est independant de `isRecurring` — une transaction peut etre un paiement d'abonnement sans etre recurrente

**Relations**:
- `subscription` : ManyToOne → Subscription (FetchType.LAZY, nullable)
- Autres relations existantes inchangees (account, category, user, product, debt)

### Subscription (inchangee)

Aucune modification. Les paiements sont traces via `Transaction.subscriptionId`.

### Notification (inchangee)

Aucune modification structurelle. Deux nouveaux types utilises :
- `NotificationType.RECURRING_TRANSACTION_DUE` (nouveau)
- `NotificationType.SUBSCRIPTION_DUE` (existant, pour les paiements d'abonnements via scheduler existant)

## Enums modifies

### NotificationType

Ajout : `RECURRING_TRANSACTION_DUE`

Valeurs finales : `SUBSCRIPTION_DUE`, `DEBT_DUE`, `BUDGET_THRESHOLD`, `BUDGET_EXCEEDED`, `DEBT_REMINDER`, `RECURRING_TRANSACTION_DUE`

### EntityType

Ajout : `TRANSACTION`

Valeurs finales : `SUBSCRIPTION`, `DEBT`, `BUDGET`, `TRANSACTION`

## Queries Repository additionnelles

### TransactionRepository

```java
// Recurrences actives pour un user
List<Transaction> findByUserIdAndIsRecurringTrueAndRecurringActiveTrueOrderByNextOccurrenceAsc(UUID userId);

// Recurrences actives avec echeance <= date pour un user (pour le scheduler)
List<Transaction> findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(UUID userId, LocalDate date);

// Paiements lies a un abonnement
List<Transaction> findBySubscriptionIdAndUserIdOrderByDateDesc(UUID subscriptionId, UUID userId);

// Cumul des paiements d'un abonnement
@Query("SELECT COALESCE(SUM(t.montant), 0) FROM Transaction t WHERE t.subscription.id = :subscriptionId AND t.user.id = :userId")
BigDecimal sumBySubscriptionIdAndUserId(@Param("subscriptionId") UUID subscriptionId, @Param("userId") UUID userId);
```

## Diagramme de flux

### Validation d'une recurrence

```
User → POST /transactions/recurring/{id}/validate
  → RecurringTransactionService.validate(id, userId)
    → Charger transaction recurrente (verifier isRecurring=true, recurringActive=true, user)
    → Creer nouvelle Transaction (copie montant/libelle/type/category/account, date=today)
    → Avancer nextOccurrence selon frequency
    → Sauvegarder les deux transactions
    → Retourner TransactionResponse (la nouvelle transaction)
```

### Paiement d'un abonnement

```
User → POST /subscriptions/{id}/pay
  → SubscriptionPaymentService.pay(subscriptionId, userId)
    → Charger subscription (verifier actif=true, user)
    → Resoudre le compte (subscription.account ?? default account)
    → Creer Transaction (type=DEPENSE, montant=sub.montant, libelle=sub.nom, subscriptionId=sub.id)
    → (dateDebut inchangee — prochaine echeance calculee dynamiquement par getNextDueDate())
    → Sauvegarder transaction
    → Retourner SubscriptionPaymentResponse
```

### Scheduler recurrences (quotidien)

```
@Scheduled(cron = "0 0 8 * * *")
  → Pour chaque user :
    → Si RECURRING_TRANSACTION_DUE enabled :
      → Trouver recurrences actives avec nextOccurrence <= today
      → Pour chaque : verifier dedup 24h, creer notification
    → Si SUBSCRIPTION_DUE enabled (existant, inchange) :
      → [comportement existant : notification la veille]
```
