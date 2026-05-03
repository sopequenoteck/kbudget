# Feature Specification: Transactions récurrentes & abonnements — Angular

**Feature Branch**: `086-angular-recurring-transactions`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Linear KKS-192 — Sous-issue Angular de KKS-159. Écran des transactions récurrentes, paiements abonnements, actions notifications.
**Parent**: KKS-159 (Transactions récurrentes & abonnements)
**Prérequis**: Backend KKS-085 terminé (endpoints API disponibles)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter et agir sur les récurrences (Priority: P1)

L'utilisateur accède à l'écran des transactions récurrentes pour voir toutes ses récurrences actives. Chaque récurrence affiche le libellé, le montant, la fréquence et la prochaine date d'occurrence. Un badge visuel indique le statut : "Aujourd'hui" (occurrence du jour), "En retard" (date dépassée), ou "À venir" (future). L'utilisateur peut valider une occurrence (ce qui crée la transaction effective), passer une occurrence (avance à la prochaine date), ou désactiver complètement la récurrence.

**Why this priority**: C'est la fonctionnalité principale de la feature — sans cet écran, les récurrences backend ne sont pas exploitables côté Angular.

**Independent Test**: Peut être testé en accédant à `/transactions/recurring`, en vérifiant l'affichage de la liste et en exécutant les 3 actions (valider, passer, désactiver).

**Acceptance Scenarios**:

1. **Given** des transactions récurrentes actives existent, **When** l'utilisateur accède à `/transactions/recurring`, **Then** la liste affiche chaque récurrence avec icône catégorie, libellé, montant, fréquence et prochaine date.
2. **Given** une récurrence dont la prochaine occurrence est aujourd'hui, **When** la liste s'affiche, **Then** un badge "Aujourd'hui" orange est visible sur cette récurrence.
3. **Given** une récurrence dont la prochaine occurrence est passée, **When** la liste s'affiche, **Then** un badge "En retard" rouge est visible.
4. **Given** une récurrence dont la prochaine occurrence est dans le futur, **When** la liste s'affiche, **Then** un badge "À venir" gris est visible.
5. **Given** l'utilisateur clique sur "Valider" sur une récurrence, **When** l'appel réussit, **Then** une transaction est créée, un toast "Transaction créée" s'affiche, et la liste se rafraîchit avec la prochaine occurrence mise à jour.
6. **Given** l'utilisateur clique sur "Passer" sur une récurrence, **When** l'appel réussit, **Then** la prochaine date avance sans créer de transaction.
7. **Given** l'utilisateur clique sur "Désactiver" sur une récurrence, **When** l'utilisateur confirme dans le dialogue de confirmation, **Then** la récurrence disparaît de la liste active.

---

### User Story 2 - Consulter les paiements et payer un abonnement (Priority: P2)

L'utilisateur consulte le détail d'un abonnement et voit l'historique des paiements effectués (date + montant) ainsi que le total cumulé. Un bouton "Payer" toujours visible permet de créer la transaction de paiement à tout moment.

**Why this priority**: Enrichit l'écran de détail abonnement existant avec le suivi financier réel — complémentaire à P1.

**Independent Test**: Peut être testé en accédant au détail d'un abonnement existant, en vérifiant l'historique des paiements et en utilisant le bouton "Payer".

**Acceptance Scenarios**:

1. **Given** un abonnement avec des paiements passés, **When** l'utilisateur accède au détail de l'abonnement, **Then** une section affiche la liste des paiements (date + montant) et le total cumulé en haut.
2. **Given** un abonnement actif, **When** le détail s'affiche, **Then** un bouton "Payer" est toujours visible.
3. **Given** l'utilisateur clique sur "Payer", **When** l'appel réussit, **Then** une transaction est créée, un toast de confirmation s'affiche, et l'historique se met à jour.
4. **Given** un abonnement sans paiements, **When** le détail s'affiche, **Then** la section paiements affiche un message "Aucun paiement".

---

### User Story 3 - Agir depuis les notifications (Priority: P3)

L'utilisateur reçoit des notifications pour les récurrences dues et les abonnements à payer. Depuis le panneau de notifications, il peut directement valider/passer une récurrence ou payer un abonnement, sans naviguer vers l'écran dédié. Un tap sur la notification elle-même navigue vers l'écran concerné.

**Why this priority**: Améliore l'expérience utilisateur en réduisant les interactions nécessaires, mais requiert P1 et P2 fonctionnels.

**Independent Test**: Peut être testé en vérifiant que les notifications de type récurrence/abonnement affichent les boutons d'action et que le tap navigue correctement.

**Acceptance Scenarios**:

