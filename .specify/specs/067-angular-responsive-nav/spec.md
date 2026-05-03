# Feature Specification: Navigation responsive Angular (bottom nav mobile)

**Feature Branch**: `067-angular-responsive-nav`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "KKS-153 en plus de ça sur mobile je voudrais supprimer la sidebar et mettre un bottomNav comme dans l'application flutter"
**Linear**: KKS-153

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigation mobile par barre inferieure (Priority: P1)

L'utilisateur accede a l'application Angular depuis son telephone. Au lieu de la sidebar avec menu hamburger, il voit une barre de navigation fixe en bas de l'ecran avec les onglets principaux (Accueil, Transactions, et les features activees). Il navigue en tapant sur les onglets, exactement comme dans l'application Flutter.

**Why this priority**: C'est la fonctionnalite principale demandee. La barre de navigation inferieure est le standard mobile et remplace le pattern sidebar/hamburger qui necessite plus d'interactions.

**Independent Test**: Peut etre teste en ouvrant l'application sur un ecran mobile (< 768px) et en verifiant que la sidebar disparait et qu'une bottom nav apparait avec les bons onglets.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur mobile (< 768px), **When** il charge l'application, **Then** il voit une barre de navigation en bas avec les onglets (pas de sidebar, pas de hamburger)
2. **Given** l'utilisateur est sur mobile avec la bottom nav, **When** il tape sur un onglet, **Then** il est redirige vers la page correspondante et l'onglet actif est visuellement distingue
3. **Given** l'utilisateur est sur desktop (>= 768px), **When** il charge l'application, **Then** il voit la sidebar laterale comme avant (pas de bottom nav)
4. **Given** l'utilisateur redimensionne la fenetre de desktop a mobile, **When** la largeur passe sous 768px, **Then** la sidebar disparait et la bottom nav apparait

---

### User Story 2 - Onglets dynamiques selon les features activees (Priority: P1)

La barre de navigation inferieure affiche les onglets en fonction des features activees par l'utilisateur et respecte l'ordre personnalise defini dans les preferences (navOrder).

**Why this priority**: Sans cette fonctionnalite, la bottom nav serait statique et incoherente avec le systeme de feature toggles deja en place. C'est indissociable de la US1.

