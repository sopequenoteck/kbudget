# Tasks: Refonte UX formulaire Transaction

**Input**: Design documents from `/specs/019-form-ux-refonte/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: Non demandes dans la specification. Pas de taches de test generees.

**Organization**: Tasks groupees par user story. Chaque story est un increment testable independamment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependance)
- **[Story]**: User story associee (US1, US2, US3, US4)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Foundational — Slot header modal

**Purpose**: Ajouter le support de contenu projete dans le header du modal. Prerequis pour toutes les user stories.

- [x] T001 Ajouter `<ng-content select="[modal-header-actions]" />` entre le titre et le bouton fermer dans `app/src/app/shared/components/modal/modal.html`
- [x] T002 [P] Adapter le layout `.modal-header` (remplacer `justify-content: space-between` par `gap`, ajouter `margin-left: auto` sur `.modal-close`, `white-space: nowrap; overflow: hidden; text-overflow: ellipsis` sur `.modal-title`) dans `app/src/app/shared/components/modal/modal.scss`

**Checkpoint**: Le modal accepte du contenu projete dans le header. Les modals existants (sans contenu projete) restent visuellement identiques.

---

## Phase 2: User Story 1 — Saisie rapide d'une transaction (Priority: P1) MVP

**Goal**: Le formulaire de creation affiche le toggle Depense/Recette dans le header du modal et les champs en grille 2 colonnes. Saisie complete en 2-3 interactions.

**Independent Test**: Ouvrir FAB > Transaction. Verifier : toggle dans le header, champs en grille (libelle+montant, categorie+date, note), soumission fonctionnelle avec le type selectionne.

### Implementation

- [x] T003 [US1] Ajouter le signal `transactionType = signal(TransactionType.DEPENSE)` et le handler `onTransactionTypeChange(type)` dans `app/src/app/shared/components/shell/shell.ts` (importer `TransactionType`)
- [x] T004 [P] [US1] Ajouter les styles `.type-toggle` compact (font-size-xs, padding reduit, border-radius) pour le header modal dans `app/src/app/shared/components/shell/shell.scss`
- [x] T005 [US1] Ajouter le bloc `@if (modalService.activeModal() === 'transaction')` avec `<div modal-header-actions>` contenant le toggle Depense/Recette, et passer `[type]="transactionType()"` a `<app-transaction-form>` dans `app/src/app/shared/components/shell/shell.html`
- [x] T006 [P] [US1] Modifier `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` : ajouter `readonly type = input(TransactionType.DEPENSE)`, retirer `type` du FormGroup, retirer `readonly TransactionType = TransactionType`, utiliser `this.type()` dans `onSubmit()` au lieu de `raw.type`
- [x] T007 [US1] Modifier `app/src/app/features/transactions/components/transaction-form/transaction-form.html` : retirer le bloc `.type-toggle`, reorganiser les champs en `.form-row` (ligne 1: libelle+montant, ligne 2: categorie+date, ligne 3: note pleine largeur), fusionner `.form-actions` avec boutons Annuler + Enregistrer a droite
- [x] T008 [P] [US1] Modifier `app/src/app/features/transactions/components/transaction-form/transaction-form.scss` : ajouter `.form-row` avec `display: grid; grid-template-columns: 1fr 1fr; gap: var(--space-3)`, premiere ligne `7fr 3fr`, retirer le bloc `.type-toggle`

**Checkpoint**: Formulaire de creation fonctionnel en grille avec toggle dans le header. Type Depense par defaut, soumission correcte.

---

## Phase 3: User Story 2 — Edition d'une transaction existante (Priority: P2)

**Goal**: En mode edition, le toggle reflete le type existant. Le bouton Supprimer est dans la barre d'actions (clic direct, pas de confirmation).

**Independent Test**: Ouvrir une transaction existante de type Recette. Verifier : toggle sur Recette, bouton Supprimer a gauche des actions, suppression au clic direct.

### Implementation

- [x] T009 [US2] Ajouter un `effect()` dans `app/src/app/shared/components/shell/shell.ts` : quand `activeModal === 'transaction'`, synchroniser `transactionType` depuis `editingEntity.type` (edition) ou reset a DEPENSE (creation)
- [x] T010 [US2] Modifier `app/src/app/features/transactions/components/transaction-form/transaction-form.html` : dans `.form-actions`, ajouter un bouton Supprimer (`btn-danger`) a gauche avec `margin-right: auto` en mode edition, retirer la section `.delete-section` et le flow de confirmation
- [x] T011 [US2] Simplifier `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` : supprimer `showDeleteConfirm`, `onDelete()`, `onConfirmDelete()`, `onCancelDelete()` — remplacer par un `onDelete()` qui emit `deleted` directement, retirer le patch de `type` dans l'effect d'edition

**Checkpoint**: Edition fonctionnelle. Toggle sync, suppression directe, pas de regression sur la creation.

---

## Phase 4: User Story 3 — Adaptation mobile petit ecran (Priority: P3)

**Goal**: Sur viewport < 400px, les champs s'empilent en colonne unique.

**Independent Test**: Ouvrir DevTools, viewport 360px, ouvrir le formulaire transaction. Verifier : champs empiles verticalement.

### Implementation

- [x] T012 [US3] Ajouter le breakpoint `@media (max-width: 400px)` dans `app/src/app/features/transactions/components/transaction-form/transaction-form.scss` : `.form-row` passe en `grid-template-columns: 1fr`

**Checkpoint**: Le formulaire s'adapte correctement entre 320px et 1024px.

---

## Phase 5: Polish & Verification

**Purpose**: Verification non-regression (US4) et validation finale.

- [x] T013 Verifier la compilation (`ng build`) et les tests existants (`npx vitest run`) dans `app/`
- [x] T014 Verifier non-regression : ouvrir les formulaires abonnement, dette et categorie — aucun toggle dans le header, layout inchange (US4, FR-010)
- [x] T015 Executer la validation quickstart.md : creation, edition, responsive, non-regression, dropdown categorie non coupe dans la grille (EC-002)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dependance — commence immediatement
- **US1 (Phase 2)**: Depend de Phase 1 (modal slot requis pour projeter le toggle)
- **US2 (Phase 3)**: Depend de Phase 2 (le formulaire grille et le toggle doivent exister)
- **US3 (Phase 4)**: Depend de Phase 2 (le layout grille doit exister pour ajouter le breakpoint)
- **Polish (Phase 5)**: Depend de toutes les phases precedentes

### Within Each Phase

- T001 et T002 sont paralleles (html vs scss du modal)
- T003 doit preceder T005 (signal avant template)
- T004 est parallele a T003 (scss vs ts du shell)
- T006 et T008 sont paralleles a T003-T005 (fichiers differents : transaction-form vs shell)
- T007 depend de T006 (template depend du composant)
- T009 doit preceder T010-T011 (shell sync avant form changes)

### Parallel Opportunities

```text
Phase 1: T001 || T002
Phase 2: (T003 → T005) || T004 || (T006 → T007) || T008
Phase 3: T009 → (T010 || T011)
Phase 4: T012 (seul)
Phase 5: T013 → T014 → T015
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completer Phase 1 : Slot modal (T001-T002)
2. Completer Phase 2 : Toggle header + grille creation (T003-T008)
3. **STOP et VALIDER** : Tester la creation avec toggle et grille
4. Le formulaire de creation est deja utilisable

### Incremental Delivery

1. Phase 1 + Phase 2 → Creation fonctionnelle (MVP)
2. Phase 3 → Edition avec suppression directe
3. Phase 4 → Responsive petit ecran
4. Phase 5 → Validation finale et non-regression

---

## Notes

- 0 nouveau fichier : toutes les modifications portent sur des fichiers existants
- 8 fichiers modifies au total (3 composants : Modal, Shell, TransactionForm)
- Pas de changement backend
- Les taches [P] touchent des fichiers differents et peuvent etre executees en parallele
- Commiter apres chaque phase pour faciliter le rollback
