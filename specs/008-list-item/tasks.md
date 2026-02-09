# Tasks: Composant ListItem réutilisable

**Input**: Design documents from `/specs/008-list-item/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: Inclus — la stratégie de tests est définie dans le plan (12 tests unitaires Vitest).

**Organization**: Tasks groupées par user story. Chaque story est indépendamment testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécutée en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3)
- Chemins de fichiers exacts inclus

## Path Conventions

- **Frontend**: `app/src/app/shared/components/list-item/`
- **Tests**: `app/src/app/shared/components/list-item/list-item.spec.ts`

---

## Phase 1: Setup

**Purpose**: Création de la structure du composant et configuration

- [x] T001 Créer le dossier et les fichiers du composant : `app/src/app/shared/components/list-item/list-item.ts`, `list-item.html`, `list-item.scss`
- [x] T002 Implémenter la classe du composant avec les 6 inputs (icon, title, value requis ; subtitle, rightSubtitle, valueClass optionnels) et le output (pressed) dans `app/src/app/shared/components/list-item/list-item.ts`

---

## Phase 2: User Story 1 - Afficher un élément de liste (Priority: P1) — MVP

**Goal**: Le composant affiche une icône, un titre, un sous-titre optionnel, et une valeur alignée à droite avec layout flexbox responsive.

**Independent Test**: Intégrer le composant avec des données statiques et vérifier que toutes les informations s'affichent correctement aux bons emplacements.

### Tests for User Story 1

- [x] T003 [US1] Écrire le test `should render icon, title, and value` (FR-001, FR-002, FR-003) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T004 [US1] Écrire le test `should render subtitle when provided` (FR-004) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T005 [US1] Écrire le test `should not render subtitle when empty` (FR-004 edge) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T006 [US1] Écrire le test `should render right subtitle when provided` (FR-005) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T007 [US1] Écrire le test `should not render right subtitle when empty` (FR-005 edge) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T008 [US1] Écrire le test `should truncate long title with ellipsis` (FR-010 edge) dans `app/src/app/shared/components/list-item/list-item.spec.ts`

### Implementation for User Story 1

- [x] T009 [US1] Implémenter le template HTML avec layout flexbox 3 zones (icône, contenu, valeur droite) et rendu conditionnel @if pour sous-titres dans `app/src/app/shared/components/list-item/list-item.html`
- [x] T010 [US1] Implémenter les styles SCSS : layout flexbox, spacing tokens, typographie, ellipsis sur le titre, bordure séparatrice dans `app/src/app/shared/components/list-item/list-item.scss`
- [x] T011 [US1] Vérifier que les tests T003-T008 passent en exécutant `cd app && npx vitest run --reporter=verbose`

**Checkpoint**: Le composant affiche correctement icône + titre + sous-titre + valeur avec layout responsive et ellipsis.

---

## Phase 3: User Story 2 - Interagir avec un élément de liste (Priority: P2)

**Goal**: Le composant émet un signal void au clic, au Enter et au Space, avec retour visuel au hover et au focus clavier.

**Independent Test**: Cliquer sur un ListItem et vérifier qu'un événement est émis. Naviguer au clavier avec Tab et vérifier le focus visuel.

### Tests for User Story 2

- [x] T012 [US2] Écrire le test `should emit pressed on click` (FR-007) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T013 [US2] Écrire le test `should emit pressed on Enter key` (FR-007 a11y) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T014 [US2] Écrire le test `should emit pressed on Space key` (FR-007 a11y) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T015 [US2] Écrire le test `should have role="button" and tabindex="0"` (FR-008 a11y) dans `app/src/app/shared/components/list-item/list-item.spec.ts`

### Implementation for User Story 2

- [x] T016 [US2] Ajouter les attributs `role="button"` et `tabindex="0"` + handlers `(click)` et `(keydown)` dans le template `app/src/app/shared/components/list-item/list-item.html`
- [x] T017 [US2] Implémenter les méthodes `onPress()` et `onKeydown()` (Enter + Space) dans `app/src/app/shared/components/list-item/list-item.ts`
- [x] T018 [US2] Ajouter les styles hover (`--hover-bg`), focus-visible (outline `--color-primary`), active et cursor pointer dans `app/src/app/shared/components/list-item/list-item.scss`
- [x] T019 [US2] Vérifier que les tests T012-T015 passent en exécutant `cd app && npx vitest run --reporter=verbose`

**Checkpoint**: Le composant est cliquable, navigable au clavier, et affiche un retour visuel au hover/focus.

---

## Phase 4: User Story 3 - Différencier visuellement les types (Priority: P3)

**Goal**: Le composant accepte une classe CSS optionnelle sur la valeur pour permettre la différenciation visuelle (revenu/dépense/dette).

**Independent Test**: Passer différentes classes CSS (`.amount-income`, `.amount-expense`) et vérifier que les couleurs s'appliquent sur la valeur.

### Tests for User Story 3

- [x] T020 [US3] Écrire le test `should apply valueClass to value element` (FR-006) dans `app/src/app/shared/components/list-item/list-item.spec.ts`
- [x] T021 [US3] Écrire le test `should not apply class when valueClass empty` (FR-006 edge) dans `app/src/app/shared/components/list-item/list-item.spec.ts`

### Implementation for User Story 3

- [x] T022 [US3] Ajouter le binding `[class]="valueClass()"` sur l'élément `.list-item__value` dans `app/src/app/shared/components/list-item/list-item.html`
- [x] T023 [US3] Vérifier que les tests T020-T021 passent en exécutant `cd app && npx vitest run --reporter=verbose`

**Checkpoint**: La valeur monétaire accepte une classe CSS externe pour la coloration conditionnelle.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et vérifications transverses

- [x] T024 Exécuter la suite complète de tests (12 tests) : `cd app && npx vitest run --reporter=verbose`
- [x] T025 Vérifier le lint : `cd app && ng lint`
- [x] T026 Vérifier le formatage : `cd app && npm run format:check`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dépendance — démarrage immédiat
- **Phase 2 (US1)**: Dépend de Phase 1 (T001, T002)
- **Phase 3 (US2)**: Dépend de Phase 2 (template et SCSS existants)
- **Phase 4 (US3)**: Dépend de Phase 2 (template existant)
- **Phase 5 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Aucune dépendance inter-story — MVP standalone
- **US2 (P2)**: Modifie le template et SCSS créés par US1 — exécuter après US1
- **US3 (P3)**: Modifie le template créé par US1 — peut être parallélisé avec US2 si merge soigneux, sinon exécuter après US2

### Within Each User Story

- Tests écrits AVANT l'implémentation (TDD)
- Tests doivent ÉCHOUER avant implémentation
- Implémentation jusqu'à ce que les tests passent
- Checkpoint de validation à chaque fin de story

### Parallel Opportunities

- **Phase 2**: T009 (HTML) et T010 (SCSS) peuvent être écrits en parallèle (fichiers différents)
- **Cross-story**: US3 (Phase 4) peut potentiellement être parallélisée avec US2 (Phase 3) car elles modifient des aspects différents du template
- **Note**: Les tests de chaque story sont séquentiels (même fichier `list-item.spec.ts`)

---

## Parallel Example: User Story 1

```bash
# Tests US1 séquentiels (même fichier) :
Task: T003 → T004 → T005 → T006 → T007 → T008

# Implémentation en parallèle (fichiers différents) :
Task: "Template HTML" (T009) | "Styles SCSS" (T010)

# Validation :
Task: "Vérification tests" (T011)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001-T002)
2. Compléter Phase 2: US1 tests + implémentation (T003-T011)
3. **STOP et VALIDER** : Le composant affiche les données correctement
4. Commit possible à ce stade

### Incremental Delivery

1. Setup → US1 → Composant affiche les données (MVP)
2. + US2 → Composant est interactif (cliquable, a11y clavier)
3. + US3 → Composant supporte la coloration conditionnelle
4. Polish → Lint, formatage, suite complète de tests
5. Chaque story ajoute de la valeur sans casser les précédentes

---

## Notes

- Tous les tests sont dans un seul fichier `list-item.spec.ts` (convention projet)
- Les 3 fichiers source (.ts, .html, .scss) sont dans le même dossier `list-item/`
- Utiliser `BrowserTestingModule` et `platformBrowserTesting` (Angular 21, pas les `Dynamic` dépréciés)
- Appeler `getTestBed().initTestEnvironment()` directement dans le fichier spec
- Utiliser `vi.fn()` au lieu de `() => {}` pour éviter les erreurs ESLint
- Commit après chaque checkpoint de phase
