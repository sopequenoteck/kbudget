# Tasks: Gestion des devises (multi-currency)

**Input**: Design documents from `/specs/030-multi-currency/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks groupés par user story. Ordre API-First : backend avant frontend dans chaque phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1-US5 mapping spec.md)

## Path Conventions

- **Backend**: `api/src/main/java/fr/kksdev/budget/api/`
- **Frontend**: `app/src/app/`
- **Migrations**: `api/src/main/resources/db/migration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Enum Currency, migration Flyway V8, modification des entités JPA. Fondations partagées par toutes les user stories.

- [x] T001 Create Currency enum with 7 values (EUR, XOF, USD, GBP, CHF, CAD, MAD) and attributes (symbol, displayName, decimalPlaces) using Lombok @Getter/@RequiredArgsConstructor pattern from AccountType in `api/src/main/java/fr/kksdev/budget/api/enums/Currency.java`
- [x] T002 [P] Create Flyway migration V8: ALTER TABLE ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR' on accounts, debts, subscriptions + default_currency on users in `api/src/main/resources/db/migration/V8__add_currency_support.sql`
- [x] T003 [P] Add currency field (@Enumerated EnumType.STRING, @Builder.Default Currency.EUR) to Account, Debt, Subscription entities and defaultCurrency to User entity in `api/src/main/java/fr/kksdev/budget/api/model/Account.java`, `Debt.java`, `Subscription.java`, `User.java`

**Checkpoint**: `cd api && mvn clean compile` doit passer. Lancer avec profil dev pour valider la migration V8.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: DTOs partagés, nouveaux endpoints de référence, services frontend de base, AmountPipe dynamique. DOIT être complet avant les user stories.

