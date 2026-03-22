# Tasks: Comptes Bancaires

**Input**: Design documents from `/specs/026-bank-accounts/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/
**Linear**: [KKS-81](https://linear.app/kksdev/issue/KKS-81)

**Tests**: Inclus (plan.md et constitution mentionnent explicitement les tests d'integration et unitaires).

**Organization**: Taches groupees par user story pour permettre implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'executer en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans chaque description

## Path Conventions

- **Backend**: `api/src/main/java/fr/kksdev/budget/api/` (source)
- **Tests**: `api/src/test/java/fr/kksdev/budget/api/` (tests)
- **Migrations**: `api/src/main/resources/db/migration/` (Flyway)

---

## Phase 1: Setup (Database & Base Types)

**Purpose**: Migration Flyway, enum et entite de base pour le compte bancaire

- [x] T001 Create Flyway migration V7__add_accounts.sql in api/src/main/resources/db/migration/V7__add_accounts.sql — creer table accounts, inserer compte par defaut pour chaque utilisateur existant, inserer categorie systeme "Virement" pour chaque utilisateur existant, ajouter account_id (nullable puis NOT NULL apres migration) et transfer_id sur transactions, ajouter account_id nullable sur subscriptions, rattacher transactions existantes au compte par defaut, creer les index (voir data-model.md section Migration V7)
- [x] T002 [P] Create AccountType enum in api/src/main/java/fr/kksdev/budget/api/enums/AccountType.java — valeurs COURANT("🏦", "#3b82f6"), EPARGNE("🐷", "#22c55e"), ESPECES("💵", "#f59e0b"). Champs: defaultIcone (String), defaultCouleur (String), constructeur prive, getters. Voir research.md R9
- [x] T003 [P] Create Account entity in api/src/main/java/fr/kksdev/budget/api/model/Account.java — champs id (UUID), nom (VARCHAR 50), type (AccountType), soldeInitial (BigDecimal NUMERIC 19,2), icone (VARCHAR 10), couleur (VARCHAR 7), isDefault (boolean, default false), actif (boolean, default true), updatedAt (@UpdateTimestamp), user (ManyToOne User). Annotations Lombok @Data @Builder @NoArgsConstructor @AllArgsConstructor. Voir data-model.md pour le schema complet

---

## Phase 2: Foundational (DTOs & Repository)

**Purpose**: DTOs, repository et requete de calcul de solde. DOIT etre complete avant les user stories.

**CRITICAL**: Pas de travail sur les user stories tant que cette phase n'est pas terminee.

- [x] T004 [P] Create AccountRequest DTO record in api/src/main/java/fr/kksdev/budget/api/dto/request/AccountRequest.java — champs: nom (@NotBlank @Size 1-50), type (@NotNull AccountType), soldeInitial (BigDecimal, nullable, default 0.00), icone (String, nullable), couleur (String, nullable, pattern hex), actif (Boolean, nullable — ignore en POST, utilise en PUT pour desactiver/reactiver). Voir contracts/accounts-api.yaml schema AccountRequest
- [x] T005 [P] Create AccountResponse DTO record in api/src/main/java/fr/kksdev/budget/api/dto/response/AccountResponse.java — champs: id (UUID), nom, type (AccountType), soldeInitial (BigDecimal), solde (BigDecimal, calcule), icone, couleur, isDefault (boolean), actif (boolean). Voir contracts/accounts-api.yaml schema AccountResponse
- [x] T006 [P] Create AccountSummary DTO record in api/src/main/java/fr/kksdev/budget/api/dto/response/AccountSummary.java — champs: id (UUID), nom (String), icone (String), couleur (String). Utilise dans TransactionResponse et SubscriptionResponse. Voir contracts/transactions-api-changes.yaml schema AccountSummary
- [x] T007 Create AccountRepository in api/src/main/java/fr/kksdev/budget/api/repository/AccountRepository.java — JpaRepository<Account, UUID>. Queries: findByUserIdAndActifTrue(UUID userId), findByUserId(UUID userId), findByIdAndUserId(UUID id, UUID userId), findByUserIdAndIsDefaultTrue(UUID userId), existsByNomIgnoreCaseAndUserIdAndActifTrue(String nom, UUID userId), existsByNomIgnoreCaseAndUserIdAndActifTrueAndIdNot(String nom, UUID userId, UUID id) (pour update — meme pattern que CategoryRepository), countByUserIdAndActifTrue(UUID userId)
- [x] T008 Add balance calculation @Query in api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java — ajouter methode calculateBalanceByAccountId(UUID accountId) avec @Query native SQL: SELECT COALESCE(SUM(CASE WHEN t.type = 'RECETTE' THEN t.montant ELSE -t.montant END), 0) FROM transactions t WHERE t.account_id = :accountId. Retourne BigDecimal. Voir research.md R4

**Checkpoint**: Infrastructure de base prete — implementation des user stories peut commencer

---

## Phase 3: User Story 1 - Gestion des comptes bancaires (Priority: P1) 🎯 MVP

**Goal**: CRUD complet des comptes avec gestion du compte par defaut, creation automatique a l'inscription, icones/couleurs par defaut selon le type

**Independent Test**: Creer, modifier, lister, desactiver et supprimer des comptes. Verifier l'unicite du nom, le toggle du defaut, le refus de suppression si donnees rattachees, le refus de desactivation du compte par defaut.

### Implementation for User Story 1

- [x] T009 [US1] Create AccountService in api/src/main/java/fr/kksdev/budget/api/service/AccountService.java — methodes: getAccounts(userId, includeInactive), getAccountById(id, userId), createAccount(request, userId) avec defaults icone/couleur via AccountType.getDefaultIcone()/getDefaultCouleur() si non fournis, updateAccount(id, request, userId) ignore soldeInitial, verifie unicite du nom via existsByNomIgnoreCaseAndUserIdAndActifTrueAndIdNot (exclut l'ID courant), gere actif si present dans request (refuse desactivation si isDefault=true → FR-006), deleteAccount(id, userId) avec guard transactions/subscriptions rattaches, setDefault(id, userId) avec toggle atomique, createDefaultAccount(user) pour inscription. Utilise transactionRepository.calculateBalanceByAccountId() pour construire AccountResponse. EntityNotFoundException (404), IllegalArgumentException (400) via GlobalExceptionHandler existant (R8). Logging INFO sur CRUD, ERROR sur erreurs metier
- [x] T010 [US1] Create AccountController in api/src/main/java/fr/kksdev/budget/api/controller/AccountController.java — @RestController @RequestMapping("/accounts"). Endpoints: GET / (list, ?includeInactive=true), GET /{id}, POST / (201 Created), PUT /{id}, DELETE /{id} (204 No Content), PUT /{id}/default. Injection de AccountService et extraction userId depuis SecurityContext. @Valid sur request bodies. Voir contracts/accounts-api.yaml
- [x] T011 [P] [US1] Modify CategoryService to seed "Virement" system category in api/src/main/java/fr/kksdev/budget/api/service/CategoryService.java — ajouter "Virement" (icone '🔄', couleur '#8b5cf6', isSystem=true) a la methode seedSystemCategories(). Pattern identique aux categories "Abonnement" et "Dette" existantes (R6)
- [x] T012 [US1] Modify AuthService to create default account on registration in api/src/main/java/fr/kksdev/budget/api/service/AuthService.java — appeler accountService.createDefaultAccount(user) dans register(), juste apres categoryService.seedSystemCategories(user). Pattern identique au seeding categories (R2)

### Tests for User Story 1

- [x] T013 [P] [US1] Create AccountServiceTest in api/src/test/java/fr/kksdev/budget/api/service/AccountServiceTest.java — tests unitaires: should_createAccount_when_validRequest, should_applyDefaultIconAndColor_when_notProvided, should_setDefault_when_requested (toggle), should_preventDelete_when_transactionsExist, should_preventDeactivation_when_isDefault, should_deletePhysically_when_noDataAttached, should_createDefaultAccount_when_userRegisters, should_calculateBalance_when_accountHasTransactions. Nommage should_xxx_when_yyy
- [x] T014 [P] [US1] Create AccountControllerTest in api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java — tests d'integration @SpringBootTest: should_listActiveAccounts_when_authenticated, should_createAccount_when_validRequest (201), should_return400_when_duplicateName, should_updateAccount_when_exists, should_deleteAccount_when_noDataAttached (204), should_return400_when_deleteWithTransactions, should_setDefault_when_accountExists, should_return404_when_accountNotFound, should_return401_when_notAuthenticated. Nommage should_xxx_when_yyy

**Checkpoint**: US1 complete — CRUD comptes, defaut, inscription, tests. MVP fonctionnel et testable independamment.

---

## Phase 4: User Story 2 + User Story 4 - Rattachement transactions + Solde (Priority: P2)

**Goal**: Chaque transaction est obligatoirement rattachee a un compte. Le solde de chaque compte est calcule a la volee (soldeInitial + recettes - depenses).

**Why combined**: US4 (solde) est delivre par la balance @Query (Phase 2) + AccountService (US1). Le solde devient significatif des que les transactions sont rattachees (US2). Pas de tache supplementaire pour US4.

**Independent Test**: Creer une transaction avec/sans accountId, verifier le rattachement au compte (ou au defaut). Consulter un compte et verifier que le solde reflete les transactions.

### Implementation for User Story 2 + 4

- [x] T015 [US2] Modify Transaction entity in api/src/main/java/fr/kksdev/budget/api/model/Transaction.java — ajouter champ account (@ManyToOne(fetch = LAZY) @JoinColumn(name = "account_id", nullable = false) Account) et champ transferId (@Column(name = "transfer_id") UUID, nullable). Voir data-model.md section Modification Transaction
- [x] T016 [P] [US2] Modify TransactionRequest DTO in api/src/main/java/fr/kksdev/budget/api/dto/request/TransactionRequest.java — ajouter champ accountId (UUID, nullable — si absent, utiliser le compte par defaut). Voir contracts/transactions-api-changes.yaml
- [x] T017 [P] [US2] Modify TransactionResponse DTO in api/src/main/java/fr/kksdev/budget/api/dto/response/TransactionResponse.java — ajouter champ account (AccountSummary, non null) et champ transferId (UUID, nullable). Voir contracts/transactions-api-changes.yaml
- [x] T018 [US2] Modify TransactionService in api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java — a la creation: resoudre accountId (si null, utiliser le compte par defaut via AccountRepository.findByUserIdAndIsDefaultTrue), valider que le compte est actif et appartient a l'utilisateur, valider que le compte existe (404 sinon). A la lecture: mapper account vers AccountSummary dans la reponse. Refuser la creation si aucun compte n'existe

### Tests for User Story 2 + 4

- [x] T018b [P] [US2] Update TransactionControllerTest in api/src/test/java/fr/kksdev/budget/api/controller/TransactionControllerTest.java — ajouter tests: should_createTransactionOnDefaultAccount_when_noAccountId, should_createTransactionOnSpecifiedAccount_when_accountIdProvided, should_return400_when_accountInactive, should_return404_when_accountNotFound, should_returnAccountSummaryInResponse_when_getTransaction, should_returnCorrectBalance_when_accountHasTransactions (US4). Nommage should_xxx_when_yyy

**Checkpoint**: US2+US4 completes — transactions rattachees aux comptes, solde calcule a la volee, testable independamment.

---

## Phase 5: User Story 3 - Rattachement des abonnements a un compte (Priority: P3)

**Goal**: Association optionnelle d'un abonnement a un compte bancaire

**Independent Test**: Creer un abonnement avec et sans compte rattache. Modifier un abonnement pour ajouter/retirer un compte.

### Implementation for User Story 3

- [x] T019 [US3] Modify Subscription entity in api/src/main/java/fr/kksdev/budget/api/model/Subscription.java — ajouter champ account (@ManyToOne(fetch = LAZY) @JoinColumn(name = "account_id") Account, nullable). Voir data-model.md section Modification Subscription
- [x] T020 [P] [US3] Modify SubscriptionRequest DTO in api/src/main/java/fr/kksdev/budget/api/dto/request/SubscriptionRequest.java — ajouter champ accountId (UUID, nullable). Voir contracts/transactions-api-changes.yaml
- [x] T021 [P] [US3] Modify SubscriptionResponse DTO in api/src/main/java/fr/kksdev/budget/api/dto/response/SubscriptionResponse.java — ajouter champ account (AccountSummary, nullable). Voir contracts/transactions-api-changes.yaml
- [x] T022 [US3] Modify SubscriptionService in api/src/main/java/fr/kksdev/budget/api/service/SubscriptionService.java — a la creation/modification: si accountId fourni, resoudre et valider que le compte est actif et appartient a l'utilisateur. Si absent, laisser null. A la lecture: mapper account vers AccountSummary dans la reponse

### Tests for User Story 3

- [x] T022b [P] [US3] Update SubscriptionControllerTest in api/src/test/java/fr/kksdev/budget/api/controller/SubscriptionControllerTest.java — ajouter tests: should_createSubscriptionWithAccount_when_accountIdProvided, should_createSubscriptionWithoutAccount_when_noAccountId, should_updateSubscription_when_addAccount, should_returnAccountSummaryInResponse_when_getSubscription. Nommage should_xxx_when_yyy

**Checkpoint**: US3 complete — abonnements optionnellement rattaches aux comptes, testable independamment.

---

## Phase 6: User Story 5 - Virement entre comptes (Priority: P3)

**Goal**: Virement entre deux comptes avec creation atomique de 2 transactions liees par un transferId UUID partage. Suppression cascade et propagation du montant.

**Independent Test**: Effectuer un virement, verifier les 2 transactions creees (depense source, recette destination), verifier les soldes mis a jour, verifier le refus si meme compte ou montant invalide. Supprimer une transaction de virement, verifier la cascade. Modifier le montant d'un virement, verifier la propagation.

### Implementation for User Story 5

- [x] T023 [P] [US5] Create TransferRequest DTO record in api/src/main/java/fr/kksdev/budget/api/dto/request/TransferRequest.java — champs: fromAccountId (@NotNull UUID), toAccountId (@NotNull UUID), montant (@NotNull @DecimalMin("0.01") BigDecimal), note (String, nullable, @Size max 500). Voir contracts/accounts-api.yaml schema TransferRequest
- [x] T024 [P] [US5] Create TransferResponse DTO record in api/src/main/java/fr/kksdev/budget/api/dto/response/TransferResponse.java — champs: transferId (UUID), debitTransaction (TransactionResponseRef), creditTransaction (TransactionResponseRef). Inclure inner record TransactionResponseRef (id, montant, libelle, type, date, accountId, accountNom). Voir contracts/accounts-api.yaml schema TransferResponse
- [x] T025 [US5] Add findByTransferId query to TransactionRepository in api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java — ajouter methode findByTransferId(UUID transferId) retournant List<Transaction>. Necessaire pour cascade delete et propagation montant
- [x] T026 [US5] Add transfer method to AccountService in api/src/main/java/fr/kksdev/budget/api/service/AccountService.java — methode transfer(request, userId) @Transactional: valider comptes source/destination distincts (400), valider montant > 0, valider comptes actifs et appartenant a l'utilisateur, generer transferId = UUID.randomUUID(), creer transaction DEPENSE sur source (libelle "Virement vers [nom destination]"), creer transaction RECETTE sur destination (libelle "Virement depuis [nom source]"), les deux avec categorie systeme "Virement" et meme transferId. Retourner TransferResponse. Voir research.md R5
- [x] T027 [US5] Add transfer endpoint to AccountController in api/src/main/java/fr/kksdev/budget/api/controller/AccountController.java — POST /accounts/transfer, @Valid TransferRequest, retourne 201 Created avec TransferResponse. Voir contracts/accounts-api.yaml path /accounts/transfer
- [x] T028 [US5] Implement cascade delete for transfer transactions in TransactionService in api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java — dans delete(): si transaction.transferId != null, trouver la transaction liee (meme transferId, id different) via findByTransferId, supprimer les deux dans meme @Transactional. Voir research.md R11
- [x] T029 [US5] Implement amount propagation for transfer modifications in TransactionService in api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java — dans update(): si transaction.transferId != null et montant modifie, propager le nouveau montant a la transaction liee. Seul le montant est propage (date, note, libelle restent independants). Voir research.md R12

### Tests for User Story 5

- [x] T030 [P] [US5] Add transfer and cascade tests to AccountControllerTest in api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java — tests supplementaires: should_createTransfer_when_validRequest (201, 2 transactions liees), should_return400_when_transferSameAccount, should_return400_when_transferNegativeAmount, should_return400_when_transferInactiveAccount, should_cascadeDelete_when_deleteTransferTransaction, should_propagateAmount_when_updateTransferTransaction

**Checkpoint**: US5 complete — virements fonctionnels avec cascade et propagation. Toutes les user stories implementees.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation end-to-end, tests supplementaires, nettoyage

- [x] T031 [P] Create AccountRepositoryTest in api/src/test/java/fr/kksdev/budget/api/repository/AccountRepositoryTest.java — @DataJpaTest: should_findActiveAccounts_when_mixedStatus, should_calculateBalance_when_transactionsExist, should_returnZeroBalance_when_noTransactions, should_findDefaultAccount_when_exists, should_enforceUniqueNamePerUser_when_duplicateName
- [x] T032 Run quickstart.md validation — executer les scenarios decrits dans quickstart.md (authentification, listing comptes, creation compte, creation transaction avec accountId, virement). Verifier les reponses attendues
- [x] T033 Run full test suite and fix regressions — cd api && mvn clean test. Corriger toute regression introduite par les modifications

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dependance — peut demarrer immediatement
- **Foundational (Phase 2)**: Depend de Phase 1 (entite Account necessaire pour DTOs et Repository)
- **US1 (Phase 3)**: Depend de Phase 2 — BLOCKS les autres user stories (AccountService necessaire pour US2, US5)
- **US2+US4 (Phase 4)**: Depend de Phase 3 (AccountService et AccountRepository necessaires)
- **US3 (Phase 5)**: Depend de Phase 3 (AccountService necessaire pour validation des comptes)
- **US5 (Phase 6)**: Depend de Phase 4 (transferId sur Transaction, findByTransferId dans Repository)
- **Polish (Phase 7)**: Depend de toutes les phases precedentes

### User Story Dependencies

```
Phase 1 (Setup)
    └── Phase 2 (Foundational)
            └── Phase 3: US1 (P1) — MVP
                    ├── Phase 4: US2+US4 (P2)
                    │       └── Phase 6: US5 (P3)
                    └── Phase 5: US3 (P3) — parallelisable avec Phase 4
