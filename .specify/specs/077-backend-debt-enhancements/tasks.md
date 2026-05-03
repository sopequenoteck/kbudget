# Tasks: Backend Debt Enhancements

**Input**: Design documents from `/specs/077-backend-debt-enhancements/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/debt-endpoints.md

**Tests**: Inclus — constitution exige tests unitaires (services) et intégration (controllers).

**Organization**: Tasks groupées par user story (5 stories P1→P5).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Backend Spring Boot: `api/src/main/java/fr/kksdev/budget/api/`
- Tests: `api/src/test/java/fr/kksdev/budget/api/`
- Migrations: `api/src/main/resources/db/migration/`

---

## Phase 1: Setup

**Purpose**: Migration Flyway et base de données

- [X] T001 Créer la migration Flyway `api/src/main/resources/db/migration/V18__add_debt_enhancements.sql` : ALTER TABLE debts ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR', ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL, ADD COLUMN include_in_balance BOOLEAN NOT NULL DEFAULT false, ADD COLUMN reminder_date DATE, ADD COLUMN reminder_time TIME ; ALTER TABLE transactions ADD COLUMN debt_id UUID REFERENCES debts(id) ON DELETE SET NULL ; CREATE INDEX idx_debts_account_id, idx_debts_reminder (partial WHERE reminder_date IS NOT NULL), idx_transactions_debt_id ; UPDATE debts SET currency = (SELECT COALESCE(SPLIT_PART(up.currencies, ',', 1), 'EUR') FROM user_preferences up WHERE up.user_id = debts.user_id) — backfill devise principale utilisateur pour les dettes existantes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Enrichissement entités, enums et DTOs partagés par toutes les user stories

**CRITICAL**: Toutes les user stories dépendent de cette phase

- [X] T002 Enrichir l'entité Debt dans `api/src/main/java/fr/kksdev/budget/api/model/Debt.java` : ajouter champs currency (Currency, @Enumerated EnumType.STRING, @Column nullable=false, default EUR), account (ManyToOne lazy, nullable FK → Account), includeInBalance (Boolean, default false), reminderDate (LocalDate, nullable), reminderTime (LocalTime, nullable)
- [X] T003 Enrichir l'entité Transaction dans `api/src/main/java/fr/kksdev/budget/api/model/Transaction.java` : ajouter champ debt (ManyToOne lazy, nullable FK → Debt)
- [X] T004 Ajouter DEBT_REMINDER à l'enum `api/src/main/java/fr/kksdev/budget/api/enums/NotificationType.java`
- [X] T005 Enrichir DebtRequest dans `api/src/main/java/fr/kksdev/budget/api/dto/request/DebtRequest.java` : ajouter accountId (UUID nullable), includeInBalance (Boolean nullable), reminderDate (LocalDate nullable), reminderTime (LocalTime nullable)
- [X] T006 Enrichir DebtResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/response/DebtResponse.java` : ajouter account (AccountSummary nullable), includeInBalance (Boolean), reminderDate (LocalDate nullable), reminderTime (LocalTime nullable), montantRestant (BigDecimal), dueDate (LocalDate nullable)
- [X] T007 Enrichir TransactionResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/response/TransactionResponse.java` : ajouter debtId (UUID nullable)
- [X] T008 Ajouter requêtes au repository `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java` : sumByDebtId(@Query native SUM(montant) WHERE debt_id = ?), findByDebtIdOrderByDateDesc(UUID debtId)
- [X] T009 Enrichir DebtService dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java` : (1) toResponse() — mapper les nouveaux champs (account → AccountSummary, includeInBalance, reminderDate, reminderTime, montantRestant via TransactionRepository.sumByDebtId(), dueDate) ; (2) create()/update() — persister les champs includeInBalance, reminderDate, reminderTime ; valider que reminderDate et reminderTime sont fournis ensemble ou absents ensemble ; si accountId fourni, forcer includeInBalance=false (FR-009). NE PAS implémenter la logique devise/compte ici (voir T018 US2).

**Checkpoint**: Entités, DTOs et mappings enrichis. Les endpoints existants (CRUD) retournent les nouveaux champs. Prêt pour les user stories.

---

## Phase 3: User Story 1 — Rembourser une dette (Priority: P1) MVP

**Goal**: L'utilisateur peut enregistrer un remboursement partiel/total qui crée une transaction liée et met à jour le montant restant dynamiquement.

**Independent Test**: Créer une dette, rembourser partiellement, vérifier transaction créée + montant restant correct. Rembourser le reste, vérifier rembourse=true.

### Implementation for User Story 1

