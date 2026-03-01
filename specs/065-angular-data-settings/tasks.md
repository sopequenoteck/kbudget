# Tasks: Gestion donnees Angular (Data Settings)

**Input**: Design documents from `/specs/065-angular-data-settings/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Non demandes dans la spec — pas de taches de test generees.

**Organization**: Taches groupees par user story pour implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Foundational (Service de base)

**Purpose**: Creer le service de health check utilise par toutes les user stories

- [x] T001 Create HealthService in `app/src/app/core/services/health.ts` — define `HealthCheckResult` type (`status: 'online' | 'offline' | 'checking'`, `responseTimeMs: number | null`, `error: string | null`, `checkedAt: Date | null`), define `ServerInfo` type (`apiUrl: string`, `environment: string`), implement `getServerInfo()` returning `ServerInfo` built from `window.location.origin + environment.apiUrl` and `environment.production`, implement `checkHealth()` returning `Observable<HealthCheckResult>` that calls `GET ${window.location.origin}/actuator/health` via `HttpClient` with 10s timeout, measures latency via `Date.now()`, maps errors to user-friendly messages (timeout → "Delai de reponse depasse", network error → "Serveur injoignable", 5xx → "Erreur serveur", other → "Erreur inconnue"). Service is `providedIn: 'root'`. Use `HttpClient` directly (not `ApiService`) since `/actuator/health` is outside the `/api` context path. Ref: research.md R2, R4; data-model.md HealthCheckResult.

**Checkpoint**: HealthService pret — les user stories peuvent commencer.

---

## Phase 2: User Story 1 - Consulter les informations de connexion serveur (Priority: P1) MVP

**Goal**: L'utilisateur voit l'URL du serveur et le statut de connexion (en ligne/hors ligne) des l'ouverture de l'ecran.

**Independent Test**: Acceder a `/settings/data`, verifier que l'URL et le badge de statut s'affichent correctement (vert si backend lance, rouge sinon).

### Implementation for User Story 1

- [x] T002 [US1] Create DataSettings component class in `app/src/app/features/settings/components/data-settings/data-settings.ts` — standalone, `ChangeDetectionStrategy.OnPush`, inject `HealthService`, expose `serverInfo` signal (from `healthService.getServerInfo()`), expose `healthResult` as `WritableSignal<HealthCheckResult>` initialized with status `'checking'`, trigger `healthService.checkHealth()` on component init via `effect()` or `OnInit`, update `healthResult` signal on response. Import `RouterLink`. Ref: research.md R5, plan.md D1.

- [x] T003 [US1] Create DataSettings template in `app/src/app/features/settings/components/data-settings/data-settings.html` — section-back link to `/settings` (same pattern as Appearance component), title "Donnees", section "Serveur" with: info row showing "URL" label + `serverInfo().apiUrl` value, info row showing "Environnement" label + `serverInfo().environment` value (`production` or `development`), section "Connexion" with: status badge showing `healthResult().status` — green dot + "En ligne" + response time if online, red dot + "Hors ligne" + error message if offline, spinner + "Verification..." if checking, `checkedAt` timestamp display ("Dernier test : HH:mm:ss"). Ref: spec.md FR-001/FR-002/FR-003.

- [x] T004 [US1] Create DataSettings styles in `app/src/app/features/settings/components/data-settings/data-settings.scss` — `:host { display: block; padding: var(--space-4) }`, reuse `.section-back` pattern from Appearance, `.data-title` (font-size-xl, font-weight-semibold), `.info-section` with label (font-size-sm, text-secondary) + value rows, `.status-badge` with variants `--online` (background green/success), `--offline` (background red/error), `--checking` (background neutral), `.status-dot` (8px circle, inline), `.info-row` (flex, gap space-2, align-items center), `.response-time` (text-secondary, font-size-sm). All values via design tokens `var(--*)`. Ref: plan.md D4.

- [x] T005 [P] [US1] Update settings route in `app/src/app/features/settings/settings.routes.ts` — replace `data` path entry: remove placeholder import, add `loadComponent: () => import('./components/data-settings/data-settings').then(m => m.DataSettings)`, remove `data: { title, icon }` property (no longer needed). Ref: plan.md Source Code structure.

- [x] T006 [P] [US1] Update settings hub card in `app/src/app/features/settings/settings.ts` — change data entry `status` from `'placeholder'` to `'active'`, update `description` to `'Serveur et maintenance'`. Ref: plan.md Source Code structure.

**Checkpoint**: L'ecran `/settings/data` affiche les infos serveur et le statut de connexion. MVP fonctionnel.

---

## Phase 3: User Story 2 - Tester manuellement la connectivite serveur (Priority: P2)

**Goal**: L'utilisateur peut lancer un test de connectivite a la demande et voir le resultat (temps de reponse ou erreur).

**Independent Test**: Cliquer sur "Tester la connexion", verifier que le badge se met a jour avec le temps de reponse ou un message d'erreur.

### Implementation for User Story 2

- [x] T007 [US2] Add manual test button to DataSettings component and template — in `data-settings.ts`: add `isTestRunning = signal(false)` flag, add `testConnection()` method that sets `healthResult` to `'checking'`, calls `healthService.checkHealth()`, updates `healthResult` on response, handles rapid clicks by using `AbortController` or ignoring if `isTestRunning()` is true. In `data-settings.html`: add "Tester la connexion" button (styled as secondary/outline) below status badge, disable button when `isTestRunning()`, show spinner inside button during test. In `data-settings.scss`: add `.test-button` styles (secondary button pattern, disabled state, spinner alignment). Ref: spec.md FR-004/FR-005/FR-006/FR-009, edge case "rapid clicks".

**Checkpoint**: Le test manuel de connectivite fonctionne avec feedback visuel.

---

## Phase 4: User Story 3 - Recharger les donnees depuis le serveur (Priority: P3)

**Goal**: L'utilisateur peut forcer un rechargement complet des donnees via `window.location.reload()` apres confirmation.

**Independent Test**: Cliquer sur "Recharger les donnees", confirmer dans le dialogue, verifier que la page se recharge.

### Implementation for User Story 3

- [x] T008 [US3] Add reload section to DataSettings component and template — in `data-settings.ts`: add `reloadData()` method that shows `window.confirm('Recharger toutes les donnees ? L\'application va redemarrer.')`, if confirmed calls `window.location.reload()`. In `data-settings.html`: add section "Maintenance" with description text "Forcer un rechargement complet des donnees depuis le serveur", add "Recharger les donnees" button (styled as warning/destructive), add explanatory note "L'application redemarrera automatiquement". In `data-settings.scss`: add `.maintenance-section` styles, `.reload-button` (warning button style — amber/orange background per design system primary color). Ref: spec.md FR-007/FR-008, research.md R3, plan.md D3.

**Checkpoint**: Toutes les user stories fonctionnent independamment. Feature complete.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et coherence

- [x] T009 Verify all acceptance scenarios by running quickstart.md validation — start backend (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`), start frontend (`cd app && ng serve`), navigate to `/settings/data`, verify: (1) URL serveur affichee correctement, (2) badge statut "En ligne" vert avec temps de reponse, (3) bouton "Tester la connexion" fonctionne, (4) arreter backend → tester → badge "Hors ligne" rouge avec message, (5) bouton "Recharger les donnees" → confirmation → page reload, (6) hub Settings montre la card Donnees sans badge "A venir"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dependance — peut demarrer immediatement
- **US1 (Phase 2)**: Depend de Phase 1 (HealthService requis)
- **US2 (Phase 3)**: Depend de Phase 2 (composant DataSettings doit exister)
- **US3 (Phase 4)**: Depend de Phase 2 (composant DataSettings doit exister). Independant de US2.
- **Polish (Phase 5)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 (P1)**: Depend uniquement de Phase 1 (Foundational) — MVP autonome
- **US2 (P2)**: Depend de US1 (ajout au composant existant) — mais testable independamment
- **US3 (P3)**: Depend de US1 (ajout au composant existant) — independant de US2, testable independamment

