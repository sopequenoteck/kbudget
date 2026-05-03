# Feature Specification: ModalService et câblage édition/suppression

**Feature Branch**: `016-modal-service`
**Created**: 2026-02-12
**Status**: Draft
**Input**: KKS-58 — Créer ModalService et câbler édition/suppression. Centraliser la gestion de la modal dans un service injectable, permettre l'édition et la suppression des entités depuis les écrans de liste.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Éditer une entité existante (Priority: P1)

L'utilisateur consulte une liste (transactions, abonnements ou dettes) et souhaite modifier un élément. Il tape sur l'élément dans la liste, une modale s'ouvre pré-remplie avec les données existantes. Il modifie les champs souhaités, sauvegarde, et la liste se met à jour avec les nouvelles valeurs.

**Why this priority**: C'est la fonctionnalité principale demandée. Sans édition, l'utilisateur doit supprimer et recréer manuellement chaque élément pour corriger une erreur, ce qui est frustrant et chronophage.

**Independent Test**: Peut être testé en naviguant vers n'importe quelle liste, en tapant sur un élément, en modifiant un champ et en sauvegardant. L'élément mis à jour apparaît immédiatement dans la liste.

**Acceptance Scenarios**:

1. **Given** une liste de transactions affichée, **When** l'utilisateur tape sur une transaction, **Then** la modale s'ouvre avec le formulaire pré-rempli des données de cette transaction
2. **Given** la modale ouverte en mode édition, **When** l'utilisateur modifie le montant et sauvegarde, **Then** la modale se ferme et la liste affiche le montant mis à jour
3. **Given** la modale ouverte en mode édition, **When** l'utilisateur annule (bouton annuler ou fermeture modale), **Then** aucune modification n'est appliquée et la liste reste inchangée
4. **Given** une liste d'abonnements affichée, **When** l'utilisateur tape sur un abonnement, **Then** la modale s'ouvre avec le formulaire abonnement pré-rempli
5. **Given** une liste de dettes affichée, **When** l'utilisateur tape sur une dette, **Then** la modale s'ouvre avec le formulaire dette pré-rempli

---

### User Story 2 - Supprimer une entité existante (Priority: P2)

L'utilisateur ouvre un élément en mode édition et souhaite le supprimer définitivement. Un bouton "Supprimer" est visible uniquement en mode édition. Après confirmation, l'élément est supprimé et la liste se met à jour.

**Why this priority**: La suppression est complémentaire à l'édition. Elle permet de corriger des erreurs de saisie ou de retirer des éléments obsolètes. Elle nécessite le mode édition (P1) comme prérequis.

**Independent Test**: Peut être testé en ouvrant un élément existant, en cliquant sur "Supprimer", en confirmant la suppression, et en vérifiant que l'élément disparaît de la liste.

**Acceptance Scenarios**:

1. **Given** la modale ouverte en mode édition, **When** l'utilisateur voit le formulaire, **Then** un bouton "Supprimer" est visible
2. **Given** la modale ouverte en mode création, **When** l'utilisateur voit le formulaire, **Then** le bouton "Supprimer" n'est PAS visible
3. **Given** le bouton "Supprimer" visible, **When** l'utilisateur clique dessus, **Then** une demande de confirmation s'affiche avant la suppression
4. **Given** la confirmation de suppression affichée, **When** l'utilisateur confirme, **Then** l'élément est supprimé, la modale se ferme et la liste se met à jour
5. **Given** la confirmation de suppression affichée, **When** l'utilisateur annule, **Then** rien ne se passe et la modale reste ouverte en mode édition

---

### User Story 3 - Centralisation de la gestion modale (Priority: P3)

La gestion de l'état de la modale (ouverte/fermée, type d'entité, entité en cours d'édition) est centralisée dans un service unique accessible depuis n'importe quel composant. Les écrans de liste peuvent ouvrir la modale directement sans passer par une chaîne d'outputs parent-enfant.

**Why this priority**: C'est une amélioration architecturale qui simplifie le code et prépare l'évolutivité. Les user stories P1 et P2 peuvent fonctionner sans cette centralisation, mais elle rend le code plus maintenable.