- [X] T010 [P] [US1] Créer DebtRepayRequest dans `api/src/main/java/fr/kksdev/budget/api/dto/request/DebtRepayRequest.java` : accountId (@NotNull UUID), amount (BigDecimal @Positive nullable, défaut=montant restant)
- [X] T011 [P] [US1] Créer DebtPaymentResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/response/DebtPaymentResponse.java` : id (UUID), amount (BigDecimal), date (LocalDate), accountName (String)
- [X] T012 [US1] Implémenter DebtService.repay(UUID debtId, DebtRepayRequest request, UUID userId) dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java` : valider dette non remboursée, calculer montantRestant via TransactionRepository.sumByDebtId(), valider amount <= montantRestant, résoudre account (actif, ownership), créer Transaction (libelle="Remboursement - {personne}", type=DEPENSE si EMPRUNT / RECETTE si PRET, category=debt.category, debt=debt, account=account), mettre à jour rembourse si montantRestant=0, retourner DebtResponse
- [X] T013 [US1] Implémenter DebtService.getPayments(UUID debtId, UUID userId) dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java` : valider ownership dette, retourner List<DebtPaymentResponse> via TransactionRepository.findByDebtIdOrderByDateDesc()
- [X] T014 [US1] Ajouter endpoints POST /debts/{id}/repay et GET /debts/{id}/payments dans `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`
- [X] T015 [US1] Adapter TransactionService.delete() dans `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java` : si la transaction supprimée a un debtId, recalculer montantRestant et mettre à jour rembourse de la dette liée (FR-023)
- [X] T016 [US1] Tests unitaires DebtService (repay + payments + recalcul) dans `api/src/test/java/fr/kksdev/budget/api/service/DebtServiceTest.java` : should_createTransaction_when_partialRepay, should_markAsRepaid_when_fullRepay, should_useRemainingAmount_when_noAmountProvided, should_reject_when_amountExceedsRemaining, should_reject_when_debtAlreadyRepaid, should_reject_when_accountInactive, should_returnPayments_when_paymentsExist, should_recalculateRembourse_when_paymentDeleted
- [X] T017 [US1] Tests intégration DebtController (repay + payments + suppression) dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java` : POST /debts/{id}/repay (200 partiel, 200 total avec auto-rembourse, 400 montant excédent, 400 dette déjà remboursée, 400 compte inactif, 404 dette introuvable), GET /debts/{id}/payments (200 liste, 200 liste vide), DELETE /debts/{id} avec remboursements existants (204 + transactions conservées avec debtId=NULL — FR-021)

**Checkpoint**: Remboursement fonctionnel. Le montant restant est calculé dynamiquement. L'historique des paiements est accessible. Le recalcul après suppression de transaction est garanti.

---

## Phase 4: User Story 2 — Associer une dette à un compte bancaire (Priority: P2)

**Goal**: L'utilisateur peut lier une dette à un compte. La devise est forcée à celle du compte. La conversion est effectuée lors d'une association tardive.

**Independent Test**: Créer une dette avec accountId, vérifier devise forcée. Modifier accountId vers un compte d'une autre devise, vérifier conversion.

### Implementation for User Story 2

- [X] T018 [US2] Enrichir DebtService.create() et update() dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java` pour la logique compte-devise : si accountId fourni → résoudre account (actif, ownership), forcer currency=account.currency ; si accountId null → currency=request.currency ou devise principale utilisateur (via PreferenceService) ; lors d'un update changeant accountId vers un compte de devise différente → convertir montant via ExchangeRateService.findPivotRate(), refuser si taux indisponible ; dissociation (accountId→null) → conserver la devise actuelle
- [X] T019 [US2] Tests unitaires DebtService (association compte) dans `api/src/test/java/fr/kksdev/budget/api/service/DebtServiceTest.java` : should_forceCurrency_when_accountProvided, should_useUserCurrency_when_noAccount, should_convertAmount_when_accountCurrencyChanges, should_reject_when_exchangeRateUnavailable, should_keepCurrency_when_accountDissociated, should_reject_when_accountBelongsToOtherUser
- [X] T020 [US2] Tests intégration DebtController (association compte) dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java` : POST /debts avec accountId (201 devise forcée), PUT /debts/{id} changement accountId (200 conversion), PUT /debts/{id} dissociation (200 devise conservée), POST /debts avec account d'un autre user (400)

**Checkpoint**: Association compte ↔ dette fonctionnelle. Devise cohérente automatiquement.

---

## Phase 5: User Story 3 — Inclure une dette dans le patrimoine total (Priority: P3)

**Goal**: L'utilisateur peut choisir d'inclure une dette sans compte dans le calcul du patrimoine total. Un nouvel endpoint retourne le solde global groupé par devise.

