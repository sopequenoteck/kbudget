# Data Model: 086-angular-recurring-transactions

**Date**: 2026-03-15

## Modèles Angular (interfaces TypeScript)

### RecurringTransactionResponse (NOUVEAU)

```typescript
interface RecurringTransactionResponse {
  id: string;
  montant: number;
  libelle: string;
  type: TransactionType;       // DEPENSE | RECETTE
  frequency: Frequency;        // HEBDOMADAIRE | MENSUEL | ANNUEL
  nextOccurrence: string;      // ISO date (yyyy-MM-dd)
  recurringActive: boolean;
  category: CategoryResponse;
  account: AccountSummary;
}
```

**Relation backend**: Miroir exact de `RecurringTransactionResponse.java`.

### SubscriptionPaymentResponse (NOUVEAU)

```typescript
interface SubscriptionPaymentResponse {
  id: string;
  montant: number;
  date: string;                // ISO date (yyyy-MM-dd)
  subscriptionName: string;
  accountName: string;
}
```

**Relation backend**: Miroir exact de `SubscriptionPaymentResponse.java`.

### Transaction (UPDATE)

Champs ajoutés au modèle existant :

```typescript
// Champs existants conservés (id, montant, libelle, type, date, category, note, account, transferId)
// Ajouts :
isRecurring?: boolean;
frequency?: Frequency;
nextOccurrence?: string;
recurringActive?: boolean;
subscriptionId?: string;
```

### NotificationType (UPDATE)

```typescript
// Avant :
type NotificationType = 'SUBSCRIPTION_DUE' | 'DEBT_DUE' | 'DEBT_REMINDER' | 'BUDGET_THRESHOLD' | 'BUDGET_EXCEEDED';

// Après :
type NotificationType = 'SUBSCRIPTION_DUE' | 'DEBT_DUE' | 'DEBT_REMINDER' | 'BUDGET_THRESHOLD' | 'BUDGET_EXCEEDED' | 'RECURRING_TRANSACTION_DUE';
```

### EntityType (UPDATE)

```typescript
// Avant :
type EntityType = 'SUBSCRIPTION' | 'DEBT';

// Après :
type EntityType = 'SUBSCRIPTION' | 'DEBT' | 'RECURRING_TRANSACTION';
```

## États dérivés (computed)

### RecurringListComponent

```typescript
// Statut badge calculé depuis nextOccurrence
type RecurringStatus = 'overdue' | 'today' | 'upcoming';

// Tri : overdue first, then today, then upcoming, then by date ASC within group
```

### SubscriptionDetailComponent

```typescript
// Total cumulé = somme des montants de SubscriptionPaymentResponse[]
// Nombre de paiements = payments.length
```

## Relations entre modèles

```
RecurringTransactionResponse
  ├── category: CategoryResponse (existant)
  └── account: AccountSummary (existant)

SubscriptionPaymentResponse
  └── (standalone — subscriptionName et accountName dénormalisés)

Notification
  ├── entityType: 'RECURRING_TRANSACTION' → entityId = recurring transaction ID
  └── entityType: 'SUBSCRIPTION' → entityId = subscription ID
```
