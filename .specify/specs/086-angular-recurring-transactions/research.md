# Research: 086-angular-recurring-transactions

**Date**: 2026-03-15

## Résumé

Aucun NEEDS CLARIFICATION identifié dans le Technical Context. Recherche focalisée sur les patterns existants du codebase et l'alignement avec les endpoints backend KKS-085.

## R1: Endpoints backend disponibles (KKS-085)

**Decision**: Consommer les endpoints existants sans modification backend.

**Rationale**: Les 8 endpoints couvrent tous les besoins de la spec.

**Endpoints récurrences** (RecurringTransactionController):
- `POST /api/transactions/recurring` → crée une récurrence → `RecurringTransactionResponse`
- `GET /api/transactions/recurring` → liste les récurrences actives → `List<RecurringTransactionResponse>`
- `POST /api/transactions/recurring/{id}/validate` → valide (crée transaction) → `TransactionResponse`
- `PATCH /api/transactions/recurring/{id}/skip` → passe l'occurrence → `RecurringTransactionResponse`
- `PATCH /api/transactions/recurring/{id}/deactivate` → désactive → `RecurringTransactionResponse`

**Endpoints paiements abonnements** (SubscriptionController):
- `POST /api/subscriptions/{id}/pay` → paye → `SubscriptionPaymentResponse`
- `GET /api/subscriptions/{id}/payments` → historique → `List<SubscriptionPaymentResponse>`
- `GET /api/subscriptions/{id}/payments/total` → cumul → `Map<String, Object>` (clés: `total`, `count`)

**Alternatives considered**: Aucune — endpoints déjà implémentés et testés (488 tests backend).

## R2: Pattern service Angular (signal-based)

**Decision**: Créer `RecurringTransactionService` suivant le pattern `TransactionService` existant.

**Rationale**: Le pattern signal-based avec `refreshTrigger` + `tap(() => this.refresh())` est le standard du projet. Tous les services existants (TransactionService, SubscriptionService, DebtService) suivent ce pattern.

**Pattern identifié**:
```typescript
// Signals
recurringTransactions = signal<RecurringTransactionResponse[]>([]);
loading = signal(false);
error = signal<string | null>(null);
refreshTrigger = signal(0);

// Methods retournent Observable, tapent pour rafraîchir
validate(id: string): Observable<TransactionResponse>
skip(id: string): Observable<RecurringTransactionResponse>
deactivate(id: string): Observable<RecurringTransactionResponse>
```

**Alternatives considered**: Store centralisé (NgRx) → rejeté (YAGNI, hors patterns projet).

## R3: Pattern composant détail (DebtDetail comme référence)

**Decision**: Suivre le pattern `DebtDetail` pour `SubscriptionDetail` et `RecurringList`.

**Rationale**: DebtDetail est le composant le plus similaire : route `:id`, chargement par ID, section historique (paiements), boutons d'action (rembourser/reporter), dialogs. Pattern éprouvé.

**Éléments réutilisés**:
- Route lazy-loaded avec `:id` paramètre
- Signals pour state (`loading`, `error`, `data`)
- `inject(ActivatedRoute)` + `input()` pour le paramètre route
- Back button avec `router.navigate(['/parent'])`
- ToastService pour feedback

**Alternatives considered**: Modal pour le détail abonnement → rejeté (trop de contenu : historique paiements + total + bouton payer).

## R4: Notification panel — pattern actions contextuelles

**Decision**: Enrichir le notification-panel existant avec `@if` conditionnel pour les types `RECURRING_TRANSACTION_DUE`.

**Rationale**: Le pattern existe déjà pour `DEBT_DUE`/`DEBT_REMINDER` (boutons Rembourser/Reporter). Même approche pour récurrences (Valider/Passer) et abonnements (Payer via `SUBSCRIPTION_DUE`).

**Pattern identifié**:
```html
@if (notification.type === 'RECURRING_TRANSACTION_DUE') {
  <button (click)="onValidateRecurring(notification)">Valider</button>
  <button (click)="onSkipRecurring(notification)">Passer</button>
}
```

**Alternatives considered**: Composant notification dédié par type → rejeté (over-engineering, le `@if` inline est le pattern existant).

## R5: Accès récurrences depuis l'écran Transactions

**Decision**: Ajouter un bouton/lien en haut de l'écran Transactions menant vers `/transactions/recurring`.

**Rationale**: Clarification spec : les récurrences font partie des Transactions, pas d'entrée séparée dans la sidebar. Un lien discret (icône + label) en haut de la liste est le moyen le plus simple.

**Alternatives considered**:
- Tab/segment control → rejeté (trop lourd, les récurrences sont une vue annexe, pas un filtre)
- FAB action → rejeté (le FAB sert à la création, pas à la navigation)

## R6: Modèle NotificationType Angular

**Decision**: Ajouter `'RECURRING_TRANSACTION_DUE'` au type union `NotificationType` et `'RECURRING_TRANSACTION'` au type union `EntityType`.

**Rationale**: Le backend (NotificationScheduler) génère déjà des notifications de ce type. L'Angular doit les reconnaître pour le rendu conditionnel et l'icône.

**Alternatives considered**: Aucune — alignement strict avec le backend.