**Independent Test**: Activer includeInBalance sur une dette sans compte, appeler GET /accounts/total-balance, vérifier que la dette est reflétée.

### Implementation for User Story 3

- [X] T021 [P] [US3] Créer TotalBalanceResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/response/TotalBalanceResponse.java` : balances (List<CurrencyBalance>)
- [X] T022 [P] [US3] Créer CurrencyBalance (record ou inner class) dans `api/src/main/java/fr/kksdev/budget/api/dto/response/CurrencyBalance.java` : currency (Currency), amount (BigDecimal)
- [X] T023 [US3] Ajouter requêtes au repository `api/src/main/java/fr/kksdev/budget/api/repository/DebtRepository.java` : findByUserIdAndRembourseFalse(UUID userId) pour récupérer toutes les dettes non remboursées (filtrage includeInBalance/account fait côté service)
- [X] T024 [US3] Implémenter AccountService.getTotalBalance(UUID userId) dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java` : pour chaque devise → somme soldes comptes actifs (soldeInitial + calculateBalanceByAccountId), ajuster par TOUTES les dettes non remboursées éligibles : dettes avec compte (automatiquement incluses) + dettes sans compte avec includeInBalance=true (EMPRUNT soustrait montantRestant via TransactionRepository.sumByDebtId, PRET ajoute montantRestant), grouper par devise, trier devise principale en premier
- [X] T025 [US3] Ajouter endpoint GET /accounts/total-balance dans `api/src/main/java/fr/kksdev/budget/api/controller/AccountController.java`
- [X] T026 [US3] Tests unitaires AccountService.getTotalBalance() dans `api/src/test/java/fr/kksdev/budget/api/service/AccountServiceTest.java` : should_sumAccountBalances_when_noDebts, should_subtractEmprunt_when_debtWithAccount, should_addPret_when_debtWithAccount, should_subtractEmprunt_when_includeInBalanceTrue, should_ignoreDebt_when_noAccountAndIncludeInBalanceFalse, should_groupByCurrency_when_multiCurrency
- [X] T027 [US3] Tests intégration AccountController (total-balance) dans `api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java` : GET /accounts/total-balance (200 sans dettes, 200 avec dettes incluses, 200 multi-devise)

**Checkpoint**: Patrimoine total calculé côté serveur. Dettes sans compte incluses/exclues selon le toggle.

---

## Phase 6: User Story 4 — Configurer un rappel sur une dette (Priority: P4)

**Goal**: L'utilisateur peut programmer un rappel (date+heure). Le système envoie une notification à l'heure prévue.

**Independent Test**: Configurer un rappel pour une heure passée, vérifier qu'une notification DEBT_REMINDER est créée au prochain cycle du scheduler.

### Implementation for User Story 4

- [X] T028 [US4] Ajouter requête au repository `api/src/main/java/fr/kksdev/budget/api/repository/DebtRepository.java` : findDueReminders(@Query "SELECT d FROM Debt d WHERE d.user.id = :userId AND d.reminderDate = :date AND d.reminderTime <= :time AND d.rembourse = false") — filtré par userId car chaque utilisateur a sa propre timezone
- [X] T029 [US4] Implémenter checkDebtReminders() dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationScheduler.java` : @Scheduled(cron = "0 * * * * *") chaque minute, pour chaque utilisateur (via userRepository.findAll()) → obtenir timezone via PreferenceService.getUserTimezone(userId), convertir l'heure courante en timezone utilisateur (LocalDate/LocalTime), appeler DebtRepository.findDueReminders(userId, dateInTz, timeInTz), pour chaque dette → vérifier déduplication 24h (existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter avec DEBT_REMINDER), créer notification (titre="Rappel dette - {personne}", message contenant montant restant)
- [X] T030 [US4] Tests unitaires NotificationScheduler.checkDebtReminders() dans `api/src/test/java/fr/kksdev/budget/api/service/NotificationSchedulerTest.java` : should_createNotification_when_reminderDue, should_createNotification_when_reminderInPast, should_skipNotification_when_debtRepaid, should_skipNotification_when_alreadyNotified24h, should_processMultipleDebts_when_multipleDue
- [X] T031 [US4] Tests intégration rappel dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java` : PUT /debts/{id} avec reminderDate+reminderTime (200 champs sauvegardés), POST /debts avec reminder (201 champs présents dans réponse), vérifier que reminderDate et reminderTime sont cohérents (tous deux fournis ou tous deux null)

**Checkpoint**: Rappels de dette fonctionnels. Notifications créées à l'heure configurée.

---

## Phase 7: User Story 5 — Reporter un rappel de dette (Priority: P5)

