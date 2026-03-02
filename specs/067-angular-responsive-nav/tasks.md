# Tasks: Navigation responsive Angular (bottom nav mobile)

**Input**: Design documents from `/specs/067-angular-responsive-nav/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md
**Linear**: KKS-153

**Tests**: T010 couvre les tests unitaires du composant BottomNav (constitution V : testabilite).

**Organization**: US1+US2 (P1, indissociables) et US3+US4 (P2) sont regroupes en Phase 2 — US3 est une regle CSS dans T006, US4 ne requiert aucun code.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `app/src/` (Angular PWA)
- **Tokens**: `app/src/styles/tokens/`
- **Components**: `app/src/app/shared/components/`

---

## Phase 1: Setup

**Purpose**: Ajouter le design token necessaire avant la creation du composant

- [x] T001 Add `--bottom-nav-height: 56px` CSS custom property in `app/src/styles/tokens/_tokens.scss` inside `:root` block, next to `--header-height`

---

## Phase 2: US1 + US2 - Bottom nav mobile avec onglets dynamiques (Priority: P1) MVP

**Goal**: Remplacer la sidebar/hamburger par une barre de navigation inferieure sur mobile (< 768px). La bottom nav affiche les onglets fixes (Accueil, Transactions) + les onglets optionnels dynamiques selon `enabledFeatures` et `navOrder` du `PreferenceService`.

**Independent Test**: Ouvrir l'app en mode mobile (< 768px) dans DevTools. Verifier : bottom nav visible avec onglets, sidebar masquee, navigation fonctionnelle, onglets dynamiques selon features activees. Basculer en desktop (>= 768px) : sidebar visible, bottom nav masquee.

### Implementation

- [x] T002 [P] [US1] Create `BottomNav` standalone component in `app/src/app/shared/components/bottom-nav/bottom-nav.ts` — `ChangeDetectionStrategy.OnPush`, `imports: [RouterLink]` (from `@angular/router`), inputs: `items = input.required<{label: string; route: string; icon: string}[]>()`, `activeRoute = input<string>('')`. Template: `<nav>` with `@for` rendering `<a routerLink>` items (icon + label), active state via class binding comparing `activeRoute().startsWith(item.route)`. Inline template (no separate HTML file).

- [x] T003 [P] [US1] Create styles in `app/src/app/shared/components/bottom-nav/bottom-nav.scss` — Host: `position: fixed; bottom: 0; left: 0; right: 0; height: var(--bottom-nav-height); background: var(--surface-default); border-top: 1px solid var(--border-default); z-index: var(--z-sticky); padding-bottom: env(safe-area-inset-bottom)`. Ne PAS definir `display` sur `:host` — le controle d'affichage (flex/none) est gere par shell.scss via media queries. Items: `flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: var(--space-1); text-decoration: none; color: var(--text-secondary)`. Active: `color: var(--color-primary); font-weight: var(--font-semibold)`. Icon: `font-size: 1.25rem`. Label: `font-size: var(--text-xs); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%`.

- [x] T004 [US1] Update `app/src/app/shared/components/shell/shell.ts` — Import `BottomNav` in component imports array. Add `currentRoute` as a computed signal derived from the existing `navigationEnd` signal (cree via `toSignal` sur `router.events`): `currentRoute = computed(() => { const e = this.navigationEnd(); return e instanceof NavigationEnd ? e.urlAfterRedirects : this.router.url; })`. Expose it for the template.

- [x] T005 [US1] Update `app/src/app/shared/components/shell/shell.html` — Lire le template actuel pour identifier l'emplacement exact. Add `<bottom-nav [items]="navItems()" [activeRoute]="currentRoute()" />` after the `.shell-content` div (before the FAB). The component is hidden/shown via CSS media queries, not `@if`. Verifier que le z-index ne cree pas de superposition avec le FAB ou les modales.

- [x] T006 [US1+US3] Update `app/src/app/shared/components/shell/shell.scss` — Mobile-default (< 768px): add `.shell-sidebar { display: none; }` (remplace le mecanisme existant `transform: translateX(-100%)` par une suppression complete du layout), `.shell-backdrop { display: none; }` to hide sidebar completely on mobile, and `.shell-hamburger { display: none; }` to hide the hamburger button (FR-009 — inutile avec la bottom nav). Add `bottom-nav { display: flex; }` as mobile default. Adjust `.shell-content` padding-bottom to `calc(var(--bottom-nav-height) + var(--space-6) + 56px + var(--space-4))` to account for bottom nav + FAB. Desktop override (`@media (min-width: 768px)`): add `bottom-nav { display: none; }` and **ajouter** `.shell-content { padding-bottom: calc(56px + var(--space-6) + var(--space-4)); }` dans le bloc media query existant (cette propriete n'y est pas actuellement) pour preserver le padding desktop original (FR-003). Preserve existing desktop sidebar styles unchanged.

- [x] T007 [US1] Update `app/src/app/shared/components/fab/fab.scss` — Add mobile-default rule: `.fab-button { bottom: calc(var(--bottom-nav-height) + var(--space-4)); }` and `.speed-dial-menu { bottom: calc(var(--bottom-nav-height) + var(--space-4) + 56px + var(--space-3)); }`. Add desktop override inside `@media (min-width: 768px)` to restore original values: `.fab-button { bottom: var(--space-6); }` and `.speed-dial-menu { bottom: calc(var(--space-6) + 56px + var(--space-3)); }`.

**Checkpoint**: Bottom nav fonctionnelle sur mobile avec onglets dynamiques. Sidebar, hamburger et FAB corrects. FR-001 a FR-013 couverts. US3 (hamburger supprime) et US4 (menu utilisateur intact) satisfaits. Verifier avec 5 features activees sur viewport 320px : les 5 onglets doivent rester lisibles (icones + labels visibles, labels tronques si necessaire).

---

## Phase 3: Polish & Cross-Cutting Concerns

**Purpose**: Verification finale et nettoyage

- [x] T008 Run `cd app && ng build && ng test` to verify zero compilation errors and no test regressions
- [x] T009 Run `cd app && npx prettier --write "src/app/shared/components/bottom-nav/**" "src/app/shared/components/shell/**" "src/app/shared/components/fab/**"` to format modified/created files
- [x] T010 [US1] Create unit test `app/src/app/shared/components/bottom-nav/bottom-nav.spec.ts` — Vitest + Angular TestBed. Tests: (1) should render all items with icon and label, (2) should apply `.active` class when `activeRoute` starts with item route, (3) should not apply `.active` to non-matching items, (4) should render 0 items when empty array, (5) should not apply `.active` when activeRoute is `/settings` (edge case: page hors bottom nav)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — T001 can start immediately
- **US1+US2+US3+US4 (Phase 2)**: Depends on T001 (CSS token used by component styles)
- **Polish (Phase 3)**: Depends on all previous phases

### User Story Dependencies

- **US1 + US2 (P1)**: Depend on Setup (T001). No external story dependency.
- **US3 (P2)**: Integre dans T006 (`.shell-hamburger { display: none }` avec les autres regles mobile)
- **US4 (P2)**: Zero code change — satisfied by existing header user menu. Verified at checkpoint.

### Within Phase 2 (US1 + US2)

```
T001 (token)
  ↓
