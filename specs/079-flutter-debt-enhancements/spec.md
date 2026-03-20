# Feature Specification: Améliorations dettes Flutter

**Feature Branch**: `079-flutter-debt-enhancements`
**Created**: 2026-03-13
**Status**: Draft
**Input**: KKS-196 — Enrichissement de l'interface dettes Flutter : formulaire enrichi (compte bancaire, rappels, patrimoine), remboursement avec suivi des paiements, notifications push avec actions.
**Linear**: [KKS-196](https://linear.app/kksdev/issue/KKS-196)

## User Scenarios & Testing

### User Story 1 - Formulaire de dette enrichi (Priority: P1)

L'utilisateur crée ou modifie une dette avec des informations supplémentaires : association à un compte bancaire, configuration d'un rappel (date + heure), et choix d'inclure la dette dans le calcul du patrimoine. Le formulaire s'adapte dynamiquement : si un compte est sélectionné, la devise est automatiquement celle du compte (champ devise masqué) ; le toggle patrimoine n'apparaît que si aucun compte n'est associé.

**Why this priority**: Le formulaire est le point d'entrée pour toutes les données enrichies. Sans lui, les autres fonctionnalités (remboursement, rappels) ne peuvent pas être alimentées.

**Independent Test**: Peut être testé en créant/modifiant une dette avec les nouveaux champs et en vérifiant la persistance via l'API.

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre le formulaire de création de dette, **When** il sélectionne un compte bancaire, **Then** le champ devise est masqué, la devise du compte est utilisée automatiquement, et "Inclure dans le patrimoine" est automatiquement coché et masqué.
2. **Given** l'utilisateur ouvre le formulaire de création de dette, **When** aucun compte n'est sélectionné, **Then** la devise principale de l'utilisateur est utilisée et le toggle "Inclure dans le patrimoine" est visible.
3. **Given** l'utilisateur configure un rappel avec une date, **When** il sélectionne la date, **Then** le champ heure apparaît (défaut : 09:00). Les deux sont persistés à la sauvegarde.
4. **Given** l'utilisateur modifie une dette existante avec un compte associé, **When** il ouvre le formulaire, **Then** le compte, le rappel (date + heure) et l'état patrimoine sont pré-remplis.

---

### User Story 2 - Remboursement d'une dette (Priority: P1)

Depuis l'écran de détail d'une dette, l'utilisateur peut effectuer un remboursement partiel ou total. Un bouton "Rembourser" ouvre une bottom sheet avec la sélection du compte source (obligatoire) et le montant (pré-rempli avec le montant restant). Le remboursement crée une transaction et met à jour la dette. Si la dette est entièrement soldée, un badge "Remboursé" est affiché.

**Why this priority**: Le remboursement est la fonctionnalité coeur de cette feature — il apporte la valeur principale en permettant le suivi de progression des dettes.

**Independent Test**: Peut être testé en effectuant un remboursement depuis le détail d'une dette et en vérifiant la transaction créée + la mise à jour du montant restant.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le détail d'une dette non soldée, **When** il appuie sur "Rembourser", **Then** une bottom sheet s'ouvre avec un sélecteur de compte (pré-sélectionné : compte associé à la dette ou premier compte actif) et un champ montant pré-rempli avec le restant dû (max = restant dû).
2. **Given** l'utilisateur remplit la bottom sheet avec un compte et un montant valide, **When** il confirme, **Then** une transaction est créée, la dette est mise à jour, et un snackbar s'affiche ("Remboursement enregistré. Reste : {montant}" ou "Dette remboursée !").
3. **Given** l'utilisateur effectue un remboursement égal au montant restant, **When** la dette est soldée, **Then** un badge "Remboursé" est affiché sur la dette.
4. **Given** l'utilisateur tente de rembourser un montant supérieur au restant dû, **When** il valide, **Then** le système refuse avec un message d'erreur ("Montant entre 0,01 et {restant}").
5. **Given** la dette est en EUR et l'utilisateur sélectionne un compte en USD, **When** il confirme le remboursement, **Then** la conversion est gérée silencieusement côté API (tous les comptes actifs sont proposés, sans filtre par devise).

---

### User Story 3 - Détail de dette enrichi avec historique des paiements (Priority: P2)

L'écran de détail affiche le montant restant, une barre de progression visuelle (paiements effectués / montant total), et un historique chronologique des paiements (date, montant, compte). Le total cumulé des paiements est affiché en en-tête de la section historique.

**Why this priority**: L'historique et la progression visuelle complètent l'expérience de suivi, mais l'utilisateur peut fonctionner sans (le remboursement seul suffit).

**Independent Test**: Peut être testé en vérifiant l'affichage du détail après plusieurs remboursements — barre de progression, liste des paiements, total cumulé.

**Acceptance Scenarios**:

1. **Given** une dette avec des paiements partiels, **When** l'utilisateur ouvre le détail, **Then** le montant restant, la barre de progression et l'historique des paiements sont affichés.
2. **Given** une dette sans aucun paiement, **When** l'utilisateur ouvre le détail, **Then** la barre de progression est à 0% et la section historique indique "Aucun paiement".
3. **Given** une dette avec 3 paiements, **When** l'utilisateur consulte l'historique, **Then** les paiements sont listés par ordre chronologique avec date, montant et nom du compte, et le total cumulé est affiché en en-tête.

---

### User Story 4 - Report de rappel (snooze) (Priority: P3)

L'utilisateur peut reporter le rappel d'une dette à une nouvelle date et heure, soit depuis une notification push, soit depuis l'écran de détail. L'action "Reporter" ouvre un dialogue rapide (date + heure) et met à jour le rappel via l'API.

**Why this priority**: Fonctionnalité de confort qui améliore l'expérience de gestion des rappels mais n'est pas bloquante pour le workflow principal.

**Independent Test**: Peut être testé en reportant un rappel et en vérifiant que la nouvelle date/heure est persistée.

**Acceptance Scenarios**:

1. **Given** une dette avec un rappel configuré, **When** l'utilisateur choisit "Reporter", **Then** un dialogue s'ouvre avec date et heure pré-remplis depuis le rappel actuel. Le bouton "Reporter" n'est visible que si la dette a un rappel configuré.
2. **Given** l'utilisateur sélectionne une nouvelle date/heure dans le dialogue, **When** il confirme, **Then** le rappel est mis à jour et un snackbar "Rappel reporté" s'affiche. La date DOIT être dans le futur (validation bloquante).

---

### User Story 5 - Actions notification push (Priority: P3)

Les notifications push de rappel de dette offrent deux actions : "Reporter" (ouvre le dialogue de report) et "Rembourser" (navigue vers l'écran de détail de la dette via deep link). Le deep link utilise la route `/debts/:id` via go_router.

**Why this priority**: Les actions push enrichissent l'expérience mais dépendent du système de notification déjà existant (KKS-072). La navigation et le remboursement fonctionnent déjà sans.

**Independent Test**: Peut être testé en simulant une notification de rappel et en vérifiant que les actions "Reporter" et "Rembourser" fonctionnent correctement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur reçoit une notification de rappel de dette, **When** il choisit "Reporter", **Then** le dialogue de report s'ouvre avec la date/heure actuelle du rappel.
2. **Given** l'utilisateur reçoit une notification de rappel de dette, **When** il choisit "Rembourser", **Then** l'application navigue vers l'écran de détail de la dette correspondante.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur supprime le compte bancaire associé à une dette ? La dette conserve sa devise, le champ compte passe à "non associé".
- Que se passe-t-il si l'utilisateur tente de rembourser une dette déjà soldée ? Le bouton "Rembourser" est masqué et le badge "Remboursé" est affiché.
- Que se passe-t-il si aucun compte actif n'est disponible pour le remboursement ? Un message invite l'utilisateur à créer un compte d'abord.
- Que se passe-t-il si le rappel est configuré dans le passé ? Le formulaire de report (snooze) rejette les dates passées avec un message d'erreur. Le formulaire de création/édition de dette accepte les dates passées (pas de validation future).
- Que se passe-t-il si la liste de paiements est vide ? La section affiche un état vide explicite.

## Requirements

### Functional Requirements

- **FR-001**: Le formulaire de dette DOIT permettre l'association optionnelle à un compte bancaire via un sélecteur.
- **FR-002**: Lorsqu'un compte est sélectionné, le système DOIT forcer la devise à celle du compte, masquer le champ devise, et auto-cocher "Inclure dans le patrimoine" (masqué).
- **FR-003**: Le formulaire DOIT permettre la configuration optionnelle d'un rappel. Le champ heure n'apparaît que si une date de rappel est sélectionnée (défaut : 09:00).
- **FR-004**: Le toggle "Inclure dans le patrimoine" DOIT être visible uniquement si aucun compte n'est associé. Il est automatiquement activé et masqué quand un compte est sélectionné.
- **FR-005**: L'écran de détail DOIT afficher le montant restant et une barre de progression visuelle.
- **FR-006**: Le bouton "Rembourser" DOIT ouvrir une bottom sheet avec sélection de compte (obligatoire, pré-sélectionné : compte associé ou premier compte actif) et montant (pré-rempli avec le restant dû, max = restant dû). Tous les comptes actifs sont proposés, sans filtre par devise.
- **FR-007**: Le remboursement DOIT créer une transaction côté serveur et rafraîchir l'état de la dette.
- **FR-008**: Une dette entièrement remboursée DOIT afficher un badge "Remboursé" et masquer le bouton de remboursement.
- **FR-009**: L'historique des paiements DOIT être affiché en ordre chronologique avec date, montant et nom du compte.
- **FR-010**: Le report de rappel DOIT mettre à jour la date et l'heure du rappel via l'API. La date DOIT être dans le futur (validation côté client). Le bouton "Reporter" n'est visible que si la dette a un rappel configuré.
- **FR-011**: Les notifications push de dette DOIVENT proposer les actions "Reporter" et "Rembourser".
- **FR-012**: L'action "Rembourser" depuis une notification DOIT naviguer vers le détail de la dette via deep link `/debts/:id`.
- **FR-013**: Le montant de remboursement NE DOIT PAS dépasser le montant restant dû.

### Key Entities

- **Debt (enrichie)** : dette existante étendue avec compte bancaire associé (optionnel), indicateur patrimoine, date/heure de rappel, montant restant calculé, liste de paiements.
- **DebtPayment** : enregistrement d'un remboursement — montant, date, nom du compte source. Lié à une dette.

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une dette enrichie (compte + rappel + patrimoine) en moins de 30 secondes.
- **SC-002**: L'utilisateur peut effectuer un remboursement complet en 3 interactions maximum (bouton → remplir → confirmer).
- **SC-003**: L'historique des paiements reflète fidèlement tous les remboursements effectués, sans délai perceptible après un remboursement.
- **SC-004**: Le report de rappel met à jour la date en 2 interactions (bouton → confirmer).
- **SC-005**: Le deep link depuis une notification ouvre directement le détail de la dette sans navigation intermédiaire.

## Clarifications

### Session 2026-03-13

- Q: Comment gérer le remboursement multi-devise (dette EUR, compte USD) ? → A: Tous les comptes actifs proposés sans filtre par devise, conversion silencieuse côté API (aligné sur Angular).
- Q: Quel comportement pour "Inclure dans le patrimoine" quand un compte est sélectionné ? → A: Auto-coché et masqué quand compte sélectionné (aligné sur Angular).
- Q: Pré-sélection du compte dans la bottom sheet de remboursement ? → A: Compte associé à la dette si existant, sinon premier compte actif (aligné sur Angular).
- Q: Validation de la date de report (snooze) ? → A: Date future obligatoire dans le dialogue de report. Pas de contrainte future dans le formulaire de création/édition (aligné sur Angular).
- Q: Visibilité du champ heure de rappel ? → A: Conditionnel — affiché uniquement si une date de rappel est sélectionnée, défaut 09:00 (aligné sur Angular).
- Q: Messages toast après actions ? → A: Remboursement total : "Dette remboursée !", partiel : "Remboursement enregistré. Reste : {montant}", snooze : "Rappel reporté" (aligné sur Angular).

## Assumptions

- Les endpoints API backend sont disponibles (prérequis KKS-160 / KKS-077 terminé) : repay, getPayments, snooze.
- Le système de notifications push (KKS-072) est en place et fonctionnel.
- Le data layer suit le pattern existant : `DebtRepositoryRemote` via Dio, mode serveur uniquement (pas de Drift pour cette feature).
- Le `DebtListNotifier` existant suit le pattern `CrudNotifier<ListState<Debt>>`.
- Les comptes actifs sont déjà disponibles via le provider existant.
- La devise principale de l'utilisateur est accessible via `AppConfig`.
