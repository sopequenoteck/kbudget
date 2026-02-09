# Feature Specification: Composant ListItem réutilisable

**Feature Branch**: `008-list-item`
**Created**: 2026-02-09
**Status**: Draft
**Input**: User description: "Créer le composant ListItem réutilisable pour les listes de transactions, abonnements et dettes"

## Clarifications

### Session 2026-02-09

- Q: L'icône doit-elle être un input du composant ? → A: Input obligatoire (toujours requis)
- Q: L'événement clic doit-il transporter des données ? → A: Signal void (le parent gère le contexte)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Afficher un élément de liste avec ses informations (Priority: P1)

En tant qu'utilisateur, je vois chaque élément de mes listes (transactions, abonnements, dettes) présenté de manière claire et structurée avec un titre, un sous-titre descriptif, et une valeur monétaire alignée à droite, afin d'identifier rapidement chaque entrée.

**Why this priority**: C'est la fonction principale du composant. Sans affichage structuré des données, le composant n'a aucune utilité.

**Independent Test**: Peut être testé en intégrant le composant dans une page avec des données statiques et en vérifiant que toutes les informations s'affichent correctement.

**Acceptance Scenarios**:

1. **Given** un ListItem avec une icône, un titre, un sous-titre et une valeur monétaire, **When** le composant s'affiche, **Then** l'icône apparaît à l'extrême gauche, suivie du titre, le sous-titre en dessous en texte secondaire, et la valeur monétaire est alignée à droite.
2. **Given** un ListItem avec uniquement un titre et une valeur (sans sous-titre optionnel à droite), **When** le composant s'affiche, **Then** seuls le titre et la valeur sont visibles, sans espace vide résiduel.
3. **Given** un titre long qui dépasse l'espace disponible, **When** le composant s'affiche, **Then** le texte est tronqué avec une ellipse et la valeur monétaire reste visible et alignée à droite.

---

### User Story 2 - Interagir avec un élément de liste (Priority: P2)

En tant qu'utilisateur, je peux cliquer/taper sur un élément de la liste pour accéder à ses détails ou déclencher une action (édition, vue détaillée), afin de naviguer fluidement dans l'application.

**Why this priority**: L'interactivité est essentielle pour la navigation, mais le composant a de la valeur même en lecture seule.

**Independent Test**: Peut être testé en cliquant sur un ListItem et en vérifiant qu'un événement est émis au composant parent.

**Acceptance Scenarios**:

1. **Given** un ListItem affiché, **When** l'utilisateur clique dessus, **Then** un signal void est émis vers le composant parent (le parent gère le contexte de l'élément cliqué).
2. **Given** un ListItem affiché, **When** l'utilisateur survole l'élément sur desktop, **Then** un retour visuel (changement de fond) indique que l'élément est interactif.
3. **Given** un ListItem affiché, **When** l'utilisateur navigue au clavier avec Tab, **Then** l'élément reçoit le focus avec un indicateur visuel clair.

---

### User Story 3 - Différencier visuellement les types d'éléments (Priority: P3)

En tant qu'utilisateur, je distingue visuellement les différents types d'éléments (revenus vs dépenses, dettes que je dois vs qu'on me doit) grâce à des classes CSS sur la valeur monétaire, afin de repérer rapidement les informations importantes.

**Why this priority**: La différenciation visuelle améliore la lisibilité mais le composant fonctionne sans.

**Independent Test**: Peut être testé en passant différentes classes CSS à la valeur et en vérifiant que les couleurs correspondantes s'appliquent.

**Acceptance Scenarios**:

1. **Given** un ListItem avec une classe de style appliquée à la valeur (ex: revenu), **When** le composant s'affiche, **Then** la valeur monétaire est colorée selon la classe (vert pour revenu, rouge pour dépense).
2. **Given** un ListItem sans classe de style sur la valeur, **When** le composant s'affiche, **Then** la valeur s'affiche dans la couleur de texte par défaut.

---

### Edge Cases

- Que se passe-t-il lorsque le titre est vide ou nul ? Le composant affiche un espace réservé vide mais conserve sa structure.
- Que se passe-t-il lorsque la valeur monétaire est très longue (ex: 1 000 000,00) ? La mise en page reste stable, le titre se tronque en priorité.
- Comment le composant se comporte-t-il sur un écran très étroit (< 320px) ? Le layout reste en flexbox horizontal, le titre se tronque avec ellipse.
- Que se passe-t-il si aucun événement de clic n'est écouté par le parent ? Le composant s'affiche normalement sans comportement interactif visible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le composant DOIT afficher une icône (texte/emoji) obligatoire à l'extrême gauche de chaque élément.
- **FR-002**: Le composant DOIT afficher un titre principal aligné à gauche, après l'icône.
- **FR-003**: Le composant DOIT afficher une valeur alignée à droite.
- **FR-004**: Le composant DOIT accepter un sous-titre optionnel affiché sous le titre.
- **FR-005**: Le composant DOIT accepter un sous-titre optionnel affiché sous la valeur à droite.
- **FR-006**: Le composant DOIT accepter une classe CSS optionnelle appliquée à la valeur pour la différenciation visuelle.
- **FR-007**: Le composant DOIT émettre un signal void (sans payload) lorsque l'utilisateur clique dessus.
- **FR-008**: Le composant DOIT afficher un retour visuel au survol (hover) et au focus clavier (focus-visible).
- **FR-009**: Le composant DOIT être responsive et s'adapter aux écrans mobiles (320px minimum).
- **FR-010**: Le composant DOIT tronquer le titre avec une ellipse si le texte dépasse l'espace disponible.
- **FR-011**: Le composant DOIT afficher un séparateur visuel (bordure inférieure) entre chaque élément de liste.
- **FR-012**: Le composant DOIT utiliser uniquement les design tokens existants du projet pour les couleurs, espacements et typographie.

### Key Entities

- **ListItem**: Élément de liste générique composé d'une icône (obligatoire, texte/emoji), d'un titre (obligatoire), d'un sous-titre (optionnel), d'une valeur affichée à droite (obligatoire), d'un sous-titre droit (optionnel), et d'une classe de style pour la valeur (optionnel).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le composant affiche correctement les 3 cas d'usage métier (transactions, abonnements, dettes) sans modification de son interface.
- **SC-002**: Le composant est utilisable au clavier : navigation par Tab et activation par Entrée/Espace.
- **SC-003**: Le texte tronqué reste lisible et la valeur monétaire est toujours entièrement visible sur un écran de 320px de large.
- **SC-004**: Le temps de compréhension visuelle d'un élément de liste est immédiat : titre, sous-titre et montant sont identifiables en moins de 2 secondes.

## Assumptions

- Le composant sera utilisé dans des listes scrollables contenant potentiellement des dizaines d'éléments.
- Les design tokens CSS du projet couvrent tous les besoins de style (couleurs, espacements, typographie).
- Le composant ne gère pas le chargement des données ; il reçoit ses données en entrée du composant parent.
- L'icône est un input obligatoire de type texte/emoji, pas un composant icône dédié (pas de dépendance à une librairie d'icônes).
- Le composant est purement présentationnel (pas de logique métier interne).
