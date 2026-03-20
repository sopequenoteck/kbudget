# Tasks: Transactions Recurrentes & Paiements Abonnements (Backend)

**Input**: Design documents from `/specs/085-recurring-transactions-backend/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-endpoints.md

**Tests**: Inclus (demandes dans la spec KKS-191)

**Organization**: Tasks groupees par user story pour implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependance)
- **[Story]**: User story associee (US1-US5)

---

## Phase 1: Setup

**Purpose**: Migration de base de donnees

- [x] T001 Creer la migration Flyway V20 dans `api/src/main/resources/db/migration/V20__add_recurring_to_transactions.sql` — ajouter 5 colonnes (is_recurring BOOLEAN DEFAULT false, frequency VARCHAR(20), next_occurrence DATE, recurring_active BOOLEAN DEFAULT true, subscription_id UUID FK subscriptions), index partiel sur (user_id, next_occurrence) WHERE is_recurring=true AND recurring_active=true, index sur subscription_id WHERE NOT NULL

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Enrichissement entite, enums, DTOs et queries — BLOQUE toutes les user stories

- [x] T002 [P] Ajouter `RECURRING_TRANSACTION_DUE` dans `api/src/main/java/fr/kksdev/budget/api/enums/NotificationType.java`
- [x] T003 [P] Ajouter `TRANSACTION` dans `api/src/main/java/fr/kksdev/budget/api/enums/EntityType.java`
- [x] T004 Enrichir l'entite Transaction dans `api/src/main/java/fr/kksdev/budget/api/model/Transaction.java` — ajouter isRecurring (Boolean, default false), frequency (Frequency enum, nullable), nextOccurrence (LocalDate, nullable), recurringActive (Boolean, default true), subscription (@ManyToOne FetchType.LAZY vers Subscription, nullable)
- [x] T005 Ajouter les queries dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java` — findByUserIdAndIsRecurringTrueAndRecurringActiveTrueOrderByNextOccurrenceAsc, findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual, findBySubscriptionIdAndUserIdOrderByDateDesc, sumBySubscriptionIdAndUserId (@Query COALESCE SUM). Modifier les queries existantes : `findByUserIdOrderByDateDesc` → `findByUserIdAndIsRecurringFalseOrderByDateDesc`, `findByUserIdAndDateBetweenOrderByDateDesc` → `findByUserIdAndIsRecurringFalseAndDateBetweenOrderByDateDesc` pour exclure les templates recurrents des listings standard (FR-014). Mettre a jour les appels dans `TransactionService` : `getAllByUser()` (L80), `getByMonth()` (L202) et `getMonthlySummary()` (L214) pour utiliser les nouvelles signatures. Adapter les tests existants (`TransactionServiceTest`, `TransactionRepositoryTest`) si necessaire
- [x] T006 [P] Creer le DTO `RecurringTransactionRequest` dans `api/src/main/java/fr/kksdev/budget/api/dto/request/RecurringTransactionRequest.java` — record avec montant (@NotNull @Positive), libelle (@NotBlank @Size max 255), type (@NotNull TransactionType), frequency (@NotNull Frequency), nextOccurrence (@NotNull @FutureOrPresent LocalDate), categoryId (UUID nullable), accountId (UUID nullable), note (@Size max 500 nullable)
- [x] T007 [P] Creer le DTO `RecurringTransactionResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/RecurringTransactionResponse.java` — record avec id (UUID), montant (BigDecimal), libelle (String), type (TransactionType), frequency (Frequency), nextOccurrence (LocalDate), recurringActive (Boolean), category (CategoryResponse nullable), account (AccountSummary nullable)
- [x] T008 [P] Creer le DTO `SubscriptionPaymentResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/SubscriptionPaymentResponse.java` — record avec id (UUID), montant (BigDecimal), date (LocalDate), subscriptionName (String), accountName (String)

**Checkpoint**: Foundation prete — les user stories peuvent demarrer

---

## Phase 3: User Story 1 - Validation d'une transaction recurrente (Priority: P1) + User Story 5 - Consultation (Priority: P3)

**Goal**: Creer, lister et valider des transactions recurrentes. US5 (liste) est incluse car c'est un prerequis fonctionnel de US1.

**Independent Test**: POST /transactions/recurring pour creer, GET /transactions/recurring pour lister, POST /transactions/recurring/{id}/validate pour valider → verifier qu'une transaction est creee et nextOccurrence avancee.

### Implementation

