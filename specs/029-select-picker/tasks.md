# Tasks: SelectPicker generique

**Input**: Design documents from `/specs/029-select-picker/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus en phase Polish (tests unitaires mentionnes dans le plan).

**Organization**: Tasks groupees par user story. Le composant generique SelectPicker est cree en phase Foundational car il bloque les 3 user stories.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story concernee (US1, US2, US3)
- Chemins exacts dans chaque description

## Path Conventions

- **Frontend**: `app/src/app/` (Angular PWA)
- **Shared components**: `app/src/app/shared/components/`
- **Feature components**: `app/src/app/features/[module]/components/`

---

## Phase 1: Setup

**Purpose**: Definition de l'interface de donnees du composant

- [x] T001 Create SelectPickerItem interface with id (string), label (string), icon (string | null), secondaryText (string | null), color (string | null) in `app/src/app/shared/components/select-picker/select-picker.model.ts`

---

## Phase 2: Foundational - SelectPicker Core Component

**Purpose**: Composant generique complet qui bloque TOUTES les user stories. Inclut ControlValueAccessor, recherche, responsive bottom-sheet, navigation clavier et click-outside (extraits du CategoryPicker existant).

**CRITICAL**: Aucun travail sur les user stories ne peut commencer avant la fin de cette phase.

- [x] T002 Create SelectPicker component with ControlValueAccessor pattern (writeValue, registerOnChange, registerOnTouched, setDisabledState), internal signals (isOpen, selectedId, searchTerm, disabled, highlightedIndex, dropAbove), computed selectedItem and filteredItems, open/close toggle, selectItem/clearSelection methods, search filtering with searchThreshold (default 5) and searchable override, showSearch computed, keyboard navigation (Enter/Space to open, ArrowDown/ArrowUp cyclic, Enter to select highlighted, Escape to close), HostListener click-outside detection, dropdown position flip via getBoundingClientRect, and an effect() that watches items() changes and clears the selection (selectedId → '', call onChange('')) if the currently selected id is no longer present in the items list (edge case EC-2: item selectionne supprime) in `app/src/app/shared/components/select-picker/select-picker.ts`. Inputs: items (SelectPickerItem[]), placeholder (string), searchable (boolean | null), searchThreshold (number), searchPlaceholder (string), clearable (boolean), emptyMessage (string). Outputs: opened (void), closed (void), searchTermChange (string — emits current search term on each input, needed by CategoryPicker wrapper for no-match detection). Reference: existing CategoryPicker pattern in `app/src/app/shared/components/category-picker/category-picker.ts` for CVA + signals + keyboard implementation.

- [x] T003 Create SelectPicker template with: (1) trigger area showing selected item (icon + label + secondaryText + color indicator) or placeholder text, with clear button if clearable and item selected, (2) dropdown panel (desktop >=768px) positioned absolute below trigger (or above if dropAbove signal), containing optional search input and scrollable item list with icon/label/secondaryText/color rendering per item, empty message when no items, (3) bottom-sheet overlay (mobile <768px) with backdrop, title area, optional search input, and item list. Use @if for open state, @for for items with track by id. Add role="listbox" on item container, role="option" on items, aria-selected, aria-expanded on trigger, tabindex="0" on trigger, (keydown) handler on component. Reference: existing CategoryPicker template in `app/src/app/shared/components/category-picker/category-picker.html` and Modal bottom-sheet pattern in `app/src/app/shared/components/modal/modal.scss` for responsive approach in `app/src/app/shared/components/select-picker/select-picker.html`

- [x] T004 Create SelectPicker styles using only CSS custom properties (var(--token)): (1) trigger with border, border-radius(--radius-xl), padding, hover/focus states matching category-picker__selected, (2) dropdown absolute positioned with max-height 14rem, overflow-y auto, shadow(--shadow-lg), z-index(--z-dropdown), border-radius(--radius-xl), surface-raised background, (3) items with icon+label+secondaryText layout, hover/highlighted(--bg-tertiary) states, (4) search input inside dropdown, (5) clear button matching category-picker__clear, (6) disabled state (opacity 0.6, pointer-events none), (7) color indicator (small dot/swatch for account color), (8) empty message centered, (9) bottom-sheet mode via @media(max-width: 767px): fixed overlay with backdrop(--surface-overlay), panel anchored bottom with slide-up animation, border-radius top only, (10) dropdown-above modifier for desktop flip. Reference: existing category-picker.scss and modal.scss for token usage and responsive patterns in `app/src/app/shared/components/select-picker/select-picker.scss`

**Checkpoint**: SelectPicker generique fonctionnel — migration des formulaires possible.

---

## Phase 3: User Story 1 - Selection de compte uniforme (Priority: P1) MVP

**Goal**: L'utilisateur selectionne un compte bancaire de maniere identique dans tous les formulaires (virement, transaction, abonnement) via le SelectPicker custom au lieu de select natifs ou chips.

**Independent Test**: Ouvrir le formulaire de virement, cliquer sur le selecteur de compte source → dropdown custom avec icone, nom et solde. Verifier comportement identique sur Chrome et Safari.

### Implementation for User Story 1

- [x] T005 [P] [US1] In transfer-form: add SelectPicker import, add accountItems computed signal transforming activeAccounts() to SelectPickerItem[] (id, label=nom, icon=icone, secondaryText=`solde €`, color=couleur), replace both native `<select formControlName="fromAccountId/toAccountId">` with `<app-select-picker formControlName="fromAccountId/toAccountId" [items]="accountItems()" placeholder="Compte source/destination" [clearable]="false" />` wrapped in existing app-form-field, remove getAccountName/getAccountIcon/getAccountSolde helper methods, remove DecimalPipe import in `app/src/app/shared/components/transfer-form/transfer-form.ts` and `app/src/app/shared/components/transfer-form/transfer-form.html`

- [x] T006 [P] [US1] In transaction-form: replace AccountPicker import with SelectPicker, add accountItems computed signal transforming activeAccounts() to SelectPickerItem[], replace `<app-account-picker>` block with `<app-form-field label="Compte" fieldId="accountId"><app-select-picker formControlName="accountId" [items]="accountItems()" placeholder="Selectionner un compte" [clearable]="!isEditMode() || !!form.get('accountId')?.value" /></app-form-field>` inside the @if(hasAccounts()) block, remove onAccountSelected method in `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` and `app/src/app/features/transactions/components/transaction-form/transaction-form.html`

- [x] T007 [P] [US1] In subscription-form: replace AccountPicker import with SelectPicker, add accountItems computed signal transforming activeAccounts() to SelectPickerItem[], replace `<app-account-picker>` block with `<app-form-field label="Compte (optionnel)" fieldId="accountId"><app-select-picker formControlName="accountId" [items]="accountItems()" placeholder="Aucun compte" [clearable]="true" /></app-form-field>` inside the @if block, remove onAccountSelected method in `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts` and `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html`

- [x] T008 [US1] Delete AccountPicker component files: `app/src/app/shared/components/account-picker/account-picker.ts`, `account-picker.html`, `account-picker.scss`, `account-picker.spec.ts`. Verify no remaining imports via grep for 'account-picker' across the codebase.

**Checkpoint**: Tous les formulaires utilisent SelectPicker pour la selection de compte. AccountPicker supprime. Tester virement, transaction et abonnement sur Chrome et Safari.

---

## Phase 4: User Story 2 - Selection de categorie avec recherche et creation inline (Priority: P2)

**Goal**: Le CategoryPicker est refactore en thin wrapper autour du SelectPicker. La recherche, la selection et la creation inline de categories sont preservees sans regression.

**Independent Test**: Ouvrir le formulaire de transaction, cliquer sur le selecteur de categorie → recherche active, filtrer par texte, creer une nouvelle categorie quand aucun match, verifier que la selection fonctionne comme avant.

### Implementation for User Story 2

- [x] T009 [US2] Refactor CategoryPicker component: replace inline dropdown/search/keyboard logic with SelectPicker delegation. Keep CategoryService injection, refreshTrigger, allCategories signal. Add categoryItems computed transforming Category[] to SelectPickerItem[] (id, label=nom, icon=icone, secondaryText=null, color=null). Add searchTerm tracking (via viewChild on SelectPicker or new searchTermChange output on SelectPicker). Compute hasExactMatch from searchTerm and categories. Keep showCreateModal signal, openCreateModal/onCategorySaved/onCreateCancelled methods. Remove: filteredCategories, highlightedIndex, isOpen, onInput, onFocus, onKeydown, selectCategory (replaced by CVA delegation), HostListener click-outside. SelectPicker configured with searchable=true, clearable=true in `app/src/app/shared/components/category-picker/category-picker.ts`

- [x] T010 [US2] Simplify CategoryPicker template: replace the entire inline dropdown structure (input, dropdown, options loop, empty message) with single `<app-select-picker [items]="categoryItems()" [searchable]="true" [clearable]="true" searchPlaceholder="Rechercher une categorie..." emptyMessage="Aucune categorie" />` that delegates to the internal CVA. Add "Creer [searchTerm]" button below or alongside SelectPicker visible when !hasExactMatch() && searchTerm(). Keep `<app-modal>` block for category creation unchanged. The CategoryPicker itself remains a ControlValueAccessor wrapping SelectPicker in `app/src/app/shared/components/category-picker/category-picker.html`

- [x] T011 [US2] Simplify CategoryPicker styles: remove __input, __dropdown, __option, __option-emoji, __option-name, __empty, __selected, __emoji, __name CSS blocks (now handled by SelectPicker styles). Keep only __create button style and disabled state. Adjust spacing if needed to align create button with SelectPicker dropdown in `app/src/app/shared/components/category-picker/category-picker.scss`

**Checkpoint**: CategoryPicker fonctionne comme avant (recherche, creation, selection, suppression) mais delegue au SelectPicker. Tester dans transaction-form et subscription-form.

---

## Phase 5: User Story 3 - Navigation clavier et accessibilite (Priority: P3)

**Goal**: Le SelectPicker est entierement navigable au clavier et conforme aux standards d'accessibilite ARIA.

**Independent Test**: Naviguer dans n'importe quel formulaire uniquement au clavier (Tab pour focus, Enter pour ouvrir, fleches pour naviguer, Enter pour selectionner, Escape pour fermer). Verifier avec un lecteur d'ecran.

### Implementation for User Story 3

- [x] T012 [US3] Enhance ARIA attributes in SelectPicker template: add aria-haspopup="listbox" on trigger, ensure aria-expanded reflects isOpen state, add aria-activedescendant pointing to highlighted item id on trigger, add unique id on each option (e.g. `select-picker-option-{{item.id}}`), add aria-label on search input, add aria-live="polite" on results count for screen readers in `app/src/app/shared/components/select-picker/select-picker.html`

- [x] T013 [US3] Add CdkTrapFocus on bottom-sheet panel to trap focus within bottom-sheet on mobile, ensure focus moves to search input (or first item) when dropdown opens, return focus to trigger when dropdown closes in `app/src/app/shared/components/select-picker/select-picker.ts` and `select-picker.html`. Import CdkTrapFocus from @angular/cdk/a11y.

**Checkpoint**: Selection entierement navigable au clavier. ARIA attributes presents. Focus piege dans le bottom-sheet mobile.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tests, verification, nettoyage

- [x] T014 [P] Write unit tests for SelectPicker: test ControlValueAccessor (writeValue, onChange, onTouched, setDisabledState), test open/close toggle, test item selection emits correct id, test clear selection emits empty string, test search filtering with threshold, test searchable override, test keyboard navigation (ArrowDown cycles, Enter selects, Escape closes), test empty list shows emptyMessage, test disabled state prevents interaction. Use TestBed + fixture.componentRef.setInput() pattern. Mock items with 3+ SelectPickerItem objects in `app/src/app/shared/components/select-picker/select-picker.spec.ts`

- [x] T015 [P] Update CategoryPicker tests: verify wrapper delegates to SelectPicker, test that selecting an item emits via CVA, test search triggers SelectPicker filtering, test "Creer" button appears when no exact match, test category creation flow (open modal → save → select created category), test clearSelection. Adapt existing test structure in `app/src/app/shared/components/category-picker/category-picker.spec.ts`

- [x] T016 Run quickstart.md validation: verify all 4 usage scenarios from quickstart.md (basic account selection, category with search, transfer form dual select, optional account in subscription). Check no lint errors with `cd app && npx ng lint`. Verify build passes with `cd app && npx ng build`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dependance — demarrage immediat
- **Foundational (Phase 2)**: Depend de Phase 1 (T001) — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Depend de Phase 2 — T005/T006/T007 parallelisables, T008 apres T005-T007
- **US2 (Phase 4)**: Depend de Phase 2 — Peut demarrer en parallele de US1
- **US3 (Phase 5)**: Depend de Phase 2 — Peut demarrer en parallele de US1/US2
- **Polish (Phase 6)**: Depend de toutes les user stories completees

### User Story Dependencies

- **User Story 1 (P1)**: Depend de Phase 2. Independante de US2 et US3.
- **User Story 2 (P2)**: Depend de Phase 2. Independante de US1 et US3. Utilise l'output searchTermChange du SelectPicker (inclus dans T002) pour la detection no-match.
- **User Story 3 (P3)**: Depend de Phase 2. Independante de US1 et US2. Enrichit le composant existant.

### Within Each User Story

- Models/interfaces avant services
- Fichiers TS avant HTML avant SCSS
- Migration formulaire par formulaire
- Suppression de l'ancien composant en dernier

### Parallel Opportunities

- **Phase 3**: T005, T006, T007 en parallele (fichiers differents: transfer-form, transaction-form, subscription-form)
- **Phase 4**: T009 → T010 → T011 sequentiels (meme composant)
- **Phase 5**: T012 et T013 sequentiels (meme composant, T013 depend de T012 pour les ids ARIA)
- **Phase 6**: T014 et T015 en parallele (fichiers de test differents)
- **Cross-story**: US1, US2 et US3 peuvent theoriquement avancer en parallele apres Phase 2

---

## Parallel Example: User Story 1

```bash
# Les 3 migrations de formulaires en parallele (fichiers differents):
Task: "T005 - Replace native <select> with SelectPicker in transfer-form"
Task: "T006 - Replace AccountPicker with SelectPicker in transaction-form"
Task: "T007 - Replace AccountPicker with SelectPicker in subscription-form"

