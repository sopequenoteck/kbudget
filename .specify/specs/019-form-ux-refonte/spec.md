# Feature Specification: Refonte UX formulaire Transaction

**Feature Branch**: `019-form-ux-refonte`
**Created**: 2026-02-12
**Status**: Draft
**Input**: Refonte du formulaire de transaction pour une saisie rapide et ergonomique sur mobile, avec layout compact en grille et toggle type dans le header du modal.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Saisie rapide d'une transaction (Priority: P1)

L'utilisateur ouvre le formulaire de nouvelle transaction depuis le bouton flottant (+). Le formulaire s'affiche dans un modal avec un layout compact : le libelle et le montant sont cote a cote sur la premiere ligne, la categorie et la date sur la deuxieme, la note en pleine largeur sur la troisieme. Le toggle Depense/Recette est directement visible dans le header du modal, a cote du titre. L'utilisateur peut saisir une transaction complete en 2-3 interactions sans scroller.

**Why this priority**: C'est le coeur de la feature. L'ergonomie mobile depend directement de la capacite a saisir une transaction rapidement avec un minimum d'interactions.

**Independent Test**: Ouvrir le formulaire de creation de transaction et verifier que tous les champs sont visibles sans scroller, organises en grille 2 colonnes.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur n'importe quel ecran, **When** il ouvre le formulaire de nouvelle transaction, **Then** le formulaire affiche les champs en layout grille (libelle + montant, categorie + date, note pleine largeur) et le toggle Depense/Recette dans le header du modal.
2. **Given** le formulaire de creation est ouvert, **When** l'utilisateur remplit libelle, montant et valide, **Then** la transaction est creee avec le type selectionne dans le toggle header (Depense par defaut).
3. **Given** le formulaire de creation est ouvert, **When** l'utilisateur change le toggle sur "Recette" puis soumet, **Then** la transaction est creee avec le type Recette.

---

### User Story 2 - Edition d'une transaction existante (Priority: P2)

L'utilisateur ouvre une transaction existante pour la modifier. Le formulaire s'affiche dans le meme layout grille compact. Le toggle Depense/Recette dans le header reflete le type actuel de la transaction. Un bouton Supprimer est visible a gauche de la barre d'actions (meme ligne que Annuler et Enregistrer).

**Why this priority**: L'edition est le deuxieme usage le plus frequent. Le toggle doit refleter correctement l'etat existant et le bouton Supprimer doit etre accessible sans etape supplementaire.

**Independent Test**: Ouvrir une transaction existante de type Recette et verifier que le toggle affiche "Recette" comme actif, et que le bouton Supprimer est present a gauche des actions.

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre une transaction existante de type Depense, **When** le modal s'ouvre, **Then** le toggle dans le header affiche "Depense" comme actif et tous les champs sont pre-remplis en layout grille.
2. **Given** l'utilisateur ouvre une transaction de type Recette, **When** le modal s'ouvre, **Then** le toggle affiche "Recette" comme actif.
3. **Given** le formulaire d'edition est ouvert, **When** l'utilisateur clique sur Supprimer, **Then** la transaction est supprimee immediatement (pas de confirmation intermediaire).

---

### User Story 3 - Adaptation mobile petit ecran (Priority: P3)

Sur les ecrans tres petits (moins de 400px de large), les champs de la grille s'empilent en une seule colonne pour rester lisibles et accessibles.

**Why this priority**: Support des appareils les plus petits. La majorite des utilisateurs ont des ecrans suffisamment larges pour la grille 2 colonnes, mais l'empilage garantit l'accessibilite universelle.

**Independent Test**: Reduire le viewport a moins de 400px et verifier que les champs du formulaire s'empilent verticalement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur un ecran de moins de 400px de large, **When** il ouvre le formulaire de transaction, **Then** tous les champs s'affichent en une seule colonne.
2. **Given** l'utilisateur est sur un ecran de plus de 400px, **When** il ouvre le formulaire, **Then** les champs s'affichent en grille 2 colonnes.

---

### User Story 4 - Pas d'impact sur les autres formulaires (Priority: P2)

Les formulaires d'abonnement, de dette et de categorie continuent de fonctionner exactement comme avant. Le slot pour actions dans le header du modal reste vide pour ces formulaires.

**Why this priority**: Non-regression critique. Les autres formulaires ne doivent pas etre affectes par cette refonte.

**Independent Test**: Ouvrir chaque type de formulaire (abonnement, dette, categorie) et verifier qu'aucun changement visuel n'est apparu.

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre le formulaire d'abonnement, **When** le modal s'affiche, **Then** le header ne contient que le titre et le bouton fermer (pas de toggle).
2. **Given** l'utilisateur ouvre le formulaire de dette, **When** le modal s'affiche, **Then** le formulaire est identique a avant la refonte.
3. **Given** l'utilisateur ouvre le formulaire de categorie, **When** le modal s'affiche, **Then** le formulaire est identique a avant la refonte.

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur change le type dans le toggle apres avoir rempli des champs ? Les champs doivent etre conserves (seul le type change).
- Comment se comporte le sélecteur de categorie (dropdown) dans le layout grille ? Le dropdown doit s'ouvrir correctement sans etre coupe par le conteneur.
- Que se passe-t-il en mode creation si l'utilisateur ne touche pas au toggle ? Le type par defaut (Depense) est utilise.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le toggle Depense/Recette DOIT etre affiche dans le header du modal, sur la meme ligne que le titre, uniquement pour le formulaire de transaction.
- **FR-002**: Le formulaire de transaction DOIT afficher les champs en layout grille 2 colonnes : libelle (70%) + montant (30%) sur la premiere ligne, categorie + date sur la deuxieme, note en pleine largeur sur la troisieme.
- **FR-003**: En mode creation, le type DOIT etre initialise a "Depense" par defaut.
- **FR-004**: En mode edition, le toggle DOIT refleter le type de la transaction existante.
- **FR-005**: Le changement de type via le toggle NE DOIT PAS reinitialiser les autres champs du formulaire.
- **FR-006**: La barre d'actions DOIT etre sur une seule ligne : bouton Supprimer a gauche (edition uniquement), Annuler et Enregistrer a droite.
- **FR-007**: La suppression DOIT etre executee au clic direct (pas de confirmation intermediaire).
- **FR-008**: Sur un viewport de moins de 400px de largeur, les champs DOIVENT s'empiler en une seule colonne.
- **FR-009**: Le modal DOIT supporter un emplacement d'actions dans le header, utilisable par n'importe quel formulaire projete dans le modal.
- **FR-010**: Les formulaires d'abonnement, dette et categorie NE DOIVENT PAS etre affectes visuellement ou fonctionnellement.

### Assumptions

- L'application est mobile-first : la majorite des utilisateurs saisissent sur smartphone.
- Le toggle compact dans le header est suffisamment lisible sur mobile (pas besoin de full-width).
- La suppression sans confirmation est acceptable car l'application est single-user et les transactions sont recuperables via l'historique.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut saisir une nouvelle transaction (libelle, montant, type, date) en 3 interactions ou moins apres ouverture du formulaire.
- **SC-002**: Tous les champs du formulaire de creation sont visibles sans scroller sur un ecran de 375px de large (iPhone SE).
- **SC-003**: Le formulaire de transaction s'adapte correctement a tous les viewports entre 320px et 1024px de large.
- **SC-004**: Les formulaires d'abonnement, dette et categorie restent visuellement et fonctionnellement identiques apres la refonte (0 regression).