- [x] T009 [US1] Creer `RecurringTransactionService` dans `api/src/main/java/fr/kksdev/budget/api/service/RecurringTransactionService.java` — methodes : create(RecurringTransactionRequest, UUID userId) cree une transaction recurrente template, listActive(UUID userId) retourne les recurrences actives, validate(UUID id, UUID userId) cree une transaction standard + avance nextOccurrence selon frequency. Injecter TransactionRepository, AccountRepository, CategoryRepository, BudgetService. Logique resolveAccount identique a TransactionService (account specifie ou default). Logique avance nextOccurrence : HEBDOMADAIRE +1 semaine, MENSUEL +1 mois, ANNUEL +1 an (java.time natif). Appeler BudgetService.checkThresholdsForCategory si DEPENSE avec categorie (meme pattern que TransactionService). Logger INFO sur create/validate.
- [x] T010 [US1] Creer `RecurringTransactionController` dans `api/src/main/java/fr/kksdev/budget/api/controller/RecurringTransactionController.java` — @RestController @RequestMapping("/transactions/recurring"). Endpoints : POST "/" (201 Created, @Valid RecurringTransactionRequest), GET "/" (200, liste RecurringTransactionResponse), POST "/{id}/validate" (201 Created, retourne TransactionResponse de la nouvelle transaction). Injecter RecurringTransactionService, extraire userId via @AuthenticationPrincipal.

### Tests

- [x] T011 [P] [US1] Tests unitaires `RecurringTransactionServiceTest` dans `api/src/test/java/fr/kksdev/budget/api/service/RecurringTransactionServiceTest.java` — should_createRecurringTransaction_when_validRequest, should_listActiveRecurrences_when_userHasRecurrences, should_returnEmptyList_when_noActiveRecurrences, should_createTransactionAndAdvanceDate_when_validateMonthly, should_createTransactionAndAdvanceDate_when_validateWeekly, should_createTransactionAndAdvanceDate_when_validateYearly, should_throwException_when_validateInactiveRecurrence, should_useDefaultAccount_when_accountIsNull, should_handleEndOfMonth_when_validateMonthlyOn31st
- [x] T012 [P] [US1] Tests @WebMvcTest `RecurringTransactionControllerTest` dans `api/src/test/java/fr/kksdev/budget/api/controller/RecurringTransactionControllerTest.java` — should_return201_when_createRecurringTransaction, should_return400_when_missingFrequency, should_return400_when_missingNextOccurrence, should_return200_when_listRecurringTransactions, should_return201_when_validateRecurrence, should_return404_when_validateNonexistentRecurrence, should_return401_when_notAuthenticated

**Checkpoint**: US1 + US5 fonctionnelles — creer, lister et valider des recurrences

---

## Phase 4: User Story 2 - Paiement d'un abonnement (Priority: P1)

**Goal**: Payer un abonnement, consulter l'historique et le cumul des paiements.

**Independent Test**: POST /subscriptions/{id}/pay → verifier transaction creee avec subscriptionId, GET /subscriptions/{id}/payments → verifier historique, GET /subscriptions/{id}/payments/total → verifier cumul exact.

### Implementation

- [x] T013 [US2] Creer `SubscriptionPaymentService` dans `api/src/main/java/fr/kksdev/budget/api/service/SubscriptionPaymentService.java` — methodes : pay(UUID subscriptionId, UUID userId) cree une Transaction DEPENSE liee (subscriptionId, libelle=sub.nom, montant=sub.montant, category=sub.category, account=sub.account ou default, date=today). dateDebut inchangee — prochaine echeance calculee dynamiquement par getNextDueDate(). getPayments(UUID subscriptionId, UUID userId) retourne les transactions liees triees par date DESC, getTotalPaid(UUID subscriptionId, UUID userId) retourne le cumul via query SUM. Injecter SubscriptionRepository, TransactionRepository, AccountRepository, BudgetService. Appeler BudgetService.checkThresholdsForCategory si categorie presente (meme pattern que T009). Verifier sub.actif avant paiement (sinon exception). Logger INFO sur pay.
- [x] T014 [US2] Ajouter les endpoints de paiement dans `api/src/main/java/fr/kksdev/budget/api/controller/SubscriptionController.java` — POST "/{id}/pay" (201 Created, retourne SubscriptionPaymentResponse), GET "/{id}/payments" (200, List SubscriptionPaymentResponse), GET "/{id}/payments/total" (200, objet avec subscriptionId, subscriptionName, totalPaid BigDecimal, paymentCount int). Injecter SubscriptionPaymentService.

### Tests

