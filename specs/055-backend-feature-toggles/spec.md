# Feature Specification: Système de Feature Toggles — Backend

**Feature Branch**: `055-backend-feature-toggles`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "KKS-117 — Backend: Système feature toggle"
**Linear**: [KKS-117](https://linear.app/kksdev/issue/KKS-117/backend-systeme-feature-toggle)

## Clarifications

### Session 2026-02-27

- Q: Lors d'une mise à jour des préférences, le navOrder est-il requis ou optionnel ? → A: navOrder est optionnel dans la requête. Si omis, le backend auto-gère (retire les désactivées, ajoute les nouvelles en fin). Si fourni, le backend valide la cohérence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter ses préférences de fonctionnalités (Priority: P1)

En tant qu'utilisateur, je veux pouvoir consulter quelles fonctionnalités optionnelles sont activées dans mon application et dans quel ordre elles apparaissent dans la navigation, afin de savoir comment mon application est configurée.

**Why this priority**: C'est le point d'entrée indispensable — sans la possibilité de lire les préférences, aucune personnalisation n'est possible côté client.

**Independent Test**: Peut être testé en appelant le point de consultation des préférences et en vérifiant que la réponse contient la liste des fonctionnalités activées et l'ordre de navigation.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié sans préférences personnalisées, **When** il consulte ses préférences, **Then** il obtient les valeurs par défaut : toutes les fonctionnalités optionnelles activées (Abonnements, Dettes, Boutique) et l'ordre de navigation standard.
2. **Given** un utilisateur authentifié avec des préférences personnalisées, **When** il consulte ses préférences, **Then** il obtient ses préférences enregistrées avec les fonctionnalités activées et l'ordre de navigation personnalisé.
3. **Given** un utilisateur non authentifié, **When** il tente de consulter des préférences, **Then** l'accès est refusé.

---

### User Story 2 - Activer ou désactiver des fonctionnalités optionnelles (Priority: P1)

En tant qu'utilisateur, je veux pouvoir activer ou désactiver les fonctionnalités optionnelles (Abonnements, Dettes, Boutique) afin de simplifier mon application en n'affichant que ce dont j'ai besoin.

**Why this priority**: C'est la fonctionnalité cœur de cette feature — permettre la modularité de l'application.

**Independent Test**: Peut être testé en désactivant une fonctionnalité puis en vérifiant que la réponse reflète le changement, et que l'ordre de navigation est mis à jour en conséquence.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec toutes les fonctionnalités activées, **When** il désactive "Dettes" sans fournir de navOrder, **Then** "Dettes" n'apparaît plus dans la liste des fonctionnalités actives et est automatiquement retirée de l'ordre de navigation.
2. **Given** un utilisateur avec "Abonnements" désactivé, **When** il réactive "Abonnements" sans fournir de navOrder, **Then** "Abonnements" apparaît dans la liste des fonctionnalités actives et est ajouté automatiquement en dernière position dans l'ordre de navigation.
3. **Given** un utilisateur, **When** il tente de désactiver toutes les fonctionnalités optionnelles, **Then** le système accepte la demande (le noyau Dashboard + Transactions reste toujours actif) et le navOrder devient vide.
4. **Given** un utilisateur, **When** il tente d'inclure "Dashboard" ou "Transactions" dans la liste des fonctionnalités, **Then** le système rejette la demande car seules les fonctionnalités optionnelles (Abonnements, Dettes, Boutique) sont des valeurs acceptées.

---

### User Story 3 - Personnaliser l'ordre de navigation (Priority: P2)

En tant qu'utilisateur, je veux pouvoir réorganiser l'ordre des onglets de ma barre de navigation afin de placer les fonctionnalités que j'utilise le plus en premier.

**Why this priority**: C'est un confort d'utilisation qui enrichit la personnalisation mais n'est pas bloquant pour le fonctionnement des toggles.

**Independent Test**: Peut être testé en envoyant un nouvel ordre de navigation et en vérifiant que la consultation retourne l'ordre mis à jour.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec Abonnements, Dettes et Boutique activés dans cet ordre, **When** il réordonne en Boutique, Dettes, Abonnements, **Then** l'ordre de navigation est sauvegardé et retourné dans le nouvel ordre.
2. **Given** un utilisateur avec Dettes désactivé, **When** il envoie un ordre de navigation contenant Dettes, **Then** le système rejette la demande car l'ordre ne peut contenir que des fonctionnalités activées.
3. **Given** un utilisateur avec Abonnements et Boutique activés, **When** il envoie un ordre de navigation ne contenant que Abonnements (Boutique manquant), **Then** le système rejette la demande car toutes les fonctionnalités activées doivent être présentes dans l'ordre.

---

### Edge Cases

- Que se passe-t-il si un utilisateur envoie des doublons dans l'ordre de navigation ? Le système rejette la demande avec une erreur de validation.
- Que se passe-t-il si un utilisateur envoie une fonctionnalité inconnue dans la liste des features ou dans l'ordre de navigation ? Le système rejette la demande avec une erreur de validation.
- Que se passe-t-il si un utilisateur envoie une demande avec une liste de features vide ? Le système accepte (toutes les features optionnelles désactivées, ordre de navigation vide).
- Que se passe-t-il à la première connexion d'un utilisateur (aucune préférence existante) ? Le système retourne les valeurs par défaut : toutes les features activées, ordre standard.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre à un utilisateur de consulter ses préférences de fonctionnalités (features activées et ordre de navigation).
- **FR-002**: Le système DOIT permettre à un utilisateur de mettre à jour la liste de ses fonctionnalités activées parmi les fonctionnalités optionnelles disponibles (Abonnements, Dettes, Boutique).
- **FR-003**: Le système DOIT permettre à un utilisateur de définir l'ordre de ses onglets de navigation. L'ordre de navigation est optionnel dans la requête de mise à jour : si fourni, le système valide sa cohérence avec les fonctionnalités activées ; si omis, le système gère automatiquement l'ordre.
- **FR-004**: Le système DOIT initialiser les préférences par défaut pour tout nouvel utilisateur : toutes les fonctionnalités optionnelles activées et ordre de navigation standard (Abonnements, Dettes, Boutique).
- **FR-005**: Le système DOIT garantir que seules les valeurs de l'enum Feature (Abonnements, Dettes, Boutique) sont acceptées. Toute autre valeur (y compris Dashboard ou Transactions) est rejetée.
- **FR-006**: Le système DOIT retirer automatiquement du navOrder toute fonctionnalité désactivée par l'utilisateur lorsque le navOrder n'est pas fourni dans la requête. Lorsqu'une fonctionnalité est réactivée sans navOrder fourni, elle est ajoutée en dernière position.
- **FR-007**: Le système DOIT valider que l'ordre de navigation ne contient que des fonctionnalités actuellement activées.
- **FR-008**: Le système DOIT valider que l'ordre de navigation contient exactement toutes les fonctionnalités activées (ni plus, ni moins, sans doublons).
- **FR-009**: Le système DOIT rejeter toute valeur de fonctionnalité inconnue avec une erreur de validation explicite.
- **FR-010**: Le système DOIT isoler les préférences par utilisateur — chaque utilisateur ne voit et ne modifie que ses propres préférences.
- **FR-011**: Le système DOIT persister les préférences utilisateur avec des valeurs par défaut via migration de schéma.

### Key Entities

- **UserPreference**: Représente les préférences de personnalisation d'un utilisateur. Attributs principaux : liste des fonctionnalités activées, ordre de navigation des onglets. Relation : appartient à un utilisateur (1:1).
- **Feature (enum)**: Ensemble fermé des fonctionnalités optionnelles disponibles : Abonnements (`SUBSCRIPTIONS`), Dettes (`DEBTS`), Boutique (`SHOP`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un utilisateur peut consulter ses préférences en une seule interaction.
- **SC-002**: Un utilisateur peut activer/désactiver n'importe quelle combinaison de fonctionnalités optionnelles en une seule interaction.
- **SC-003**: La modification des préférences est persistée et restituée fidèlement lors de la prochaine consultation.
- **SC-004**: Toute demande invalide (feature inconnue, navOrder incohérent, doublons) est rejetée avec un message d'erreur explicite.
- **SC-005**: Les données de préférences d'un utilisateur sont totalement isolées de celles des autres utilisateurs.

## Assumptions

- L'application est mono-utilisateur en usage courant, mais le système gère les préférences par utilisateur pour respecter l'architecture multi-tenant existante.
- Les fonctionnalités optionnelles actuelles sont limitées à trois (Abonnements, Dettes, Boutique). L'ajout de nouvelles fonctionnalités se fera par extension de l'enum et migration de données.
- L'ordre de navigation standard par défaut est : Abonnements, Dettes, Boutique.
- Lorsqu'une fonctionnalité est réactivée, elle est ajoutée en dernière position dans l'ordre de navigation.
