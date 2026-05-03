# Feature Specification: Flutter Settings — Gestion Catégories

**Feature Branch**: `054-flutter-settings-categories`
**Created**: 2026-02-26
**Status**: Draft
**Input**: User description: "Flutter: Settings — Gestion Catégories. Sous-page: liste des catégories + CRUD. Formulaire: nom, icône (EmojiInput), couleur. Protection catégories système. Ref: categories.html + category-form Angular."
**Linear**: KKS-114

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des catégories (Priority: P1)

L'utilisateur accède à la sous-page "Catégories" depuis les paramètres pour visualiser toutes ses catégories personnalisées. Les catégories système (Abonnement, Dette, Virement, Ajustement) sont visibles mais clairement identifiées comme non modifiables. La liste affiche le nom, l'icône emoji et la couleur de chaque catégorie.

**Why this priority**: C'est le point d'entrée de la feature — sans la liste, aucune autre interaction n'est possible. L'utilisateur doit pouvoir voir ses catégories existantes avant de les gérer.

**Independent Test**: Peut être testé en naviguant vers Paramètres > Catégories et en vérifiant que toutes les catégories apparaissent avec leurs attributs visuels (icône, couleur, nom).

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran des paramètres, **When** il tape sur "Catégories", **Then** la liste de toutes ses catégories s'affiche, triée par nom alphabétique
2. **Given** la liste est en cours de chargement, **When** les données ne sont pas encore disponibles, **Then** un squelette de chargement (shimmer) s'affiche
3. **Given** la liste est affichée, **When** l'utilisateur tire vers le bas, **Then** les catégories sont rafraîchies depuis la source de données
4. **Given** le chargement échoue (erreur réseau), **When** l'écran s'affiche, **Then** un message d'erreur apparaît avec un bouton "Réessayer"
5. **Given** l'utilisateur n'a aucune catégorie personnalisée, **When** la liste s'affiche, **Then** un état vide est affiché avec une invitation à créer une première catégorie

---

### User Story 2 - Créer une nouvelle catégorie (Priority: P1)

L'utilisateur crée une catégorie en remplissant un formulaire avec le nom, une icône emoji et une couleur. Une couleur aléatoire est pré-sélectionnée à l'ouverture du formulaire.

**Why this priority**: La création est essentielle pour que l'utilisateur puisse personnaliser ses catégories de transactions, abonnements et dettes.

**Independent Test**: Peut être testé en tapant le bouton "+" dans la barre d'application, en remplissant le formulaire, et en vérifiant que la catégorie apparaît dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la liste des catégories, **When** il tape le bouton d'ajout (+), **Then** le formulaire de création s'ouvre avec une couleur aléatoire pré-sélectionnée
2. **Given** le formulaire est ouvert, **When** l'utilisateur remplit le nom, sélectionne un emoji et une couleur puis valide, **Then** la catégorie est créée et l'utilisateur revient à la liste mise à jour
3. **Given** le formulaire est ouvert, **When** l'utilisateur tente de valider sans nom, **Then** un message de validation s'affiche
4. **Given** le formulaire est ouvert, **When** l'utilisateur tente de valider sans emoji, **Then** un message de validation s'affiche
5. **Given** le formulaire est ouvert, **When** l'utilisateur saisit un nom déjà utilisé par une autre catégorie, **Then** une erreur s'affiche indiquant que le nom est déjà pris

---

### User Story 3 - Modifier une catégorie existante (Priority: P2)

L'utilisateur modifie une catégorie personnalisée en tapant dessus dans la liste. Le formulaire s'ouvre pré-rempli avec les valeurs actuelles.

**Why this priority**: Modifier une catégorie est une action courante mais moins fréquente que la création ou la consultation.

**Independent Test**: Peut être testé en tapant sur une catégorie existante, en modifiant un champ, et en vérifiant que la modification est persistée.

**Acceptance Scenarios**:

1. **Given** l'utilisateur tape sur une catégorie personnalisée, **When** le formulaire s'ouvre, **Then** les champs sont pré-remplis avec le nom, l'icône et la couleur actuels
2. **Given** le formulaire d'édition est ouvert, **When** l'utilisateur modifie le nom et valide, **Then** la catégorie est mise à jour et la liste est rafraîchie
3. **Given** une catégorie système est affichée dans la liste, **When** l'utilisateur tente de taper dessus, **Then** l'action est bloquée — la catégorie n'est pas cliquable

---

### User Story 4 - Supprimer une catégorie (Priority: P2)

L'utilisateur supprime une catégorie personnalisée depuis le formulaire d'édition. Les éléments liés (transactions, abonnements, dettes) sont dissociés de cette catégorie.

**Why this priority**: La suppression complète le CRUD mais est moins fréquente. Un avertissement est nécessaire car des éléments peuvent être liés.

**Independent Test**: Peut être testé en ouvrant une catégorie en édition, en tapant le bouton de suppression, en confirmant, et en vérifiant sa disparition de la liste.

**Acceptance Scenarios**:

1. **Given** le formulaire d'édition est ouvert, **When** l'utilisateur tape le bouton de suppression, **Then** une boîte de dialogue de confirmation s'affiche avertissant que les éléments liés seront dissociés
2. **Given** la boîte de confirmation est affichée, **When** l'utilisateur confirme, **Then** la catégorie est supprimée et l'utilisateur revient à la liste mise à jour
3. **Given** la boîte de confirmation est affichée, **When** l'utilisateur annule, **Then** rien ne se passe et le formulaire reste ouvert

