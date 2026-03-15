# Feature Specification: Transactions récurrentes & améliorations abonnements (consolidée)

**Feature Branch**: `089-recurring-transactions`
**Created**: 2026-03-15
**Status**: Done (rétroactive)
**Input**: KKS-159 — Transactions récurrentes & améliorations abonnements — workflow notification → validation → transaction
**Linear**: [KKS-159](https://linear.app/kksdev/issue/KKS-159)

## Contexte

Spec consolidée cross-plateforme pour KKS-159 (comme 080-debt-enhancements pour les dettes). Les 4 sous-tâches ont été implémentées et validées :

| Sous-issue | Feature | Tâches | Tests |
|------------|---------|--------|-------|
| KKS-191 (085-recurring-transactions-backend) | Backend : migration V20, services, endpoints, scheduler | 25 | 488 passent |
| KKS-192 (086-angular-recurring-transactions) | Angular : écran récurrences, détail abonnement, notifications | 26 | 375 passent |
| KKS-087 (087-angular-recurring-form) | Angular : formulaire création + conversion récurrente | 14 | 379 passent |
| KKS-193 (088-flutter-recurring-transactions) | Flutter : écran récurrences, détail abonnement, notifications | 39 | 626 passent |

**Total** : 104 tâches documentées, toutes complétées.

## User Scenarios & Testing

### User Story 1 - Valider une transaction récurrente (Priority: P1)

L'utilisateur définit une dépense ou recette récurrente (loyer, électricité, salaire). Le système le rappelle quotidiennement via notification lorsque l'échéance est atteinte. L'utilisateur valide manuellement, ce qui crée la transaction effective et avance la prochaine échéance. Aucune transaction n'est créée automatiquement — l'utilisateur reste maître.

**Why this priority**: C'est le cœur de la feature — le workflow notification → validation → transaction donne à l'utilisateur le contrôle total sur ses dépenses récurrentes.

**Independent Test**: Créer une récurrence, attendre/déclencher le scheduler, recevoir la notification, valider, vérifier la transaction créée et la prochaine date avancée.

**Acceptance Scenarios**:

1. **Given** une transaction récurrente active avec nextOccurrence <= aujourd'hui, **When** l'utilisateur valide l'occurrence, **Then** une transaction est créée (même montant/libellé/type/catégorie/compte) et nextOccurrence avance au prochain cycle selon la fréquence
2. **Given** une transaction récurrente désactivée, **When** l'utilisateur tente de valider, **Then** le système refuse avec une erreur appropriée
3. **Given** une transaction récurrente active, **When** l'utilisateur passe l'occurrence, **Then** nextOccurrence avance sans création de transaction
4. **Given** une transaction récurrente active, **When** l'utilisateur la désactive, **Then** recurringActive passe à false et elle disparaît de la liste active

---

### User Story 2 - Payer un abonnement et suivre les paiements (Priority: P1)

L'utilisateur reçoit une notification de renouvellement d'abonnement. Il valide le paiement, ce qui crée une transaction liée à l'abonnement (via subscriptionId). Il peut consulter l'historique des paiements et le total cumulé sur l'écran de détail de l'abonnement.

**Why this priority**: Les abonnements existants n'avaient aucune traçabilité des paiements. Cette fonctionnalité complète le cycle de vie et permet de savoir combien a été dépensé par abonnement.

**Independent Test**: Payer un abonnement via le bouton "Payer", vérifier la transaction créée avec subscriptionId, consulter l'historique et le cumul.

**Acceptance Scenarios**:

1. **Given** un abonnement actif avec un compte associé, **When** l'utilisateur paie, **Then** une transaction est créée sur le compte de l'abonnement, liée par subscriptionId
2. **Given** un abonnement actif sans compte associé, **When** l'utilisateur paie, **Then** une transaction est créée sur le compte par défaut
3. **Given** un abonnement avec plusieurs paiements, **When** l'utilisateur consulte le détail, **Then** il voit la liste des paiements (date + montant) et le total cumulé
4. **Given** un abonnement inactif, **When** l'utilisateur tente de payer, **Then** le système refuse avec une erreur

---

### User Story 3 - Créer et convertir des récurrences (Priority: P2)

L'utilisateur peut créer une transaction récurrente depuis le formulaire de transaction (toggle "Récurrente" avec fréquence et prochaine occurrence). Il peut aussi convertir une transaction existante en récurrente via l'action "Rendre récurrente" depuis la liste des transactions — le formulaire s'ouvre pré-rempli.

**Why this priority**: Complémentaire aux US1/US2, permet l'alimentation du système en récurrences.

**Independent Test**: Ouvrir le formulaire, activer le toggle, remplir les champs, soumettre. Vérifier que la récurrence apparaît dans la liste.

**Acceptance Scenarios**:

1. **Given** le formulaire de transaction en mode création, **When** l'utilisateur active le toggle "Récurrente", **Then** les champs fréquence et prochaine occurrence apparaissent
2. **Given** le toggle récurrence activé avec tous les champs remplis, **When** l'utilisateur soumet, **Then** une transaction récurrente est créée via POST /transactions/recurring
3. **Given** une transaction existante dans la liste, **When** l'utilisateur clique sur "Rendre récurrente", **Then** le formulaire s'ouvre pré-rempli en mode récurrent
4. **Given** le formulaire est en mode édition, **When** l'utilisateur consulte les options, **Then** le toggle "Récurrente" n'est pas visible

---

### User Story 4 - Notifications et écran de gestion (Priority: P2)

Le scheduler quotidien (8h) détecte les échéances dues et crée des notifications. L'utilisateur accède à un écran dédié listant ses récurrences actives (triées par statut : en retard > aujourd'hui > à venir). Depuis les notifications, il peut agir directement (valider/passer/payer) sans navigation.