- [x] T004 [P] Create CurrencyInfo response DTO (record with code, symbol, name, decimalPlaces) and CurrencyController with GET /currencies returning all Currency enum values in `api/src/main/java/fr/kksdev/budget/api/dto/response/CurrencyInfo.java` and `api/src/main/java/fr/kksdev/budget/api/controller/CurrencyController.java`
- [x] T005 [P] Create UserResponse DTO (record with name, email, defaultCurrency), UserService with getProfile(userId) method, and UserController with GET /users/me endpoint in `api/src/main/java/fr/kksdev/budget/api/dto/response/UserResponse.java`, `api/src/main/java/fr/kksdev/budget/api/service/UserService.java`, `api/src/main/java/fr/kksdev/budget/api/controller/UserController.java`
- [x] T006 [P] Add currency field (String) to AccountSummary response DTO and update toAccountSummary mapping in AccountService to include account.getCurrency().name() in `api/src/main/java/fr/kksdev/budget/api/dto/response/AccountSummary.java` and `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T007 [P] Create CurrencyInfo TypeScript interface and CurrencyService (GET /currencies with signal cache) in `app/src/app/core/models/currency.model.ts` and `app/src/app/core/services/currency.ts`
- [x] T008 [P] Add defaultCurrency field to UserInfo interface and create UserService with getProfile() method (GET /users/me) in `app/src/app/core/models/user.model.ts` and `app/src/app/core/services/user.ts`
- [x] T009 Modify AmountPipe to accept optional currency as SECOND parameter (pipe: amount[:type[:currency]]). Keep existing type parameter position for backward compatibility — all existing `| amount:'DEPENSE'` calls continue working. Replace hardcoded 'EUR' Intl.NumberFormat with dynamic formatter per currency. Default currency = 'EUR' when not provided in `app/src/app/shared/pipes/amount.pipe.ts`
- [x] T009b [P] Write integration tests for CurrencyController (GET /currencies returns all 7 currencies, response format matches CurrencyInfo) and UserController (GET /users/me returns profile with defaultCurrency, 401 if unauthenticated) in `api/src/test/java/fr/kksdev/budget/api/controller/CurrencyControllerTest.java` and `api/src/test/java/fr/kksdev/budget/api/controller/UserControllerTest.java`

**Checkpoint**: GET /currencies et GET /users/me fonctionnent avec tests. AmountPipe affiche correctement EUR et XOF.

---

## Phase 3: User Story 1 + 3 — Compte avec devise + Affichage formaté (Priority: P1) — MVP

**Goal**: Un utilisateur peut créer un compte avec une devise spécifique. Tous les montants (transactions, abonnements, comptes) s'affichent avec le formatage correct de la devise.

**Independent Test**: Créer un compte en XOF, ajouter une transaction, vérifier que les montants s'affichent avec "CFA" et sans décimales. Créer un compte en EUR, vérifier l'affichage avec "€" et 2 décimales. Tenter un virement entre les deux → erreur 400.

### Backend

- [x] T010 [P] [US1] Add optional Currency currency field to AccountRequest and add currency field to AccountResponse in `api/src/main/java/fr/kksdev/budget/api/dto/request/AccountRequest.java` and `api/src/main/java/fr/kksdev/budget/api/dto/response/AccountResponse.java`
- [x] T011 [P] [US1] Add optional Currency currency field to SubscriptionRequest and add currency field to SubscriptionResponse in `api/src/main/java/fr/kksdev/budget/api/dto/request/SubscriptionRequest.java` and `api/src/main/java/fr/kksdev/budget/api/dto/response/SubscriptionResponse.java`
- [x] T012 [US1] Modify AccountService.createAccount(): set currency from request or user.defaultCurrency if null. Modify updateAccount(): reject if request currency differs from existing (400 "La devise d'un compte ne peut pas être modifiée"). Update toAccountResponse() mapping to include currency in `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T013 [US1] Add cross-currency transfer validation in AccountService.transfer(): after active checks, compare fromAccount.getCurrency() != toAccount.getCurrency() → throw IllegalArgumentException("Le virement entre comptes de devises différentes n'est pas autorisé") in `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T014 [US3] Modify SubscriptionService.create(): if accountId present, force currency = account.getCurrency() (ignore request value); if accountId null, use request currency or user.defaultCurrency. Modify update(): if accountId changes to new account, force currency. Update toSubscriptionResponse() to include currency in `api/src/main/java/fr/kksdev/budget/api/service/SubscriptionService.java`
- [x] T014b Write integration tests for account currency: should_create_account_with_currency_when_provided, should_use_default_currency_when_not_provided, should_reject_update_when_currency_changed (400), should_reject_transfer_when_currencies_differ (400). Update AccountControllerTest and add AccountService currency tests in `api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java` and `api/src/test/java/fr/kksdev/budget/api/service/AccountServiceTest.java`
- [x] T014c [P] Write integration tests for subscription currency: should_force_account_currency_when_account_linked, should_use_request_currency_when_no_account, should_update_currency_when_account_changes in `api/src/test/java/fr/kksdev/budget/api/service/SubscriptionServiceTest.java`

### Frontend

- [x] T015 [P] [US1] Add currency field (string) to Account interface, AccountSummary interface, and Subscription interface in `app/src/app/core/models/account.model.ts` and `app/src/app/core/models/subscription.model.ts`
- [x] T016 [US1] Add currency SelectPicker to account-form: load currencies from CurrencyService, pre-select user.defaultCurrency (via UserService.getProfile()) on create mode, disable selector on edit mode (currency immutable). Add currency field to form submit payload in `app/src/app/shared/components/account-form/account-form.ts`
- [x] T017 [P] [US3] Update all transaction amount displays to pass account.currency to AmountPipe (replace `| amount` with `| amount:transaction.type:transaction.account?.currency`) in transaction list and detail templates under `app/src/app/features/transactions/`
- [x] T018 [US3] Update subscription list templates to pass currency to AmountPipe, and update account balance displays in settings account list to pass account.currency in `app/src/app/features/subscriptions/` and `app/src/app/features/settings/components/accounts/`
- [x] T018b [US1] Add conditional currency selector to subscription-form: if accountId selected → show currency as read-only (forced to account.currency, auto-update on account change); if no accountId → show editable SelectPicker (pre-select user.defaultCurrency). Add currency field to form submit payload in `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts`
- [x] T013b [P] [US1] Handle cross-currency transfer error in transfer-form: filter destination accounts to same currency as source account (reactive on source change), or display error message from 400 response in `app/src/app/shared/components/transfer-form/transfer-form.ts`

**Checkpoint**: Comptes créables avec devise. Devise immuable en édition. Virements cross-currency bloqués. Montants formatés correctement par devise. Subscription-form avec devise conditionnelle. MVP fonctionnel.

---

## Phase 4: User Story 2 — Devise par défaut configurable (Priority: P2)

**Goal**: L'utilisateur peut configurer sa devise par défaut dans les paramètres. Cette devise pré-remplit les formulaires de création.

**Independent Test**: Changer la devise par défaut en XOF dans les paramètres. Créer un nouveau compte → XOF pré-sélectionné. Créer une dette → XOF pré-sélectionné.

### Backend

- [x] T019 [US2] Create UserUpdateRequest DTO (record with optional name, optional defaultCurrency with validation), add updateProfile() to UserService, add PUT /users/me to UserController in `api/src/main/java/fr/kksdev/budget/api/dto/request/UserUpdateRequest.java`, `api/src/main/java/fr/kksdev/budget/api/service/UserService.java`, `api/src/main/java/fr/kksdev/budget/api/controller/UserController.java`
- [x] T019b Write integration tests for PUT /users/me: should_update_default_currency, should_reject_invalid_currency (400), should_not_affect_existing_accounts in `api/src/test/java/fr/kksdev/budget/api/controller/UserControllerTest.java`

### Frontend

- [x] T020 [US2] Add updateProfile() method to frontend UserService (PUT /users/me) in `app/src/app/core/services/user.ts`
- [x] T021 [US2] Add default currency selector (SelectPicker with CurrencyService data) to profile settings component, call UserService.updateProfile() on change in `app/src/app/features/settings/components/profile/profile.ts`

**Checkpoint**: Devise par défaut modifiable dans les paramètres. Le wire de user.defaultCurrency dans les formulaires est déjà intégré dans T016 (account-form), T026 (debt-form) et T018b (subscription-form).

---

## Phase 5: User Story 4 — Dettes avec devise (Priority: P2)

**Goal**: L'utilisateur peut enregistrer une dette avec une devise spécifique, indépendamment de ses comptes.

**Independent Test**: Créer une dette en XOF → montant affiché avec "CFA". Modifier la devise d'une dette existante → formatage mis à jour.

### Backend

- [x] T023 [P] [US4] Add optional Currency currency field to DebtRequest and add currency field to DebtResponse in `api/src/main/java/fr/kksdev/budget/api/dto/request/DebtRequest.java` and `api/src/main/java/fr/kksdev/budget/api/dto/response/DebtResponse.java`
- [x] T024 [US4] Modify DebtService.create(): set currency from request or user.defaultCurrency if null. Update toDebtResponse() mapping to include currency in `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T024b Write integration tests for debt currency: should_create_debt_with_currency_when_provided, should_use_default_currency_when_not_provided, should_include_currency_in_response in `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java`

