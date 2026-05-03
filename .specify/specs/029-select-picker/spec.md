# Feature Specification: Composant de selection generique (SelectPicker)

**Feature Branch**: `029-select-picker`
**Created**: 2026-02-17
**Status**: Draft
**Input**: Mutualiser les selecteurs de l'application en un composant generique SelectPicker qui remplace les select natifs du transfer-form, le category-picker et le account-picker

## Clarifications

### Session 2026-02-17

- Q: Quel comportement du dropdown sur mobile (petit ecran) ? → A: Bottom-sheet sur mobile (le dropdown se transforme en overlay ancre en bas de l'ecran sur petits ecrans)
- Q: La recherche doit-elle etre activee pour la selection de compte ? → A: Recherche activee conditionnellement, apparait a partir d'un seuil d'items (5+)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Selection de compte uniforme dans toute l'application (Priority: P1)

L'utilisateur doit pouvoir selectionner un compte bancaire de maniere identique quel que soit le formulaire (transaction, abonnement, virement) et quel que soit le navigateur (Chrome, Safari, Firefox). Aujourd'hui, le formulaire de virement utilise un selecteur natif du navigateur (rendu different sur Chrome vs Safari) tandis que le formulaire de transaction utilise des chips horizontaux qui ne scalent pas. Le nouveau composant offre un selecteur custom avec dropdown identique partout.

**Why this priority**: C'est le probleme declencheur : l'incherence cross-browser sur la selection de compte et le non-passage a l'echelle des chips horizontaux. Resoudre ce probleme apporte une valeur immediate a l'utilisateur.

**Independent Test**: Peut etre teste en remplacant le selecteur de compte dans un seul formulaire (ex: virement) et en verifiant le comportement identique sur Chrome et Safari.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le formulaire de virement, **When** il clique sur le selecteur de compte source, **Then** un dropdown custom s'affiche avec la liste des comptes actifs (icone, nom, solde) de maniere identique sur Chrome et Safari
2. **Given** l'utilisateur a 15 comptes actifs, **When** il ouvre le selecteur de compte, **Then** le dropdown affiche tous les comptes dans une liste scrollable sans debordement visuel
3. **Given** l'utilisateur est sur le formulaire de transaction, **When** il selectionne un compte, **Then** le composant utilise le meme rendu visuel et le meme comportement que dans le formulaire de virement
4. **Given** l'utilisateur est sur le formulaire d'abonnement, **When** le champ compte est optionnel, **Then** le selecteur affiche le placeholder "Aucun compte" par defaut et propose un bouton de suppression (×) pour vider la selection apres qu'un compte a ete selectionne (clearable=true)

---

### User Story 2 - Selection de categorie avec recherche et creation inline (Priority: P2)

L'utilisateur doit pouvoir rechercher et selectionner une categorie via le meme composant de selection generique, avec la possibilite de filtrer par saisie de texte et de creer une nouvelle categorie a la volee si aucune correspondance n'est trouvee. Ce comportement existe deja dans le category-picker actuel et doit etre preserve.

**Why this priority**: Le category-picker fonctionne deja bien. L'enjeu est de le refactorer pour s'appuyer sur le composant generique sans regression, en conservant les fonctionnalites specifiques (recherche, creation inline).

**Independent Test**: Peut etre teste en verifiant que la selection de categorie dans le formulaire de transaction conserve exactement les memes fonctionnalites qu'avant (recherche, creation, selection, suppression).

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le formulaire de transaction, **When** il clique sur le selecteur de categorie, **Then** un champ de recherche et un dropdown de categories s'affichent
2. **Given** l'utilisateur tape "Ali" dans le champ de recherche, **When** des categories contiennent "Ali", **Then** seules ces categories sont affichees dans le dropdown
3. **Given** l'utilisateur tape un nom qui ne correspond a aucune categorie, **When** le dropdown s'affiche, **Then** une option "Creer [nom saisi]" est proposee en bas de la liste
4. **Given** l'utilisateur a selectionne une categorie, **When** il veut changer sa selection, **Then** il peut cliquer sur la categorie affichee pour rouvrir le selecteur ou cliquer sur le bouton de suppression pour vider la selection

---

### User Story 3 - Navigation clavier et accessibilite (Priority: P3)

L'utilisateur doit pouvoir naviguer dans le selecteur entierement au clavier, conformement aux standards d'accessibilite. Cela concerne l'ouverture du dropdown, la navigation entre les options, la selection et la fermeture.

**Why this priority**: L'accessibilite est un standard de qualite. Elle arrive en P3 car le category-picker existant a deja une base de navigation clavier qui sert de reference.

**Independent Test**: Peut etre teste en naviguant dans n'importe quel formulaire uniquement au clavier (Tab, fleches, Entree, Echap) et en verifiant que chaque action est realisable sans souris.

**Acceptance Scenarios**:

1. **Given** le selecteur a le focus, **When** l'utilisateur appuie sur Entree ou Espace, **Then** le dropdown s'ouvre
2. **Given** le dropdown est ouvert, **When** l'utilisateur appuie sur Fleche Bas, **Then** l'option suivante est surlignee visuellement
3. **Given** une option est surlignee, **When** l'utilisateur appuie sur Entree, **Then** cette option est selectionnee et le dropdown se ferme
4. **Given** le dropdown est ouvert, **When** l'utilisateur appuie sur Echap, **Then** le dropdown se ferme sans modifier la selection
5. **Given** le dropdown est ouvert, **When** l'utilisateur clique en dehors du composant, **Then** le dropdown se ferme

---

### Edge Cases

- Que se passe-t-il quand la liste d'items est vide (aucun compte, aucune categorie) ? Le selecteur affiche un message "Aucun element disponible" et reste non-interactif.
- Que se passe-t-il quand l'item selectionne est supprime de la liste (ex: compte desactive) ? La selection est videe automatiquement.
- Que se passe-t-il quand le dropdown risque d'etre coupe par le bas du viewport ? Le dropdown s'affiche au-dessus du champ si l'espace en dessous est insuffisant.
- Que se passe-t-il quand l'utilisateur selectionne le meme compte en source et destination dans le virement ? La validation existante (comptes differents) continue de s'appliquer au niveau du formulaire parent.
- Que se passe-t-il quand le composant est dans un etat desactive (formulaire en cours de soumission) ? Le selecteur est visuellement grise et non-cliquable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT fournir un composant de selection generique reutilisable pour tout type de liste (comptes, categories, ou toute future entite)
- **FR-002**: Le composant DOIT afficher un dropdown custom (pas de selecteur natif du navigateur) pour garantir un rendu identique sur tous les navigateurs
- **FR-003**: Le composant DOIT supporter un mode avec recherche/filtre textuel. La recherche est toujours active pour les categories. Pour les comptes, la recherche apparait automatiquement a partir d'un seuil de 5 items dans la liste
- **FR-004**: Le composant DOIT supporter un affichage personnalisable des elements (icone + nom pour les categories, icone + nom + solde pour les comptes)
- **FR-005**: Le composant DOIT s'integrer aux formulaires reactifs via le pattern standard d'integration de controle de formulaire
- **FR-006**: Le composant DOIT supporter la possibilite de vider la selection (activable selon le contexte)
- **FR-007**: Le composant DOIT gerer la navigation clavier : ouverture (Entree/Espace), navigation (Fleches Haut/Bas), selection (Entree), fermeture (Echap)
- **FR-008**: Le composant DOIT se fermer quand l'utilisateur clique en dehors
- **FR-009**: Le composant DOIT afficher des attributs d'accessibilite (roles listbox/option, etats aria-selected, aria-expanded)
- **FR-010**: Le composant DOIT supporter un etat desactive qui empeche toute interaction
- **FR-011**: Le composant DOIT gerer le positionnement du dropdown (au-dessus si l'espace en dessous est insuffisant sur desktop)
- **FR-016**: Sur petit ecran (mobile), le dropdown DOIT se transformer en bottom-sheet (overlay ancre en bas de l'ecran) pour une meilleure ergonomie tactile
- **FR-012**: Le composant DOIT supporter un placeholder configurable
- **FR-013**: Le selecteur de categorie DOIT conserver la fonctionnalite de creation inline d'une nouvelle categorie quand aucun resultat ne correspond a la recherche
- **FR-014**: Le selecteur de compte dans le formulaire de virement DOIT valider que les comptes source et destination sont differents (validation au niveau du formulaire parent)
- **FR-015**: Le composant DOIT afficher un message quand la liste est vide ("Aucun element disponible" ou message configurable)

### Key Entities

- **SelectPicker**: Composant generique de selection. Attributs cles : liste d'items, valeur selectionnee, placeholder, recherche activee/desactivee, possibilite de vider la selection, etat desactive. Relation : utilise par tous les formulaires de l'application.
- **SelectPickerItem**: Representation generique d'un element selectionnable. Attributs cles : identifiant unique, affichage (texte principal, icone, texte secondaire optionnel). Relation : fourni au SelectPicker par le formulaire parent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le selecteur de compte affiche un rendu visuellement identique sur Chrome, Safari et Firefox (meme structure de dropdown, memes interactions)
- **SC-002**: L'utilisateur peut selectionner un element parmi une liste de 50+ items sans degradation de l'experience (scroll fluide, filtre reactif)
- **SC-003**: Toutes les fonctionnalites existantes du selecteur de categorie (recherche, creation inline, selection, suppression) sont conservees sans regression
- **SC-004**: L'utilisateur peut completer une selection entierement au clavier (sans souris) en moins de 5 interactions
- **SC-005**: Le nombre de composants de selection dans la codebase passe de 3 (select natif, category-picker, account-picker) a 1 composant generique (plus un wrapper pour la creation de categorie)
- **SC-006**: Tous les formulaires existants (transaction, abonnement, virement, dette) continuent de fonctionner sans regression apres la migration

## Assumptions

- Le composant generique sera utilise uniquement cote frontend ; aucun changement backend n'est necessaire
- Le nombre d'items dans les listes reste raisonnable (dizaines a centaines, pas des milliers) ; une virtualisation de scroll n'est pas necessaire
- Le design visuel du nouveau composant suit les tokens SCSS existants (couleurs, espacements, typographie) du design system de l'application
- La validation metier (ex: comptes source/destination differents dans un virement) reste dans les formulaires parents, pas dans le composant de selection
- Le selecteur de categorie conserve sa fonctionnalite de creation inline via un wrapper specialise autour du composant generique
