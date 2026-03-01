# Tasks: Feature Toggles Angular

**Input**: Design documents from `/specs/064-angular-feature-toggles/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/preferences-api.md

**Tests**: Tâches de test ajoutées pour PreferenceService et featureGuard (constitution V — testabilité).

**Organization**: US1 et US2 sont fusionnées dans la même phase car US2 (sidebar dynamique) est la manifestation visible de US1 (toggle features) — les deux sont P1 et indissociables.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend Angular**: `app/src/app/`
- Modèles : `app/src/app/core/models/`
- Services : `app/src/app/core/services/`
- Guards : `app/src/app/core/guards/`
- Features : `app/src/app/features/`
- Shell/FAB : `app/src/app/shared/components/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Définir le modèle de données côté client (Feature type, interfaces, métadonnées)

- [x] T001 Create Feature type union, FEATURES metadata array, UserPreference and UserPreferenceRequest interfaces in `app/src/app/core/models/preference.model.ts`. Feature type = `'SUBSCRIPTIONS' | 'DEBTS' | 'SHOP'`. FEATURES array: each entry has `value`, `label`, `icon` (emoji string, cohérent avec le reste de l'app — ex: 🔄, 🤝, 🏪), `description`, `route`. Interfaces match API contract from `contracts/preferences-api.md`. See `data-model.md` for field details.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Service de préférences, guard de routes, placeholder Boutique — DOIT être complet avant les user stories

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Create PreferenceService in `app/src/app/core/services/preference.ts`. Signal-based service (pattern similaire à ThemeService — état dans signals + méthodes de mutation). Signals: `enabledFeatures = signal<Feature[]>([])`, `navOrder = signal<Feature[]>([])`, `error = signal<string | null>(null)`. Methods: `loadPreferences()` (GET /users/me/preferences → update signals), `toggleFeature(feature: Feature)` (optimistic: update enabledFeatures signal immediately, then fire-and-forget PUT with enabledFeatures only — no navOrder, let backend auto-manage), `isEnabled(feature: Feature): boolean` (check enabledFeatures signal), `isLoaded(): boolean` (return `enabledFeatures().length > 0` — utilisé par featureGuard T003 pour détecter si les préférences sont chargées). Use `inject(ApiService)`, `firstValueFrom()` for API calls. Error handling: catch errors, set error signal, do NOT rollback state (per design decision D4).
- [x] T003 Create featureGuard in `app/src/app/core/guards/feature.guard.ts`. Functional guard (`CanActivateFn`). Read `route.data['feature']` to get the required Feature. Inject PreferenceService, check `isEnabled(feature)`. If disabled → redirect to `/dashboard` via Router. **Race condition handling**: si les préférences ne sont pas encore chargées (`!preferenceService.isLoaded()`), retourner `true` (permettre la navigation) — le shell effect (T011) se chargera de la redirection une fois les données chargées. Follow same pattern as existing `auth.guard.ts`.
- [x] T004 [P] Create ShopPlaceholder component in `app/src/app/features/shop/shop-placeholder.ts`. Standalone component with inline template. Display centered emoji (🏪) + title "Boutique" + message "Cette fonctionnalité sera bientôt disponible." + back link to `/dashboard`. Use design tokens (`var(--color-*)`, `var(--space-*)`, `var(--radius-*)`). ChangeDetectionStrategy.OnPush.
- [x] T005 Update routes in `app/src/app/app.routes.ts`. Add `featureGuard` + `data: { feature: 'SUBSCRIPTIONS' }` on the `/subscriptions` route. Add `featureGuard` + `data: { feature: 'DEBTS' }` on the `/debts` route. Add new route `/shop` with `featureGuard` + `data: { feature: 'SHOP' }`, lazy-loading ShopPlaceholder. Import featureGuard. Keep authGuard on parent shell route (unchanged).
- [x] T006 Hook PreferenceService.loadPreferences() into auth flow. In `app/src/app/shared/components/shell/shell.ts`, inject PreferenceService and call `loadPreferences()` in the constructor effect that runs after authentication is confirmed (when `isAuthenticated()` becomes true). This ensures preferences are loaded once after login/session restore, before the sidebar renders optional modules.

**Checkpoint**: Foundation ready — PreferenceService loaded with API data, routes guarded, Shop placeholder accessible

---

## Phase 3: User Story 1+2 - Toggle Features + Navigation dynamique (Priority: P1) — MVP

**Goal**: L'utilisateur peut activer/désactiver les modules optionnels depuis Settings > Fonctionnalités. La sidebar et le FAB reflètent dynamiquement les features activées.

**Independent Test**: Se connecter → Settings > Fonctionnalités → désactiver "Abonnements" → vérifier que le lien disparaît de la sidebar et que l'action "Nouvel abonnement" disparaît du FAB. Réactiver → le lien réapparaît.

### Implementation

- [x] T007 [US1] Create Features component in `app/src/app/features/settings/components/features/features.ts`. Standalone component, OnPush. Inject PreferenceService. Display section "Modules" with `@for` loop over FEATURES array. Each item: icon in CircleAvatar + label + description + toggle (checkbox/switch). Toggle calls `preferenceService.toggleFeature(feature)`. Display error message from `preferenceService.error()` signal if not null.
- [x] T008 [P] [US1] Create Features template in `app/src/app/features/settings/components/features/features.html`. Back-link to `/settings` (same pattern as Appearance/Profile components: `<a class="section-back" routerLink="/settings">`). Section "Modules" with title styled like Flutter reference (primary color, semibold). List of 3 feature items with toggle switches. Reserve space for navigation section (Phase 4, US3).
- [x] T009 [P] [US1] Create Features styles in `app/src/app/features/settings/components/features/features.scss`. Follow existing settings sub-component pattern (section-back, card layout). Use design tokens: `var(--space-*)`, `var(--radius-*)`, `var(--color-primary)`, `var(--surface-default)`, `var(--shadow-sm)`. Toggle item: flex row, icon circle, text block, switch aligned right. Section title: primary color, small font weight 600.
- [x] T010 [US1] Add Features route and settings section. In `app/src/app/features/settings/settings.routes.ts`: add route `{ path: 'features', loadComponent: () => import('./components/features/features').then(m => m.Features) }`. In `app/src/app/features/settings/settings.ts`: add section `{ id: 'features', title: 'Fonctionnalités', description: 'Activer/désactiver les modules', icon: '⚡', route: 'features' }` in SECTIONS array, positioned before 'appearance'.
- [x] T011 [US2] Update Shell sidebar for dynamic navigation in `app/src/app/shared/components/shell/shell.ts` and `app/src/app/shared/components/shell/shell.html`. In shell.ts: inject PreferenceService, create `navItems = computed()` that builds array from fixed items (Dashboard, Transactions) + enabled features in navOrder. Each nav item: `{ label, route, icon }`. In shell.html: replace the 4 hardcoded `<a routerLink>` in `.shell-sidebar` with `@for (item of navItems(); track item.route)` rendering `<a [routerLink]="item.route" routerLinkActive="active">`. Also redirect to `/dashboard` if current route is a disabled feature (use `effect()` watching navItems + current URL).
- [x] T012 [US2] Update FAB to filter actions by enabled features in `app/src/app/shared/components/fab/fab.ts`. Inject PreferenceService. In the `actions` computed signal, filter out: `subscription` action if `SUBSCRIPTIONS` is disabled, `debt` action if `DEBTS` is disabled. Keep `transaction` and `transfer` always visible (they are not tied to optional features).

**Checkpoint**: MVP complete — toggle features from Settings, sidebar and FAB react dynamically, routes guarded, preferences persist on server

---

## Phase 4: User Story 3 - Réordonner la navigation (Priority: P2)

**Goal**: L'utilisateur peut réordonner les modules optionnels dans la navigation via drag & drop. L'ordre est persisté et reflété dans la sidebar.

**Independent Test**: Activer les 3 modules → aller dans Settings > Fonctionnalités → section Navigation → drag Boutique au-dessus d'Abonnements → vérifier que la sidebar reflète le nouvel ordre → se reconnecter → vérifier la persistance.

### Implementation

- [x] T013 [US3] Add reorderNavigation() method to PreferenceService in `app/src/app/core/services/preference.ts`. Method signature: `reorderNavigation(newNavOrder: Feature[]): void`. Optimistic: update `navOrder` signal immediately. Fire-and-forget PUT with both `enabledFeatures` and `navOrder` (per design decision D5 — navOrder is only sent explicitly during reorder). Error handling: set error signal on failure, no rollback.
- [x] T014 [US3] Add Navigation reorder section to Features component. In `app/src/app/features/settings/components/features/features.ts`: import `CdkDragDrop, DragDropModule` from `@angular/cdk/drag-drop`. Add section "Navigation" after "Modules" section. Show locked items (Accueil, Transactions) with lock icon and grey styling. Show enabled features as draggable items with `cdkDrag` + `cdkDragHandle`. On `cdkDropListDropped`: recompute navOrder using this algorithm: (1) get `enabledInOrder = navOrder filtered to only enabled features`, (2) `moveItemInArray(enabledInOrder, event.previousIndex, event.currentIndex)` via CDK utility, (3) call `preferenceService.reorderNavigation(enabledInOrder)`. In `features.html`: add `<div cdkDropList (cdkDropListDropped)="onDrop($event)">` with `@for` over enabled features in navOrder. In `features.scss`: add styles for drag handle, drag preview (elevation), locked items.

**Checkpoint**: Reorder working — drag & drop changes sidebar order, persisted via API

---

## Phase 5: User Story 4 - Protection des données à la désactivation (Priority: P3)

**Goal**: Un dialogue de confirmation apparaît avant de désactiver un module contenant des données existantes.

**Independent Test**: Créer un abonnement → aller dans Fonctionnalités → désactiver Abonnements → vérifier que le dialogue apparaît → confirmer → module désactivé. Recommencer sans données → pas de dialogue.

### Implementation

- [x] T015 [US4] Add inline confirmation before disabling features with existing data in `app/src/app/features/settings/components/features/features.ts` and template. Inject SubscriptionService and DebtService. Add signal `confirmDisableFeature = signal<Feature | null>(null)`. Before calling `toggleFeature()` when disabling: check if feature has data via `firstValueFrom(subscriptionService.getAll())` for SUBSCRIPTIONS, `firstValueFrom(debtService.getAll())` for DEBTS, always false for SHOP. If data exists: set `confirmDisableFeature(feature)` to show inline confirmation banner (same pattern as `categories.html` and `accounts.html` — inline banner with message "Vos données seront masquées mais pas supprimées." + buttons "Annuler" / "Désactiver"). On confirm → proceed with toggle + reset signal. On cancel → reset signal. If no data → toggle directly without confirmation.

**Checkpoint**: Full feature complete — all 4 user stories implemented

---

## Phase 5bis: Tests unitaires (Constitution V)

**Purpose**: Tests unitaires pour les composants critiques de la feature (service + guard)

- [x] T018 [P] Write unit tests for PreferenceService in `app/src/app/core/services/preference.spec.ts`. Use Vitest. Mock ApiService. Tests: `should_load_preferences_when_called` (GET → signals updated), `should_toggle_feature_on_when_disabled` (optimistic update + PUT called), `should_toggle_feature_off_when_enabled`, `should_set_error_when_api_fails` (error signal set, state not rollbacked), `should_return_true_when_feature_enabled` (isEnabled), `should_return_false_when_feature_disabled`.
- [x] T019 [P] Write unit tests for featureGuard in `app/src/app/core/guards/feature.guard.spec.ts`. Use Vitest. Mock PreferenceService + Router. Tests: `should_allow_navigation_when_feature_enabled`, `should_redirect_to_dashboard_when_feature_disabled`, `should_allow_navigation_when_preferences_not_loaded` (race condition — isLoaded() returns false).

**Checkpoint**: Tests passing — `ng test` green

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Vérification end-to-end, nettoyage

- [x] T016 Verify full end-to-end flow: login → preferences loaded → sidebar shows correct modules → Settings > Fonctionnalités → toggle features → sidebar updates → navigate to disabled module URL → redirect to Dashboard → FAB shows only relevant actions → reorder modules → sidebar reflects new order → logout and login → state persisted. Verify Flutter parity (SC-006): comparer les toggles activés/désactivés et l'ordre de navigation avec l'app Flutter pour confirmer la parité fonctionnelle. Test with backend running (profil dev).
- [x] T017 Verify Shop placeholder: enable Shop toggle → sidebar shows Boutique link → click → "Coming soon" page displays → disable Shop toggle → sidebar removes Boutique → navigate to /shop directly → redirect to Dashboard.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 model) — BLOCKS all user stories
- **US1+US2 (Phase 3)**: Depends on Phase 2 — MVP delivery
- **US3 (Phase 4)**: Depends on Phase 3 (needs Features component + PreferenceService)
- **US4 (Phase 5)**: Depends on Phase 3 (needs Features component toggle logic)
- **Tests (Phase 5bis)**: Depends on Phase 2 (service + guard must exist). Can run in parallel with Phase 4+5.
- **Polish (Phase 6)**: Depends on all phases complete