**Independent Test**: Peut être vérifié en ouvrant une modale depuis n'importe quel écran de liste et en constatant que le Shell réagit correctement sans couplage direct entre composants.

**Acceptance Scenarios**:

1. **Given** l'utilisateur sur l'écran transactions, **When** il tape sur un élément, **Then** la modale s'ouvre sans que l'écran ait besoin de communiquer directement avec le Shell
2. **Given** la modale ouverte, **When** l'utilisateur navigue vers un autre écran, **Then** la modale se ferme automatiquement
3. **Given** le FAB speed dial visible, **When** l'utilisateur choisit de créer une nouvelle entité, **Then** la modale s'ouvre en mode création via le même mécanisme centralisé

---

### Edge Cases

- Que se passe-t-il si la suppression échoue (erreur réseau) ? L'utilisateur doit être informé et l'élément ne doit pas disparaître de la liste.
- Que se passe-t-il si l'utilisateur modifie un formulaire puis ferme la modale sans sauvegarder ? Les modifications sont perdues sans avertissement (comportement existant conservé).
- Que se passe-t-il si l'utilisateur double-tape rapidement sur un élément ? La modale ne doit s'ouvrir qu'une seule fois.
- Que se passe-t-il si l'entité a été supprimée par ailleurs entre le chargement de la liste et le clic ? L'erreur serveur doit être gérée gracieusement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT fournir un service centralisé pour gérer l'état de la modale (type actif, entité en édition)
- **FR-002**: Le système DOIT permettre l'ouverture de la modale en mode édition au clic/tap sur un élément de liste
- **FR-003**: Le système DOIT pré-remplir le formulaire avec les données de l'entité sélectionnée en mode édition
- **FR-004**: Le système DOIT distinguer le mode création (nouvelle entité) du mode édition (entité existante) et appeler l'opération appropriée (création ou mise à jour)
- **FR-005**: Le système DOIT afficher un bouton "Supprimer" uniquement en mode édition
- **FR-006**: Le système DOIT demander une confirmation avant toute suppression
- **FR-007**: Le système DOIT mettre à jour la liste après une édition ou une suppression réussie
- **FR-008**: Le système DOIT fermer la modale après une sauvegarde ou une suppression réussie
- **FR-009**: Le système DOIT permettre à n'importe quel composant d'ouvrir la modale via le service centralisé
- **FR-010**: Le titre de la modale DOIT refléter le mode (ex: "Nouvelle transaction" vs "Modifier la transaction")

### Key Entities

- **ModalState**: Représente l'état courant de la modale — type d'entité active (transaction, abonnement, dette ou aucun) et l'entité en cours d'édition le cas échéant
- **Transaction, Subscription, Debt**: Entités métier existantes pouvant être éditées ou supprimées via la modale

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut ouvrir, modifier et sauvegarder une entité existante en 3 interactions (tap sur l'élément, modifier un champ, sauvegarder)
- **SC-002**: L'utilisateur peut supprimer une entité en 3 interactions (tap sur l'élément, supprimer, confirmer)
- **SC-003**: 100% des types d'entités (transactions, abonnements, dettes) supportent l'édition et la suppression
- **SC-004**: La liste se met à jour immédiatement après chaque édition ou suppression sans rechargement manuel de la page
- **SC-005**: Le bouton "Supprimer" n'est jamais visible en mode création, évitant toute confusion utilisateur

## Assumptions

- Les services CRUD existants (create, update, delete) fonctionnent correctement et sont déjà testés
- Les formulaires existants supportent déjà le mode édition via un input optionnel (entité ou null)
- Le composant ListItem existant émet déjà un événement au clic/tap
- Le composant Modal existant gère déjà le focus trap et la fermeture par overlay/Escape
- Le comportement existant de perte des modifications non sauvegardées à la fermeture de la modale est acceptable (pas de confirmation "Voulez-vous sauvegarder ?")
- La confirmation de suppression utilise un mécanisme simple intégré au formulaire (pas de modale de confirmation séparée)
