# Data Model: 078-angular-debt-enhancements

## Interfaces TypeScript (modifications)

### Debt (enrichi)

```typescript
// app/src/app/core/models/debt.model.ts
export interface Debt {
  id: string;
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  dueDate: string | null;           // NEW
  currency: string;
  rembourse: boolean;
  montantRestant: number;            // NEW — montant - somme paiements
  category: Category | null;
  account: AccountSummary | null;    // NEW — compte associé
  includeInBalance: boolean;         // NEW
  reminderDate: string | null;       // NEW — format yyyy-MM-dd
  reminderTime: string | null;       // NEW — format HH:mm
}
```

### DebtRequest (enrichi)

```typescript
export interface DebtRequest {
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  rembourse?: boolean;
  categoryId?: string;
  currency?: string;
  accountId?: string | null;         // NEW
  includeInBalance?: boolean;        // NEW
  reminderDate?: string | null;      // NEW
  reminderTime?: string | null;      // NEW
}
```

### AccountSummary (nouveau)

```typescript
// app/src/app/core/models/debt.model.ts (ou account.model.ts)
export interface AccountSummary {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
  currency: string;
}
```

### DebtRepayRequest (nouveau)

```typescript
export interface DebtRepayRequest {
  accountId: string;
  amount?: number;   // Si absent, rembourse le montantRestant total
}
```

### DebtPaymentResponse (nouveau)

```typescript
export interface DebtPaymentResponse {
  id: string;
  amount: number;
  date: string;
  accountName: string;
}
```

### DebtSnoozeRequest (nouveau)

```typescript
export interface DebtSnoozeRequest {
  reminderDate: string;   // yyyy-MM-dd, futur ou aujourd'hui
  reminderTime: string;   // HH:mm
}
```

### NotificationType (enrichi)

```typescript
// app/src/app/core/models/notification.model.ts
export type NotificationType = 'SUBSCRIPTION_DUE' | 'DEBT_DUE' | 'DEBT_REMINDER' | 'BUDGET_THRESHOLD' | 'BUDGET_EXCEEDED';
```

### Toast (nouveau)

```typescript
// app/src/app/shared/components/toast/toast.service.ts
export type ToastType = 'success' | 'error' | 'info';

export interface Toast {
  id: number;
  type: ToastType;
  message: string;
}
```

## State Transitions

### Dette — Cycle de remboursement

```
ACTIVE (montantRestant > 0, rembourse = false)
  ├── repay(partiel) → ACTIVE (montantRestant diminue)
  └── repay(total)   → REMBOURSÉ (montantRestant = 0, rembourse = true)
```

### Dette — Rappel

```
SANS_RAPPEL (reminderDate = null)
  └── set reminder → AVEC_RAPPEL (reminderDate + reminderTime définis)

AVEC_RAPPEL
  ├── snooze → AVEC_RAPPEL (nouvelles date/heure)
  └── clear  → SANS_RAPPEL (via édition formulaire)
```

## Relations

```
Debt 1 ──── 0..1 Account (accountId, optionnel)
Debt 1 ──── 0..* DebtPayment (via GET /debts/{id}/payments)
Debt 1 ──── 0..1 Category (categoryId)
Notification * ──── 0..1 Debt (entityType=DEBT, entityId=debt.id)
```
