# Tasks: Tests unitaires services Phase 4

**Input**: Design documents from `/specs/017-phase4-unit-tests/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: User Story 1 - Tests TransactionService (Priority: P1)

**Goal**: Couvrir les 7 methodes publiques de TransactionService (CRUD + getSummary + refreshTrigger) + test successive mutations

**Independent Test**: `cd app && npx vitest run src/app/core/services/transaction.spec.ts`

### Implementation

- [X] T001 [P] [US1] Creer le fichier de test TransactionService avec setup TestBed, mock ApiService et donnees de test dans `app/src/app/core/services/transaction.spec.ts`. Inclure les 8 tests suivants : should_return_transactions_when_getAll_called (GET /transactions), should_return_transaction_when_getById_called (GET /transactions/{id}), should_create_and_refresh_when_create_called (POST /transactions + refreshTrigger +1), should_update_and_refresh_when_update_called (PUT /transactions/{id} + refreshTrigger +1), should_delete_and_refresh_when_delete_called (DELETE /transactions/{id} + refreshTrigger +1), should_return_summary_when_getSummary_called_without_params (GET /transactions/summary), should_return_summary_when_getSummary_called_with_month_and_year (GET /transactions/summary?month=1&year=2026), should_increment_refreshTrigger_on_successive_mutations (3 creates → refreshTrigger 0→3). Pattern : TestBed + BrowserTestingModule + platformBrowserTesting(), mock ApiService = { get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() }, nommage should_X_when_Y. Reference : `app/src/app/core/services/auth.spec.ts`

**Checkpoint**: `cd app && npx vitest run src/app/core/services/transaction.spec.ts` — 8 tests passent

---

## Phase 2: User Story 2 - Tests SubscriptionService (Priority: P2)

**Goal**: Couvrir les 5 methodes publiques de SubscriptionService (CRUD + filtre actif + refreshTrigger)

**Independent Test**: `cd app && npx vitest run src/app/core/services/subscription.spec.ts`

### Implementation

- [X] T002 [P] [US2] Creer le fichier de test SubscriptionService avec setup TestBed, mock ApiService et donnees de test dans `app/src/app/core/services/subscription.spec.ts`. Inclure les 8 tests suivants : should_return_subscriptions_when_getAll_called_without_filter (GET /subscriptions), should_return_active_subscriptions_when_getAll_called_with_actif_true (GET /subscriptions?actif=true), should_return_inactive_subscriptions_when_getAll_called_with_actif_false (GET /subscriptions?actif=false), should_return_subscription_when_getById_called (GET /subscriptions/{id}), should_create_and_refresh_when_create_called (POST /subscriptions + refreshTrigger +1), should_update_and_refresh_when_update_called (PUT /subscriptions/{id} + refreshTrigger +1), should_delete_and_refresh_when_delete_called (DELETE /subscriptions/{id} + refreshTrigger +1), should_increment_refreshTrigger_on_successive_mutations (3 creates → refreshTrigger 0→3). Meme pattern TestBed que T001. Reference : `app/src/app/core/services/auth.spec.ts`

**Checkpoint**: `cd app && npx vitest run src/app/core/services/subscription.spec.ts` — 8 tests passent

---

## Phase 3: User Story 3 - Tests DebtService (Priority: P3)

**Goal**: Couvrir les 5 methodes publiques de DebtService (CRUD + filtre rembourse + refreshTrigger)

**Independent Test**: `cd app && npx vitest run src/app/core/services/debt.spec.ts`

### Implementation

- [X] T003 [P] [US3] Creer le fichier de test DebtService avec setup TestBed, mock ApiService et donnees de test dans `app/src/app/core/services/debt.spec.ts`. Inclure les 8 tests suivants : should_return_debts_when_getAll_called_without_filter (GET /debts), should_return_repaid_debts_when_getAll_called_with_rembourse_true (GET /debts?rembourse=true), should_return_unpaid_debts_when_getAll_called_with_rembourse_false (GET /debts?rembourse=false), should_return_debt_when_getById_called (GET /debts/{id}), should_create_and_refresh_when_create_called (POST /debts + refreshTrigger +1), should_update_and_refresh_when_update_called (PUT /debts/{id} + refreshTrigger +1), should_delete_and_refresh_when_delete_called (DELETE /debts/{id} + refreshTrigger +1), should_increment_refreshTrigger_on_successive_mutations (3 creates → refreshTrigger 0→3). Meme pattern TestBed que T001. Reference : `app/src/app/core/services/auth.spec.ts`

**Checkpoint**: `cd app && npx vitest run src/app/core/services/debt.spec.ts` — 8 tests passent

---

## Phase 4: Polish & Verification

**Purpose**: Validation globale — build, lint, suite de tests complete

- [X] T004 Executer la suite de tests complete et verifier que les 24 nouveaux tests + les tests existants passent : `cd app && npx vitest run`
- [X] T005 Verifier la compilation sans erreur : `cd app && ng build`
- [X] T006 Verifier le linting sans warning : `cd app && ng lint`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1)**, **Phase 2 (US2)**, **Phase 3 (US3)** : Aucune dependance entre elles — peuvent demarrer en parallele
- **Phase 4 (Polish)** : Depend de la completion des 3 phases precedentes

### User Story Dependencies

- **User Story 1 (P1)** : T001 — independant, peut demarrer immediatement
- **User Story 2 (P2)** : T002 — independant, peut demarrer immediatement
- **User Story 3 (P3)** : T003 — independant, peut demarrer immediatement

### Parallel Opportunities

- T001, T002, T003 sont tous [P] — 3 fichiers differents, aucune dependance croisee
- Les 3 user stories peuvent etre implementees simultanement

---

## Parallel Example

```bash
# Les 3 fichiers de test peuvent etre crees en parallele :
Task: "T001 [US1] transaction.spec.ts"
Task: "T002 [US2] subscription.spec.ts"
Task: "T003 [US3] debt.spec.ts"

# Puis verification sequentielle :
Task: "T004 Suite complete"
Task: "T005 Build"
Task: "T006 Lint"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completer T001 (TransactionService tests)
2. **STOP and VALIDATE** : `cd app && npx vitest run src/app/core/services/transaction.spec.ts`
3. 7 tests passent → MVP valide

### Incremental Delivery

1. T001 → TransactionService couvert (8 tests) → Valider
2. T002 → SubscriptionService couvert (8 tests) → Valider
3. T003 → DebtService couvert (8 tests) → Valider
4. T004-T006 → Verification globale (24 tests + existants + build + lint)

---

## Notes

- Tous les tests suivent le pattern TestBed Angular 21 avec `BrowserTestingModule` + `platformBrowserTesting()`
- Mock ApiService = `{ get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() }`
- Nommage : `should_[resultat]_when_[condition]`
- Reference pattern : `app/src/app/core/services/auth.spec.ts`
- Les pipes (AmountPipe, RelativeDatePipe) sont exclus — deja couverts (12 + 11 tests)
