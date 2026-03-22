# Feature Specification: Bottom Navigation — Refonte visuelle premium

**Feature Branch**: `092-bottom-nav-revamp`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Refonte visuelle de la barre de navigation inférieure Angular pour un rendu iOS-like cohérent avec le dashboard revampé (091)

## Clarifications

### Session 2026-03-15

- Q: Comment gérer les labels longs sans troncature ? → A: Réduction de la taille de police en CSS quand 6+ items (passer de font-size-xs à 10px). Pas de mapping d'abréviations.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Indicateur actif premium avec pill indicator (Priority: P1)

L'utilisateur navigue entre les sections de l'app et identifie instantanément l'onglet actif grâce à un indicateur pill (pastille arrondie derrière l'icône active) au lieu d'un simple changement de couleur. L'icône active passe en version remplie (fill) et le pill donne du volume visuel.

**Why this priority**: L'indicateur actif est l'élément le plus visible du bottom nav. Le changement de couleur seul (amber) est trop subtil — un pill indicator est le standard iOS/Material 3.

**Independent Test**: Naviguer entre deux onglets et vérifier que l'onglet actif affiche un pill coloré derrière l'icône + icône fill, et que l'onglet inactif n'a pas de pill.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur "Accueil", **When** il regarde le bottom nav, **Then** l'icône Accueil est remplie (fill) et entourée d'un pill arrondi avec fond teinté de la couleur primaire
2. **Given** l'utilisateur est sur "Accueil", **When** il tap sur "Transactions", **Then** le pill disparaît de "Accueil" et apparaît sur "Transactions" avec une transition fluide
3. **Given** `prefers-reduced-motion: reduce`, **When** l'utilisateur change d'onglet, **Then** le pill apparaît instantanément sans animation de transition

---

### User Story 2 — Glassmorphism et profondeur de la barre (Priority: P2)

La barre de navigation utilise un effet de glassmorphism (fond semi-transparent, flou d'arrière-plan) en dark mode, créant une continuité visuelle avec les cards du dashboard. La shadow hardcodée est remplacée par un effet plus subtil.

**Why this priority**: La barre actuelle a un fond opaque plat et une shadow hardcodée qui tranche avec le reste du dashboard revampé. Le glassmorphism unifie l'expérience.

**Independent Test**: Vérifier que le contenu de la page est visible en transparence derrière la barre en dark mode, et que la barre reste opaque et lisible en light mode.

**Acceptance Scenarios**:

1. **Given** le dashboard en dark mode, **When** l'utilisateur scrolle, **Then** le contenu est partiellement visible derrière la barre de navigation (effet de flou)
2. **Given** le dashboard en light mode, **When** l'utilisateur regarde la barre, **Then** la barre a un fond opaque propre avec une bordure supérieure subtile (pas de glassmorphism)
3. **Given** un navigateur ne supportant pas `backdrop-filter`, **When** la barre s'affiche, **Then** elle utilise un fond opaque comme fallback

---

### User Story 3 — Labels lisibles sans troncature (Priority: P2)

Les labels des onglets sont entièrement visibles sans troncature. Si le nombre d'items dépasse 5, les labels raccourcissent intelligemment ou la taille de police s'adapte pour tout faire tenir.

**Why this priority**: Les labels tronqués ("Abonneme...", "Transacti...") nuisent à la lisibilité et donnent un aspect bâclé.

**Independent Test**: Configurer 6 onglets et vérifier qu'aucun label n'est tronqué avec des points de suspension.

**Acceptance Scenarios**:

1. **Given** 5 onglets ou moins dans la navigation, **When** la barre s'affiche, **Then** tous les labels sont entièrement visibles sans troncature
2. **Given** 6 onglets dans la navigation, **When** la barre s'affiche, **Then** les labels sont raccourcis si nécessaire mais restent lisibles (pas de "...")
3. **Given** un écran de 320px de large (petit mobile), **When** la barre s'affiche, **Then** les labels s'adaptent à l'espace disponible sans troncature

---

### Edge Cases

- Que se passe-t-il si l'utilisateur a configuré un seul onglet ? La barre s'affiche normalement avec un seul item centré.
- Le pill indicator interfère-t-il avec le badge de notification ? Non, le badge reste au-dessus du pill.
- La barre glassmorphism obscurcit-elle le FAB ? Non, le FAB est positionné au-dessus de la barre (z-index supérieur).
- Que se passe-t-il avec `prefers-reduced-motion` ? Toutes les transitions (pill, scale) sont désactivées.
- En desktop (>= 768px), la barre est-elle affichée ? Non, la sidebar desktop remplace la bottom nav (comportement existant inchangé).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'onglet actif DOIT afficher un pill indicator (pastille arrondie avec fond teinté de la couleur primaire) derrière l'icône
- **FR-002**: L'icône de l'onglet actif DOIT être en version remplie (fill), les onglets inactifs en version outline (regular)
- **FR-003**: La transition entre onglets DOIT être fluide (le pill se déplace ou apparaît/disparaît avec une transition)
- **FR-004**: La barre de navigation DOIT utiliser un effet glassmorphism (fond semi-transparent + flou d'arrière-plan) en dark mode uniquement
- **FR-005**: En light mode, la barre DOIT utiliser un fond opaque avec une bordure supérieure subtile
- **FR-006**: La shadow hardcodée DOIT être remplacée par un effet visuel utilisant les tokens du design system
- **FR-007**: Les labels des onglets NE DOIVENT PAS être tronqués avec des points de suspension — la taille de police DOIT être réduite automatiquement quand la barre contient 6 items ou plus
- **FR-008**: Toutes les animations DOIVENT être désactivées quand `prefers-reduced-motion: reduce` est actif
- **FR-009**: L'effet glassmorphism DOIT avoir un fallback opaque pour les navigateurs ne supportant pas `backdrop-filter`
- **FR-010**: Les changements DOIVENT fonctionner correctement en dark mode ET en light mode
- **FR-011**: Le safe area inset pour les mobiles à encoche DOIT être conservé

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur identifie l'onglet actif en moins de 0.5 seconde (grâce au pill indicator visuel)
- **SC-002**: Aucun label n'est tronqué quel que soit le nombre d'onglets (1 à 6) et la largeur d'écran (>= 320px)
- **SC-003**: La barre de navigation est visuellement cohérente avec le dashboard revampé (glassmorphism, tokens, profondeur)
- **SC-004**: Toutes les animations respectent `prefers-reduced-motion`
- **SC-005**: Aucune fonctionnalité existante n'est altérée — tous les tests passent sans modification
- **SC-006**: La barre reste utilisable et lisible sur tous les navigateurs cibles (Safari iOS, Chrome Android, Chrome Desktop)

## Assumptions

- Le pill indicator utilise la couleur primaire (`--color-primary-light` pour le fond, `--color-primary` pour l'icône/label actif) — même palette que le rest du dashboard
- Le glassmorphism de la barre réutilise les tokens `--glass-bg`, `--glass-border`, `--glass-blur` créés dans la feature 091
- Les labels longs sont gérés par réduction de taille de police en CSS (pas d'abréviations) — quand 6+ items, la police passe de `font-size-xs` (12px) à ~10px pour tout faire tenir sans troncature
- Le scope est limité à la barre de navigation Angular (app/) — la navigation Flutter n'est pas concernée
- Le comportement desktop (sidebar au lieu de bottom nav) reste inchangé
- Le FAB reste positionné au-dessus de la barre, son style n'est pas modifié
