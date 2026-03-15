# Tasks: Dashboard Visual Revamp

**Input**: Design documents from `/specs/091-dashboard-visual-revamp/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Non requis — feature purement visuelle, les tests Angular existants doivent passer sans modification.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans les descriptions

## Path Conventions

- **Frontend Angular**: `app/src/`
- **Dashboard**: `app/src/app/features/dashboard/`
- **Tokens/Themes**: `app/src/styles/themes/`

---

## Phase 1: Setup (Tokens de thème)

**Purpose**: Ajouter les tokens CSS nécessaires aux thèmes dark et light pour supporter les nouveaux effets visuels.

- [x] T001 [P] Ajouter les tokens glassmorphism, hero et typographie au thème dark dans `app/src/styles/themes/_dark.scss` — Ajouter les custom properties : `--hero-gradient` (linear-gradient 135deg amber-900 → indigo-900), `--glass-bg` (rgba gray-800 60%), `--glass-border` (rgba white 8%), `--glass-blur` (20px), `--page-gradient-color` (rgba amber-400 8%), `--font-size-hero` (2.25rem), `--shadow-hero-text` (0 2px 8px rgba(0,0,0,0.3))
- [x] T002 [P] Ajouter les tokens hero gradient, typographie et fond opaque stylé au thème light dans `app/src/styles/themes/_light.scss` — Ajouter les custom properties : `--hero-gradient` (linear-gradient 135deg amber-50 → indigo-50), `--glass-bg` (var(--surface-raised), opaque), `--glass-border` (var(--border-default)), `--page-gradient-color` (rgba amber-500 5%), `--font-size-hero` (2.25rem), `--shadow-hero-text` (none)

**Checkpoint**: Les tokens sont disponibles. Aucun impact visuel encore (non consommés).

---

## Phase 2: User Story 1 — Hiérarchie visuelle et Hero card patrimoine (Priority: P1) 🎯 MVP

**Goal**: La zone patrimoine se distingue visuellement comme point focal du dashboard (gradient, typographie amplifiée, badges variation).

**Independent Test**: Ouvrir `http://localhost:4200/dashboard` en dark mode et vérifier que la hero card a un fond gradient distinct, un montant plus grand, et les variations en badges colorés.

### Implementation

- [x] T003 [US1] Refondre le style de la zone patrimoine dans `app/src/app/features/dashboard/dashboard.scss` — Remplacer `background-color: var(--surface-default)` de `.accounts-zone__total` par `background: var(--hero-gradient)`. Augmenter `.accounts-zone__total-value` font-size à `var(--font-size-hero)` avec `text-shadow: var(--shadow-hero-text)` (tokens définis en T001/T002, valeur différente par thème). Ajouter `box-shadow: var(--shadow-lg)` pour plus de profondeur.
- [x] T004 [US1] Ajouter les styles de badges variation dans `app/src/app/features/dashboard/dashboard.scss` — Créer les classes `.variation-badge`, `.variation-badge--positive` (bg: `var(--bg-success)`, color: `var(--text-success)`), `.variation-badge--negative` (bg: `var(--bg-error)`, color: `var(--text-error)`), `.variation-badge--neutral` (bg: `var(--bg-tertiary)`, color: `var(--text-secondary)`). Style : `display: inline-flex`, `padding: var(--space-1) var(--space-2)`, `border-radius: var(--radius-round)`, `font-size: var(--font-size-xs)`, `font-weight: var(--font-weight-medium)`.
- [x] T005 [US1] Appliquer les classes badge aux variations patrimoine dans `app/src/app/features/dashboard/dashboard.html` — Envelopper le `<span class="patrimoine-variation">` existant (lignes 38-49) dans un `<span class="variation-badge">` avec la classe conditionnelle `variation-badge--positive/negative/neutral` selon `netDuMois()`. Conserver le contenu textuel existant intact. Vérifier que le greeting (ligne 19) reste lisible avec le nouveau gradient.

**Checkpoint**: La hero card se distingue visuellement. Badges de variation colorés. MVP validable.

---

## Phase 3: User Story 2 — Glassmorphism et profondeur des cards (Priority: P2)

**Goal**: Les cards Revenus/Dépenses ont un effet glass en dark mode et réagissent au touch.

**Independent Test**: En dark mode, vérifier le flou d'arrière-plan sur les cards. Taper dessus → effet scale. En light mode → fond opaque. Avec `prefers-reduced-motion` → pas d'animation.

### Implementation

