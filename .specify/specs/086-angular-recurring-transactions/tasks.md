# Tasks: Transactions récurrentes & abonnements — Angular

**Input**: Design documents from `/specs/086-angular-recurring-transactions/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/api-endpoints.md, research.md, quickstart.md

**Tests**: Inclus — la spec mentionne "Tests unitaires des composants et services" dans le scope.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

## Path Conventions

- **Frontend Angular**: `app/src/app/`
- **Models**: `app/src/app/core/models/`
- **Services**: `app/src/app/core/services/`
- **Features**: `app/src/app/features/`
- **Shared**: `app/src/app/shared/components/`

---

## Phase 1: Setup (Modèles & Types)

**Purpose**: Créer les interfaces TypeScript et mettre à jour les types existants pour supporter les récurrences et paiements.

- [x] T001 [P] Créer l'interface `RecurringTransactionResponse` dans `app/src/app/core/models/recurring-transaction.model.ts` — champs: id, montant, libelle, type (TransactionType), frequency (Frequency), nextOccurrence (string), recurringActive (boolean), category (CategoryResponse), account (AccountSummary)
- [x] T002 [P] Créer l'interface `SubscriptionPaymentResponse` dans `app/src/app/core/models/subscription-payment.model.ts` — champs: id, montant, date (string), subscriptionName, accountName
- [x] T003 [P] Mettre à jour `app/src/app/core/models/notification.model.ts` — ajouter `'RECURRING_TRANSACTION_DUE'` au type union `NotificationType` et `'RECURRING_TRANSACTION'` au type union `EntityType`

---

## Phase 2: Foundational (Services)

**Purpose**: Créer et enrichir les services Angular qui seront utilisés par toutes les user stories.

**CRITICAL**: Les user stories dépendent de cette phase.

- [x] T004 Créer `RecurringTransactionService` (signal-based) dans `app/src/app/core/services/recurring-transaction.ts` — signals: recurringTransactions, loading, error, refreshTrigger — méthodes: loadActive() GET, validate(id) POST /{id}/validate, skip(id) PATCH /{id}/skip, deactivate(id) PATCH /{id}/deactivate — pattern: tap(() => this.refresh()) sur les mutations, comme TransactionService existant
- [x] T005 Enrichir `SubscriptionService` dans `app/src/app/core/services/subscription.ts` — ajouter 3 méthodes: pay(id): Observable\<SubscriptionPaymentResponse\> POST /{id}/pay, getPayments(id): Observable\<SubscriptionPaymentResponse[]\> GET /{id}/payments, getTotalPaid(id): Observable\<Map\> GET /{id}/payments/total

**Checkpoint**: Services prêts — l'implémentation des user stories peut commencer.

---

## Phase 3: User Story 1 — Consulter et agir sur les récurrences (Priority: P1) MVP

**Goal**: L'utilisateur accède à `/transactions/recurring`, voit la liste triée par statut (En retard > Aujourd'hui > À venir), et peut valider/passer/désactiver chaque récurrence.

**Independent Test**: Accéder à `/transactions/recurring`, vérifier l'affichage avec badges, exécuter les 3 actions et vérifier les toasts de feedback.

### Implementation for User Story 1

- [x] T006 [US1] Ajouter la route `recurring` (lazy-loaded) dans `app/src/app/features/transactions/transactions.routes.ts` — loadComponent vers RecurringListComponent
- [x] T007 [US1] Créer `RecurringListComponent` (standalone, OnPush) dans `app/src/app/features/transactions/components/recurring-list/recurring-list.ts` — inject RecurringTransactionService + ToastService + Router — signals: computed sortedRecurringTransactions (tri par statut: overdue > today > upcoming, puis date ASC) — computed getStatus(nextOccurrence): 'overdue' | 'today' | 'upcoming' — méthodes: onValidate(id), onSkip(id), onDeactivate(id) avec disable du bouton pendant l'appel, confirmation dialog pour désactiver — état vide si aucune récurrence — back button vers /transactions
- [x] T008 [US1] Créer le template `app/src/app/features/transactions/components/recurring-list/recurring-list.html` — liste @for avec: icône catégorie, libellé, montant formaté, fréquence (Hebdo/Mensuel/Annuel), prochaine date — badge coloré: "En retard" (rouge/--color-error), "Aujourd'hui" (orange/--color-warning), "À venir" (gris/--text-secondary) — boutons d'action par item: Valider (primary), Passer (secondary), Désactiver (danger, avec confirmation) — état vide avec message "Aucune transaction récurrente" — loading state — responsive mobile-first
- [x] T009 [US1] Créer les styles `app/src/app/features/transactions/components/recurring-list/recurring-list.scss` — design tokens uniquement (var(--token)), badges statut, layout liste, boutons actions, responsive < 768px
- [x] T010 [US1] Ajouter un lien/bouton vers `/transactions/recurring` dans le template Transactions existant `app/src/app/features/transactions/transactions.html` — icône Phosphor (phosphorRepeat) + label "Récurrences", positionné en haut de l'écran

### Tests for User Story 1

- [x] T011 [P] [US1] Tests unitaires RecurringTransactionService dans `app/src/app/core/services/recurring-transaction.spec.ts` — tester: loadActive, validate, skip, deactivate, refresh après mutation
- [x] T012 [P] [US1] Tests unitaires RecurringListComponent dans `app/src/app/features/transactions/components/recurring-list/recurring-list.spec.ts` — tester: affichage liste, tri par statut, badges, actions avec toast, état vide, disable bouton pendant appel

**Checkpoint**: L'écran des récurrences est fonctionnel et testable indépendamment. MVP livrable.

---

## Phase 4: User Story 2 — Paiements et détail abonnement (Priority: P2)

**Goal**: L'utilisateur accède au détail d'un abonnement, voit l'historique des paiements avec total cumulé, et peut payer à tout moment.

**Independent Test**: Accéder au détail d'un abonnement, vérifier l'historique des paiements, le total cumulé, et utiliser le bouton Payer.

### Implementation for User Story 2

- [x] T013 [US2] Ajouter la route `:id` (lazy-loaded) dans `app/src/app/features/subscriptions/subscriptions.routes.ts` — loadComponent vers SubscriptionDetailComponent, pattern identique à debts.routes.ts
- [x] T014 [US2] Créer `SubscriptionDetailComponent` (standalone, OnPush) dans `app/src/app/features/subscriptions/components/subscription-detail/subscription-detail.ts` — inject ActivatedRoute, SubscriptionService, ToastService, Router, ModalService — signals: subscription, payments, totalPaid, loading, paymentsLoading, payInProgress — charger subscription par id + payments + total au init — méthode onPay(): appelle pay(id), toast succès, rafraîchit payments et total — méthode onEdit(): ouvre modal subscription — back button vers /subscriptions
- [x] T015 [US2] Créer le template `app/src/app/features/subscriptions/components/subscription-detail/subscription-detail.html` — header: nom abonnement, montant, fréquence, statut (actif/inactif), catégorie, compte — section total cumulé: montant total + nombre de paiements — bouton "Payer" toujours visible (disable pendant payInProgress) — section historique paiements: liste date + montant, trié par date DESC — état vide "Aucun paiement" si pas de paiements — loading states (subscription + payments) — responsive mobile-first
- [x] T016 [US2] Créer les styles `app/src/app/features/subscriptions/components/subscription-detail/subscription-detail.scss` — design tokens, layout détail, section paiements, bouton payer, responsive
- [x] T017 [US2] Modifier le click handler dans `app/src/app/features/subscriptions/subscriptions.ts` — au lieu d'ouvrir le modal, naviguer vers `/subscriptions/${subscription.id}` pour accéder au détail

### Tests for User Story 2

- [x] T018 [P] [US2] Tests unitaires SubscriptionService (méthodes paiement) dans `app/src/app/core/services/subscription.spec.ts` — tester: pay, getPayments, getTotalPaid
- [x] T019 [P] [US2] Tests unitaires SubscriptionDetailComponent dans `app/src/app/features/subscriptions/components/subscription-detail/subscription-detail.spec.ts` — tester: affichage détail, historique paiements, total cumulé, bouton payer, état vide, navigation retour

**Checkpoint**: Le détail abonnement avec paiements est fonctionnel et testable indépendamment.

---

## Phase 5: User Story 3 — Actions depuis les notifications (Priority: P3)

**Goal**: L'utilisateur peut valider/passer une récurrence et payer un abonnement directement depuis le panneau de notifications, et naviguer vers l'écran concerné en tapant sur la notification.

**Independent Test**: Ouvrir le panneau de notifications avec des notifications récurrence/abonnement, vérifier les boutons d'action et la navigation au tap.

### Implementation for User Story 3

- [x] T020 [US3] Mettre à jour l'icône mapping dans `app/src/app/shared/components/notification-panel/notification-panel.ts` — ajouter l'icône pour `RECURRING_TRANSACTION_DUE` dans getIconForType() (phosphorRepeat) — inject RecurringTransactionService et SubscriptionService (si pas déjà injecté) — méthodes: onValidateRecurring(notification), onSkipRecurring(notification), onPaySubscription(notification) avec toast feedback — méthode onNotificationTap(notification): si RECURRING_TRANSACTION_DUE → navigate /transactions/recurring, si SUBSCRIPTION_DUE → navigate /subscriptions/{entityId}
- [x] T021 [US3] Mettre à jour le template `app/src/app/shared/components/notification-panel/notification-panel.html` — ajouter bloc @if pour RECURRING_TRANSACTION_DUE: boutons "Valider" et "Passer" (pattern identique à DEBT_DUE) — ajouter bloc @if pour SUBSCRIPTION_DUE: bouton "Payer" — ajouter (click) sur le corps de la notification pour navigation vers l'écran concerné — disable boutons pendant l'appel

### Tests for User Story 3

- [x] T022 [US3] Tests unitaires notification-panel (enrichissement) dans `app/src/app/shared/components/notification-panel/notification-panel.spec.ts` — tester: affichage boutons pour RECURRING_TRANSACTION_DUE, affichage bouton Payer pour SUBSCRIPTION_DUE, navigation au tap, appels service, toasts

**Checkpoint**: Toutes les user stories sont fonctionnelles et testables indépendamment.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et nettoyage.

- [x] T023 Vérifier le responsive mobile (< 768px) sur RecurringListComponent et SubscriptionDetailComponent — tester sur viewport mobile, ajuster les styles si nécessaire
- [x] T024 Vérifier la cohérence des design tokens utilisés (couleurs badges, spacing, typographie) avec `docs/design-tokens.md`
- [x] T025 Run `cd app && ng build` pour vérifier la compilation sans erreurs
- [x] T026 Run `cd app && ng test` pour vérifier que tous les tests passent

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — peut démarrer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (modèles nécessaires pour les services)
- **US1 (Phase 3)**: Dépend de Phase 2 (RecurringTransactionService)
- **US2 (Phase 4)**: Dépend de Phase 2 (SubscriptionService enrichi) — indépendant de US1
- **US3 (Phase 5)**: Dépend de Phase 2 (services créés/enrichis) — les routes cibles (`/transactions/recurring`, `/subscriptions/:id`) doivent exister pour la navigation, donc idéalement après US1/US2 mais non bloquant pour l'implémentation
- **Polish (Phase 6)**: Dépend de toutes les user stories complétées

### User Story Dependencies

- **US1 (P1)**: Peut démarrer après Phase 2 — aucune dépendance sur d'autres stories
- **US2 (P2)**: Peut démarrer après Phase 2 — aucune dépendance sur d'autres stories
- **US3 (P3)**: Dépend de Phase 2 (services) — idéalement après US1/US2 pour que les routes de navigation existent, mais implémentable dès Phase 2

### Within Each User Story

- Routes avant composants
- Composants (ts) avant templates (html) et styles (scss)
- Implémentation avant tests
- Story complète avant passage à la suivante (sauf US1/US2 parallélisables)

### Parallel Opportunities

- **Phase 1**: T001, T002, T003 en parallèle (fichiers différents)
- **Phase 2**: T004 et T005 en parallèle (services différents)
- **Phase 3-4**: US1 et US2 en parallèle (features indépendantes, fichiers différents)
- **Tests**: T011/T012, T018/T019, T022 parallélisables au sein de leur phase

---

## Parallel Example: User Story 1 + User Story 2

```text
# Après Phase 2, lancer en parallèle :

# Développeur A — US1 :
T006: Route recurring
T007: RecurringListComponent
T008: Template
T009: Styles
T010: Lien depuis Transactions
T011: Tests service
T012: Tests composant

# Développeur B — US2 :
T013: Route :id
T014: SubscriptionDetailComponent
T015: Template
T016: Styles
T017: Wire click handler
T018: Tests service
T019: Tests composant
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001-T003)
2. Compléter Phase 2: Foundational (T004-T005)
3. Compléter Phase 3: US1 — Écran récurrences (T006-T012)
4. **STOP et VALIDER**: Tester `/transactions/recurring` indépendamment
5. Livrer si prêt

### Incremental Delivery

1. Setup + Foundational → Base prête
2. US1 → Écran récurrences fonctionnel → **MVP**
3. US2 → Détail abonnement avec paiements → Valeur ajoutée
4. US3 → Actions notifications → Expérience complète
5. Polish → Vérifications finales

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [Story] = traçabilité vers la user story spec.md
- Chaque user story est indépendamment complétable et testable
- Commiter après chaque tâche ou groupe logique
- Penser à `/sync-doc` après les commits