T002 + T003 (parallel — component TS + SCSS)
  ↓
T004 (shell.ts — depends on T002 for import)
  ↓
T005 (shell.html — depends on T004 for template binding)
  ↓
T006 + T007 (parallel — shell.scss + fab.scss, independent files)
```

### Parallel Opportunities

```
T002 + T003 → can run in parallel (different files: .ts + .scss)
T006 + T007 → can run in parallel (different files: shell.scss + fab.scss)
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2)

1. T001: Setup token
2. T002 + T003 en parallele: Composant BottomNav
3. T004 → T005: Integration shell
4. T006 + T007 en parallele: CSS responsive (inclut hamburger hide)
5. **STOP et VALIDER**: Bottom nav fonctionnelle sur mobile, sidebar sur desktop, hamburger supprime

### Incremental Delivery

1. Phase 1 + Phase 2 → Feature complete (bottom nav + onglets dynamiques + header adapte)
2. Phase 3 → Build + format + tests

### Suggested MVP Scope

Phase 1 + Phase 2 (T001-T007) delivrent 100% de la valeur utilisateur (US1-US4). Phase 3 est de la validation et du polish.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US2 est inherently satisfait par US1 : le composant BottomNav recoit `navItems()` qui est deja un computed signal dynamique base sur `enabledFeatures` et `navOrder`
- US4 ne requiert aucun code : le menu utilisateur dans le header est inchange
- T008 verifie build + tests existants (constitution V : "Les tests DOIVENT passer avant tout commit")
- T010 couvre les tests unitaires du composant BottomNav (constitution V : testabilite)
- Commit recommande apres chaque phase