- [x] T006 [US2] Appliquer le glassmorphism aux summary cards dans `app/src/app/features/dashboard/dashboard.scss` — Modifier `.summary-card` : remplacer `background-color: var(--surface-default)` par `background-color: var(--glass-bg)`, remplacer `box-shadow: var(--shadow-md)` par `box-shadow: none`, et ajouter `border: 1px solid var(--glass-border)`. Ajouter `@supports (backdrop-filter: blur(1px))` avec `backdrop-filter: blur(var(--glass-blur))` et `-webkit-backdrop-filter: blur(var(--glass-blur))`. Le fallback opaque est géré par les tokens (`--glass-bg` est opaque en light mode, `--glass-border` est `--border-default` en light mode).
- [x] T007 [US2] Ajouter les micro-interactions tap sur les cards interactives dans `app/src/app/features/dashboard/dashboard.scss` — Ajouter sur `.summary-card` et `.accounts-zone__total` : `transition: transform var(--duration-fast) var(--easing-default)`, et `&:active { transform: scale(0.97) }`. Le respect de `prefers-reduced-motion` est automatique via le token `--duration-fast` mis à 0ms par `_tokens.scss`.
- [x] T008 [US2] Appliquer les classes badge aux variations revenus/dépenses dans `app/src/app/features/dashboard/dashboard.html` — Envelopper les `<span class="summary-card__variation">` (lignes 83-87 et 101-105) dans des `<span class="variation-badge">` avec la classe conditionnelle appropriée (positif/négatif selon la logique existante `variationRevenus() >= 0` et `variationDepenses() <= 0`).

**Checkpoint**: Cards glassmorphism fonctionnelles. Micro-interactions au tap. Dark + light mode OK.

---

## Phase 4: User Story 3 — Barres de budget enrichies (Priority: P2)

**Goal**: Les barres de budget ont des coins arrondis pill, hauteur 10px, et animation d'apparition.

**Independent Test**: Ouvrir le dashboard avec des budgets actifs. Vérifier : barres arrondies, hauteur visible, animation de largeur au chargement.

### Implementation

- [x] T009 [US3] Enrichir les barres de budget dans `app/src/app/features/dashboard/components/budget-summary/budget-summary.ts` — Dans les inline styles : changer `.budget-bar` height de `7px` à `10px`. Remplacer la `transition` existante sur `.budget-bar__fill` par `transition: width var(--duration-slow) var(--easing-out)`. Ajouter une classe `.budget-bar__fill--initial` avec `width: 0 !important` appliquée au mount. Dans le composant TypeScript, ajouter un signal `animated = signal(false)` et un `effect()` qui met `animated` à `true` après un `setTimeout(0)` pour déclencher la transition. Dans le template, appliquer `[class.budget-bar__fill--initial]="!animated()"` sur chaque `.budget-bar__fill`. Résultat : les barres démarrent à 0 puis transitionnent vers leur largeur réelle. `prefers-reduced-motion` est géré automatiquement car `--duration-slow` passe à `0ms`.

**Checkpoint**: Barres de budget visuellement enrichies. Animation d'apparition fonctionnelle.

---

## Phase 5: User Story 4 — Transactions avec profondeur visuelle (Priority: P3)

**Goal**: Les transactions sont séparées par des gaps au lieu de border-bottom.

**Independent Test**: Vérifier que chaque transaction est visuellement séparée par un espace et non un trait.

### Implementation

- [x] T010 [US4] Transformer la liste de transactions en cards individuelles dans `app/src/app/features/dashboard/dashboard.scss` — Modifier `.dashboard-list` : retirer `overflow: hidden`, changer `background-color` et `box-shadow` pour un fond transparent. Ajouter `gap: var(--space-2)`. Chaque `li` devient une card : `background-color: var(--surface-default)`, `border-radius: var(--radius-lg)`, `box-shadow: var(--shadow-sm)`. Supprimer la règle `li:not(:last-child) { border-bottom }`.

**Checkpoint**: Transactions en cards individuelles. FR-009 (cercles emoji) déjà implémenté dans ListItem.

---

## Phase 6: User Story 5 — Gradient de fond et ambiance page (Priority: P3)

**Goal**: Le fond du dashboard a un gradient radial subtil en haut.

**Independent Test**: Vérifier visuellement un léger halo coloré en haut de la page.

### Implementation

- [x] T011 [US5] Ajouter le gradient de fond page dans `app/src/app/features/dashboard/dashboard.scss` — Ajouter un pseudo-élément `:host::before` avec `content: ''`, `position: fixed`, `top: 0`, `left: 0`, `right: 0`, `height: 40vh`, `background: radial-gradient(ellipse at top center, var(--page-gradient-color) 0%, transparent 70%)`, `pointer-events: none`, `z-index: -1`.

**Checkpoint**: Ambiance page premium. Gradient visible en haut, s'estompe naturellement.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale cross-mode et nettoyage.