1. **Given** une notification de type récurrence due, **When** le panneau de notifications est ouvert, **Then** des boutons "Valider" et "Passer" sont affichés sur la notification.
2. **Given** l'utilisateur clique sur "Valider" depuis une notification récurrence, **When** l'appel réussit, **Then** la transaction est créée et un toast de confirmation s'affiche.
3. **Given** une notification de type abonnement à payer, **When** le panneau de notifications est ouvert, **Then** un bouton "Payer" est affiché.
4. **Given** l'utilisateur tape sur une notification récurrence, **When** la navigation se déclenche, **Then** l'utilisateur est redirigé vers `/transactions/recurring`.
5. **Given** l'utilisateur tape sur une notification abonnement, **When** la navigation se déclenche, **Then** l'utilisateur est redirigé vers le détail de l'abonnement concerné.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur double-clique sur un bouton d'action ? Le système désactive le bouton pendant l'appel pour empêcher les doubles soumissions.
- Que se passe-t-il si l'appel échoue lors d'une validation/skip/paiement ? Un toast d'erreur s'affiche et l'état de la liste reste inchangé.
- Que se passe-t-il si aucune récurrence active n'existe ? L'écran affiche un état vide avec un message explicatif.
- Que se passe-t-il si l'utilisateur désactive la dernière récurrence ? L'écran bascule vers l'état vide.
- Que se passe-t-il si une notification référence une récurrence déjà désactivée ? L'action échoue avec un message d'erreur explicite et la notification est marquée comme lue.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher la liste des transactions récurrentes actives avec icône catégorie, libellé, montant, fréquence (Hebdomadaire/Mensuel/Annuel) et prochaine date d'occurrence.
- **FR-002**: Le système DOIT afficher un badge de statut coloré sur chaque récurrence : "Aujourd'hui" (orange), "En retard" (rouge), "À venir" (gris). La liste DOIT être triée par statut prioritaire (En retard > Aujourd'hui > À venir), puis par date croissante au sein de chaque groupe.
- **FR-003**: L'utilisateur DOIT pouvoir valider une occurrence, ce qui crée la transaction correspondante et avance la prochaine date.
- **FR-004**: L'utilisateur DOIT pouvoir passer (skip) une occurrence sans créer de transaction.
- **FR-005**: L'utilisateur DOIT pouvoir désactiver une récurrence après confirmation via un dialogue.
- **FR-006**: Le système DOIT afficher l'historique des paiements d'un abonnement (date + montant) dans le détail abonnement.
- **FR-007**: Le système DOIT afficher le total cumulé des paiements d'un abonnement.
- **FR-008**: L'utilisateur DOIT pouvoir payer un abonnement depuis son écran de détail à tout moment (bouton toujours visible).
- **FR-009**: Le panneau de notifications DOIT afficher des boutons d'action contextuels : "Valider"/"Passer" pour les récurrences, "Payer" pour les abonnements.
- **FR-010**: Un tap sur une notification DOIT naviguer vers l'écran concerné (récurrences ou détail abonnement).
- **FR-011**: L'écran Transactions DOIT fournir un accès vers l'écran des récurrences (`/transactions/recurring`), sans entrée séparée dans la sidebar/navigation principale.
- **FR-012**: Le système DOIT empêcher les doubles soumissions en désactivant les boutons pendant les appels en cours.
- **FR-013**: Le système DOIT afficher des toasts de feedback pour chaque action réussie ou échouée.
- **FR-014**: Le système DOIT afficher un état vide approprié lorsqu'il n'y a aucune récurrence active ou aucun paiement.

### Key Entities

- **Transaction récurrente** : Transaction avec indicateur de récurrence, fréquence (hebdomadaire/mensuel/annuel), prochaine date d'occurrence, statut actif/inactif. Liée à une catégorie et un compte.
- **Paiement d'abonnement** : Transaction créée à partir d'un abonnement, avec date et montant. Liée à un abonnement.
- **Notification** : Notification de type récurrence due ou abonnement à payer, avec référence à l'entité source. Supporte des actions contextuelles.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter ses récurrences actives et exécuter une action (valider/passer/désactiver) en moins de 3 interactions depuis le menu.
- **SC-002**: L'utilisateur peut visualiser le cumul des paiements d'un abonnement et payer en 2 interactions depuis le détail abonnement.
- **SC-003**: L'utilisateur peut agir sur une notification (valider/passer/payer) en 1 seul clic sans navigation supplémentaire.
- **SC-004**: 100% des actions (valider, passer, désactiver, payer) fournissent un feedback visuel immédiat (toast) en cas de succès ou d'erreur.
- **SC-005**: Les doubles soumissions sont impossibles — aucune action dupliquée ne peut être déclenchée par un double-clic.
- **SC-006**: L'écran des récurrences s'affiche correctement sur mobile (< 768px) et desktop.

## Clarifications

### Session 2026-03-15

- Q: Où placer l'entrée "Récurrences" dans la navigation ? → A: Pas d'entrée séparée dans la sidebar — les récurrences font partie des Transactions, accessibles via un lien/bouton depuis l'écran Transactions existant.
- Q: Quel tri pour la liste des récurrences ? → A: Par statut prioritaire (En retard > Aujourd'hui > À venir), puis par date croissante au sein de chaque groupe.
- Q: Quand le bouton "Payer" est-il visible sur un abonnement ? → A: Toujours visible — l'utilisateur décide quand payer.

## Assumptions

- Les endpoints backend (KKS-085) sont disponibles et fonctionnels : `GET /transactions/recurring`, `POST /transactions/recurring/{id}/validate`, `POST /transactions/recurring/{id}/skip`, `POST /transactions/recurring/{id}/deactivate`, `GET /subscriptions/{id}/payments`, `POST /subscriptions/{id}/pay`.
- Le panneau de notifications existant (KKS-072) supporte déjà les types `RECURRING_TRANSACTION_DUE` et peut être enrichi avec des boutons d'action.
- Le service d'abonnements (`SubscriptionService`) existe déjà et peut être enrichi avec les méthodes de paiement.
- Le système de routing et la sidebar/menu existants suivent les patterns Angular établis dans le projet.
- Les design tokens existants couvrent les besoins visuels (couleurs de badge, espacement, typographie).

## Scope

### Inclus

- Écran liste des récurrences avec actions
- Enrichissement du détail abonnement (paiements + bouton payer)
- Actions contextuelles dans les notifications
- Route `/transactions/recurring` accessible depuis l'écran Transactions
- Service Angular pour les récurrences
- Enrichissement du service abonnements
- Tests unitaires des composants et services

### Exclus

- Création de nouvelles transactions récurrentes (géré par le formulaire de transaction existant)
- Modification des récurrences existantes (hors scope KKS-192)
- Backend API (couvert par KKS-085)
- Implémentation Flutter (autre sous-issue de KKS-159)
