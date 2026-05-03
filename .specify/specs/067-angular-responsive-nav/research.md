# Research: 067-angular-responsive-nav

**Date**: 2026-03-01

## Decision 1: Approche responsive (CSS-only vs JS detection)

**Decision**: CSS-only via `@media (min-width: 768px)` — meme pattern que le shell actuel.

**Rationale**: Le shell utilise deja ce breakpoint pour masquer/afficher le hamburger et la sidebar. Ajouter une detection JS (ex: `window.matchMedia`) ajouterait de la complexite sans benefice. Les media queries CSS gerent nativement le redimensionnement en temps reel (FR-011).

**Alternatives considered**:
- JS `matchMedia` listener + signal boolean `isMobile` → plus complexe, synchronisation JS/CSS necessaire, pas necessaire ici
- Angular CDK `BreakpointObserver` → dependance supplementaire, le CSS suffit

## Decision 2: Composant dedie vs inline dans le shell

**Decision**: Creer un composant standalone `BottomNav` dans `app/src/app/shared/components/bottom-nav/`.

**Rationale**: Le shell fait deja 322 lignes TS + 192 lignes HTML. Ajouter la bottom nav inline alourdirait le composant. Un composant dedie est plus testable, reutilisable et suit le pattern du FAB (composant separe dans `shared/components/fab/`).

**Alternatives considered**:
- Inline dans shell.html → plus rapide mais viole le principe de responsabilite unique, shell deja volumineux
- Directive Angular → pas adapte, c'est un composant visuel avec template

## Decision 3: Hauteur de la bottom nav

**Decision**: 56px — meme hauteur que le header (`--header-height: 56px`).

**Rationale**: Coherence visuelle avec le header. C'est aussi la hauteur standard des bottom navigation bars (Material Design = 56-80px, iOS = 49-83px). Nouvelle CSS variable `--bottom-nav-height: 56px` pour reutilisation.

**Alternatives considered**:
- 64px (Material 3 default) → plus grand, prend plus d'espace ecran
- 48px → trop compact pour des cibles tactiles confortables

## Decision 4: Style des icones (emoji vs icon font)

**Decision**: Conserver les emojis existants definis dans `FEATURES` constant.

**Rationale**: Le projet utilise deja des emojis pour les icones de navigation (sidebar, FAB, settings). Changer pour une icon font (Material Icons, Lucide) serait un changement de scope hors feature. Les emojis sont deja dans `FEATURES`: 🏠, 💰, 🔄, 🤝, 🏪.

**Alternatives considered**:
- Material Icons → necessite ajout de dependance, changement global
- SVG inline → plus de travail, hors scope

## Decision 5: Positionnement du FAB au-dessus de la bottom nav

**Decision**: Sur mobile, decaler le FAB vers le haut de `--bottom-nav-height` via media query CSS.

**Rationale**: Le FAB est actuellement positionne a `bottom: var(--space-6)` (24px). Sur mobile, il doit etre a `bottom: calc(var(--bottom-nav-height) + var(--space-4))` pour rester au-dessus de la bottom nav. Le speed dial menu s'ajuste automatiquement car il est positionne relativement au FAB.

## Decision 6: Gestion de la route active dans la bottom nav

**Decision**: Utiliser `Router.url` via signal dans le shell (deja disponible) et passer la route active au composant `BottomNav`.

**Rationale**: Le shell a deja acces au `Router` et utilise `router.url` pour detecter la route courante (visible dans la logique de redirection). Le composant `BottomNav` recevra `activeRoute` en input et comparera avec chaque `item.route`.

## Decision 7: Z-index de la bottom nav

**Decision**: `z-index: var(--z-sticky)` (200) — en dessous de la sidebar overlay (300) et du FAB (302).

**Rationale**: La bottom nav est un element de navigation persistant, pas un overlay. Elle doit etre sous le FAB et les modals. Le token `--z-sticky` (200) est le niveau appropriate pour les elements fixes de navigation.

## Fichiers impactes

| Fichier | Action | Raison |
|---------|--------|--------|
| `app/src/app/shared/components/bottom-nav/bottom-nav.ts` | CREER | Nouveau composant |
| `app/src/app/shared/components/bottom-nav/bottom-nav.scss` | CREER | Styles bottom nav |
| `app/src/app/shared/components/shell/shell.html` | MODIFIER | Ajouter `<bottom-nav>`, supprimer hamburger mobile |
| `app/src/app/shared/components/shell/shell.scss` | MODIFIER | Masquer sidebar mobile, ajouter padding bottom nav |
| `app/src/app/shared/components/shell/shell.ts` | MODIFIER | Import BottomNav, passer navItems/activeRoute |
| `app/src/app/shared/components/fab/fab.scss` | MODIFIER | Repositionner FAB au-dessus de bottom nav sur mobile |
| `app/src/styles/tokens/_tokens.scss` | MODIFIER | Ajouter `--bottom-nav-height` |
