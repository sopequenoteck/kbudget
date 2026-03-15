# Data Model: Transactions récurrentes & améliorations abonnements

**Feature**: 089-recurring-transactions (consolidée)
**Date**: 2026-03-15
**Status**: Done (rétroactive)

## Entités modifiées

### Transaction (enrichie)

| Champ | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| isRecurring | BOOLEAN | Non | false | Indique si la transaction est un "template" récurrent |
| frequency | VARCHAR(10) | Oui | null | HEBDOMADAIRE, MENSUEL, ANNUEL |
| nextOccurrence | DATE | Oui | null | Prochaine date d'échéance |
| recurringActive | BOOLEAN | Non | true | Si false, la récurrence est désactivée |
| subscription_id | UUID (FK) | Oui | null | Référence vers l'abonnement source (traçabilité paiements) |

**Contraintes** :
- Si `isRecurring = true`, alors `frequency` et `nextOccurrence` sont obligatoires
- Les transactions "templates" (isRecurring=true) ne sont PAS retournées par GET /transactions standard
- `subscription_id` est renseigné uniquement pour les transactions créées via POST /subscriptions/{id}/pay

**Relations ajoutées** :
- Transaction → Subscription (ManyToOne, nullable) via subscription_id
- Transaction → Product (ManyToOne, nullable) via product_id (existait déjà conceptuellement, formalisé)
- Transaction → Debt (ManyToOne, nullable) via debt_id (existait déjà conceptuellement, formalisé)

### Subscription (inchangée)

Aucune modification de la table. Les paiements sont tracés via les transactions liées (subscription_id sur Transaction).

**Requêtes dérivées** :
- `GET /subscriptions/{id}/payments` → `SELECT * FROM transactions WHERE subscription_id = ? AND user_id = ? ORDER BY date DESC`
- `GET /subscriptions/{id}/payments/total` → `SELECT COUNT(*) FROM transactions WHERE subscription_id = ? AND user_id = ?`

### Notification (enrichie)

**Nouveaux types** :
- `NotificationType.RECURRING_TRANSACTION_DUE` — notification d'échéance de récurrence
- `NotificationType.SUBSCRIPTION_DUE` — notification d'échéance d'abonnement (existait, formalisé)

**Nouveaux entity types** :
- `EntityType.RECURRING_TRANSACTION`
- `EntityType.BUDGET`
- `EntityType.TRANSACTION`

## Migration Flyway V20

```sql
-- Enrichissement de la table transactions pour les récurrences
ALTER TABLE transactions ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE transactions ADD COLUMN frequency VARCHAR(10);
ALTER TABLE transactions ADD COLUMN next_occurrence DATE;
ALTER TABLE transactions ADD COLUMN recurring_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE transactions ADD COLUMN subscription_id UUID REFERENCES subscriptions(id);
```

## Diagramme de relations

```
User (1) ──── (N) Transaction
                    ├── isRecurring = true  → "template" récurrent (non visible dans listings standard)
                    ├── isRecurring = false → transaction classique
                    ├── subscription_id FK ──→ Subscription (traçabilité paiement)
                    ├── product_id FK ──→ Product (vente/achat)
                    └── debt_id FK ──→ Debt (remboursement)

User (1) ──── (N) Subscription
                    └── (via subscription_id sur Transaction) ──→ historique paiements

User (1) ──── (N) Notification
                    ├── type = RECURRING_TRANSACTION_DUE
                    │   └── entityType = RECURRING_TRANSACTION, entityId = transaction.id
                    └── type = SUBSCRIPTION_DUE
                        └── entityType = SUBSCRIPTION, entityId = subscription.id
```

## Modèles Flutter (Freezed)

### RecurringTransaction

Réutilise le modèle Transaction existant avec les champs enrichis. Pas de modèle séparé — filtrés par isRecurring=true côté API.

### SubscriptionPayment

```dart
@freezed
class SubscriptionPayment with _$SubscriptionPayment {
  const factory SubscriptionPayment({
    required String id,
    required double amount,
    required DateTime date,
    String? accountName,
  }) = _SubscriptionPayment;
}
```

## Modèles Angular

### RecurringTransactionResponse

Interface TypeScript miroir du DTO backend (libellé, montant, type, fréquence, nextOccurrence, catégorie, compte).

### RecurringTransactionRequest

Interface pour POST /transactions/recurring (libellé, montant, type, fréquence, nextOccurrence, categoryId, accountId).