### Frontend

- [x] T025 [US4] Add currency field to Debt TypeScript interface in `app/src/app/core/models/debt.model.ts`
- [x] T026 [US4] Add currency SelectPicker to debt-form (pre-select from user.defaultCurrency, modifiable) and update debt list/detail templates to pass currency to AmountPipe in `app/src/app/features/debts/components/debt-form/debt-form.ts` and debt list templates under `app/src/app/features/debts/`

**Checkpoint**: Dettes créables/éditables avec devise. Montants formatés correctement.

---

## Phase 6: User Story 5 — Dashboard groupé par devise (Priority: P3)

**Goal**: Les totaux du dashboard (solde, dépenses, revenus, abonnements, dettes) sont affichés séparément par devise.

**Independent Test**: Avoir des comptes en EUR et XOF avec transactions → dashboard affiche deux sections de totaux séparées. Avec un seul groupe de devises → affichage identique à l'actuel.

### Backend

- [x] T027 [US5] Add currency field to MonthlySummaryResponse DTO and modify TransactionRepository: add JPQL/native query joining transactions with accounts grouped by account.currency in `api/src/main/java/fr/kksdev/budget/api/dto/response/MonthlySummaryResponse.java` and `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`
- [x] T028 [US5] Modify TransactionService.getMonthlySummary() to return List<MonthlySummaryResponse> (breaking change: object → array, co-deploy with T029-T030). Order: user.defaultCurrency first, then alphabetical in `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java`
- [x] T028b Write integration tests for monthly summary grouped by currency: should_return_list_grouped_by_currency, should_return_single_item_when_one_currency, should_order_default_currency_first in `api/src/test/java/fr/kksdev/budget/api/service/TransactionServiceTest.java`

### Frontend

- [x] T029 [US5] Update MonthlySummary TypeScript interface (add currency field) and modify TransactionService.getSummary() to handle array response in `app/src/app/core/models/transaction.model.ts` and `app/src/app/core/services/transaction.ts`
- [x] T030 [US5] Refactor dashboard component: group account totals by currency (computed signals per currency), group monthly summary by currency, group subscription/debt totals by currency. Display each currency group as a separate section in `app/src/app/features/dashboard/dashboard.ts` and `app/src/app/features/dashboard/dashboard.html`

**Checkpoint**: Dashboard affiche les totaux par devise. Un seul groupe de devises → affichage identique à l'actuel.

**Co-deploy obligatoire**: T027-T030 constituent un breaking change API (object → array). Ces tâches DOIVENT être dans le même commit pour éviter de casser le dashboard entre backend et frontend.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Vérification globale de cohérence et cas limites.

