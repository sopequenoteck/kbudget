# Feature Specification: Formulaire de création et conversion de transactions récurrentes (Angular)

**Feature Branch**: `087-angular-recurring-form`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Ajouter la possibilité de créer une transaction récurrente et de convertir une transaction existante en récurrente côté Angular. Le backend POST /transactions/recurring existe déjà (KKS-085).

## User Scenarios & Testing

### User Story 1 - Créer une transaction récurrente depuis le formulaire (Priority: P1)

L'utilisateur ouvre le formulaire de création de transaction (via le FAB +), active le toggle "Récurrente", choisit une fréquence et une date de prochaine occurrence, puis valide. La transaction récurrente est créée et apparaît dans la liste des récurrences.

**Why this priority**: C'est la fonctionnalité principale demandée. Sans elle, l'utilisateur ne peut créer de transactions récurrentes que via l'API directement, ce qui n'est pas utilisable.

**Independent Test**: Ouvrir le formulaire de transaction, activer le toggle récurrence, remplir les champs, soumettre. Vérifier que la récurrence apparaît dans /transactions/recurring.

**Acceptance Scenarios**:

1. **Given** le formulaire de transaction est ouvert en mode création, **When** l'utilisateur active le toggle "Récurrente", **Then** les champs fréquence et prochaine occurrence apparaissent et le champ date classique disparaît
2. **Given** le toggle récurrence est activé avec tous les champs remplis, **When** l'utilisateur soumet le formulaire, **Then** une transaction récurrente est créée via l'API et un toast de confirmation s'affiche
3. **Given** le toggle récurrence est activé, **When** l'utilisateur désactive le toggle, **Then** les champs fréquence et prochaine occurrence disparaissent et le champ date classique réapparaît
4. **Given** le toggle récurrence est activé mais la date de prochaine occurrence est dans le passé, **When** l'utilisateur soumet, **Then** le formulaire affiche une erreur de validation

---

### User Story 2 - Convertir une transaction existante en récurrente (Priority: P2)

Depuis la liste des transactions, l'utilisateur peut déclencher une action "Rendre récurrente" sur une transaction existante. Cela ouvre le formulaire de création pré-rempli avec les données de la transaction source (montant, libellé, type, catégorie, compte) et le toggle récurrence activé. La transaction d'origine reste inchangée.

**Why this priority**: Complète la US1 en offrant un raccourci depuis les transactions existantes. L'utilisateur n'a pas à ressaisir les informations.

**Independent Test**: Depuis la liste des transactions, cliquer sur "Rendre récurrente" pour une transaction, vérifier que le formulaire s'ouvre pré-rempli en mode récurrent, soumettre, et vérifier que la récurrence est créée.

**Acceptance Scenarios**:

1. **Given** la liste des transactions affiche des transactions, **When** l'utilisateur clique sur l'action "Rendre récurrente" d'une transaction, **Then** le formulaire de transaction s'ouvre en mode création avec les champs pré-remplis (montant, libellé, type, catégorie, compte) et le toggle récurrence activé
2. **Given** le formulaire est pré-rempli depuis une transaction existante, **When** l'utilisateur modifie le montant et soumet, **Then** la récurrence est créée avec le montant modifié et la transaction d'origine reste inchangée
3. **Given** le formulaire est pré-rempli depuis une transaction existante, **When** l'utilisateur choisit la fréquence et la date de prochaine occurrence puis soumet, **Then** la récurrence est créée avec ces paramètres

---

### Edge Cases

- Que se passe-t-il si l'utilisateur active le toggle récurrence en mode édition d'une transaction existante ? Le toggle ne doit pas être affiché en mode édition (la conversion se fait via l'action dédiée, pas en éditant une transaction).
- Que se passe-t-il si l'utilisateur tente de créer une récurrence sans sélectionner de fréquence ? La fréquence a une valeur par défaut (Mensuel), donc ce cas ne devrait pas se produire.
- Que se passe-t-il si le serveur retourne une erreur lors de la création ? Un message d'erreur s'affiche dans le formulaire, les données restent saisies pour permettre une nouvelle tentative.

## Requirements

### Functional Requirements

- **FR-001**: Le formulaire de transaction DOIT proposer un toggle "Récurrente" visible uniquement en mode création (pas en mode édition)
- **FR-002**: Lorsque le toggle récurrence est activé, le système DOIT afficher un sélecteur de fréquence (Hebdomadaire, Mensuel, Annuel) avec "Mensuel" comme valeur par défaut
- **FR-003**: Lorsque le toggle récurrence est activé, le système DOIT afficher un champ date "Prochaine occurrence" et masquer le champ date classique
- **FR-004**: La date de prochaine occurrence DOIT être aujourd'hui ou dans le futur
- **FR-005**: La soumission du formulaire en mode récurrent DOIT créer la transaction récurrente via l'endpoint existant POST /transactions/recurring
- **FR-006**: La liste des transactions DOIT proposer une action "Rendre récurrente" sur chaque transaction
- **FR-007**: L'action "Rendre récurrente" DOIT ouvrir le formulaire pré-rempli avec les données de la transaction source et le toggle récurrence activé
- **FR-008**: Un toast de confirmation DOIT s'afficher après la création réussie d'une transaction récurrente
- **FR-009**: En cas d'erreur serveur, un message d'erreur DOIT s'afficher dans le formulaire

### Key Entities

- **Transaction récurrente** : montant, libellé, type (dépense/recette), fréquence (hebdomadaire/mensuel/annuel), prochaine occurrence, catégorie, compte
- **Transaction existante** : sert de source pour le pré-remplissage lors de la conversion (aucune modification de la transaction source)

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une transaction récurrente en moins de 4 interactions depuis le FAB (ouvrir formulaire, activer toggle, remplir date, soumettre)
- **SC-002**: La conversion d'une transaction existante en récurrente se fait en 2 interactions (action "Rendre récurrente", soumettre le formulaire pré-rempli)
- **SC-003**: Tous les tests unitaires existants continuent de passer après les modifications
- **SC-004**: Au moins 4 nouveaux tests couvrent les scénarios de création et de conversion de récurrence

## Assumptions

- Le backend POST /transactions/recurring (KKS-085) est fonctionnel et déployé
- Le modèle `RecurringTransactionResponse` existe déjà côté Angular (KKS-086)
- L'enum `Frequency` (HEBDOMADAIRE, MENSUEL, ANNUEL) est déjà défini dans le modèle subscription
- Le `RecurringTransactionService` existe déjà mais ne possède pas de méthode `create()`
- Le `TransactionForm` utilise le `ModalService` pour l'ouverture/fermeture
- La transaction d'origine n'est jamais modifiée lors d'une conversion

## Scope

### In scope

- Enrichissement du formulaire de transaction existant avec toggle récurrence
- Ajout de `RecurringTransactionRequest` et `create()` au service
- Action "Rendre récurrente" dans la liste de transactions

### Out of scope

- Modification du backend (déjà implémenté KKS-085)
- Édition d'une transaction récurrente existante (modification de fréquence, etc.)
- Flutter (fera l'objet d'une issue séparée)
