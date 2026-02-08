# Tasks: Bouton flottant (+) avec Speed Dial

**Input**: Design documents from `/specs/006-fab-speed-dial/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Installer la dépendance `@angular/cdk` et ajouter le token `--z-fab` dans les design tokens.

- [x] T001 Installer `@angular/cdk` dans `app/package.json` via `cd app && npm install @angular/cdk`
- [x] T002 [P] Ajouter le token `$z-fab: 250` dans `app/src/styles/tokens/_primitives.scss` (entre `$z-sticky` et `$z-overlay`)
- [x] T003 [P] Ajouter la CSS custom property `--z-fab: #{p.$z-fab}` dans `app/src/styles/tokens/_tokens.scss` (entre `--z-sticky` et `--z-overlay`)

---

## Phase 2: Foundational — Composant Modal (shared, réutilisable)

**Purpose**: Créer le composant Modal réutilisable qui sera utilisé par US3/US4 et les futures features formulaires. DOIT être complété avant les phases user story.

- [x] T004 Créer le composant Modal (TypeScript) dans `app/src/app/shared/components/modal/modal.ts` — Standalone, OnPush, inputs: `isOpen` (required boolean), `title` (required string), output: `closed`. Importer `CdkTrapFocus` de `@angular/cdk/a11y`. Implémenter le scroll lock via `effect()` (toggle `document.body.style.overflow`). Écouter keydown Escape pour émettre `closed`. Restaurer le focus sur l'élément précédent à la fermeture
- [x] T005 Créer le template Modal dans `app/src/app/shared/components/modal/modal.html` — Overlay (cliquable → `closed`), panel avec header (titre + bouton ×), body (`<ng-content />`). Attributs a11y : `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, `cdkTrapFocus`, `cdkTrapFocusAutoCapture`. Conditionnel via `@if (isOpen())`
- [x] T006 Créer les styles Modal dans `app/src/app/shared/components/modal/modal.scss` — Overlay plein écran (`z-index: var(--z-modal)`, fond semi-transparent), panel centré (mobile: `width: calc(100% - 32px)`, desktop >=768px: `max-width: 480px`), header fixe avec bouton ×, body scrollable (`max-height: 80vh`, `overflow-y: auto`). Animations CSS : fade-in + scale (opacity 0→1, scale 0.95→1, `var(--duration-normal)`, `var(--easing-out)`). Utiliser uniquement des tokens CSS

**Checkpoint**: Le composant Modal est créé et prêt à être intégré. Il n'est pas encore utilisé dans le Shell.

---

## Phase 3: User Story 1 — Accès rapide à la création (Priority: P1) — MVP

**Goal**: L'utilisateur authentifié voit un bouton rond (+) en bas à droite de l'écran sur toutes les pages authentifiées.

**Independent Test**: Naviguer sur `/dashboard`, `/transactions`, `/subscriptions`, `/debts` — le FAB (+) est visible en bas à droite. Absent sur `/auth`.

### Implementation for User Story 1

- [x] T007 [US1] Créer le composant Fab (TypeScript) dans `app/src/app/shared/components/fab/fab.ts` — Standalone, OnPush. Inputs: `isOpen` (required boolean), `isHidden` (boolean, défaut false). Outputs: `toggle` (void), `actionSelected` (ModalType). Définir le type `ModalType = 'transaction' | 'subscription' | 'debt'` et l'interface `SpeedDialItem` + constante `SPEED_DIAL_ACTIONS` dans ce fichier. Exporter `ModalType`
- [x] T008 [US1] Créer le template Fab dans `app/src/app/shared/components/fab/fab.html` — Bouton FAB rond avec icône +, conditionnel `@if (!isHidden())` pour masquer le FAB. Attributs a11y: `aria-label="Actions rapides"`, `aria-expanded` lié à `isOpen()`. Le contenu speed dial (overlay + items) sera ajouté dans US2
- [x] T009 [US1] Créer les styles Fab dans `app/src/app/shared/components/fab/fab.scss` — Bouton 56×56px, `border-radius: var(--radius-round)`, fond `var(--color-primary)`, couleur icône `var(--color-primary-contrast)`, `position: fixed`, `bottom: var(--space-4)`, `right: var(--space-4)`, `z-index: var(--z-fab)`, `box-shadow: var(--shadow-lg)`. Hover: `var(--color-primary-hover)`. Transition icône rotation (0→135deg, `var(--duration-normal)`, `var(--easing-default)`). État `.open` pour la rotation en ×
- [x] T010 [US1] Intégrer le composant Fab dans le Shell — Modifier `app/src/app/shared/components/shell/shell.ts` : ajouter signal `speedDialOpen = signal(false)`, signal `activeModal = signal<ModalType | null>(null)`, computed `modalOpen`, computed `modalTitle`. Ajouter méthodes `onFabToggle()`, `onSpeedDialAction(type)`, `onModalClose()`. Importer `Fab` et `Modal`
- [x] T011 [US1] Modifier le template Shell dans `app/src/app/shared/components/shell/shell.html` — Ajouter `<app-fab [isOpen]="speedDialOpen()" [isHidden]="modalOpen()" (toggle)="onFabToggle()" (actionSelected)="onSpeedDialAction($event)" />` après la balise `</main>`

**Checkpoint**: Le FAB (+) est visible sur toutes les pages authentifiées, correctement positionné en bas à droite. Le clic ne fait rien de visible encore (toggle le signal mais pas d'UI speed dial).

---

## Phase 4: User Story 2 — Ouverture du speed dial (Priority: P1)

**Goal**: Au clic sur le FAB, un menu speed dial s'ouvre avec 3 actions (Transaction, Abonnement, Dette), une animation staggered, et un overlay semi-transparent.

**Independent Test**: Cliquer sur le FAB → le speed dial s'ouvre avec 3 items, l'icône devient ×, l'overlay apparaît.

### Implementation for User Story 2

- [x] T012 [US2] Ajouter le speed dial au template Fab dans `app/src/app/shared/components/fab/fab.html` — Overlay semi-transparent (cliquable → toggle), conteneur `role="menu"` avec 3 items `role="menuitem"` (boucle `@for` sur `SPEED_DIAL_ACTIONS`), chaque item affiche icône + label. Conditionnel `@if (isOpen())` sur le bloc speed dial. Importer `CdkTrapFocus` de `@angular/cdk/a11y` et l'appliquer sur le conteneur menu
- [x] T013 [US2] Ajouter les styles speed dial dans `app/src/app/shared/components/fab/fab.scss` — Overlay plein écran (`z-index: var(--z-overlay)`, fond semi-transparent). Items positionnés au-dessus du FAB (colonne verticale, `gap: var(--space-3)`). Chaque item : fond `var(--surface-raised)`, `border-radius: var(--radius-lg)`, `box-shadow: var(--shadow-md)`, padding, texte `var(--text-primary)`. Animation staggered : chaque item `opacity 0→1`, `translateY(8px)→translateY(0)`, `transition-delay` via `nth-child` (0ms, 50ms, 100ms), durée `var(--duration-normal)`, easing `var(--easing-out)`

**Checkpoint**: Le speed dial s'ouvre au clic FAB avec animation fluide, overlay visible, 3 items affichés. Le clic sur un item ne fait rien encore.

---

## Phase 5: User Story 3 — Ouverture du modal de création (Priority: P1)

**Goal**: Au clic sur un item du speed dial, un modal s'ouvre avec un placeholder, le speed dial se ferme, le FAB est masqué.

**Independent Test**: Ouvrir speed dial → cliquer "Transaction" → modal "Nouvelle transaction" avec placeholder, FAB invisible.

### Implementation for User Story 3

- [x] T014 [US3] Connecter l'action speed dial au modal dans `app/src/app/shared/components/shell/shell.html` — Ajouter `<app-modal [isOpen]="modalOpen()" [title]="modalTitle()" (closed)="onModalClose()">` avec contenu placeholder conditionnel selon `activeModal()` : texte "Formulaire de [type] — à venir" pour chaque type. Positionner après `<app-fab>`
- [x] T015 [US3] Implémenter `onSpeedDialAction(type: ModalType)` dans `app/src/app/shared/components/shell/shell.ts` — Fermer le speed dial (`speedDialOpen.set(false)`), ouvrir le modal (`activeModal.set(type)`)

**Checkpoint**: Le flux complet fonctionne : FAB → speed dial → clic action → modal avec placeholder. Le FAB est masqué quand le modal est ouvert.

---

## Phase 6: User Story 4 — Fermeture du modal (Priority: P1)

**Goal**: L'utilisateur ferme le modal via ×, overlay, ou Echap. Le FAB redevient visible.

**Independent Test**: Ouvrir un modal → fermer avec chaque méthode (×, overlay, Echap) → vérifier que le FAB réapparaît.

### Implementation for User Story 4

- [x] T016 [US4] Implémenter `onModalClose()` dans `app/src/app/shared/components/shell/shell.ts` — `activeModal.set(null)`. Vérifier que le computed `modalOpen` repasse à false et que le FAB redevient visible via `isHidden` input

**Checkpoint**: Le cycle complet ouverture → fermeture du modal fonctionne. Le FAB réapparaît après fermeture. Scroll lock actif pendant que le modal est ouvert.

---

## Phase 7: User Story 5 — Fermeture du speed dial (Priority: P2)

**Goal**: L'utilisateur ferme le speed dial via overlay, Echap, ou re-clic sur le FAB (×).

**Independent Test**: Ouvrir le speed dial → fermer avec chaque méthode → vérifier que le FAB reprend l'icône (+).

### Implementation for User Story 5

- [x] T017 [US5] Ajouter la navigation clavier au speed dial dans `app/src/app/shared/components/fab/fab.ts` — Handler `(keydown)` sur le conteneur menu : ArrowUp/ArrowDown pour naviguer entre les items (focus programmatique), Enter pour sélectionner l'item focusé (émet `actionSelected`), Escape pour fermer (émet `toggle`). Focus sur le premier item à l'ouverture via `effect()` réagissant à `isOpen`. Restaurer le focus sur le bouton FAB à la fermeture
- [x] T018 [US5] Implémenter la fermeture automatique sur navigation dans `app/src/app/shared/components/shell/shell.ts` — Injecter `Router`, écouter `Router.events` filtré sur `NavigationEnd` via `toSignal()` + `effect()`. Dans l'effect : `speedDialOpen.set(false)` et `activeModal.set(null)`

**Checkpoint**: Toutes les méthodes de fermeture du speed dial fonctionnent. La navigation clavier est opérationnelle (ArrowUp/Down, Enter, Escape). Le changement de route ferme tout.

---

## Phase 8: Polish & Edge Cases

**Purpose**: Gestion des edge cases et vérifications finales.

- [x] T019 Implémenter la protection anti-rebond sur le FAB dans `app/src/app/shared/components/fab/fab.ts` — Ignorer les clics pendant l'animation (200ms) pour éviter le clignotement du speed dial lors de clics rapides multiples
- [x] T020 Vérifier le lint et le formatage — Exécuter `cd app && ng lint` et `cd app && npm run format:check`, corriger les erreurs éventuelles
- [x] T021 Valider le build production — Exécuter `cd app && ng build` pour vérifier qu'il n'y a pas d'erreurs de compilation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — démarrage immédiat
- **Foundational (Phase 2)**: Dépend de T001 (CDK installé). BLOQUE US3/US4 (modal requis)
- **US1 (Phase 3)**: Dépend de T002/T003 (tokens). Peut démarrer en parallèle avec Phase 2
- **US2 (Phase 4)**: Dépend de US1 (composant Fab existe) et T001 (CDK pour focus trap)
- **US3 (Phase 5)**: Dépend de US2 (speed dial) et Phase 2 (modal)
- **US4 (Phase 6)**: Dépend de US3 (modal ouvert pour pouvoir le fermer)
- **US5 (Phase 7)**: Dépend de US2 (speed dial ouvert pour pouvoir le fermer)
- **Polish (Phase 8)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1** (FAB visible): Indépendant — MVP minimal
- **US2** (speed dial ouvert): Dépend de US1 (FAB existe)
- **US3** (modal ouvert): Dépend de US2 (speed dial) + Phase 2 (modal composant)
- **US4** (modal fermé): Dépend de US3 (modal ouvert)
- **US5** (speed dial fermé + clavier + navigation): Dépend de US2 (speed dial)

```
Phase 1 (Setup) ─────────────────────────────────────────────┐
  │                                                          │
  ├─→ Phase 2 (Modal) ──────────────────────────┐            │
  │                                              │            │
  └─→ Phase 3 (US1: FAB) ──→ Phase 4 (US2: SD) ─┤            │
                                                  │            │
                                      ┌───────────┤            │
                                      ▼           ▼            │
                              Phase 5 (US3)   Phase 7 (US5)   │
                                  │                            │
                                  ▼                            │
                              Phase 6 (US4)                    │
                                  │                            │
                                  ▼                            │
                              Phase 8 (Polish) ◄───────────────┘
