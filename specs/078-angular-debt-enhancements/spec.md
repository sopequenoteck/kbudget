# Feature Specification: Améliorations dettes Angular

**Feature Branch**: `078-angular-debt-enhancements`
**Created**: 2026-03-10
**Status**: Draft
**Input**: KKS-195 — Enrichissement interface dettes Angular : association compte bancaire, remboursement avec suivi des paiements, toggle patrimoine, rappels.
**Linear**: [KKS-195](https://linear.app/kksdev/issue/KKS-195)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rembourser une dette (Priority: P1)

L'utilisateur consulte le détail d'une dette et souhaite enregistrer un remboursement (total ou partiel). Il clique sur "Rembourser", sélectionne le compte source, ajuste le montant si nécessaire, et valide. La transaction est créée, le montant restant est mis à jour, et une barre de progression montre l'avancement.

**Why this priority**: Le remboursement est la fonctionnalité centrale de la gestion de dettes. Sans elle, le suivi des paiements n'a pas de sens.

**Independent Test**: Peut être testé en ouvrant le détail d'une dette existante, en cliquant "Rembourser", et en vérifiant que la transaction est créée et le montant restant recalculé.

**Acceptance Scenarios**:

1. **Given** une dette active de 500 EUR avec 0 EUR remboursé, **When** l'utilisateur rembourse 200 EUR depuis un compte, **Then** le montant restant affiche 300 EUR, la barre de progression montre 40%, et la transaction apparaît dans l'historique des paiements.
2. **Given** une dette active avec 200 EUR restant, **When** l'utilisateur rembourse 50 EUR, **Then** le montant restant affiche 150 EUR, la barre de progression se met à jour, et un toast affiche "Remboursement de 50 € enregistré. Reste : 150 €".
3. **Given** une dette active de 300 EUR restant, **When** l'utilisateur rembourse la totalité (300 EUR), **Then** la dette est marquée "Remboursé", un badge "Remboursé" s'affiche, et un toast affiche "Dette remboursée !".
4. **Given** une dette active, **When** l'utilisateur ouvre le dialog de remboursement, **Then** le montant est pré-rempli avec le montant restant et le champ compte source est obligatoire.
5. **Given** une dette sans compte associé, **When** l'utilisateur rembourse, **Then** il doit sélectionner un compte source dans le dialog.

---

### User Story 2 - Formulaire dette enrichi (Priority: P1)

L'utilisateur crée ou modifie une dette avec de nouveaux champs : compte bancaire associé (optionnel), rappel (date + heure), et toggle "Inclure dans le patrimoine". Le formulaire s'adapte dynamiquement selon les sélections.

**Why this priority**: Le formulaire est le point d'entrée pour créer des dettes enrichies. Les nouveaux champs (compte, rappel, patrimoine) sont nécessaires pour toutes les autres fonctionnalités.

**Independent Test**: Peut être testé en créant une nouvelle dette avec un compte associé et un rappel, puis en vérifiant que les valeurs sont enregistrées et re-affichées en édition.

**Acceptance Scenarios**:

1. **Given** le formulaire de création de dette, **When** l'utilisateur sélectionne un compte bancaire, **Then** la devise est forcée à celle du compte et le champ devise est masqué.
2. **Given** le formulaire de création de dette, **When** aucun compte n'est sélectionné, **Then** la devise est celle par défaut de l'utilisateur et le toggle "Inclure dans le patrimoine" est visible.
3. **Given** le formulaire de création de dette, **When** un compte est sélectionné, **Then** le toggle "Inclure dans le patrimoine" est masqué.
4. **Given** le formulaire avec un rappel défini (date + heure), **When** l'utilisateur sauvegarde, **Then** le rappel est enregistré et visible en édition.
5. **Given** une dette existante avec un compte associé, **When** l'utilisateur ouvre le formulaire d'édition, **Then** le compte est pré-sélectionné et la devise affiche celle du compte.

---

### User Story 3 - Consulter l'historique des paiements (Priority: P2)

L'utilisateur accède à l'écran de détail d'une dette et voit l'historique chronologique des paiements effectués, avec pour chaque paiement la date, le montant et le compte source. Un total cumulé est affiché.

**Why this priority**: L'historique donne la visibilité sur les remboursements passés. C'est un complément essentiel de la US1 mais peut être consulté indépendamment.

**Independent Test**: Peut être testé en consultant le détail d'une dette qui a déjà des paiements enregistrés et en vérifiant la liste affichée.

**Acceptance Scenarios**:

1. **Given** une dette avec 3 paiements effectués, **When** l'utilisateur ouvre le détail, **Then** la section "Historique paiements" affiche les 3 paiements classés du plus récent au plus ancien, avec date, montant et compte.
2. **Given** une dette sans paiement, **When** l'utilisateur ouvre le détail, **Then** la section historique affiche un état vide approprié.
3. **Given** une dette avec des paiements, **When** l'utilisateur consulte l'historique, **Then** le total cumulé des paiements est affiché.

---

### User Story 4 - Reporter un rappel de dette (Priority: P2)

Depuis une notification de dette ou l'écran de détail, l'utilisateur peut reporter le rappel à une nouvelle date et heure via un dialog rapide.

**Why this priority**: Le report de rappel est une action courante qui complète la gestion des rappels définis dans le formulaire.

**Independent Test**: Peut être testé en recevant une notification de dette et en cliquant "Reporter", puis en vérifiant que la nouvelle date est enregistrée.

**Acceptance Scenarios**:

1. **Given** une notification de rappel de dette, **When** l'utilisateur clique "Reporter", **Then** un dialog s'ouvre avec des champs date et heure pour le nouveau rappel.
2. **Given** le dialog de report ouvert, **When** l'utilisateur choisit une nouvelle date/heure et valide, **Then** le rappel est mis à jour et la notification est traitée.
3. **Given** le dialog de report, **When** l'utilisateur choisit une date dans le passé, **Then** une erreur de validation s'affiche.

---

### User Story 5 - Actions notification dette (Priority: P3)

Les notifications de type dette proposent deux actions rapides : "Reporter" (ouvre le dialog de report) et "Rembourser" (ouvre le dialog de remboursement).

**Why this priority**: Amélioration de productivité qui s'appuie sur les US1 et US4. Utile mais pas bloquant pour les fonctionnalités de base.

**Independent Test**: Peut être testé en naviguant vers les notifications, en identifiant une notification de type dette, et en vérifiant que les deux boutons d'action sont présents et fonctionnels.

**Acceptance Scenarios**:

1. **Given** une notification de type dette, **When** l'utilisateur la visualise, **Then** deux boutons d'action "Reporter" et "Rembourser" sont affichés.
2. **Given** une notification de dette, **When** l'utilisateur clique "Rembourser", **Then** le dialog de remboursement s'ouvre pré-rempli avec les informations de la dette.
3. **Given** une notification de dette, **When** l'utilisateur clique "Reporter", **Then** le dialog de report s'ouvre.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur tente de rembourser un montant supérieur au restant dû ? → Le champ montant a un maximum fixé au restant dû (prévention via contrainte de saisie, pas de message d'avertissement nécessaire).
- Que se passe-t-il si le compte sélectionné pour le remboursement est désactivé entre-temps ? → Seuls les comptes actifs sont proposés dans la liste.
- Que se passe-t-il si la dette est déjà entièrement remboursée ? → Le bouton "Rembourser" est désactivé et un badge "Remboursé" est affiché.
- Que se passe-t-il si l'utilisateur supprime le compte associé à une dette ? → La dette conserve son historique, le champ compte devient vide.
- Que se passe-t-il si aucun compte actif n'existe pour le remboursement ? → Le bouton "Rembourser" est désactivé avec un tooltip explicatif.
- Que se passe-t-il en cas de remboursement partiel avec un montant de 0 ? → Le formulaire valide que le montant est strictement positif.

## Clarifications

### Session 2026-03-10

- Q: Quelle valeur pour `includeInBalance` quand un compte est associé à la dette ? → A: Auto-incluse (`includeInBalance = true` automatiquement). La dette liée à un compte contribue au patrimoine total via le solde agrégé.
- Q: Pré-sélection du compte dans le dialog de remboursement quand la dette a un compte associé ? → A: Pré-sélectionner le compte associé (modifiable par l'utilisateur).
- Q: Feedback visuel après un remboursement partiel ? → A: Toast succès avec détail : "Remboursement de X € enregistré. Reste : Y €".
- Q: Correspondance terminologique reporter/snooze ? → A: "Reporter" côté UI francophone, "snooze" côté technique (API endpoint `/debts/{id}/snooze`, code Angular `DebtSnoozeRequest`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre d'associer un compte bancaire optionnel à une dette lors de la création ou l'édition.
- **FR-002**: Le système DOIT forcer la devise de la dette à celle du compte quand un compte est sélectionné, et masquer le sélecteur de devise.
- **FR-003**: Le système DOIT afficher le toggle "Inclure dans le patrimoine" uniquement quand aucun compte n'est associé. Quand un compte est sélectionné, `includeInBalance` est automatiquement défini à `true`.
- **FR-004**: Le système DOIT permettre de définir un rappel (date + heure) sur une dette.
- **FR-005**: Le système DOIT permettre le remboursement total ou partiel d'une dette via un dialog avec sélection de compte source et montant.
- **FR-006**: Le système DOIT pré-remplir le montant du remboursement avec le montant restant dû. Si la dette a un compte associé, ce compte DOIT être pré-sélectionné comme source (modifiable).
- **FR-007**: Le système DOIT créer une transaction lors d'un remboursement et rafraîchir les données de la dette.
- **FR-008**: Le système DOIT afficher le montant restant et une barre de progression sur l'écran de détail de la dette.
- **FR-009**: Le système DOIT afficher l'historique des paiements (date, montant, compte) avec total cumulé sur l'écran de détail.
- **FR-010**: Le système DOIT marquer visuellement une dette comme "Remboursé" quand le montant restant atteint zéro.
- **FR-011**: Le système DOIT permettre de reporter un rappel de dette à une nouvelle date/heure via un dialog.
- **FR-012**: Le système DOIT valider que la date de report est dans le futur.
- **FR-013**: Le système DOIT proposer les actions "Reporter" et "Rembourser" sur les notifications de type dette.
- **FR-014**: Le système DOIT plafonner le montant de remboursement au montant restant dû.
- **FR-015**: Le système DOIT ne proposer que les comptes actifs dans les sélecteurs de compte (formulaire et dialog remboursement).

### Key Entities

- **Dette (enrichie)** : Montant, personne, sens (emprunt/prêt), date, devise, compte bancaire associé (optionnel), rappel (date + heure, optionnel), inclusion dans le patrimoine (conditionnel), statut remboursement.
- **Paiement de dette** : Date, montant, compte source — lié à une transaction créée automatiquement.
- **Notification dette** : Type rappel, actions contextuelles (reporter, rembourser).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une dette avec compte bancaire et rappel en moins de 30 secondes.
- **SC-002**: L'utilisateur peut effectuer un remboursement (ouverture dialog → validation) en moins de 15 secondes.
- **SC-003**: Le montant restant et la barre de progression se mettent à jour immédiatement après un remboursement sans rechargement de page.
- **SC-004**: L'historique des paiements affiche correctement toutes les entrées avec total cumulé.
- **SC-005**: Le report de rappel fonctionne en moins de 10 secondes depuis une notification.
- **SC-006**: Tous les composants sont couverts par des tests unitaires.

## Assumptions

- Les endpoints API backend (repay, getPayments, postpone) sont disponibles et fonctionnels (KKS-077 terminé).
- Le système de notifications Angular est déjà en place (KKS-072).
- Le formulaire de dette existant (`DebtFormComponent`) est enrichissable sans refonte complète.
- Le `DebtService` Angular existe et peut être étendu avec les nouvelles méthodes.
- Les comptes actifs sont récupérables via le `AccountService` existant.

## Out of Scope

- Modification du backend (les endpoints existent déjà).
- Remboursement automatique ou récurrent.
- Notifications push (seules les notifications in-app sont concernées).
- Gestion multi-devises lors du remboursement (la devise du remboursement suit la dette).
