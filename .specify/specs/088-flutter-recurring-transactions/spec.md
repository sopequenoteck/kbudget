# Feature Specification: Transactions récurrentes & abonnements — Flutter

**Feature Branch**: `088-flutter-recurring-transactions`
**Created**: 2026-03-15
**Status**: Draft
**Input**: User description: "KKS-193 — Transactions récurrentes & abonnements — Flutter : écran récurrences, paiements abonnements, notifications"
**Linear**: [KKS-193](https://linear.app/kksdev/issue/KKS-193)
**Parent**: KKS-159 (Transactions récurrentes & abonnements — cross-plateforme)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter et gérer les récurrences actives (Priority: P1)

L'utilisateur accède à l'écran des transactions récurrentes pour visualiser toutes ses récurrences actives. Chaque récurrence affiche le libellé, le montant, la fréquence et la prochaine date d'échéance avec un badge de statut ("En retard", "Aujourd'hui", "A venir"). L'utilisateur peut déclencher les actions via swipe (gauche/droite) pour une action rapide ou via long press qui ouvre un bottom sheet avec toutes les actions disponibles (valider, passer, désactiver).

**Why this priority**: C'est la fonctionnalité principale — sans cet écran, aucune gestion des récurrences n'est possible sur mobile.

**Independent Test**: Peut être testé en accédant à l'écran récurrences, en vérifiant la liste affichée, puis en validant/passant/désactivant une récurrence et en observant le feedback.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des récurrences actives, **When** il ouvre l'écran récurrences, **Then** il voit la liste triée par statut (en retard > aujourd'hui > à venir) puis par date croissante, avec skeleton loading pendant le chargement.
2. **Given** une récurrence avec échéance aujourd'hui, **When** l'utilisateur la valide, **Then** une transaction est créée et un snackbar de succès s'affiche.
3. **Given** une récurrence active, **When** l'utilisateur choisit "Passer", **Then** la prochaine date est avancée selon la fréquence.
4. **Given** une récurrence active, **When** l'utilisateur choisit "Désactiver", **Then** un dialog de confirmation s'affiche, et après confirmation la récurrence disparait de la liste.
5. **Given** aucune récurrence active, **When** l'utilisateur ouvre l'écran, **Then** un état vide est affiché avec un message explicatif.

---

### User Story 2 - Payer un abonnement et consulter l'historique des paiements (Priority: P2)

L'utilisateur consulte le détail d'un abonnement et voit la section "Historique des paiements" avec la liste chronologique des paiements (date + montant) et le total cumulé en en-tête. Si l'échéance de l'abonnement est atteinte, un bouton "Payer" permet de créer une transaction liée.

**Why this priority**: Enrichit l'écran existant des abonnements avec le suivi des paiements — forte valeur pour le suivi financier.

**Independent Test**: Peut être testé en ouvrant le détail d'un abonnement, en vérifiant l'historique affiché, puis en payant un abonnement échu.

**Acceptance Scenarios**:

1. **Given** un abonnement avec des paiements passés, **When** l'utilisateur ouvre le détail, **Then** il voit la section historique avec la liste des paiements et le total cumulé.
2. **Given** un abonnement dont l'échéance est atteinte, **When** l'utilisateur appuie sur "Payer", **Then** une transaction liée est créée et le paiement apparait dans l'historique.
3. **Given** un abonnement sans historique de paiements, **When** l'utilisateur ouvre le détail, **Then** la section historique affiche un état vide.

---

### User Story 3 - Actions depuis les notifications (Priority: P3)

L'utilisateur reçoit des notifications pour ses récurrences dues et abonnements à payer. Depuis la notification, il peut effectuer une action rapide (Valider/Passer pour une récurrence, Payer pour un abonnement) ou taper la notification pour naviguer vers l'écran concerné.

**Why this priority**: Améliore l'expérience en permettant des actions directes depuis les notifications, mais nécessite les écrans P1 et P2 comme destinations.

**Independent Test**: Peut être testé en recevant une notification de récurrence due, en effectuant l'action "Valider" depuis la notification, et en vérifiant que la transaction est créée.

**Acceptance Scenarios**:

1. **Given** une notification de type récurrence due, **When** l'utilisateur choisit l'action "Valider", **Then** la récurrence est validée (transaction créée) et la notification est marquée comme lue.
2. **Given** une notification de type récurrence due, **When** l'utilisateur choisit l'action "Passer", **Then** la prochaine date est avancée et la notification est marquée comme lue.
3. **Given** une notification de type abonnement dû, **When** l'utilisateur choisit l'action "Payer", **Then** le paiement est effectué et la notification est marquée comme lue.
4. **Given** une notification récurrence ou abonnement, **When** l'utilisateur tape sur la notification, **Then** il est redirigé vers l'écran correspondant via deep link.

---

### Edge Cases

- Que se passe-t-il si la validation d'une récurrence échoue (erreur réseau) ? Un snackbar d'erreur s'affiche avec possibilité de réessayer.
- Que se passe-t-il si l'utilisateur tente de payer un abonnement dont le compte associé n'existe plus ? Un message d'erreur explicite est affiché.
- Que se passe-t-il si plusieurs récurrences sont en retard ? Elles sont toutes affichées en haut de la liste, triées par date croissante.
- Que se passe-t-il lors d'une désactivation si la requête échoue ? Le dialog se ferme, un snackbar d'erreur s'affiche, la récurrence reste dans la liste.
- Que se passe-t-il si l'utilisateur navigue vers une récurrence depuis une notification mais que la récurrence a déjà été traitée ? L'écran se rafraichit et montre l'état actuel.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'application DOIT afficher la liste des transactions récurrentes actives avec libellé, montant, fréquence, icône catégorie et prochaine date.
- **FR-002**: L'application DOIT trier les récurrences par statut (en retard > aujourd'hui > à venir) puis par date croissante.
- **FR-003**: L'application DOIT permettre de valider une récurrence (créer la transaction correspondante).
- **FR-004**: L'application DOIT permettre de passer une récurrence (avancer la prochaine date selon la fréquence).
- **FR-005**: L'application DOIT permettre de désactiver une récurrence après confirmation utilisateur.
- **FR-006**: L'application DOIT proposer les actions via deux mécanismes : swipe (action rapide) et long press (bottom sheet avec toutes les actions).
- **FR-007**: L'application DOIT afficher un skeleton loading (shimmer) pendant le chargement de la liste.
- **FR-008**: L'application DOIT afficher un état vide si aucune récurrence active n'existe.
- **FR-009**: L'application DOIT afficher un snackbar de succès après validation/skip et un snackbar d'erreur en cas d'échec.
- **FR-010**: L'application DOIT afficher la section "Historique des paiements" dans le détail d'un abonnement avec liste chronologique et total cumulé.
- **FR-011**: L'application DOIT permettre de payer un abonnement échu via un bouton "Payer" dans le détail.
- **FR-012**: L'application DOIT gérer les actions depuis les notifications push (Valider/Passer pour récurrences, Payer pour abonnements).
- **FR-013**: L'application DOIT naviguer vers l'écran correspondant lors du tap sur une notification (deep link).
- **FR-014**: L'application DOIT consommer les endpoints API REST existants (pas de stockage local).

### Key Entities

- **RecurringTransaction**: Transaction programmée avec libellé, montant, type (dépense/recette), fréquence, prochaine date d'échéance, statut actif/inactif, catégorie et compte associés.
- **SubscriptionPayment**: Paiement effectué pour un abonnement, avec montant, date et compte utilisé.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter ses récurrences actives en moins de 2 secondes après ouverture de l'écran.
- **SC-002**: L'utilisateur peut valider, passer ou désactiver une récurrence en 2 interactions maximum (action + confirmation si applicable).
- **SC-003**: L'utilisateur peut payer un abonnement échu et voir le paiement dans l'historique immédiatement après l'action.
- **SC-004**: L'utilisateur peut agir sur une notification (valider/passer/payer) sans ouvrir manuellement l'écran correspondant.
- **SC-005**: L'historique des paiements d'un abonnement affiche le total cumulé correct et la liste complète des paiements passés.

## Clarifications

### Session 2026-03-15

- Q: Comment l'utilisateur déclenche-t-il les actions sur un item de la liste des récurrences ? → A: Swipe (action rapide) + long press ouvre un bottom sheet avec toutes les actions.

## Assumptions

- Les endpoints API backend pour les récurrences et paiements d'abonnements sont déjà disponibles (KKS-085 terminé).
- Le système de notifications push est déjà en place dans l'app Flutter (KKS-072).
- L'écran de détail des abonnements n'existe pas encore (seul le formulaire modal existe) — un écran dédié sera créé.
- Le pattern ListState<T> existant sera réutilisé avec un Notifier custom (actions non-CRUD : validate, skip, deactivate).
- API REST uniquement (pas de stockage local Drift pour cette feature).

## Dependencies

- **KKS-085** (backend recurring transactions) — endpoints API requis
- **KKS-072** (notification system) — infrastructure notifications Flutter
- **KKS-086** (Angular recurring transactions) — référence fonctionnelle pour la parité

## Out of Scope

- Création de transactions récurrentes depuis Flutter (futur ticket dédié)
- Stockage local Drift des récurrences
- Modification des paramètres d'une récurrence (fréquence, montant)
- Gestion des notifications côté backend (déjà en place)