---

### User Story 5 - Protection des catégories système (Priority: P1)

Les catégories système (créées automatiquement) sont protégées contre la modification et la suppression. Elles apparaissent dans la liste mais sont visuellement distinctes des catégories personnalisées.

**Why this priority**: La protection des catégories système est critique pour l'intégrité de l'application — certaines fonctionnalités dépendent de ces catégories.

**Independent Test**: Peut être testé en vérifiant que les catégories système sont affichées différemment et qu'aucune action d'édition ou suppression n'est possible.

**Acceptance Scenarios**:

1. **Given** la liste est affichée, **When** des catégories système existent, **Then** elles sont visuellement distinctes des catégories personnalisées (badge ou indication visuelle)
2. **Given** une catégorie système est affichée, **When** l'utilisateur tente de la modifier, **Then** l'action est bloquée (élément non cliquable)
3. **Given** une catégorie système est affichée, **When** l'utilisateur tente de la supprimer, **Then** l'action est impossible — pas de bouton de suppression visible

---

### Edge Cases

- Que se passe-t-il si l'utilisateur crée une catégorie avec un nom identique (casse différente) à une catégorie existante ? Le doublon est refusé (comparaison insensible à la casse).
- Que se passe-t-il si une catégorie est supprimée alors qu'elle est utilisée par des transactions ? Les éléments liés sont dissociés (catégorie = null côté serveur).
- Que se passe-t-il si le nom dépasse la longueur maximale ? Le champ est limité à 30 caractères avec validation.
- Que se passe-t-il si la connexion réseau est perdue pendant une opération CRUD ? Un message d'erreur s'affiche et l'opération peut être retentée.
- Que se passe-t-il avec une très longue liste de catégories ? La liste supporte le défilement fluide et le rafraîchissement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher la liste de toutes les catégories de l'utilisateur, triées par nom alphabétique
- **FR-002**: Le système DOIT afficher pour chaque catégorie : son nom, son icône emoji et sa couleur
- **FR-003**: Le système DOIT distinguer visuellement les catégories système des catégories personnalisées
- **FR-004**: Le système DOIT permettre la création d'une catégorie avec : nom (obligatoire, max 30 caractères), icône emoji (obligatoire), couleur (obligatoire, palette de 12 couleurs prédéfinies)
- **FR-005**: Le système DOIT pré-sélectionner une couleur aléatoire à l'ouverture du formulaire de création
- **FR-006**: Le système DOIT permettre la modification du nom, de l'icône et de la couleur d'une catégorie personnalisée
- **FR-007**: Le système DOIT empêcher la modification et la suppression des catégories système
- **FR-008**: Le système DOIT permettre la suppression d'une catégorie personnalisée après confirmation explicite de l'utilisateur
- **FR-009**: Le système DOIT avertir l'utilisateur lors de la suppression qu'une catégorie peut être liée à des éléments existants
- **FR-010**: Le système DOIT refuser la création ou modification d'une catégorie avec un nom déjà utilisé (comparaison insensible à la casse)
- **FR-011**: Le système DOIT afficher un indicateur de chargement (squelette shimmer) pendant le chargement des données
- **FR-012**: Le système DOIT afficher un état vide avec message d'invitation lorsqu'aucune catégorie personnalisée n'existe
- **FR-013**: Le système DOIT supporter le rafraîchissement par glissement vers le bas (pull-to-refresh)
- **FR-014**: Le système DOIT afficher les erreurs de manière compréhensible avec possibilité de réessayer

### Key Entities

- **Category**: Catégorie de classification des transactions, abonnements et dettes. Attributs : identifiant unique, nom (texte, max 30 caractères), icône (emoji), couleur (code hexadécimal), indicateur système (booléen). Appartient à un utilisateur. Peut être référencée par plusieurs transactions, abonnements et dettes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter la liste complète de ses catégories en moins de 2 secondes après navigation
- **SC-002**: L'utilisateur peut créer une nouvelle catégorie en 3 interactions ou moins (ouvrir formulaire, remplir champs, valider)
- **SC-003**: L'utilisateur peut modifier une catégorie existante en 3 interactions ou moins
- **SC-004**: 100% des tentatives de modification ou suppression de catégories système sont bloquées avec un retour visuel clair
- **SC-005**: Les catégories système sont identifiables au premier coup d'oeil, sans confusion possible avec les catégories personnalisées
- **SC-006**: Tout état d'erreur affiche un message compréhensible et une action de récupération (réessayer)

## Assumptions

- Les catégories système existantes sont : Abonnement, Dette, Virement (créées à l'inscription) et Ajustement (créée automatiquement au premier ajustement de solde)
- La palette de couleurs comprend 12 couleurs prédéfinies, identique à celle utilisée dans l'application Angular et l'écran de gestion des comptes Flutter
- Le widget EmojiInput existant est réutilisé tel quel pour la sélection d'icône
- Le widget ColorPalettePicker existant dans les comptes est réutilisable pour la sélection de couleur
- La dissociation des éléments liés lors de la suppression est gérée côté serveur (API)
- L'écran suit les mêmes patterns UX que l'écran de gestion des comptes (053) : liste avec shimmer, formulaire avec prévisualisation, confirmation de suppression
