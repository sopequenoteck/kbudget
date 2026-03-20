# Tasks: Alignement Settings Angular sur Flutter

**Input**: Design documents from `/specs/098-angular-settings-alignment/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Pas de setup specifique necessaire — le projet Angular est deja initialise et tous les fichiers cibles existent.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Enrichir le modele de donnees du hub avant les modifications visuelles

- [x] T001 Enrichir l'interface `SettingsSection` avec `iconColor: string` et `group: SettingsGroup`, definir le type `SettingsGroup` et la map `GROUP_LABELS`, et remplir le nouveau tableau `SECTIONS` avec les 10 items groupes/colores (retirer Budget, ajouter Securite), mettre a jour les imports Phosphor (`phosphorToggleRight`, `phosphorDatabase`, `phosphorLock` en remplacement de `phosphorLightning`, `phosphorFloppyDisk`) dans `app/src/app/features/settings/settings.ts`

**Checkpoint**: Modele de donnees du hub pret — les phases suivantes peuvent commencer

---

## Phase 3: User Story 1 - Hub Settings groupe et colore (Priority: P1)

**Goal**: Le hub affiche les sections en 3 groupes avec headers, couleurs d'icones variees, ordre aligne sur Flutter

**Independent Test**: Ouvrir /settings et verifier visuellement les 3 groupes, l'ordre, les couleurs et les placeholders

### Implementation for User Story 1

- [x] T002 [US1] Ajouter un computed signal `groupedSections` qui retourne les sections groupees par `SettingsGroup` dans l'ordre (general, management, other), et exposer `GROUP_LABELS` dans le composant, dans `app/src/app/features/settings/settings.ts`
- [x] T003 [P] [US1] Refondre le template pour iterer par groupe avec un header `<h3>` par groupe et les items en dessous, appliquer `[style.background]` avec `iconColor` sur le cercle d'icone, gerer le cas placeholder (pas de routerLink, badge "A venir"), dans `app/src/app/features/settings/settings.html`
- [x] T004 [P] [US1] Ajouter les styles pour les headers de groupe (`.settings-group__title`), modifier le cercle d'icone pour accepter une couleur dynamique au lieu de `--color-primary-light`, ajouter espacement entre groupes, dans `app/src/app/features/settings/settings.scss`
- [x] T005 [US1] Retirer la route `budget` et ajouter la route `security` pointant vers le composant Placeholder avec `data: { title: 'Securite', icon: 'phosphorLock' }` dans `app/src/app/features/settings/settings.routes.ts`

**Checkpoint**: Hub Settings affiche 3 groupes avec headers, couleurs variees, ordre Flutter, Budget absent, Securite placeholder

---

## Phase 4: User Story 2 - Page A propos enrichie (Priority: P2)

**Goal**: La page A propos affiche 3 cards : Application (version + statut serveur + env), Mes donnees (4 compteurs), Contact (auteur + mailto)

**Independent Test**: Ouvrir /settings/about et verifier les 3 cards, le statut serveur, les compteurs dynamiques et le lien contact

### Implementation for User Story 2

- [x] T006 [US2] Refondre le composant About : injecter `HealthService`, `TransactionService`, `AccountService`, `SubscriptionService`, `DebtService`; ajouter signals `healthResult`, `serverInfo`, `stats` (via `forkJoin` + `toSignal`); appeler `checkHealth()` au init, dans `app/src/app/features/settings/components/about/about.ts`
- [x] T007 [P] [US2] Refondre le template avec 3 cards : card Application (icone + nom + version + pill statut serveur + badge environnement), card Mes donnees (grille 2x2 compteurs avec fallback tiret), card Contact (icone email + nom + mailto), dans `app/src/app/features/settings/components/about/about.html`
- [x] T008 [P] [US2] Refondre les styles : card layout, pill statut (vert online / rouge offline), badge environnement (indigo), grille 2x2 stats, row contact avec hover, support dark mode via tokens existants, dans `app/src/app/features/settings/components/about/about.scss`

**Checkpoint**: Page A propos affiche les 3 cards avec donnees dynamiques, statut serveur et compteurs

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Verification globale et coherence

- [x] T009 Verifier la coherence dark mode sur le hub Settings et la page A propos
- [x] T010 Executer les tests existants (`cd app && npm run test`) et corriger si necessaire
- [x] T011 Verifier le rendu responsive mobile (< 768px) sur les deux pages

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: Pas de dependance — peut commencer immediatement
- **US1 Hub (Phase 3)**: Depend de T001 (modele de donnees)
- **US2 About (Phase 4)**: Independant de US1 — peut commencer en parallele apres T001
- **Polish (Phase 5)**: Depend de US1 et US2

### User Story Dependencies

- **User Story 1 (P1)**: Depend de T001 uniquement. Pas de dependance sur US2.
- **User Story 2 (P2)**: Depend de T001 uniquement (besoin que les routes soient a jour). Pas de dependance sur US1.

### Within Each User Story

- US1: T002 (computed) → T003 (template) + T004 (styles) en parallele → T005 (routes)
- US2: T006 (composant) → T007 (template) + T008 (styles) en parallele

### Parallel Opportunities

- T003 et T004 peuvent etre faits en parallele (fichiers differents)
- T007 et T008 peuvent etre faits en parallele (fichiers differents)
- US1 et US2 peuvent etre implementees en parallele apres T001

---

## Parallel Example: User Story 1

```
# Apres T002 (computed signal pret) :
Task T003: "Refondre template hub" (settings.html)
Task T004: "Ajouter styles groupes" (settings.scss)
# Ces deux taches modifient des fichiers differents → parallele possible
```

## Parallel Example: User Story 2

```
# Apres T006 (composant refait) :
Task T007: "Refondre template about" (about.html)
Task T008: "Refondre styles about" (about.scss)
# Ces deux taches modifient des fichiers differents → parallele possible
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completer T001 (modele de donnees enrichi)
2. Completer T002-T005 (hub groupe et colore)
3. **STOP et VALIDER** : verifier /settings visuellement
4. Commiter

### Incremental Delivery

1. T001 → Modele pret
2. T002-T005 → Hub aligne sur Flutter → Commiter
3. T006-T008 → Page A propos enrichie → Commiter
4. T009-T011 → Polish → Commiter

---

## Notes

- [P] tasks = fichiers differents, pas de dependances
- Pas de changement backend — feature frontend-only
- Reutiliser HealthService et les services CRUD existants
- Commiter apres chaque user story completee
- Verifier dark mode apres chaque modification visuelle