```

### Parallel Opportunities

**Phase 1** :
```
T002 (primitives) ──┐
                     ├── en parallèle (fichiers différents)
T003 (tokens)    ────┘
```

**Phase 2 + Phase 3** (partiellement parallélisables) :
```
Phase 2: T004 → T005 → T006 (Modal)
Phase 3: T007 → T008 → T009 (Fab) → T010 → T011 (Shell)
```
Les Phases 2 et 3 peuvent avancer en parallèle car elles touchent des fichiers différents. La jonction se fait en Phase 5 (US3) quand le Fab déclenche le Modal.

---

## Implementation Strategy

### MVP First (US1 Only)

1. Compléter Phase 1: Setup (T001-T003)
2. Compléter Phase 3: US1 — FAB visible (T007-T011)
3. **STOP et VALIDER**: Le FAB (+) est visible sur tous les écrans authentifiés
4. Livrable : bouton FAB positionné, cliquable (sans action)

### Incremental Delivery

1. Setup + US1 → FAB visible (MVP)
2. + Modal (Phase 2) + US2 → Speed dial fonctionnel
3. + US3 + US4 → Modals avec placeholder, cycle complet ouverture/fermeture
4. + US5 → Navigation clavier, fermeture automatique sur route
5. + Polish → Edge cases, lint, build

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label mappe chaque tâche à une user story pour la traçabilité
- Chaque user story est testable indépendamment après complétion
- Commiter après chaque phase ou groupe logique de tâches
- Pas de tests unitaires dans ce plan (non demandés dans la spec)
