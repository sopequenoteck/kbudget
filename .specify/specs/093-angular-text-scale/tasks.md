# Tasks: Angular Text Scale

**Input**: Design documents from `/specs/093-angular-text-scale/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, quickstart.md

**Tests**: Non requis — les tests existants doivent passer sans modification.

**Organization**: Tasks groupées par user story.

## Format: `[ID] [P?] [Story] Description`

## Path Conventions

- **Services**: `app/src/app/core/services/`
- **Appearance**: `app/src/app/features/settings/components/appearance/`

---

## Phase 1: Foundational (Service TextScale)

**Purpose**: Créer le service qui gère la persistance et l'application du scale. Bloque les user stories.

- [x] T001 Créer le service `TextScaleService` dans `app/src/app/core/services/text-scale.ts` — Pattern identique à `ThemeService` : type `TextScale = 'small' | 'medium' | 'large'`, map `SCALE_FACTORS` (small: 0.85, medium: 1.0, large: 1.3), signal `currentTextScale` (défaut `'medium'`), méthode `setTextScale(scale)` qui met à jour le signal + `localStorage.setItem('budget_text_scale', scale)`, méthode privée `restoreTextScale()` appelée au constructeur qui lit `localStorage`, `effect()` dans le constructeur qui applique `document.documentElement.style.fontSize = SCALE_FACTORS[scale] * 100 + '%'`. Exposer aussi un computed `scaleFactor` qui retourne le nombre.

**Checkpoint**: Service injectable, scale appliqué au DOM via effect.

---

## Phase 2: User Story 1 — Sélecteur de taille dans Apparence (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur peut choisir Petit/Normal/Grand dans Paramètres > Apparence. Le choix est persisté et appliqué immédiatement.

**Independent Test**: Ouvrir `/settings/appearance`, changer la taille, vérifier que tous les textes changent. Recharger → réglage conservé.

### Implementation

- [x] T002 [US1] Injecter TextScaleService dans le composant Appearance dans `app/src/app/features/settings/components/appearance/appearance.ts` — Ajouter `private readonly textScaleService = inject(TextScaleService)`. Exposer `readonly currentTextScale = this.textScaleService.currentTextScale`. Ajouter méthode `setTextScale(scale: TextScale): void { this.textScaleService.setTextScale(scale); }`. Importer `TextScaleService` et `TextScale` depuis `'../../../../core/services/text-scale'`.
- [x] T003 [US1] Ajouter la section "Taille du texte" dans `app/src/app/features/settings/components/appearance/appearance.html` — Après la `</div>` de fermeture de `.theme-section`, ajouter une section identique : `<div class="theme-section">` avec `<h3>Taille du texte</h3>` et 3 boutons segmented control (Petit/Normal/Grand) utilisant le même pattern que le thème. Chaque bouton : `[class.segmented-control__option--active]="currentTextScale() === 'small'"` + `(click)="setTextScale('small')"` (idem pour medium/large).
- [x] T004 [US1] Ajouter les styles de la section taille dans `app/src/app/features/settings/components/appearance/appearance.scss` — Aucun nouveau style requis si les classes `.theme-section`, `.segmented-control`, `.segmented-control__option` sont déjà globales ou dans le SCSS existant. Vérifier et ajuster si nécessaire.

**Checkpoint**: Sélecteur fonctionnel, scale appliqué, persisté.

---

## Phase 3: User Story 2 — Aperçu en temps réel (Priority: P2)

**Goal**: Un texte d'aperçu sous le sélecteur montre l'effet de la taille choisie.

**Independent Test**: Changer la taille et vérifier que le texte d'aperçu change immédiatement.

### Implementation

- [x] T005 [US2] Ajouter le bloc aperçu dans `app/src/app/features/settings/components/appearance/appearance.html` — Après le segmented control de la taille, ajouter : `<div class="text-preview" [style.fontSize.%]="textScaleService.scaleFactor() * 100">Voici un aperçu de la taille du texte choisie.</div>`.
- [x] T006 [US2] Ajouter le style du preview dans `app/src/app/features/settings/components/appearance/appearance.scss` — Classe `.text-preview` : `margin-top: var(--space-3)`, `padding: var(--space-4)`, `background-color: var(--surface-default)`, `border-radius: var(--radius-lg)`, `color: var(--text-primary)`, `line-height: var(--line-height-normal)`, `transition: font-size var(--duration-normal) var(--easing-default)`.

**Checkpoint**: Aperçu dynamique fonctionnel.

---

## Phase 4: Polish & Cross-Cutting Concerns

- [ ] T007 Vérification visuelle — Ouvrir `/settings/appearance`, tester les 3 options, vérifier le scale sur tout le dashboard. Vérifier que les icônes ne changent pas de taille.
- [ ] T008 Vérification persistance — Sélectionner "Grand", recharger la page, vérifier que "Grand" est toujours actif.
- [x] T009 Exécuter les tests existants via `cd app && npx vitest run` — Vérifier que tous les tests passent sans modification.
- [ ] T010 Validation quickstart — Suivre `specs/093-angular-text-scale/quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)** : Pas de dépendances — démarrer immédiatement.
- **Phase 2 (US1)** : Dépend de Phase 1 (T001 requis).
- **Phase 3 (US2)** : Dépend de Phase 2 (sélecteur requis pour le preview).
- **Phase 4 (Polish)** : Dépend de toutes les phases.

### Parallel Opportunities

- T005 + T006 parallélisables (HTML vs SCSS)

---

## Implementation Strategy

### MVP First (User Story 1)

1. T001 : TextScaleService
2. T002 + T003 + T004 : Sélecteur dans Apparence
3. **STOP et VALIDER** : scale fonctionne, persisté

### Incremental Delivery

1. Service TextScale → Foundation
2. US1 Sélecteur → MVP
3. US2 Aperçu → Finition
4. Polish → Validation

---

## Notes

- Pattern identique à ThemeService (signal + localStorage + effect)
- Le scale via `html { font-size: X% }` affecte tous les `rem` automatiquement
- Les icônes en `px` ne sont pas affectées (FR-008)
- Le `textScaleService` doit être `public` dans le composant pour le binding template `[style.fontSize.%]`