### Within Each Phase

- Phase 2: T002 → T003, T004 (sequentiel: class → template → styles). T005, T006 sont [P] entre eux et peuvent etre faits en parallele de T003/T004
- Phase 3: T007 seule tache
- Phase 4: T008 seule tache

### Parallel Opportunities

- T005 et T006 peuvent etre executes en parallele (fichiers differents: routes vs hub)
- US2 et US3 sont independantes entre elles et pourraient theoriquement etre developpees en parallele par deux personnes (mais elles modifient le meme composant, donc sequentiel recommande pour un seul developpeur)

---

## Parallel Example: User Story 1

```text
# Sequentiel (meme composant, dependances):
T002: Create DataSettings component class (.ts)
T003: Create DataSettings template (.html) — depends on T002
T004: Create DataSettings styles (.scss) — depends on T003

# Parallele (fichiers differents, pas de dependances mutuelles):
T005: Update settings.routes.ts   ← peut etre fait en meme temps que T006
T006: Update settings.ts hub card ← peut etre fait en meme temps que T005
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: HealthService (T001)
2. Complete Phase 2: DataSettings component + wiring (T002-T006)
3. **STOP and VALIDATE**: Tester US1 independamment — l'ecran affiche infos serveur et statut
4. Deployer si pret

### Incremental Delivery

1. Phase 1 → HealthService pret
2. Phase 2 (US1) → Ecran fonctionnel avec infos serveur et statut auto (MVP)
3. Phase 3 (US2) → Ajout test manuel de connectivite
4. Phase 4 (US3) → Ajout rechargement donnees
5. Phase 5 → Validation finale
6. Chaque story ajoute de la valeur sans casser les precedentes

---

## Notes

- [P] = fichiers differents, pas de dependances
- Pas de tests unitaires generes (non demandes dans la spec)
- Feature Angular-only — aucune modification backend requise
- Le composant `Appearance` sert de reference pour le pattern (voir `app/src/app/features/settings/components/appearance/`)
- Commit recommande apres chaque phase completee