**Why this priority**: Le scheduler est le déclencheur du workflow ; l'écran dédié donne la vue d'ensemble.

**Independent Test**: Configurer des récurrences/abonnements avec échéance due, vérifier les notifications, agir depuis le panneau.

**Acceptance Scenarios**:

1. **Given** des récurrences actives avec nextOccurrence <= aujourd'hui, **When** le scheduler s'exécute, **Then** une notification est créée pour chaque occurrence due
2. **Given** l'utilisateur ouvre l'écran récurrences, **When** la liste se charge, **Then** les items sont triés par statut puis par date, avec badges colorés (rouge/orange/gris)
3. **Given** une notification de type récurrence due, **When** l'utilisateur choisit "Valider" depuis la notification, **Then** la transaction est créée sans navigation
4. **Given** une notification de type abonnement dû, **When** l'utilisateur choisit "Payer", **Then** le paiement est effectué

---

### Edge Cases

- Récurrence en retard de plusieurs jours : le scheduler crée une notification chaque jour. La validation avance au prochain cycle (pas de rattrapage automatique)
- Suppression du compte associé à une récurrence : la récurrence reste active, l'utilisateur devra choisir un compte lors de la validation
- Abonnement désactivé entre notification et paiement : le paiement est refusé avec erreur
- Fin de mois (31 janvier → 28/29 février) : mensuel = même jour tronqué au dernier jour du mois
- Double-clic sur bouton d'action : le bouton est désactivé pendant l'appel (Angular et Flutter)
- Notification référençant une récurrence désactivée : l'action échoue avec message d'erreur explicite

## Requirements

### Functional Requirements

**Backend**

- **FR-001**: Le système DOIT permettre de créer une transaction récurrente via POST /transactions/recurring avec fréquence et nextOccurrence obligatoires
- **FR-002**: Le système DOIT lister les récurrences actives via GET /transactions/recurring
- **FR-003**: Le système DOIT valider une occurrence via POST /transactions/recurring/{id}/validate (crée transaction + avance date)
- **FR-004**: Le système DOIT passer une occurrence via POST /transactions/recurring/{id}/skip (avance date sans transaction)
- **FR-005**: Le système DOIT désactiver une récurrence via POST /transactions/recurring/{id}/deactivate
- **FR-006**: Le système DOIT payer un abonnement via POST /subscriptions/{id}/pay (crée transaction liée par subscriptionId)
- **FR-007**: Le système DOIT fournir l'historique des paiements (GET /subscriptions/{id}/payments) et le nombre total de paiements (GET /subscriptions/{id}/total-paid). Le cumul monétaire est calculé côté frontend
- **FR-008**: Le scheduler quotidien DOIT détecter les échéances et créer des notifications sans créer de transactions automatiquement
- **FR-008b**: Le cumul monétaire des paiements d'un abonnement DOIT être calculé côté frontend à partir de la liste des paiements (GET /subscriptions/{id}/payments). L'endpoint GET /subscriptions/{id}/total-paid retourne le nombre de paiements (count), pas la somme monétaire
- **FR-009**: Les transactions récurrentes "templates" NE DOIVENT PAS apparaître dans GET /transactions standard
- **FR-010**: Toutes les données DOIVENT être isolées par utilisateur authentifié

**Angular**