# Puis suppression apres completion des 3:
Task: "T008 - Delete AccountPicker component files"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002-T004) — SelectPicker fonctionnel
3. Complete Phase 3: User Story 1 (T005-T008) — Comptes uniformes partout
4. **STOP and VALIDATE**: Tester selection de compte dans virement, transaction et abonnement
5. Deploy/demo si satisfaisant

### Incremental Delivery

1. Setup + Foundational → SelectPicker pret
2. US1 → Comptes uniformes → Test → Deploy (MVP!)
3. US2 → Categories refactorees → Test → Deploy
4. US3 → Accessibilite complete → Test → Deploy
5. Polish → Tests + validation → Deploy final

### Sequential Strategy (Recommande pour single developer)

1. Phase 1 + 2: Creer le composant generique (T001-T004)
2. Phase 3: Migrer tous les comptes (T005-T008) — Valider MVP
3. Phase 4: Refactorer CategoryPicker (T009-T011) — Valider regression
4. Phase 5: Accessibilite (T012-T013) — Valider clavier + ARIA
5. Phase 6: Tests + validation finale (T014-T016)

---

## Notes

- [P] tasks = fichiers differents, pas de dependances
- [Story] label = tracabilite vers la user story de spec.md
- Le SelectPicker inclut la navigation clavier des Phase 2 (extraite du CategoryPicker existant) — US3 ajoute les attributs ARIA et le focus management
- La suppression de AccountPicker (T008) doit etre faite APRES la migration de tous les formulaires
- Le CategoryPicker wrapper (US2) utilise l'output searchTermChange du SelectPicker (ajoute dans T002) pour detecter le no-match et afficher le bouton "Creer"
- Le debt-form n'est PAS modifie (utilise CategoryPicker via formControlName, pas d'AccountPicker)
- Commit apres chaque phase ou groupe logique de tasks