- [x] T015 [P] [US2] Tests unitaires `SubscriptionPaymentServiceTest` dans `api/src/test/java/fr/kksdev/budget/api/service/SubscriptionPaymentServiceTest.java` — should_createTransaction_when_payMonthlySubscription, should_createTransaction_when_payAnnualSubscription, should_notModifyDateDebut_when_pay, should_useSubscriptionAccount_when_accountPresent, should_useDefaultAccount_when_subscriptionAccountNull, should_throwException_when_subscriptionInactive, should_throwException_when_subscriptionNotFound, should_returnPayments_when_getPayments, should_returnZero_when_noPayments, should_returnExactTotal_when_getTotalPaid
- [x] T016 [P] [US2] Tests @WebMvcTest pour les endpoints de paiement dans `api/src/test/java/fr/kksdev/budget/api/controller/SubscriptionControllerTest.java` — ajouter : should_return201_when_paySubscription, should_return400_when_payInactiveSubscription, should_return404_when_payNonexistentSubscription, should_return200_when_getPayments, should_return200_when_getTotalPaid. Note : si le fichier test existe deja, ajouter les tests dans le fichier existant. Ajouter `@MockitoBean SubscriptionPaymentService` dans la classe de test existante (actuellement seul `SubscriptionService` est mocke).

**Checkpoint**: US2 fonctionnelle — payer, historique et cumul des paiements d'abonnements

---

## Phase 5: User Story 3 - Notification automatique des echeances (Priority: P2)

**Goal**: Le scheduler quotidien detecte les recurrences et abonnements a echeance et cree des notifications.

**Independent Test**: Creer des recurrences avec nextOccurrence <= today, appeler manuellement le scheduler, verifier que les notifications sont creees (une par recurrence due). Verifier la notification quotidienne persistante (pas de dedup entre jours).

### Implementation

