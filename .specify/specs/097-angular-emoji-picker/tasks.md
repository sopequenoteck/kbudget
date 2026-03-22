# Tasks: Angular Emoji Picker

**Input**: Design documents from `/specs/097-angular-emoji-picker/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Inclus (FR-010 dans la spec demande explicitement des tests unitaires).

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Installation des dépendances et configuration initiale

- [x] T001 Installer `emoji-mart` et `@emoji-mart/data` via npm dans `app/`
- [x] T002 Ajouter `CUSTOM_ELEMENTS_SCHEMA` au composant `EmojiInput` dans `app/src/app/shared/components/emoji-input/emoji-input.ts`

**Checkpoint**: Les packages sont installés et le schema custom element est configuré.

---

## Phase 2: User Story 1 - Sélectionner un emoji via le picker (Priority: P1) — MVP

**Goal**: Remplacer l'input texte par une trigger box 48×48 + popover CDK Overlay contenant le picker emoji-mart avec catégories et recherche en français.

**Independent Test**: Ouvrir le formulaire catégorie, cliquer sur la box → picker s'ouvre avec catégories et recherche. Cliquer un emoji → picker se ferme, emoji affiché dans la box.

### Implementation for User Story 1

- [x] T003 [US1] Refactorer `emoji-input.ts` : remplacer l'input texte par un signal `isOpen`, importer CDK Overlay (`CdkOverlayOrigin`, `CdkConnectedOverlay`), initialiser emoji-mart une seule fois via `init({ data })` (cf. research.md R3) avec la locale française, écouter l'événement `emoji-select` pour émettre `valueChange` et fermer le picker dans `app/src/app/shared/components/emoji-input/emoji-input.ts`
- [x] T004 [US1] Refactorer `emoji-input.html` : trigger box (div cliquable 48×48, affichant `value()` ou placeholder "...") + `CdkConnectedOverlay` contenant `<em-emoji-picker>` avec binding locale et catégories dans `app/src/app/shared/components/emoji-input/emoji-input.html`
- [x] T005 [US1] Refactorer `emoji-input.scss` : styles trigger box (48×48, border, radius, cursor pointer, focus ring) + styles du popover overlay + surcharges CSS emoji-mart pour intégration design tokens dans `app/src/app/shared/components/emoji-input/emoji-input.scss`

**Checkpoint**: Le picker s'ouvre au clic, affiche les emojis par catégorie avec recherche en français, la sélection émet la valeur et ferme le popover.

---

## Phase 3: User Story 2 - Emojis récents (Priority: P2)

**Goal**: La section "Récents" s'affiche en première position du picker avec les emojis précédemment sélectionnés.

**Independent Test**: Sélectionner 3 emojis dans des formulaires successifs, rouvrir le picker → section "Récents" visible en premier.

### Implementation for User Story 2

- [x] T006 [US2] Vérifier que emoji-mart affiche la catégorie "frequent" en première position par défaut ; si ce n'est pas le cas, configurer l'ordre des catégories explicitement. Vérifier que le stockage des récents (localStorage interne emoji-mart) fonctionne dans `app/src/app/shared/components/emoji-input/emoji-input.ts`

**Checkpoint**: Les emojis récents apparaissent en première position. Première utilisation sans récents → première catégorie standard affichée.

---

## Phase 4: User Story 3 - Thème dark/light (Priority: P2)

**Goal**: Le picker s'adapte automatiquement au thème actif (light/dark) de l'application.

**Independent Test**: Basculer entre light et dark → le picker adapte ses couleurs.

### Implementation for User Story 3

- [x] T007 [US3] Détecter la classe `.theme-dark` sur le document au moment de l'ouverture du picker (lecture ponctuelle via `document.body.classList.contains('theme-dark')`, pas de MutationObserver) et passer `theme="dark"` ou `theme="light"` au `<em-emoji-picker>` dans `app/src/app/shared/components/emoji-input/emoji-input.ts`
- [x] T008 [US3] Ajouter les surcharges CSS pour harmoniser le picker emoji-mart avec les design tokens du projet (bordures, radius, ombres) en light et dark dans `app/src/app/shared/components/emoji-input/emoji-input.scss`

**Checkpoint**: En mode light → picker fond clair. En mode dark → picker fond sombre, cohérent avec le design system.

---

## Phase 5: User Story 4 - Fermeture du picker (Priority: P3)

**Goal**: Le picker se ferme sans changement au clic extérieur ou à la touche Escape.

**Independent Test**: Ouvrir le picker, cliquer à l'extérieur ou appuyer Escape → picker fermé, valeur inchangée.

### Implementation for User Story 4

- [x] T009 [US4] Configurer le CDK Overlay avec `hasBackdrop` (transparent) pour fermeture au clic extérieur et écouter le `keydown.escape` pour fermeture clavier dans `app/src/app/shared/components/emoji-input/emoji-input.ts` et `app/src/app/shared/components/emoji-input/emoji-input.html`. Note : le CDK Overlay gère aussi le repositionnement au redimensionnement et la destruction automatique à la navigation (edge cases spec).

**Checkpoint**: Clic extérieur et Escape ferment le picker sans modifier la valeur.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tests, vérification intégration et validation finale

- [x] T010 [P] Créer les tests unitaires du composant `EmojiInput` (ouverture picker, sélection emoji + vérification émission `valueChange` avec la valeur native, fermeture clic extérieur sans émission, fermeture Escape sans émission, thème dark/light, compatibilité API `value`/`valueChange` pour intégration formulaires) dans `app/src/app/shared/components/emoji-input/emoji-input.spec.ts`
- [x] T011 [P] Vérifier le fonctionnement dans le formulaire catégorie (`app/src/app/shared/components/category-form/category-form.html`) — aucune modification attendue grâce à l'API inchangée
- [x] T012 [P] Vérifier le fonctionnement dans le formulaire compte (`app/src/app/shared/components/account-form/account-form.html`) — aucune modification attendue grâce à l'API inchangée
- [ ] T013 Exécuter la validation quickstart.md (10 étapes de vérification manuelle)
- [x] T014 Lancer `ng lint` et `npm run format` pour vérifier conformité dans `app/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — démarrage immédiat
- **US1 (Phase 2)**: Dépend de Phase 1 (packages installés + schema configuré)
- **US2 (Phase 3)**: Dépend de Phase 2 (picker fonctionnel pour tester les récents)
- **US3 (Phase 4)**: Dépend de Phase 2 (picker fonctionnel pour appliquer le thème)
- **US4 (Phase 5)**: Dépend de Phase 2 (picker fonctionnel pour tester la fermeture)
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Bloquant — toutes les autres stories dépendent du picker fonctionnel
- **US2 (P2)**: Peut démarrer après US1 — indépendant de US3/US4
- **US3 (P2)**: Peut démarrer après US1 — indépendant de US2/US4
- **US4 (P3)**: Peut démarrer après US1 — indépendant de US2/US3