- **FR-011**: L'écran /transactions/recurring DOIT afficher les récurrences avec badges de statut (En retard/Aujourd'hui/À venir) triées par priorité
- **FR-012**: Le formulaire de transaction DOIT proposer un toggle "Récurrente" en mode création uniquement
- **FR-013**: La liste des transactions DOIT proposer l'action "Rendre récurrente" avec pré-remplissage du formulaire
- **FR-014**: Le détail abonnement DOIT afficher l'historique des paiements et le total cumulé
- **FR-015**: Le panneau de notifications DOIT afficher des actions contextuelles (Valider/Passer, Payer)

**Flutter**

- **FR-016**: L'écran récurrences DOIT afficher la liste avec skeleton loading et état vide
- **FR-017**: Les actions DOIVENT être accessibles via swipe (rapide) et long press (bottom sheet)
- **FR-018**: Le détail abonnement DOIT afficher historique + total cumulé + bouton "Payer"
- **FR-019**: Les notifications DOIVENT supporter les actions Valider/Passer/Payer avec deep link vers l'écran concerné
- **FR-020**: L'application DOIT consommer les endpoints API REST (pas de stockage local Drift)

### Key Entities

- **Transaction (enrichie)** : +isRecurring (boolean), +frequency (Frequency, nullable), +nextOccurrence (date, nullable), +recurringActive (boolean), +subscription (FK → Subscription, nullable), +product (FK → Product), +debt (FK → Debt)
- **Subscription (existante)** : inchangée. Paiements tracés via subscriptionId sur Transaction
- **Notification (existante)** : +RECURRING_TRANSACTION_DUE, +SUBSCRIPTION_DUE
- **EntityType (enrichi)** : +RECURRING_TRANSACTION, +BUDGET, +TRANSACTION

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut valider/passer/désactiver une récurrence en 2 interactions maximum
- **SC-002**: L'historique des paiements d'un abonnement affiche le total cumulé exact
- **SC-003**: Les notifications d'échéance sont créées quotidiennement pour toutes les récurrences et abonnements dus
- **SC-004**: Les 3 fréquences (hebdomadaire, mensuel, annuel) calculent correctement la prochaine occurrence, y compris les cas limites
- **SC-005**: L'utilisateur peut créer une récurrence en moins de 4 interactions depuis le FAB
- **SC-006**: La conversion d'une transaction existante en récurrente se fait en 2 interactions
- **SC-007**: 488 tests backend + 379 tests Angular + 626 tests Flutter passent

## Modifications techniques

### Migration Flyway V20

```sql
ALTER TABLE transactions ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE transactions ADD COLUMN frequency VARCHAR(10);
ALTER TABLE transactions ADD COLUMN next_occurrence DATE;
ALTER TABLE transactions ADD COLUMN recurring_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE transactions ADD COLUMN subscription_id UUID REFERENCES subscriptions(id);
```

### Endpoints API

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | /transactions/recurring | Créer une transaction récurrente |
| GET | /transactions/recurring | Lister les récurrences actives |
| POST | /transactions/recurring/{id}/validate | Valider une occurrence |
| POST | /transactions/recurring/{id}/skip | Passer une occurrence |
| POST | /transactions/recurring/{id}/deactivate | Désactiver une récurrence |
| POST | /subscriptions/{id}/pay | Payer un abonnement |
| GET | /subscriptions/{id}/payments | Historique paiements abonnement |
| GET | /subscriptions/{id}/total-paid | Total cumulé paiements |

### Services créés

- **RecurringTransactionService** (backend) : CRUD + validation + skip + deactivate
- **SubscriptionPaymentService** (backend) : pay + getPayments + getTotalPaid
- **NotificationScheduler** (backend) : +checkRecurringTransactions() minutely job
- **RecurringTransactionService** (Angular) : signal-based, loadActive/validate/skip/deactivate/create
- **RecurringListNotifier** (Flutter) : Notifier custom (non-CRUD : validate, skip, deactivate)

## Dependencies

- **KKS-158** (072-notification-system) : infrastructure notifications (prérequis)
- **KKS-155** : refonte écran par écran (intégration design)

## Assumptions

- Le système de notifications (KKS-158) est en place et fonctionnel
- Les paiements partiels ne sont pas supportés pour les abonnements
- Le scheduler s'exécute à 8h (heure serveur) pour les récurrences
- API REST uniquement côté Flutter (pas de Drift pour cette feature)
- Le toggle récurrence n'est visible qu'en mode création (pas édition)

## Out of Scope

- Création automatique de transactions sans validation utilisateur
- Paiements partiels d'abonnements
- Modification de la fréquence ou du montant d'une récurrence existante
- Gestion multi-devises des récurrences
- Stockage local Drift pour les récurrences Flutter
