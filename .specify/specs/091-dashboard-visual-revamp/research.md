# Research: Dashboard Visual Revamp

**Branch**: `091-dashboard-visual-revamp` | **Date**: 2026-03-15

## R1 — Glassmorphism CSS : implémentation et fallback

**Decision**: Utiliser `backdrop-filter: blur()` avec `@supports` pour le fallback.

**Rationale**: `backdrop-filter` est supporté par 96%+ des navigateurs modernes (Chrome 76+, Safari 9+, Firefox 103+). L'approche `@supports` permet un fallback gracieux vers un fond opaque sans dégradation fonctionnelle.

**Implementation pattern**:
```scss
.glass-card {
  // Fallback opaque (navigateurs sans support)
  background-color: var(--surface-default);

  @supports (backdrop-filter: blur(1px)) {
    background-color: rgba(31, 41, 55, 0.6); // gray-800 semi-transparent
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.08);
  }
}
```

**Alternatives considered**:
- Pseudo-élément `::before` avec blur : plus complexe, problèmes de stacking context
- SVG filter blur : pas de support du backdrop, mauvaise performance
- Opacité simple sans blur : visuellement pauvre, pas d'effet glass

## R2 — Hero card gradient : couleurs et direction

**Decision**: Gradient diagonal (135deg) du Amber-900 vers l'Indigo-900 en dark mode, Amber-50 vers Indigo-50 en light mode.

**Rationale**: Les teintes 900 (dark) et 50 (light) des palettes existantes permettent un gradient subtil qui ne détruit pas la lisibilité du texte. L'angle 135deg (haut-gauche → bas-droite) est le standard iOS pour les cards hero.

**Implementation pattern**:
```scss
// Dark mode
background: linear-gradient(135deg, var(--amber-900) 0%, var(--indigo-900) 100%);

// Light mode
background: linear-gradient(135deg, var(--amber-50) 0%, var(--indigo-50) 100%);
```

**Alternatives considered**:
- Gradient avec couleurs vives (amber-400 → indigo-400) : trop agressif, réduit la lisibilité
- Gradient monochrome (gray-800 → gray-700) : trop subtil, pas d'identité visuelle
- Background image (mesh gradient) : plus lourd, pas maintenable via tokens

## R3 — Barres de budget : animation et seuils

**Decision**: Utiliser `transition: width` avec une classe initiale `--initial` (width: 0) retirée après le mount via un signal Angular, pour animer l'apparition des barres. Les seuils de couleur existants (80% warning, 100% dépassement) sont conservés.

**Rationale**: Le budget-summary utilise déjà `transition: width var(--duration-normal)` mais n'anime pas l'apparition initiale. L'approche retenue : ajouter une classe `budget-bar__fill--initial` (width: 0) au mount, puis la retirer après un `setTimeout(0)` via un signal `animated`. La transition CSS native gère le reste. Les seuils 80%/100% sont déjà en place dans le composant.

**Note**: Le composant applique déjà `border-radius: var(--radius-round)` et la hauteur est de 7px. Changements : hauteur → 10px, transition `--duration-slow` au lieu de `--duration-normal`, classe initiale pour animation d'apparition.

**Alternatives rejected**:
- `@keyframes` sur width : `@keyframes` ne peut pas interpoler vers une CSS custom property ni vers une valeur inline `[style.width.%]`. La transition CSS avec classe initiale est plus fiable et plus simple.
- IntersectionObserver pour trigger au scroll : over-engineering pour 4 barres visibles immédiatement

## R4 — Badges de variation : pattern et accessibilité

**Decision**: Badges inline (`<span class="badge badge--positive/negative/neutral">`) avec fond teinté et coins arrondis.

**Rationale**: Les tokens `--bg-success`, `--bg-error` et les couleurs text `--text-success`, `--text-error` existent déjà dans le design system. Les utiliser pour les badges garantit la cohérence. Le badge est un conteneur inline avec padding, border-radius, et fond teinté.

**Implementation pattern**:
```scss
.badge {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-round);
  font-size: var(--font-size-xs);
  font-weight: var(--font-weight-medium);

  &--positive {
    background: var(--bg-success);
    color: var(--text-success);
  }
  &--negative {
    background: var(--bg-error);
    color: var(--text-error);
  }
  &--neutral {
    background: var(--bg-tertiary);
    color: var(--text-secondary);
  }
}
```

## R5 — Micro-interactions : prefers-reduced-motion

**Decision**: Utiliser le mécanisme existant dans `_tokens.scss` qui met `--duration-*` à `0ms` quand `prefers-reduced-motion: reduce`.

**Rationale**: Le design system repose déjà les transitions sur `var(--duration-normal)` et `var(--easing-default)`. Le media query dans `_tokens.scss` (ligne 133-138) met automatiquement toutes les durées à 0ms. Toutes les nouvelles animations DOIVENT utiliser ces tokens, ce qui garantit le respect de `prefers-reduced-motion` sans code supplémentaire.

**Alternatives considered**:
- Media query dans chaque composant : redondant, le système global suffit
- JavaScript `matchMedia` : over-engineering quand CSS suffit

## R6 — Gradient de fond page : technique

**Decision**: Pseudo-élément `::before` sur `:host` avec un gradient radial positionné en haut.

**Rationale**: Un pseudo-élément permet d'éviter de modifier le flux du contenu. Le gradient est fixé en position et ne scrolle pas avec le contenu, créant un effet d'ambiance subtil.

**Implementation pattern**:
```scss
:host::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 40vh;
  background: radial-gradient(ellipse at top center, rgba(amber, 0.08) 0%, transparent 70%);
  pointer-events: none;
  z-index: -1;
}
```

## R7 — Transactions : cercles emoji et cards individuelles

**Decision**: Le composant `ListItem` partagé applique DÉJÀ un cercle coloré sur les icônes emoji (`list-item__icon` : `background-color: var(--color-primary-light)`, `border-radius: var(--radius-round)`, `width/height: var(--space-10)`).

**Rationale**: L'analyse du code `list-item.scss` montre que FR-009 est déjà implémenté. Le seul changement nécessaire est de passer du conteneur unique `dashboard-list` (avec `border-bottom` entre items) à un layout en gap (items séparés par des espaces).

**Impact**: FR-009 est déjà satisfait. Seul FR-008 (gaps au lieu de borders) nécessite un changement SCSS dans `dashboard.scss`.