### Parallel Opportunities

- T003, T004, T005 modifient le même composant mais des fichiers différents → [P] non applicable (cohérence requise)
- T006, T007, T008 concernent des aspects distincts → peuvent être parallélisés après US1
- T010, T011, T012 sont indépendants → parallélisables

---

## Parallel Example: Post-US1

```bash
# Après US1 complétée, lancer en parallèle :
Task T006: "Configurer emojis récents dans emoji-input.ts"
Task T007: "Détecter thème dark/light dans emoji-input.ts"
Task T009: "Configurer fermeture CDK Overlay dans emoji-input.ts"

# Attention : T006, T007, T009 modifient le même fichier .ts
# En pratique, les exécuter séquentiellement pour éviter les conflits
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: US1 - Core picker (T003-T005)
3. **STOP and VALIDATE**: Tester la sélection d'emoji via le picker
4. Le picker est fonctionnel — les récents, thème et fermeture sont des améliorations

### Incremental Delivery

1. Setup → Packages installés
2. US1 → Picker fonctionnel (MVP)
3. US2 → Récents activés
4. US3 → Thème dark/light
5. US4 → Fermeture propre (clic extérieur, Escape)
6. Polish → Tests + validation cross-formulaires

---

## Notes

- Tous les fichiers modifiés sont dans `app/src/app/shared/components/emoji-input/`
- L'API publique (`value` input / `valueChange` output) ne change PAS — zéro modification dans les formulaires consommateurs
- emoji-mart gère les récents en interne (localStorage) — pas de code custom
- Le CDK Overlay est déjà en dépendance du projet — pas de nouvelle dépendance Angular
- Commit recommandé après chaque phase complétée
