# Feature Specification: Bouton flottant (+) avec Speed Dial

**Feature Branch**: `006-fab-speed-dial`
**Created**: 2026-02-08
**Status**: Draft
**Input**: KKS-30 Implémenter le bouton flottant (+) - FAB dans le Shell avec speed dial pour création rapide (transaction, abonnement, dette). Positionné en bas à droite, responsive sidebar desktop.

## Clarifications

### Session 2026-02-08

- Q: Les actions du speed dial doivent-elles naviguer vers des routes ou afficher le formulaire autrement ? → A: Les formulaires de création doivent s'afficher dans un modal, pas via navigation vers des routes dédiées.
- Q: Le scope de KKS-30 inclut-il l'implémentation des formulaires de création ? → A: Non. KKS-30 = FAB + speed dial + modal avec placeholder. Les formulaires seront implémentés dans des issues séparées.
- Q: Comment l'utilisateur ferme-t-il le modal ? → A: Bouton fermer (×) dans le header du modal + clic overlay + touche Echap.
- Q: Le FAB est-il visible quand un modal est ouvert ? → A: Non. Le FAB est masqué (invisible) quand un modal est affiché.
- Q: Comment les items du speed dial sont-ils accessibles au clavier ? → A: Focus trap + navigation flèches (ArrowUp/Down entre items, Enter pour sélectionner).
- Q: Quelle taille pour le bouton FAB ? → A: 56px (standard Material Design FAB).
- Q: Où placer le composant modal dans l'arborescence Angular ? → A: `app/src/app/shared/components/modal/` (composant shared réutilisable).
- Q: Quelle durée pour les animations du speed dial ? → A: 200ms (standard Material Design).
- Q: Quel critère objectif pour valider la fluidité des animations ? → A: 60 FPS minimum pendant l'animation.
- Q: Quelle stratégie de z-index pour les couches superposées ? → A: Tokens CSS custom properties (`--z-fab`, `--z-overlay`, `--z-modal`) dans les design tokens.
- Q: Quelle transition pour l'apparition/disparition du modal ? → A: Fade-in + scale depuis le centre (opacity 0→1, scale 0.95→1, 200ms).

### Session 2026-02-09

- Q: Quel comportement quand le contenu du modal dépasse la hauteur écran ? → A: Hauteur max 80vh avec scroll interne sur le body du modal.
- Q: Que se passe-t-il si l'utilisateur navigue vers une autre route avec le speed dial ouvert ? → A: Le speed dial se ferme automatiquement à chaque changement de route.
- Q: Le modal doit-il verrouiller le scroll du body en arrière-plan ? → A: Oui, scroll lock sur le body quand le modal est ouvert.
- Q: Le composant Modal doit-il gérer scroll lock et focus trap manuellement ou via `@angular/cdk` ? → A: Utiliser `@angular/cdk` (overlay + a11y) pour scroll lock et focus trap.
- Q: Quelle largeur pour le modal ? → A: Mobile : 100% - 32px padding. Desktop (>=768px) : max-width 480px centré.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Accès rapide à la création (Priority: P1)

L'utilisateur authentifié voit un bouton rond (+) en bas à droite de l'écran, quelle que soit la page sur laquelle il se trouve. Ce bouton est toujours accessible et constitue le point d'entrée principal pour créer du contenu dans l'application.

**Why this priority**: Le FAB est le composant central de cette feature. Sans lui, aucune des autres stories n'a de sens. Il concrétise le principe Mobile-First UX du projet (saisie en 2-3 interactions).

**Independent Test**: Peut être testé en naviguant sur n'importe quel écran authentifié et en vérifiant que le bouton (+) est visible et correctement positionné.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est authentifié et sur le dashboard, **When** la page se charge, **Then** un bouton rond (+) est visible en bas à droite de l'écran
2. **Given** l'utilisateur est authentifié, **When** il navigue vers n'importe quelle page (transactions, abonnements, dettes), **Then** le bouton (+) reste visible et positionné au même endroit
3. **Given** l'utilisateur est sur un écran desktop (>= 768px), **When** la sidebar est affichée, **Then** le bouton (+) est positionné dans la zone de contenu (pas derrière la sidebar)

---

### User Story 2 - Ouverture du speed dial (Priority: P1)

L'utilisateur appuie sur le bouton (+) et un menu d'actions rapides s'affiche avec 3 options : nouvelle transaction, nouvel abonnement, nouvelle dette. Un overlay semi-transparent apparaît derrière le menu pour focaliser l'attention.