**Independent Test**: Activer/desactiver des features dans les settings et verifier que la bottom nav reflete les changements.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a active Abonnements et Dettes, **When** il voit la bottom nav, **Then** elle affiche : Accueil, Transactions, Abonnements, Dettes (dans l'ordre de navOrder)
2. **Given** l'utilisateur desactive une feature, **When** il retourne sur la bottom nav, **Then** l'onglet correspondant disparait
3. **Given** l'utilisateur a reordonne la navigation dans les settings, **When** il voit la bottom nav, **Then** les onglets optionnels suivent le nouvel ordre

---

### User Story 3 - Header adapte au mobile (Priority: P2)

Le header de l'application est simplifie sur mobile : le bouton hamburger disparait puisque la sidebar n'est plus utilisee. Le header conserve le logo et le menu utilisateur.

**Why this priority**: Coherence visuelle. Le hamburger n'a plus de raison d'etre si la sidebar est remplacee par la bottom nav.

**Independent Test**: Verifier que le header sur mobile ne contient plus de bouton hamburger et que le menu utilisateur reste accessible.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur mobile, **When** il voit le header, **Then** il n'y a pas de bouton hamburger
2. **Given** l'utilisateur est sur mobile, **When** il voit le header, **Then** le logo et le menu utilisateur (avatar, settings, deconnexion) sont toujours presents
3. **Given** l'utilisateur est sur desktop, **When** il voit le header, **Then** rien ne change par rapport a l'existant (sidebar toujours visible, hamburger deja masque sur desktop)

---

### User Story 4 - Acces aux Settings depuis le header (Priority: P2)

L'utilisateur peut acceder aux reglages depuis le menu utilisateur dans le header, comme actuellement. Les settings ne sont pas un onglet de la bottom nav (ils restent dans le menu utilisateur du header).

**Why this priority**: Garantir que l'utilisateur ne perd pas l'acces aux reglages avec la suppression de la sidebar.

**Independent Test**: Sur mobile, verifier que le menu utilisateur dans le header permet toujours d'acceder aux settings.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur mobile avec la bottom nav, **When** il ouvre le menu utilisateur dans le header, **Then** il peut acceder a Settings et Deconnexion

---

### Edge Cases

- Que se passe-t-il si l'utilisateur n'a aucune feature optionnelle activee ? La bottom nav affiche uniquement Accueil et Transactions (2 onglets)
- Que se passe-t-il si l'utilisateur a active toutes les features (5 onglets) ? La bottom nav affiche tous les onglets ; l'UI doit rester utilisable (icones + labels courts)
- Que se passe-t-il si les preferences ne sont pas encore chargees ? La bottom nav affiche les 2 onglets fixes en attendant le chargement
- Que se passe-t-il si l'utilisateur est sur une page dont la feature est desactivee ? Redirection vers le dashboard (comportement existant conserve)
- Que se passe-t-il si l'utilisateur navigue vers les Settings (pas dans la bottom nav) ? Aucun onglet n'est actif dans la bottom nav

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher une barre de navigation fixe en bas de l'ecran sur les appareils mobiles (largeur < 768px)
- **FR-002**: Le systeme DOIT masquer la sidebar sur mobile lorsque la bottom nav est active
- **FR-003**: Le systeme DOIT conserver la sidebar sur desktop (>= 768px) sans modification
- **FR-004**: La bottom nav DOIT afficher 2 onglets fixes (Accueil, Transactions) toujours visibles et en premier
- **FR-005**: La bottom nav DOIT afficher les onglets optionnels (Abonnements, Dettes, Boutique) uniquement si la feature correspondante est activee
- **FR-006**: La bottom nav DOIT respecter l'ordre personnalise (navOrder) defini dans les preferences utilisateur pour les onglets optionnels
- **FR-007**: Chaque onglet DOIT afficher une icone et un label court
- **FR-008**: L'onglet actif DOIT etre visuellement distingue par la couleur primaire (`--color-primary`) et un poids de police semi-bold (`--font-semibold`)
- **FR-009**: Le header sur mobile DOIT supprimer le bouton hamburger
- **FR-010**: Le header sur mobile DOIT conserver le logo et le menu utilisateur (avatar, settings, deconnexion)
- **FR-011**: La transition entre sidebar et bottom nav DOIT se faire automatiquement au redimensionnement de la fenetre (responsive, pas de rechargement)
- **FR-012**: Le contenu principal DOIT avoir un padding inferieur suffisant pour ne pas etre masque par la bottom nav sur mobile
- **FR-013**: Le FAB (bouton d'action flottant) DOIT rester positionne au-dessus de la bottom nav sur mobile

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur accede a n'importe quelle section en 1 seule interaction sur mobile (tap sur l'onglet) au lieu de 2 (hamburger + tap lien sidebar)
- **SC-002**: La navigation mobile est visuellement coherente avec l'application Flutter : meme position (bottom fixe), meme hauteur (56px), meme pattern icone + label, memes tokens de couleur (`--color-primary` pour actif, `--text-secondary` pour inactif)
- **SC-003**: 100% des features activees sont accessibles via la bottom nav sur mobile
- **SC-004**: Le passage desktop / mobile est fluide sans rechargement de page
- **SC-005**: L'application reste pleinement fonctionnelle sur desktop sans aucune regression

## Clarifications

### Session 2026-03-01

- Q: Faut-il inclure une previsualisation de la bottom nav dans les settings (comme Flutter) ? → A: Non, pas de preview. Le reordering dans les settings suffit.

## Assumptions

- Le breakpoint mobile/desktop est 768px, coherent avec le breakpoint existant dans le shell Angular
- L'API `GET/PUT /users/me/preferences` avec `navOrder` est deja fonctionnelle (KKS-150/KKS-064)
- Le `PreferenceService` Angular et la logique de navigation dynamique sont deja implementes
- Les icones des features sont deja definies dans la constante `FEATURES` (emoji)
- Les design tokens CSS existants (`docs/design-tokens.md`) sont la reference pour les couleurs et styles
- Le FAB speed dial existant fonctionne deja et doit simplement etre repositionne au-dessus de la bottom nav