```

### Within Each User Story

- Entites/DTOs avant services
- Services avant controllers
- Core implementation avant tests
- Tests apres implementation

### Parallel Opportunities

- **Phase 1**: T002 et T003 en parallele (apres T001)
- **Phase 2**: T004, T005, T006 en parallele; T008 apres T007
- **Phase 3**: T011 en parallele avec T009; T013 et T014 en parallele (apres service/controller)
- **Phase 4**: T016 et T017 en parallele; T018 attend T015-T017
- **Phase 5**: T020 et T021 en parallele; T022 attend T019-T021
- **Phase 6**: T023 et T024 en parallele; T025 independant; T028 et T029 parallelisables (apres T025)
- **Phase 4 et Phase 5 peuvent s'executer en parallele** (fichiers differents, pas de dependance croisee)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Batch 1 — fichiers independants:
Task T004: "Create AccountRequest DTO"
Task T005: "Create AccountResponse DTO"
Task T006: "Create AccountSummary DTO"

# Batch 2 — depend des DTOs:
Task T007: "Create AccountRepository"

# Batch 3 — depend du repository:
Task T008: "Add balance @Query"
```

## Parallel Example: Phase 4+5 (US2+US4 et US3 en parallele)

```bash
# Stream A (US2+US4):
T015 → T016+T017 (parallele) → T018

# Stream B (US3) — en parallele avec Stream A:
T019 → T020+T021 (parallele) → T022
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (migration + enum + entite)
2. Complete Phase 2: Foundational (DTOs + repository + balance query)
3. Complete Phase 3: User Story 1 (CRUD comptes + defaut + inscription + tests)
4. **STOP and VALIDATE**: Tester US1 independamment — creer/modifier/lister/supprimer des comptes
5. Deploy/demo si pret

### Incremental Delivery

1. Setup + Foundational → Infrastructure prete
2. US1 → Test independamment → Deploy/Demo (**MVP!**)
3. US2+US4 → Transactions rattachees, solde calcule → Deploy/Demo
4. US3 → Abonnements rattaches (optionnel) → Deploy/Demo
5. US5 → Virements entre comptes → Deploy/Demo
6. Polish → Tests supplementaires, validation end-to-end

### Scope

| Segment | Taches | IDs |
|---------|--------|-----|
| Setup | 3 | T001-T003 |
| Foundational | 5 | T004-T008 |
| US1 (P1) | 6 | T009-T014 |
| US2+US4 (P2) | 5 | T015-T018, T018b |
| US3 (P3) | 5 | T019-T022, T022b |
| US5 (P3) | 8 | T023-T030 |
| Polish | 3 | T031-T033 |
| **Total** | **35** | T001-T033 + T018b, T022b |

---

## Notes

- [P] tasks = fichiers differents, pas de dependances
- [Story] label = tracabilite vers la user story
- Chaque user story est testable independamment
- Commit apres chaque tache ou groupe logique
- S'arreter a chaque checkpoint pour valider
- BigDecimal partout pour les montants (precision 2 decimales)
- EntityNotFoundException (404) et IllegalArgumentException (400) via GlobalExceptionHandler existant
- Solde initial fige apres creation (ignore dans PUT)
- Les virements creent 2 transactions liees par UUID, pas une entite separee