**Why this priority**: Le speed dial est indissociable du FAB. Sans le menu, le bouton n'a aucune utilité.

**Independent Test**: Peut être testé en cliquant sur le FAB et en vérifiant que les 3 options apparaissent avec une animation fluide.

**Acceptance Scenarios**:

1. **Given** le FAB est visible, **When** l'utilisateur clique dessus, **Then** un menu speed dial s'ouvre avec 3 actions : "Transaction", "Abonnement", "Dette"
2. **Given** le FAB est visible, **When** l'utilisateur clique dessus, **Then** le bouton (+) s'anime (rotation en icône ×) pour indiquer l'état ouvert
3. **Given** le FAB est visible, **When** l'utilisateur clique dessus, **Then** un overlay semi-transparent apparaît derrière le menu

---

### User Story 3 - Ouverture du modal de création (Priority: P1)

L'utilisateur sélectionne une des 3 actions du speed dial et un modal s'ouvre avec un contenu placeholder indiquant le type de formulaire à venir (ex: "Formulaire de transaction - à venir"). Le speed dial se ferme automatiquement quand le modal s'ouvre. Le FAB est masqué pendant que le modal est affiché.

**Why this priority**: Le modal est le résultat attendu de l'interaction avec le FAB. Sans lui, le speed dial est décoratif.

**Independent Test**: Peut être testé en ouvrant le speed dial, cliquant sur chaque action et vérifiant qu'un modal s'ouvre avec le bon placeholder.

**Acceptance Scenarios**:

1. **Given** le speed dial est ouvert, **When** l'utilisateur clique sur "Transaction", **Then** un modal s'ouvre avec le placeholder du formulaire de transaction
2. **Given** le speed dial est ouvert, **When** l'utilisateur clique sur "Abonnement", **Then** un modal s'ouvre avec le placeholder du formulaire d'abonnement
3. **Given** le speed dial est ouvert, **When** l'utilisateur clique sur "Dette", **Then** un modal s'ouvre avec le placeholder du formulaire de dette
4. **Given** le speed dial est ouvert, **When** l'utilisateur clique sur une action, **Then** le speed dial se ferme et le modal s'ouvre
5. **Given** un modal est ouvert, **When** l'utilisateur regarde la page, **Then** le FAB n'est pas visible

---

### User Story 4 - Fermeture du modal (Priority: P1)

L'utilisateur peut fermer le modal via le bouton fermer (×) dans le header du modal, en cliquant sur l'overlay derrière le modal, ou en appuyant sur la touche Echap. Quand le modal se ferme, le FAB redevient visible.

**Why this priority**: La fermeture est indissociable de l'ouverture du modal. L'utilisateur doit pouvoir revenir à l'état normal.

**Independent Test**: Peut être testé en ouvrant un modal puis en utilisant chaque méthode de fermeture.

**Acceptance Scenarios**:

1. **Given** un modal est ouvert, **When** l'utilisateur clique sur le bouton (×) du modal, **Then** le modal se ferme et le FAB redevient visible
2. **Given** un modal est ouvert, **When** l'utilisateur clique sur l'overlay, **Then** le modal se ferme
3. **Given** un modal est ouvert, **When** l'utilisateur appuie sur Echap, **Then** le modal se ferme

---

### User Story 5 - Fermeture du speed dial (Priority: P2)

L'utilisateur peut fermer le speed dial en cliquant en dehors du menu (sur l'overlay), en appuyant sur Echap, ou en cliquant à nouveau sur le bouton (×).

**Why this priority**: Essentielle pour l'UX mais secondaire par rapport à l'ouverture et le modal.

**Independent Test**: Peut être testé en ouvrant le speed dial puis en utilisant chaque méthode de fermeture.

**Acceptance Scenarios**:

1. **Given** le speed dial est ouvert, **When** l'utilisateur clique sur l'overlay, **Then** le menu se ferme et le bouton reprend l'icône (+)
2. **Given** le speed dial est ouvert, **When** l'utilisateur clique sur le bouton (×), **Then** le menu se ferme
3. **Given** le speed dial est ouvert, **When** l'utilisateur appuie sur la touche Echap, **Then** le menu se ferme

---

### Edge Cases