### User Story Dependencies

```
Phase 1: Setup
    │
    ▼
Phase 2: Foundational (T002-T006)
    │
    ▼
Phase 3: US1+US2 — Toggle + Navigation (MVP)
    │
    ├──────────────────┐
    ▼                  ▼
Phase 4: US3       Phase 5: US4
(Reorder DnD)      (Confirmation dialog)
    │                  │
    └──────┬───────────┘
           ▼
    Phase 5bis: Tests (T018-T019)
           ▼
    Phase 6: Polish
```

- **US3 et US4** peuvent être implémentées en parallèle après US1+US2
- **US4 ne dépend PAS de US3** (la confirmation est indépendante du réordonnancement)

### Within Each Phase

- T001 before T002 (model needed by service)
- T002 before T003 (guard injects PreferenceService)
- T002 before T005 (service needed before routes use guard)
- T004 can run in parallel with T002 (different files, no dependency)
- T007, T008, T009 can run in parallel within Phase 3
- T010 needs T007 (route references component)
- T011, T012 need T002 (depend on PreferenceService signals)
- T018, T019 can run in parallel (different test files)

### Parallel Opportunities

```
Phase 2 parallel:
  T002 (PreferenceService) | T004 (ShopPlaceholder)
  T003 (featureGuard) — after T002

Phase 3 parallel:
  T007 (features.ts) | T008 (features.html) | T009 (features.scss)
  T011 (shell) | T012 (FAB)  — after T002

Phase 4+5 parallel (after Phase 3):
  T013+T014 (US3 reorder) | T015 (US4 confirmation)

Phase 5bis parallel:
  T018 (test PreferenceService) | T019 (test featureGuard)
```

---

## Implementation Strategy

### MVP First (Phase 1+2+3)

1. Complete Phase 1: Setup (T001) — 1 fichier
2. Complete Phase 2: Foundational (T002-T006) — 4 fichiers créés, 2 modifiés
3. Complete Phase 3: US1+US2 (T007-T012) — 3 fichiers créés, 4 modifiés
4. **STOP and VALIDATE**: Toggle features → sidebar updates → FAB filters → routes guarded
5. Commit et deploy possible à ce stade

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1+US2 → MVP fonctionnel (toggle + navigation dynamique)
3. US3 → Réordonnancement DnD (amélioration UX)
4. US4 → Dialogue de confirmation (polish UX)
5. Polish → Vérification end-to-end

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US1 et US2 sont fusionnées car la navigation dynamique EST la manifestation visible du toggle
- Angular est **server-only** — pas de stockage local des préférences
- CDK DragDrop est déjà installé (`@angular/cdk: ^21.1.3`)
- Les routes `/subscriptions` et `/debts` existent déjà — on ajoute uniquement le `featureGuard`
- Le FAB filtre uniquement `subscription` et `debt` actions — `transaction` et `transfer` restent toujours visibles
- Commit recommandé après chaque phase complète