- [ ] T012 Vérification visuelle dark mode — Parcourir le dashboard complet en dark mode. Vérifier : hero gradient, glassmorphism, barres budget, badges, transactions cards, page gradient. Corriger tout défaut visuel.
- [ ] T013 Vérification visuelle light mode — Parcourir le dashboard complet en light mode. Vérifier : hero gradient adapté, cards opaques (pas de glassmorphism), barres budget, badges, transactions cards, page gradient doux. Corriger tout défaut visuel.
- [ ] T014 Vérification `prefers-reduced-motion` — Activer `prefers-reduced-motion: reduce` dans les DevTools. Vérifier qu'aucune animation n'est visible (pas de scale, pas d'animation barres, pas de transitions).
- [x] T015 Exécuter les tests Angular existants via `cd app && ng test` — Vérifier que tous les tests passent sans modification. Si un test échoue, investiguer et corriger le changement visuel responsable sans modifier le test.
- [ ] T016 Benchmark performance du rendu dashboard — Ouvrir Chrome DevTools > Performance, mesurer le temps de First Contentful Paint du dashboard avant et après les changements. Vérifier que le delta est ≤ 200ms (SC-005). Si le `backdrop-filter` dégrade significativement, réduire le blur ou supprimer le glassmorphism sur mobile.
- [ ] T017 Validation quickstart — Suivre le `specs/091-dashboard-visual-revamp/quickstart.md` point par point pour valider la checklist complète.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup tokens)** : Pas de dépendances — démarrer immédiatement. T001 et T002 parallélisables.
- **Phase 2 (US1 - Hero card)** : Dépend de Phase 1. MVP — priorité absolue.
- **Phase 3 (US2 - Glassmorphism)** : Dépend de Phase 1. Peut être parallélisée avec Phase 2 (fichiers différents pour T006, même fichier pour T007/T008).
- **Phase 4 (US3 - Budget bars)** : Dépend de Phase 1. Parallélisable avec toutes les autres phases (fichier différent : `budget-summary.ts`).
- **Phase 5 (US4 - Transactions)** : Dépend de Phase 1. Parallélisable avec Phase 2/3 (section différente de `dashboard.scss`).
- **Phase 6 (US5 - Page gradient)** : Dépend de Phase 1. Parallélisable (ajout `:host::before` indépendant).
- **Phase 7 (Polish)** : Dépend de toutes les phases précédentes.

### User Story Dependencies

- **US1 (Hero card)** : Aucune dépendance sur les autres stories
- **US2 (Glassmorphism)** : Aucune dépendance sur les autres stories
- **US3 (Budget bars)** : Aucune dépendance sur les autres stories
- **US4 (Transactions)** : Aucune dépendance sur les autres stories
- **US5 (Page gradient)** : Aucune dépendance sur les autres stories

### Parallel Opportunities

- T001 + T002 : parallélisables (fichiers différents)
- T009 parallélisable avec T003-T008 (fichier `budget-summary.ts` distinct)
- T010 parallélisable avec T003-T009 (section `.dashboard-list` distincte)
- T011 parallélisable avec T003-T010 (pseudo-élément `:host::before` distinct)

---

## Parallel Example: All Stories

```bash
# Après Phase 1 (tokens), lancer en parallèle :
Task T003-T005: "US1 - Hero card (dashboard.scss + dashboard.html)"
Task T009: "US3 - Budget bars (budget-summary.ts)"
Task T011: "US5 - Page gradient (dashboard.scss ::before)"

# Puis séquentiellement (même fichier dashboard.scss) :
Task T006-T008: "US2 - Glassmorphism (dashboard.scss + dashboard.html)"
Task T010: "US4 - Transactions (dashboard.scss .dashboard-list)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 : Setup tokens (T001 + T002)
2. Phase 2 : Hero card patrimoine (T003 + T004 + T005)
3. **STOP et VALIDER** : hero card gradient + badges variation visibles
4. Commit et test

### Incremental Delivery

1. Setup tokens → Tokens prêts
2. US1 Hero card → MVP (point focal patrimoine)
3. US2 Glassmorphism → Cards premium
4. US3 Budget bars → Barres enrichies
5. US4 Transactions → Cards individuelles
6. US5 Page gradient → Ambiance finale
7. Polish → Validation cross-mode

---

## Notes

- Tous les changements sont SCSS + HTML template mineur
- Aucun test nouveau requis — les tests existants doivent passer
- FR-009 (cercles emoji) est déjà implémenté dans `list-item.scss`
- Le seuil 80% pour les barres budget est déjà hardcodé dans `budget-summary.ts`
- `prefers-reduced-motion` est géré automatiquement par `_tokens.scss` (durées à 0ms)
- Commits recommandés après chaque phase complétée
- T008 (US2) dépend implicitement de T004 (US1) pour les styles `.variation-badge` — exécuter US1 avant US2
- Toutes les valeurs dans les composants utilisent des tokens `var(--*)`, jamais de valeurs hardcodées