- [x] T031 Verify all amount displays across the entire app use currency-aware AmountPipe: search for `| amount` without currency parameter and fix any remaining occurrences in `app/src/app/`
- [x] T032 Validate edge cases end-to-end: cross-currency transfer returns 400, subscription currency updates when account changes, creating default account for new user uses EUR, all existing data migrated to EUR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (Currency enum, entities, migration)
- **US1+US3 (Phase 3)**: Depends on Phase 2 — MVP delivery
- **US2 (Phase 4)**: Depends on Phase 2. Backend (T019) can start after Phase 2. Frontend (T020-T021) after T019. Note: le wire de defaultCurrency dans les formulaires est intégré dans T016/T026/T018b (pas de T022)
- **US4 (Phase 5)**: Depends on Phase 2. Can run in parallel with Phases 3-4
- **US5 (Phase 6)**: Depends on Phase 2. Can run in parallel with Phases 3-5
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational)
    │
    ├──▶ Phase 3: US1+US3 (P1) ──── MVP ✓
    │
    ├──▶ Phase 4: US2 (P2) ──────── can start after Phase 2
    │
    ├──▶ Phase 5: US4 (P2) ──────── can start after Phase 2
    │
    └──▶ Phase 6: US5 (P3) ──────── can start after Phase 2
                                     │
                                     ▼
                              Phase 7 (Polish)
```

### Within Each User Story

- Backend DTOs before backend services (services use the DTOs)
- Backend services before frontend (API must exist before consuming it)
- Frontend models before frontend components (components use the models)
- Core implementation before integration/display

### Parallel Opportunities

**Phase 1**: T002 and T003 can run in parallel (migration and entities are independent files)
**Phase 2**: T004, T005, T006, T007, T008 can all run in parallel (different files/layers)
**Phase 3**: T010 and T011 in parallel (different DTOs). T015 in parallel with backend tasks. T017 in parallel with T018. T013b in parallel with T018b
**Phase 4**: T019 → T019b (test) then T020-T021 (frontend sequential)
**Phase 5**: T023 (DTO) can start immediately. T025 in parallel with T023-T024
**Phase 6**: T027-T028-T028b sequential (same service + tests). T029-T030 sequential (model then component)

---

## Parallel Example: Phase 3 (US1+US3 MVP)

```
# Backend DTOs in parallel:
T010: AccountRequest/Response + currency
T011: SubscriptionRequest/Response + currency

# Then backend services (sequential within AccountService):
T012: AccountService create/update currency logic
T013: AccountService transfer validation
T014: SubscriptionService currency from account

# Backend tests (after services):
T014b: Account currency tests
T014c: Subscription currency tests (parallel with T014b)

# Frontend model + components:
T015: TypeScript models (parallel with backend)
T016: Account-form currency selector (after T015)
T017: Transaction display templates (after T015, parallel with T018)
T018: Subscription/account display templates (after T015)
T018b: Subscription-form conditional currency selector (after T015)
T013b: Transfer-form cross-currency handling (parallel with T018b)
```

---

## Implementation Strategy

### MVP First (US1 + US3 Only)

1. Complete Phase 1: Setup (enum + migration + entities)
2. Complete Phase 2: Foundational (DTOs partagés + AmountPipe + services)
3. Complete Phase 3: US1 + US3 (comptes avec devise + affichage formaté)
4. **STOP and VALIDATE**: Créer un compte XOF, ajouter des transactions, vérifier l'affichage
5. Commit et deploy si prêt

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1 + US3 → **MVP** : comptes multi-devises avec affichage correct
3. US2 → Devise par défaut configurable (confort utilisateur)
4. US4 → Dettes avec devise
5. US5 → Dashboard groupé par devise (polish)
6. Chaque story ajoute de la valeur sans casser les précédentes

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances entre eux
- [USn] label lie la tâche à la user story pour traçabilité
- Les phases 3-6 sont indépendantes entre elles (dépendent toutes de Phase 2)
- Commiter après chaque phase ou groupe logique de tâches
- FR mappées : FR-001→T010/T012/T016, FR-002→T012/T016, FR-003→T001/T004, FR-004→T005/T019/T021, FR-005→T002/T003, FR-006→T012/T016, FR-007→T009/T017/T018, FR-008→T023/T024/T026, FR-009→T011/T014/T018b, FR-010→T013/T013b, FR-011→T027-T030, FR-012→T002, FR-013→implicite (aucune feature de conversion)
- Tests mappés : T009b (Phase 2), T014b/T014c (Phase 3), T019b (Phase 4), T024b (Phase 5), T028b (Phase 6)
