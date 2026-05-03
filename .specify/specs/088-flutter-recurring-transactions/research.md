# Research: Flutter Recurring Transactions & Subscription Payments

**Feature**: 088-flutter-recurring-transactions
**Date**: 2026-03-15

## R1 — Pattern interaction swipe + long press

**Decision**: Utiliser `Dismissible` natif avec `confirmDismiss` (swipe) + `GestureDetector.onLongPress` → `showModalBottomSheet` (long press).
**Rationale**: Le projet n'utilise pas `flutter_slidable`. `Dismissible` est déjà employé dans `notification_panel.dart`. Ajouter une dépendance externe pour un seul écran contredit le principe YAGNI.
**Alternatives considered**:
- `flutter_slidable` : plus riche (multi-action revealed), mais dépendance supplémentaire inutile
- Boutons visibles inline : moins mobile-friendly, prend de l'espace

## R2 — Notifier pattern pour actions non-CRUD

**Decision**: `RecurringListNotifier extends Notifier<ListState<RecurringTransaction>>` avec méthodes `loadItems()`, `validate(id)`, `skip(id)`, `deactivate(id)`.
**Rationale**: Les actions validate/skip/deactivate ne sont pas du CRUD classique. Le pattern est identique à `DebtNotifier` qui a des actions custom (repay, snooze). `mutatingIds` dans `ListState` gère l'état de chargement par item.
**Alternatives considered**:
- Étendre `CrudNotifier<RecurringTransaction>` + override : forcerait des méthodes inutiles (create, update, delete) et ajouterait de la confusion

## R3 — SubscriptionDetailScreen vs enrichissement modal

**Decision**: Créer un `SubscriptionDetailScreen` dédié (route `/subscriptions/:id`).
**Rationale**: L'historique des paiements + total cumulé + bouton payer nécessitent plus d'espace qu'un modal. Le pattern est identique à `DebtDetailScreen` (route `/debts/:id`). Le tap sur un item de la liste naviguera vers le détail.
**Alternatives considered**:
- Enrichir le modal existant : trop contraint en espace pour l'historique + actions

## R4 — Endpoints API existants (KKS-085)

**Decision**: Consommer les 8 endpoints existants sans modification backend.
**Rationale**: Tous les endpoints nécessaires sont déjà en place.
**Endpoints**:
- `GET /transactions/recurring` — liste active
- `POST /transactions/recurring/{id}/validate` — valider → TransactionResponse
- `PATCH /transactions/recurring/{id}/skip` — passer → RecurringTransactionResponse
- `PATCH /transactions/recurring/{id}/deactivate` — désactiver → RecurringTransactionResponse
- `POST /subscriptions/{id}/pay` — payer → SubscriptionPaymentResponse
- `GET /subscriptions/{id}/payments` — historique → List<SubscriptionPaymentResponse>
- `GET /subscriptions/{id}/payments/total` — total → Map{totalPaid, paymentCount}

## R5 — Tri des récurrences par statut

**Decision**: Tri côté client après récupération de la liste.
**Rationale**: L'API retourne les récurrences triées par `nextOccurrence ASC`. Le classement par badge (overdue > today > upcoming) est un concern UI. Le tri se fait dans le notifier via `sortItems()` avec comparaison sur le statut dérivé puis la date.
**Alternatives considered**:
- Tri serveur avec paramètre : surcharge l'API pour un besoin purement UI