- Que se passe-t-il si l'utilisateur clique rapidement plusieurs fois sur le FAB ? Le menu ne doit pas clignoter — un seul toggle par interaction
- Que se passe-t-il si l'utilisateur redimensionne la fenêtre avec le speed dial ouvert ? Le FAB doit rester correctement positionné
- Que se passe-t-il si l'utilisateur n'est pas authentifié ? Le FAB ne doit pas être visible (il fait partie du Shell authentifié)
- Que se passe-t-il si un modal est ouvert et l'utilisateur appuie sur Echap ? Le modal se ferme, le FAB redevient visible
- Que se passe-t-il si l'utilisateur navigue vers une autre route avec le speed dial ou un modal ouvert ? Le speed dial et le modal se ferment automatiquement à chaque changement de route

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher un bouton d'action flottant rond (+) sur tous les écrans authentifiés
- **FR-002**: Le bouton DOIT être positionné en bas à droite de la zone de contenu, avec un espacement de 16px par rapport aux bords. Dimensions : 56px × 56px (standard Material Design FAB)
- **FR-003**: En mode desktop (>= 768px), le bouton DOIT tenir compte du décalage de la sidebar et rester dans la zone de contenu
- **FR-004**: Au clic sur le FAB, le système DOIT afficher un menu speed dial avec exactement 3 actions : Transaction, Abonnement, Dette
- **FR-005**: Chaque action du speed dial DOIT ouvrir un modal contenant un placeholder pour le formulaire de création correspondant
- **FR-006**: Le speed dial DOIT se fermer au clic sur l'overlay, au clic sur le FAB, ou à l'appui sur Echap
- **FR-007**: Le FAB DOIT avoir une animation de transition entre l'état fermé (+) et ouvert (×). Durée : 200ms
- **FR-008**: Les items du speed dial DOIVENT apparaître avec une animation séquentielle (staggered) de bas en haut. Durée totale : 200ms
- **FR-009**: Un overlay semi-transparent DOIT apparaître quand le speed dial est ouvert. Les z-index sont gérés via des tokens CSS custom properties (`--z-fab`, `--z-overlay`, `--z-modal`) dans les design tokens
- **FR-010**: Le FAB ne DOIT PAS être visible sur les pages non authentifiées (écran de login)
- **FR-011**: Le modal DOIT pouvoir être fermé via un bouton (×) dans son header, un clic sur l'overlay, ou la touche Echap. Animation d'apparition : fade-in + scale (opacity 0→1, scale 0.95→1, 200ms). Disparition : animation inverse. Le modal DOIT avoir une hauteur maximale de 80vh avec scroll interne sur le body (le header reste fixe). Largeur : mobile 100% - 32px padding, desktop (>=768px) max-width 480px centré
- **FR-012**: Le FAB DOIT être masqué (invisible) quand un modal est affiché, et redevenir visible à la fermeture du modal
- **FR-014**: Le modal DOIT verrouiller le scroll du body en arrière-plan (scroll lock) à l'ouverture et le restaurer à la fermeture. Implémenté via `effect()` Angular (toggle `document.body.style.overflow`)
- **FR-013**: Le speed dial DOIT implémenter un focus trap avec navigation clavier : ArrowUp/ArrowDown pour naviguer entre les items, Enter pour sélectionner, Echap pour fermer. Le focus DOIT être placé sur le premier item à l'ouverture. Focus trap implémenté via `@angular/cdk/a11y`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut initier la création d'une transaction, abonnement ou dette en 2 interactions maximum (clic FAB + clic action) et le modal s'affiche immédiatement
- **SC-002**: Le FAB est visible et accessible sur 100% des écrans authentifiés sans chevaucher le contenu existant
- **SC-003**: L'animation d'ouverture/fermeture du speed dial s'exécute à 60 FPS minimum (vérifiable via DevTools Performance)
- **SC-004**: Le FAB s'adapte correctement aux deux modes d'affichage (mobile et desktop avec sidebar) sans repositionnement manuel

## Assumptions

- Le FAB est intégré dans le composant Shell existant, qui gère déjà le layout authentifié (header + sidebar + contenu).
- Le comportement "hide on scroll" mentionné dans l'issue est marqué comme optionnel et n'est pas inclus dans cette spécification v1.
- Les labels des actions sont en français : "Transaction", "Abonnement", "Dette".
- Les modals affichent un contenu placeholder en v1. Les formulaires réels seront implémentés dans des issues dédiées.
- Le composant modal créé dans cette feature sera réutilisable pour les futures features de formulaires. Il sera placé dans `app/src/app/shared/components/modal/`.