- [x] T017 [US3] Enrichir `NotificationScheduler` dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationScheduler.java` — ajouter un SECOND job @Scheduled dedie `@Scheduled(cron = "0 0 8 * * *") checkRecurringTransactions()` (NE PAS modifier le cron existant 6h de runDailyJob). Ce nouveau job itere les users, appelle processRecurringTransactions(UUID userId, LocalDate today, ZoneId zoneId) : chercher les recurrences actives avec nextOccurrence <= today via `findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(userId, today)`, pour chacune verifier dedup 24h (existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter avec RECURRING_TRANSACTION_DUE), creer notification titre "Transaction recurrente [libelle]" message "[libelle] [montant] [currency] — echeance [date]" entityType=TRANSACTION entityId=transaction.id. Verifier que RECURRING_TRANSACTION_DUE est enabled dans les preferences avant traitement. Le job existant runDailyJob() (6h, notifications abonnements la veille) reste INCHANGE.

### Tests

- [x] T018 [US3] Tests `NotificationSchedulerTest` dans `api/src/test/java/fr/kksdev/budget/api/service/NotificationSchedulerTest.java` — ajouter : should_createNotification_when_recurringTransactionDue, should_notCreateNotification_when_noRecurringDue, should_createNotificationDaily_when_notValidatedYesterday (pas de dedup inter-jours), should_notDuplicate_when_schedulerRunsTwiceSameDay, should_skipNotification_when_recurringTransactionDueDisabled, should_notNotify_when_recurrenceInactive, should_notCreateTransaction_when_schedulerRuns (FR-010 — verifie que le scheduler cree uniquement des notifications, jamais de transactions). Note : si le fichier test existe deja, ajouter les tests dans le fichier existant.

**Checkpoint**: US3 fonctionnelle — scheduler detecte et notifie les echeances

---

## Phase 6: User Story 4 - Passer ou desactiver une recurrence (Priority: P2)

**Goal**: L'utilisateur peut passer une occurrence (skip) ou desactiver completement une recurrence.

**Independent Test**: PATCH /transactions/recurring/{id}/skip → verifier nextOccurrence avancee sans transaction creee. PATCH /transactions/recurring/{id}/deactivate → verifier recurringActive=false et absence de la liste active.

### Implementation

- [x] T019 [US4] Ajouter les methodes skip et deactivate dans `RecurringTransactionService` (`api/src/main/java/fr/kksdev/budget/api/service/RecurringTransactionService.java`) — skip(UUID id, UUID userId) : charger la recurrence (verifier active + user), avancer nextOccurrence selon frequency, sauvegarder, retourner RecurringTransactionResponse. deactivate(UUID id, UUID userId) : charger la recurrence (verifier active + user), mettre recurringActive=false, sauvegarder, retourner RecurringTransactionResponse. Logger INFO sur skip/deactivate.
- [x] T020 [US4] Ajouter les endpoints dans `RecurringTransactionController` (`api/src/main/java/fr/kksdev/budget/api/controller/RecurringTransactionController.java`) — PATCH "/{id}/skip" (200, retourne RecurringTransactionResponse), PATCH "/{id}/deactivate" (200, retourne RecurringTransactionResponse)

### Tests

- [x] T021 [P] [US4] Tests unitaires skip/deactivate dans `RecurringTransactionServiceTest` (`api/src/test/java/fr/kksdev/budget/api/service/RecurringTransactionServiceTest.java`) — ajouter : should_advanceDateWithoutTransaction_when_skip, should_throwException_when_skipInactiveRecurrence, should_setRecurringActiveFalse_when_deactivate, should_throwException_when_deactivateAlreadyInactive
- [x] T022 [P] [US4] Tests @WebMvcTest skip/deactivate dans `RecurringTransactionControllerTest` (`api/src/test/java/fr/kksdev/budget/api/controller/RecurringTransactionControllerTest.java`) — ajouter : should_return200_when_skipRecurrence, should_return400_when_skipInactiveRecurrence, should_return200_when_deactivateRecurrence, should_return404_when_deactivateNonexistent

**Checkpoint**: US4 fonctionnelle — skip et deactivate sur les recurrences

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verification globale et nettoyage

- [x] T023 Verifier que `mvn clean compile` passe sans erreur dans `api/`
- [x] T024 Verifier que `mvn test` passe (tous les tests, existants + nouveaux) dans `api/`
- [x] T025 Executer les scenarios de `quickstart.md` manuellement (curl) pour valider le workflow complet : creer recurrence → valider → verifier transaction creee + nextOccurrence avancee ; payer abonnement → verifier historique + cumul

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dependance — demarrer immediatement
- **Phase 2 (Foundational)**: Depend de Phase 1 — BLOQUE toutes les user stories
- **Phase 3 (US1+US5)**: Depend de Phase 2
- **Phase 4 (US2)**: Depend de Phase 2 — peut etre fait en parallele avec Phase 3
- **Phase 5 (US3)**: Depend de Phase 2 — peut etre fait en parallele avec Phase 3/4
- **Phase 6 (US4)**: Depend de Phase 3 (meme service/controller)
- **Phase 7 (Polish)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1+US5 (P1/P3)**: Depend de la fondation. Pas de dependance sur d'autres stories.
- **US2 (P1)**: Depend de la fondation. Independante de US1 (service/controller differents). Peut etre faite en parallele.
- **US3 (P2)**: Depend de la fondation. Independante fonctionnellement (scheduler). Peut etre faite en parallele.
- **US4 (P2)**: Depend de US1 (meme RecurringTransactionService/Controller). Doit etre faite apres US1.

### Parallel Opportunities

```
Phase 2 complete
    ├── Phase 3 (US1+US5) ──→ Phase 6 (US4)
    ├── Phase 4 (US2)
    └── Phase 5 (US3)
                              ──→ Phase 7 (Polish)
```

---

## Parallel Example: Apres Phase 2

```bash
# Lancer en parallele :
Agent 1: T009-T012 (US1+US5 — RecurringTransactionService + Controller + Tests)
Agent 2: T013-T016 (US2 — SubscriptionPaymentService + endpoints + Tests)
Agent 3: T017-T018 (US3 — Scheduler + Tests)

# Puis sequentiellement :
Agent 1: T019-T022 (US4 — skip/deactivate, depend de US1)
```

---

## Implementation Strategy

### MVP First (US1 + US5)

1. Phase 1: Migration V20
2. Phase 2: Entity + enums + DTOs + queries
3. Phase 3: RecurringTransactionService + Controller (creer, lister, valider)
4. **STOP et VALIDER**: Tester US1 independamment
5. Deployer si pret

### Incremental Delivery

1. Setup + Foundational → fondation prete
2. US1+US5 → creer/lister/valider des recurrences (MVP)
3. US2 → payer des abonnements + historique
4. US3 → scheduler automatique
5. US4 → skip/deactivate
6. Polish → validation globale

---

## Notes

- [P] tasks = fichiers differents, pas de dependance
- Les tests existants (442+) ne doivent pas etre casses par les modifications
- La logique de resolution de compte (resolveAccount) et de calcul de prochaine occurrence doit etre coherente entre RecurringTransactionService, SubscriptionPaymentService et NotificationScheduler
- Le scheduler existant (cron 6h) notifie la veille pour les abonnements. Les recurrences notifient le jour meme (nextOccurrence <= today) — ne pas confondre les deux comportements
- Commit apres chaque phase ou groupe logique de taches
