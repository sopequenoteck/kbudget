# Feature Specification: Formulaire Transaction (modal)

**Feature Branch**: `009-transaction-form`
**Created**: 2026-02-09
**Status**: Draft
**Input**: User description: "KKS-51 — Formulaire Transaction (modal). Composant formulaire pour créer/éditer une transaction, affiché dans la modal du Shell."
**Linear**: KKS-51

## Clarifications

### Session 2026-02-09

- Q: Comment l'utilisateur choisit-il le type de transaction (DEPENSE/RECETTE) ? → A: Toggle segmenté (2 boutons côte à côte : Dépense / Recette)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer une transaction (Priority: P1)

L'utilisateur ouvre la modal via le bouton flottant (+) et sélectionne "Transaction". Un formulaire s'affiche avec les champs nécessaires pour saisir une nouvelle transaction. Il remplit les informations, soumet le formulaire, et la transaction est enregistrée.

**Why this priority**: C'est le flux principal et la raison d'être du composant. Sans création, le formulaire n'a aucune utilité.

**Independent Test**: Peut être testé en ouvrant la modal, remplissant tous les champs requis, et en vérifiant que l'événement `saved` émet un objet `TransactionRequest` valide.

**Acceptance Scenarios**:

1. **Given** la modal est ouverte en mode création (aucune transaction existante passée en entrée), **When** le formulaire s'affiche, **Then** les champs sont vides sauf la date (aujourd'hui) et le type (DEPENSE par défaut)
2. **Given** l'utilisateur a rempli tous les champs requis (libellé, montant, type, date), **When** il soumet le formulaire, **Then** un événement `saved` est émis avec un objet contenant les valeurs saisies
3. **Given** l'utilisateur a rempli les champs requis et optionnels (catégorie, note), **When** il soumet le formulaire, **Then** l'objet émis contient aussi `categoryId` et `note`

---

### User Story 2 - Validation des champs obligatoires (Priority: P1)

L'utilisateur tente de soumettre le formulaire sans remplir tous les champs requis. Le système affiche des messages d'erreur ciblés pour chaque champ invalide et empêche la soumission.

**Why this priority**: La validation garantit l'intégrité des données et évite des erreurs côté serveur. Indissociable de la création.

**Independent Test**: Peut être testé en soumettant un formulaire vide et en vérifiant que les messages d'erreur apparaissent pour chaque champ requis.

**Acceptance Scenarios**:

1. **Given** le formulaire est affiché, **When** l'utilisateur soumet sans remplir le libellé, **Then** un message d'erreur "Libellé requis" s'affiche sous le champ
2. **Given** le formulaire est affiché, **When** l'utilisateur saisit un montant négatif ou zéro, **Then** un message d'erreur "Le montant doit être supérieur à 0" s'affiche
3. **Given** le formulaire est affiché, **When** l'utilisateur efface la date, **Then** un message d'erreur "Date requise" s'affiche
4. **Given** un ou plusieurs champs sont invalides, **When** l'utilisateur tente de soumettre, **Then** le formulaire ne se soumet pas et tous les champs invalides sont mis en évidence

---

### User Story 3 - Éditer une transaction existante (Priority: P2)

L'utilisateur ouvre la modal pour modifier une transaction existante. Le formulaire est pré-rempli avec les valeurs actuelles de la transaction. Il modifie les champs souhaités et soumet pour enregistrer les changements.

**Why this priority**: L'édition est essentielle mais secondaire à la création. Elle réutilise le même formulaire avec un mode différent.

**Independent Test**: Peut être testé en passant une transaction existante en entrée et en vérifiant que les champs sont pré-remplis, puis que la soumission émet les valeurs modifiées.

**Acceptance Scenarios**:

1. **Given** une transaction existante est passée en entrée du formulaire, **When** le formulaire s'affiche, **Then** tous les champs sont pré-remplis avec les valeurs de la transaction (libellé, montant, type, date, catégorie, note)
2. **Given** le formulaire est pré-rempli en mode édition, **When** l'utilisateur modifie le montant et soumet, **Then** l'événement `saved` émet un objet avec le nouveau montant et les autres valeurs inchangées

---

### User Story 4 - Annuler la saisie (Priority: P2)

L'utilisateur décide d'annuler la saisie en cours. Il clique sur le bouton d'annulation et la modal se ferme sans enregistrer de données.

**Why this priority**: L'annulation est un flux standard nécessaire pour une bonne expérience utilisateur.

