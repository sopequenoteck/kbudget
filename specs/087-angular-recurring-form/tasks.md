# Tasks: Formulaire de création et conversion de transactions récurrentes (Angular)

**Input**: Design documents from `/specs/087-angular-recurring-form/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2)

---

## Phase 1: Setup

**Purpose**: Modèle et service — prérequis partagés par les deux user stories

- [x] T001 [P] Ajouter l'interface `RecurringTransactionRequest` dans `app/src/app/core/models/recurring-transaction.model.ts`
- [x] T002 [P] Ajouter la méthode `create(request: RecurringTransactionRequest)` dans `app/src/app/core/services/recurring-transaction.ts` — POST /transactions/recurring, retourne `Observable<RecurringTransactionResponse>`, pipe `tap(() => this.loadActive())`

**Checkpoint**: Service prêt — les user stories peuvent commencer.

---

## Phase 2: User Story 1 - Créer une transaction récurrente depuis le formulaire (Priority: P1)

**Goal**: L'utilisateur peut activer un toggle "Récurrente" dans le formulaire de transaction pour créer une transaction récurrente au lieu d'une transaction classique.

**Independent Test**: Ouvrir le formulaire via FAB → activer le toggle → remplir fréquence + date → soumettre → vérifier dans /transactions/recurring.

### Implementation

- [x] T003 [US1] Ajouter 3 champs au FormGroup dans `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` — `isRecurring` (boolean, false), `frequency` (Frequency, MENSUEL, disabled), `nextOccurrence` (string, '', disabled). Importer `Frequency` depuis `subscription.model.ts` et `RecurringTransactionService`.
- [x] T004 [US1] Ajouter un listener `valueChanges` sur `isRecurring` dans le constructeur de `transaction-form.ts` — quand `true` : enable `frequency` + `nextOccurrence`, disable `date` ; quand `false` : disable `frequency` + `nextOccurrence`, enable `date`.
- [x] T005 [US1] Modifier `onSubmit()` dans `transaction-form.ts` — si `isRecurring === true`, construire un `RecurringTransactionRequest` et appeler `recurringTransactionService.create()` au lieu de `transactionService.create()`. Toast "Transaction récurrente créée". Ne pas afficher le toggle en mode édition (`isEditing` signal).
- [x] T006 [US1] Ajouter le toggle et les champs conditionnels dans `app/src/app/features/transactions/components/transaction-form/transaction-form.html` — toggle checkbox/slide "Récurrente" ; `@if (form.get('isRecurring')?.value)` : select fréquence (3 options Hebdomadaire/Mensuel/Annuel) + input date "Prochaine occurrence" avec `min` = date du jour (FR-004 : validation client-side date future/aujourd'hui) ; masquer le champ `date` classique quand récurrence activée. Cacher le toggle entier en mode édition.
- [x] T007 [US1] Ajouter les styles pour le toggle et les champs conditionnels dans `app/src/app/features/transactions/components/transaction-form/transaction-form.scss` — utiliser les design tokens existants (`var(--space-*)`, `var(--radius-*)`, etc.)

**Checkpoint**: US1 fonctionnelle — création de transaction récurrente depuis le formulaire.

---

## Phase 3: User Story 2 - Convertir une transaction existante en récurrente (Priority: P2)

**Goal**: Depuis la liste des transactions, l'utilisateur peut cliquer "Rendre récurrente" pour ouvrir le formulaire pré-rempli en mode récurrent.

**Independent Test**: Depuis la liste des transactions → cliquer l'icône "Rendre récurrente" → formulaire pré-rempli avec toggle activé → soumettre → vérifier dans /transactions/recurring.

### Implementation

- [x] T008 [US2] Ajouter une méthode `onMakeRecurring(transaction: Transaction)` dans `app/src/app/features/transactions/transactions.ts` — ouvre le formulaire de transaction via `ModalService` en mode création avec les données pré-remplies (montant, libellé, type, categoryId, accountId, note) et un flag `asRecurring: true`.
- [x] T009 [US2] Ajouter le bouton/icône "Rendre récurrente" (phosphorRepeat) dans `app/src/app/features/transactions/transactions.html` — sur chaque ligne de transaction, bouton discret avec `(click)="onMakeRecurring(transaction)"`.
- [x] T010 [US2] Adapter `transaction-form.ts` pour lire le flag `asRecurring` depuis le `ModalService` — si présent, activer `isRecurring` et pré-remplir les champs depuis l'entité passée. Fréquence par défaut : MENSUEL. Date prochaine occurrence : aujourd'hui.
- [x] T011 [US2] Ajouter le style du bouton "Rendre récurrente" dans `app/src/app/features/transactions/transactions.scss` — bouton icône discret, cohérent avec les autres actions.

**Checkpoint**: US2 fonctionnelle — conversion de transaction existante en récurrente.

---

## Phase 4: Polish & Tests

**Purpose**: Tests unitaires et validation finale

- [x] T012 Ajouter 4 tests dans `app/src/app/features/transactions/components/transaction-form/transaction-form.spec.ts` : `should_show_recurring_toggle_in_creation_mode`, `should_hide_recurring_toggle_in_edit_mode`, `should_call_recurring_service_create_when_recurring_enabled`, `should_prefill_form_when_converting_transaction`
- [x] T013 Exécuter `cd app && npx ng build` — vérifier compilation sans erreur
- [x] T014 Exécuter `cd app && npx vitest run` — vérifier que tous les tests passent (existants + nouveaux)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 + T002 en parallèle — pas de dépendance
- **US1 (Phase 2)**: Dépend de T001 + T002. T003 → T004 → T005 séquentiels. T006 dépend de T003-T005. T007 en parallèle de T006.
- **US2 (Phase 3)**: Dépend de T005 (logique onSubmit avec isRecurring). T008 + T009 en parallèle. T010 dépend de T008. T011 en parallèle de T010.
- **Polish (Phase 4)**: Dépend de US1 + US2 complètes. T012 (4 tests). T013-T014 séquentiels après tests.

### User Story Dependencies

- **US1 (P1)**: Dépend uniquement de Setup → MVP complet
- **US2 (P2)**: Dépend de US1 (réutilise la logique isRecurring du formulaire)

---

## Implementation Strategy

### MVP First (US1 seule)

1. T001 + T002 (Setup — parallèle)
2. T003 → T004 → T005 → T006 + T007 (US1)
3. **STOP et VALIDER** : créer une récurrence depuis le formulaire

### Livraison complète

1. Setup → US1 → valider MVP
2. US2 (T008-T011) → valider conversion
3. Polish (T012-T014) → tests + build final

---

## Notes

- Aucun nouveau fichier source à créer — uniquement modification de fichiers existants
- Le `ModalService` existant doit être étudié pour le mécanisme de pré-remplissage (T008/T010)
- L'icône `phosphorRepeat` est déjà importée dans le projet (KKS-086)
- 14 tâches au total : 2 setup, 5 US1, 4 US2, 3 polish