**Goal**: L'utilisateur peut reporter le rappel d'une dette à une date/heure ultérieure.

**Independent Test**: Configurer un rappel, appeler POST /debts/{id}/snooze avec nouvelle date/heure, vérifier mise à jour.

### Implementation for User Story 5

- [X] T032 [P] [US5] Créer DebtSnoozeRequest dans `api/src/main/java/fr/kksdev/budget/api/dto/request/DebtSnoozeRequest.java` : reminderDate (@NotNull @FutureOrPresent LocalDate), reminderTime (@NotNull LocalTime)
- [X] T033 [US5] Implémenter DebtService.snooze(UUID debtId, DebtSnoozeRequest request, UUID userId) dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java` : valider ownership, vérifier que la dette a un rappel existant (sinon 400), mettre à jour reminderDate et reminderTime, retourner DebtResponse
- [X] T034 [US5] Ajouter endpoint POST /debts/{id}/snooze dans `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`
- [X] T035 [US5] Tests unitaires DebtService.snooze() dans `api/src/test/java/fr/kksdev/budget/api/service/DebtServiceTest.java` : should_updateReminder_when_snooze, should_reject_when_noExistingReminder
- [X] T036 [US5] Tests intégration DebtController (snooze) dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java` : POST /debts/{id}/snooze (200 mise à jour, 400 pas de rappel existant, 404 dette introuvable)

**Checkpoint**: Report de rappel fonctionnel.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validation globale et nettoyage

- [X] T037 Logging INFO dans DebtService pour : remboursement effectué, association compte, rappel configuré/reporté, dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [X] T038 Valider le quickstart : exécuter `cd api && mvn clean test` et vérifier que tous les tests passent

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — migration V18
- **Foundational (Phase 2)**: Depends on Phase 1 — entités, DTOs, repositories
- **User Stories (Phase 3-7)**: Toutes dépendent de Phase 2
  - US1 (P1): Indépendante
  - US2 (P2): Indépendante
  - US3 (P3): Indépendante (nouveau endpoint Account)
  - US4 (P4): Indépendante (scheduler)
  - US5 (P5): Dépend de US4 (rappel doit exister pour être reporté)
- **Polish (Phase 8)**: Après toutes les user stories

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                      ├── US1 (Rembourser) ──────────┐
                      ├── US2 (Assoc. compte) ───────┤
                      ├── US3 (Patrimoine) ──────────┤── Phase 8 (Polish)
                      └── US4 (Rappels) ─────────────┤
                            └── US5 (Reporter) ──────┘
```

### Within Each User Story

- DTOs avant services
- Services avant controllers/endpoints
- Implementation avant tests
- Tests unitaires et intégration dans la même tâche

### Parallel Opportunities

- T002, T003, T004 (entités + enum) en parallèle
- T005, T006, T007 (DTOs) en parallèle après entités
- T010, T011 (DTOs US1) en parallèle
- T021, T022 (DTOs US3) en parallèle
- US1, US2, US3, US4 en parallèle après Phase 2
- US5 après US4

---

## Parallel Example: User Story 1

```bash
# DTOs US1 en parallèle :
Task T010: "Créer DebtRepayRequest dans api/.../dto/request/DebtRepayRequest.java"
Task T011: "Créer DebtPaymentResponse dans api/.../dto/response/DebtPaymentResponse.java"

# Puis séquentiellement :
Task T012: "Implémenter DebtService.repay()"
Task T013: "Implémenter DebtService.getPayments()"
Task T014: "Ajouter endpoints POST repay + GET payments"
Task T015: "Adapter TransactionService.delete() pour recalcul rembourse"
Task T016: "Tests unitaires"
Task T017: "Tests intégration"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Migration V18
2. Phase 2: Entités + DTOs + Repositories enrichis
3. Phase 3: US1 — Remboursement de dette (inclut recalcul après suppression)
4. **STOP and VALIDATE**: Tester POST /debts/{id}/repay + GET /debts/{id}/payments
5. Commit + push

### Incremental Delivery

1. Setup + Foundational → Base prête
2. US1 (Rembourser) → Test → Commit (MVP)
3. US2 (Assoc. compte) → Test → Commit
4. US3 (Patrimoine) → Test → Commit
5. US4 (Rappels) → Test → Commit
6. US5 (Reporter) → Test → Commit
7. Polish → Test final → Commit

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label lie la tâche à la user story pour traçabilité
- Chaque user story est testable indépendamment
- Commit après chaque user story complète
- Le calcul dynamique de montantRestant est le pattern clé (SUM SQL, pas de champ persisté)
- Penser à `/sync-doc` après les commits