**Independent Test**: Peut être testé en cliquant sur le bouton annuler et en vérifiant que l'événement `cancelled` est émis sans aucune donnée.

**Acceptance Scenarios**:

1. **Given** le formulaire est affiché (création ou édition), **When** l'utilisateur clique sur "Annuler", **Then** un événement `cancelled` est émis
2. **Given** l'utilisateur a rempli des champs, **When** il clique sur "Annuler", **Then** les données saisies sont perdues et aucun événement `saved` n'est émis

---

### Edge Cases

- Que se passe-t-il si le libellé contient 255 caractères (limite maximale) ? Le formulaire doit accepter exactement 255 caractères et refuser au-delà.
- Que se passe-t-il si la note contient 500 caractères (limite maximale) ? Le formulaire doit accepter exactement 500 caractères et refuser au-delà.
- Que se passe-t-il si l'utilisateur saisit un montant avec plus de 2 décimales ? Le formulaire accepte la saisie (la troncature est gérée côté serveur).
- Que se passe-t-il si aucune catégorie n'est disponible ? Le champ catégorie affiche uniquement l'option par défaut "Aucune catégorie".
- Que se passe-t-il si la transaction passée en mode édition a une catégorie qui n'existe plus ? Le champ catégorie revient à l'option par défaut "Aucune catégorie".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le formulaire DOIT afficher les champs suivants : libellé (texte), montant (numérique), type (sélection entre DEPENSE et RECETTE), date (date), catégorie (sélection optionnelle), note (zone de texte optionnelle)
- **FR-002**: Le libellé DOIT être obligatoire et limité à 255 caractères maximum
- **FR-003**: Le montant DOIT être obligatoire et strictement supérieur à 0
- **FR-004**: Le type DOIT être obligatoire avec DEPENSE comme valeur par défaut, présenté sous forme de toggle segmenté (2 boutons côte à côte : Dépense / Recette)
- **FR-005**: La date DOIT être obligatoire avec la date du jour comme valeur par défaut
- **FR-006**: La catégorie DOIT être un champ optionnel présentant la liste des catégories disponibles
- **FR-007**: La note DOIT être un champ optionnel limité à 500 caractères maximum
- **FR-008**: En mode création (aucune transaction en entrée), les champs DOIVENT être initialisés avec les valeurs par défaut (date = aujourd'hui, type = DEPENSE, autres vides)
- **FR-009**: En mode édition (transaction existante en entrée), les champs DOIVENT être pré-remplis avec les valeurs de la transaction
- **FR-010**: La soumission DOIT être bloquée tant que des champs requis sont invalides, avec affichage des messages d'erreur correspondants
- **FR-011**: Lors de la soumission réussie, le formulaire DOIT émettre un événement `saved` contenant les données saisies au format attendu par le service
- **FR-012**: Le bouton d'annulation DOIT émettre un événement `cancelled` sans données
- **FR-013**: Les messages d'erreur DOIVENT s'afficher uniquement après que l'utilisateur a interagi avec le champ (touched) ou tenté de soumettre

### Key Entities

- **Transaction**: Opération financière caractérisée par un libellé, un montant, un type (dépense ou recette), une date, une catégorie optionnelle et une note optionnelle
- **Catégorie**: Classification d'une transaction, identifiée par un nom, une icône et une couleur. Sélectionnée par l'utilisateur dans une liste déroulante
- **TransactionRequest**: Objet de transfert contenant : montant, libellé, type, date, categoryId (optionnel), note (optionnel)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une transaction en remplissant le formulaire et en soumettant en moins de 15 secondes (3 champs requis + soumission)
- **SC-002**: 100% des champs invalides affichent un message d'erreur explicite avant la soumission
- **SC-003**: Le formulaire en mode édition affiche les valeurs existantes instantanément (pas de chargement visible)
- **SC-004**: L'annulation ferme le formulaire sans effet de bord ni perte de données ailleurs dans l'application
- **SC-005**: Le formulaire est utilisable sur mobile (écran 360px de large minimum) sans défilement horizontal

## Assumptions

- Les catégories sont déjà disponibles via un service existant et chargées avant l'ouverture du formulaire
- Le composant modal parent (Shell) gère l'ouverture/fermeture de la modal ; le formulaire ne gère que son contenu
- La conversion de la date au format attendu par le serveur (ISO) est gérée par le formulaire avant émission
- Le type par défaut est DEPENSE car c'est le cas d'usage le plus fréquent pour une application de budget
- Le formulaire n'appelle pas directement le service backend ; il émet un événement avec les données, et le composant parent se charge de l'appel API
