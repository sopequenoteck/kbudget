# Feature Specification: Virement entre comptes Angular

**Feature Branch**: `066-angular-transfer-form`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "KKS-152 — Virement entre comptes Angular"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Effectuer un virement entre comptes (Priority: P1)

L'utilisateur souhaite transférer de l'argent d'un de ses comptes vers un autre. Il ouvre le formulaire de virement via le bouton d'action flottant, sélectionne le compte source et le compte destination, saisit un montant, et valide. Le système crée deux transactions liées (un débit et un crédit) et met à jour les soldes des deux comptes.

**Why this priority**: C'est la fonctionnalité principale et unique de cette feature. Sans elle, l'utilisateur doit créer manuellement deux transactions séparées pour simuler un virement.

**Independent Test**: Peut être testé en créant un virement entre deux comptes et en vérifiant que les deux transactions apparaissent dans la liste avec le bon montant et le bon type.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a au moins 2 comptes actifs, **When** il clique sur le FAB puis "Virement", **Then** un formulaire de virement s'ouvre dans une modale.
2. **Given** le formulaire de virement est ouvert, **When** l'utilisateur sélectionne un compte source, un compte destination différent, saisit un montant > 0, et valide, **Then** le virement est effectué, la modale se ferme, et la liste des transactions se rafraîchit.
3. **Given** le formulaire de virement est ouvert, **When** l'utilisateur sélectionne le même compte source et destination, **Then** un message d'erreur indique que les comptes doivent être différents et le bouton de validation est désactivé.
4. **Given** le virement est effectué avec succès, **Then** deux transactions liées apparaissent : une DEPENSE sur le compte source et une RECETTE sur le compte destination, avec le même `transferId`.

---

### User Story 2 - Accès conditionnel au virement (Priority: P2)

L'option de virement ne doit être proposée que si l'utilisateur dispose d'au moins 2 comptes actifs. Si ce n'est pas le cas, l'option n'apparaît pas dans le menu d'actions.

**Why this priority**: Évite la confusion de proposer une action impossible à réaliser.

**Independent Test**: Peut être testé en vérifiant la visibilité de l'action "Virement" dans le FAB avec 0, 1, puis 2+ comptes actifs.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a moins de 2 comptes actifs, **When** il ouvre le FAB, **Then** l'option "Virement" n'apparaît pas dans la liste des actions.
2. **Given** l'utilisateur a exactement 2 comptes actifs, **When** il ouvre le FAB, **Then** l'option "Virement" est visible et cliquable.

---

### User Story 3 - Ajouter une note au virement (Priority: P3)

L'utilisateur peut optionnellement ajouter une note descriptive au virement pour garder une trace du motif du transfert.

**Why this priority**: Fonctionnalité secondaire qui enrichit l'expérience mais n'est pas indispensable au virement.

**Independent Test**: Peut être testé en effectuant un virement avec une note et en vérifiant que la note apparaît sur les deux transactions résultantes.

**Acceptance Scenarios**:

1. **Given** le formulaire de virement est ouvert, **When** l'utilisateur saisit une note et valide, **Then** la note est associée aux deux transactions créées.
2. **Given** le formulaire de virement est ouvert, **When** l'utilisateur ne saisit pas de note et valide, **Then** le virement est effectué sans note.

---

### Edge Cases

- Que se passe-t-il si le serveur retourne une erreur lors du virement (compte introuvable, solde insuffisant) ? Le formulaire affiche le message d'erreur du serveur et reste ouvert pour correction.
- Que se passe-t-il si l'utilisateur tente de soumettre un montant de 0 ou négatif ? Le formulaire bloque la soumission via la validation côté client (montant > 0).
- Que se passe-t-il si un compte est désactivé entre l'ouverture du formulaire et la soumission ? Le serveur rejette la requête et le formulaire affiche l'erreur.
- Que se passe-t-il si l'utilisateur annule le formulaire ? La modale se ferme sans aucune action ni effet de bord.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT proposer une action "Virement" dans le menu d'actions flottant (FAB) lorsque l'utilisateur a au moins 2 comptes actifs.
- **FR-002**: Le système DOIT afficher un formulaire de virement dans une modale avec les champs : compte source, compte destination, montant, et note (optionnelle).
- **FR-003**: Le système DOIT empêcher la sélection du même compte comme source et destination (validation cross-champ).
- **FR-004**: Le système DOIT valider que le montant est supérieur à 0 avant soumission.
- **FR-005**: Le système DOIT envoyer la requête de virement au serveur et gérer la réponse (succès ou erreur).
- **FR-006**: En cas de succès, le système DOIT fermer la modale et rafraîchir la liste des transactions.
- **FR-007**: En cas d'erreur serveur, le système DOIT afficher le message d'erreur dans le formulaire sans fermer la modale.
- **FR-008**: Le système DOIT afficher un état de chargement sur le bouton de soumission pendant le traitement de la requête.
- **FR-009**: Le système DOIT permettre l'annulation du formulaire sans effet de bord.
- **FR-010**: Le formulaire DOIT afficher un message explicatif si l'utilisateur a moins de 2 comptes actifs et tente d'accéder au formulaire directement.

### Key Entities

- **Virement (Transfer)** : opération atomique créant deux transactions liées. Attributs : compte source, compte destination, montant, note optionnelle. Résultat : un identifiant de virement (`transferId`) partagé par les deux transactions.
- **Transaction de débit** : transaction de type DEPENSE créée sur le compte source, liée au virement par `transferId`.
- **Transaction de crédit** : transaction de type RECETTE créée sur le compte destination, liée au virement par `transferId`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut effectuer un virement entre deux comptes en moins de 30 secondes (3 interactions : sélection source, sélection destination, saisie montant + validation).
- **SC-002**: 100% des virements effectués génèrent exactement 2 transactions liées visibles dans la liste.
- **SC-003**: Les erreurs de validation (même compte, montant invalide) sont signalées avant toute requête serveur.
- **SC-004**: Les erreurs serveur sont affichées de manière compréhensible sans perte des données saisies par l'utilisateur.

## Assumptions

- L'API backend `POST /accounts/transfer` est déjà implémentée et fonctionnelle.
- Le système de modales (ModalService) et le FAB (speed dial) sont déjà en place dans l'application Angular.
- La date du virement est gérée automatiquement côté serveur (date du jour).
- La note est limitée à 500 caractères (contrainte backend).
- L'opération est atomique côté serveur : soit les deux transactions sont créées, soit aucune.
