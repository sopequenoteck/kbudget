# Tasks: Bottom Nav Revamp

**Input**: Design documents from `/specs/092-bottom-nav-revamp/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, quickstart.md

**Tests**: Non requis — feature purement visuelle, les 5 tests existants doivent passer sans modification.

**Organization**: Tasks groupées par user story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle
- **[Story]**: US1, US2, US3

## Path Conventions

- **Bottom Nav**: `app/src/app/shared/components/bottom-nav/`
- **Tokens/Themes**: `app/src/styles/themes/`

---

## Phase 1: Setup

**Purpose**: Aucun setup requis. Les tokens glassmorphism (`--glass-bg`, `--glass-border`, `--glass-blur`) existent déjà depuis la feature 091. Seul ajout : un token pour la bordure supérieure en light mode.

- [x] T001 Ajouter le token `--nav-border-top` dans `app/src/styles/themes/_light.scss` — Valeur : `1px solid var(--border-default)`. Ajouter dans la section `// -- Dashboard visual revamp --` existante. Dans `app/src/styles/themes/_dark.scss`, ajouter `--nav-border-top: 1px solid var(--glass-border)`.

**Checkpoint**: Token disponible.

---

## Phase 2: User Story 1 — Pill indicator actif (Priority: P1) 🎯 MVP

**Goal**: L'onglet actif affiche un pill coloré derrière l'icône + icône fill.

**Independent Test**: Naviguer entre deux onglets. L'actif a un pill teinté derrière l'icône, l'inactif non.

### Implementation

- [x] T002 [US1] Ajouter le pseudo-élément pill indicator dans `app/src/app/shared/components/bottom-nav/bottom-nav.scss` — Sur `.nav-item`, ajouter `position: relative`. Sur `.nav-item.active`, ajouter un `&::before` avec : `content: ''`, `position: absolute`, `top: 4px` (au-dessus du label), `left: 50%`, `transform: translateX(-50%)`, `width: 56px`, `height: 32px`, `border-radius: var(--radius-round)`, `background-color: var(--color-primary-light)`, `z-index: 0`, `transition: opacity var(--duration-normal) var(--easing-default)`. L'icône doit avoir `position: relative; z-index: 1` pour rester au-dessus du pill.
- [x] T003 [US1] Vérifier que l'icône fill est bien appliquée sur l'onglet actif dans `app/src/app/shared/components/bottom-nav/bottom-nav.ts` — Le composant utilise déjà un ternaire pour switcher entre icône regular et fill selon `isActive`. Vérifier que c'est fonctionnel. Si besoin, ajuster le style de l'icône active (couleur `--color-primary`).

**Checkpoint**: Pill visible sur l'onglet actif. MVP validable.

---

## Phase 3: User Story 2 — Glassmorphism barre (Priority: P2)

**Goal**: La barre a un fond glassmorphism en dark mode, opaque avec bordure en light mode.

**Independent Test**: En dark mode, le contenu scrollé est visible flouté derrière la barre. En light mode, fond opaque + bordure subtile.

### Implementation

- [x] T004 [US2] Appliquer le glassmorphism au bottom nav dans `app/src/app/shared/components/bottom-nav/bottom-nav.scss` — Remplacer `background-color: var(--surface-default)` et `box-shadow: 0 -1px 8px rgb(0 0 0 / 0.08)` par : `background-color: var(--glass-bg)`, `border-top: var(--nav-border-top)`, `box-shadow: none`. Ajouter `@supports (backdrop-filter: blur(1px))` avec `backdrop-filter: blur(var(--glass-blur))` et `-webkit-backdrop-filter: blur(var(--glass-blur))`.

**Checkpoint**: Glassmorphism visible en dark mode. Fond opaque + bordure en light mode.

---

## Phase 4: User Story 3 — Labels sans troncature (Priority: P2)

**Goal**: Les labels ne sont jamais tronqués. Police réduite pour 6+ items.

**Independent Test**: Configurer 6 onglets. Aucun label ne doit afficher "...".

### Implementation

- [x] T005 [US3] Ajouter le data-attribute item count dans `app/src/app/shared/components/bottom-nav/bottom-nav.ts` — Ajouter dans le décorateur `@Component` un `host: { '[attr.data-item-count]': 'items().length.toString()' }`. Cela expose le nombre d'items comme attribut HTML sur le host pour le ciblage CSS.
- [x] T006 [US3] Ajouter le style police réduite pour 6+ items dans `app/src/app/shared/components/bottom-nav/bottom-nav.scss` — Ajouter `:host([data-item-count="6"]) .nav-item__label { font-size: 0.625rem; }`. Retirer `text-overflow: ellipsis` et `overflow: hidden` du `.nav-item__label` existant pour éviter toute troncature.

**Checkpoint**: 6 onglets → labels complets, police plus petite.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale.

- [ ] T007 Vérification visuelle dark mode — Pill indicator, glassmorphism, labels visibles. Corriger tout défaut.
- [ ] T008 Vérification visuelle light mode — Pill indicator, fond opaque, bordure subtile, labels visibles. Corriger tout défaut.
- [ ] T009 Vérification `prefers-reduced-motion` — Pas de transition pill, pas d'animation.
- [x] T010 Exécuter les tests existants via `cd app && npx vitest run` — Vérifier que tous les tests passent sans modification.
- [ ] T011 Validation quickstart — Suivre `specs/092-bottom-nav-revamp/quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** : Pas de dépendances.
- **Phase 2 (US1 - Pill)** : Dépend de Phase 1.
- **Phase 3 (US2 - Glassmorphism)** : Dépend de Phase 1. Parallélisable avec Phase 2 (sections SCSS différentes).
- **Phase 4 (US3 - Labels)** : Dépend de Phase 1. Parallélisable avec Phase 2/3.
- **Phase 5 (Polish)** : Dépend de toutes les phases.

### Parallel Opportunities

- T002 + T004 parallélisables (sections SCSS différentes)
- T005 + T006 parallélisables (fichiers différents TS vs SCSS)

---

## Implementation Strategy

### MVP First (User Story 1)

1. T001 : Token bordure
2. T002 + T003 : Pill indicator
3. **STOP et VALIDER** : pill visible sur l'onglet actif

### Incremental Delivery

1. US1 Pill → MVP
2. US2 Glassmorphism → Profondeur
3. US3 Labels → Finition
4. Polish → Validation cross-mode

---

## Notes

- Les tokens glassmorphism (`--glass-bg`, `--glass-border`, `--glass-blur`) existent déjà (feature 091)
- Le composant utilise déjà le switch icône regular/fill — pas de changement logique
- `prefers-reduced-motion` géré automatiquement via tokens `--duration-*`
- Desktop (>= 768px) : bottom nav masqué — pas d'impact
