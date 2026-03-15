# Tasks: Transactions récurrentes & améliorations abonnements (consolidée)

**Input**: Design documents from `/specs/089-recurring-transactions/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/
**Status**: Done (rétroactive — consolide 085/086/087/088)

**Organization**: Tasks groupées par user story. Chaque story est indépendamment testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Migration BDD et enrichissement du modèle de données

- [x] T001 Créer migration Flyway V20 — ajout colonnes récurrences et subscription_id sur transactions in `api/src/main/resources/db/migration/V20__recurring_transactions.sql`
- [x] T002 Enrichir l'entité Transaction — isRecurring, frequency, nextOccurrence, recurringActive, subscription FK, product FK, debt FK in `api/src/main/java/fr/kksdev/budget/api/model/Transaction.java`
- [x] T003 [P] Ajouter NotificationType.RECURRING_TRANSACTION_DUE in `api/src/main/java/fr/kksdev/budget/api/enums/NotificationType.java`
- [x] T004 [P] Ajouter EntityType.RECURRING_TRANSACTION in `api/src/main/java/fr/kksdev/budget/api/enums/EntityType.java`
- [x] T005 [P] Créer RecurringTransactionRequest DTO in `api/src/main/java/fr/kksdev/budget/api/dto/RecurringTransactionRequest.java`
- [x] T006 [P] Créer RecurringTransactionResponse DTO in `api/src/main/java/fr/kksdev/budget/api/dto/RecurringTransactionResponse.java`
- [x] T007 [P] Créer SubscriptionPaymentResponse DTO in `api/src/main/java/fr/kksdev/budget/api/dto/SubscriptionPaymentResponse.java`
- [x] T008 [P] Créer CategoryResponse.from() et AccountSummary.from() static factories (dédupliquent 5 services) in `api/src/main/java/fr/kksdev/budget/api/dto/`
- [x] T009 Ajouter countBySubscriptionIdAndUserId query in `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`
- [x] T010 Exclure les transactions isRecurring=true du listing standard GET /transactions in `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`

**Checkpoint**: Schéma BDD migré, modèle enrichi, DTOs prêts

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Services backend et endpoints — prérequis pour tous les frontends

**⚠️ CRITICAL**: Angular et Flutter dépendent de cette phase

- [x] T011 Implémenter RecurringTransactionService — create, listActive, validate, skip, deactivate in `api/src/main/java/fr/kksdev/budget/api/service/RecurringTransactionService.java`
- [x] T012 Implémenter SubscriptionPaymentService — pay, getPayments, getTotalPaid in `api/src/main/java/fr/kksdev/budget/api/service/SubscriptionPaymentService.java`
- [x] T013 Implémenter RecurringTransactionController — 5 endpoints /transactions/recurring in `api/src/main/java/fr/kksdev/budget/api/controller/RecurringTransactionController.java`
- [x] T014 Enrichir SubscriptionController — +3 endpoints pay/payments/total-paid in `api/src/main/java/fr/kksdev/budget/api/controller/SubscriptionController.java`
- [x] T015 Enrichir NotificationScheduler — +checkRecurringTransactions() job quotidien in `api/src/main/java/fr/kksdev/budget/api/service/NotificationScheduler.java`
- [x] T016 Guard : type de transaction immutable pour les transactions récurrentes in `api/src/main/java/fr/kksdev/budget/api/service/RecurringTransactionService.java`
- [x] T017 [P] Tests service RecurringTransactionService (25 tests) in `api/src/test/java/fr/kksdev/budget/api/service/RecurringTransactionServiceTest.java`
- [x] T018 [P] Tests controller RecurringTransactionController (16 tests) in `api/src/test/java/fr/kksdev/budget/api/controller/RecurringTransactionControllerTest.java`
- [x] T019 [P] Tests SubscriptionPaymentService et SubscriptionController in `api/src/test/java/fr/kksdev/budget/api/`

**Checkpoint**: 488 tests backend passent. API complète et testée — frontends peuvent démarrer

---

## Phase 3: User Story 1 — Valider une transaction récurrente (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur peut valider, passer ou désactiver ses récurrences depuis un écran dédié (Angular + Flutter)

**Independent Test**: Accéder à /transactions/recurring, voir les récurrences avec badges de statut, exécuter les 3 actions

### Angular — Écran récurrences

- [x] T020 [P] [US1] Créer RecurringTransactionService Angular (signal-based, loadActive/validate/skip/deactivate) in `app/src/app/services/recurring-transaction.service.ts`
- [x] T021 [P] [US1] Créer RecurringTransactionResponse interface in `app/src/app/models/recurring-transaction.model.ts`
- [x] T022 [US1] Créer RecurringListComponent — liste triée overdue/today/upcoming, badges colorés, 3 actions in `app/src/app/features/transactions/recurring-list/`
- [x] T023 [US1] Ajouter route /transactions/recurring et lien depuis l'écran Transactions in `app/src/app/app.routes.ts`
- [x] T024 [US1] Ajouter dialogue de confirmation pour désactivation in `app/src/app/features/transactions/recurring-list/recurring-list.component.ts`
- [x] T025 [P] [US1] Tests RecurringListComponent et RecurringTransactionService (9 tests) in `app/src/app/features/transactions/recurring-list/recurring-list.component.spec.ts`

### Flutter — Écran récurrences

- [x] T026 [P] [US1] Créer RecurringTransaction model (réutilise Transaction enrichi) in `flutter/lib/src/domain/models/`
- [x] T027 [P] [US1] Créer RecurringTransactionRemoteDataSource in `flutter/lib/src/features/recurring/data/recurring_transaction_remote_data_source.dart`
- [x] T028 [P] [US1] Créer RecurringTransactionRepository (interface + remote) in `flutter/lib/src/features/recurring/data/`
- [x] T029 [US1] Créer RecurringListNotifier — validate, skip, deactivate (Notifier custom non-CRUD) in `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart`
- [x] T030 [US1] Créer RecurringListScreen — liste avec skeleton loading, badges, swipe + long press in `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart`
- [x] T031 [US1] Ajouter route /recurring dans go_router in `flutter/lib/src/routing/`
- [x] T032 [US1] Gérer état vide et erreurs réseau (snackbar) in `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart`
- [x] T033 [P] [US1] Tests RecurringListNotifier (12 tests) in `flutter/test/src/features/recurring/`

**Checkpoint**: US1 fonctionnelle — récurrences consultables et actionnables sur les 2 plateformes

---

## Phase 4: User Story 2 — Payer un abonnement et suivre les paiements (Priority: P1)

**Goal**: L'utilisateur peut payer un abonnement et consulter l'historique des paiements + total cumulé

**Independent Test**: Ouvrir le détail d'un abonnement, voir les paiements passés, cliquer "Payer", vérifier la mise à jour

### Angular — Détail abonnement enrichi

- [x] T034 [US2] Enrichir SubscriptionService — +pay(), getPayments(), getTotalPaid() in `app/src/app/services/subscription.service.ts`
- [x] T035 [US2] Créer SubscriptionDetailComponent — section paiements, total cumulé, bouton "Payer" in `app/src/app/features/subscriptions/subscription-detail/`
- [x] T036 [US2] Ajouter route /subscriptions/:id et câblage depuis SubscriptionList in `app/src/app/app.routes.ts`
- [x] T037 [US2] Gérer état vide paiements et feedback toast in `app/src/app/features/subscriptions/subscription-detail/`
- [x] T038 [P] [US2] Tests SubscriptionDetailComponent (5 tests) in `app/src/app/features/subscriptions/subscription-detail/subscription-detail.component.spec.ts`

### Flutter — Détail abonnement enrichi

- [x] T039 [P] [US2] Créer SubscriptionPayment model (Freezed) in `flutter/lib/src/domain/models/subscription_payment.dart`
- [x] T040 [US2] Enrichir SubscriptionRemoteDataSource — +pay(), getPayments(), getTotalPaid() in `flutter/lib/src/features/subscriptions/data/`
- [x] T041 [US2] Créer SubscriptionDetailScreen — historique paiements, total cumulé, bouton "Payer" in `flutter/lib/src/features/subscriptions/presentation/subscription_detail_screen.dart`
- [x] T042 [US2] Ajouter route /subscriptions/:id in `flutter/lib/src/routing/`
- [x] T043 [P] [US2] Tests SubscriptionDetailScreen et notifier (8 tests) in `flutter/test/src/features/subscriptions/`

**Checkpoint**: US2 fonctionnelle — paiements abonnements traçables sur les 2 plateformes

---

## Phase 5: User Story 3 — Créer et convertir des récurrences (Priority: P2)

**Goal**: L'utilisateur peut créer une récurrence depuis le formulaire et convertir une transaction existante

**Independent Test**: Activer le toggle récurrence dans le formulaire, créer la récurrence. Depuis la liste, cliquer "Rendre récurrente".

### Angular — Formulaire enrichi

- [x] T044 [US3] Créer RecurringTransactionRequest interface + RecurringTransactionService.create() in `app/src/app/services/recurring-transaction.service.ts`
- [x] T045 [US3] Enrichir TransactionForm — toggle isRecurring, champs frequency + nextOccurrence (mode création uniquement) in `app/src/app/features/transactions/transaction-form/transaction-form.component.ts`
- [x] T046 [US3] Ajouter ModalService.asRecurring signal + action "Rendre récurrente" dans la liste transactions in `app/src/app/services/modal.service.ts`
- [x] T047 [US3] Implémenter le pré-remplissage du formulaire depuis une transaction existante (icône phosphorRepeat) in `app/src/app/features/transactions/transaction-list/`
- [x] T048 [US3] Validation : date nextOccurrence >= aujourd'hui, fréquence par défaut MENSUEL in `app/src/app/features/transactions/transaction-form/`
- [x] T049 [P] [US3] Tests formulaire récurrence (4 tests) in `app/src/app/features/transactions/transaction-form/transaction-form.component.spec.ts`

### Flutter — Formulaire enrichi

- [x] T050 [US3] Enrichir TransactionForm — toggle isRecurring, champs frequency + nextOccurrence in `flutter/lib/src/features/transactions/presentation/transaction_form_screen.dart`
- [x] T051 [US3] Implémenter création via RecurringTransactionRemoteDataSource.create() in `flutter/lib/src/features/recurring/data/`
- [x] T052 [US3] Action "Rendre récurrente" depuis la liste des transactions (pré-remplissage) in `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart`
- [x] T053 [P] [US3] Tests formulaire récurrence (6 tests) in `flutter/test/src/features/transactions/`

**Checkpoint**: US3 fonctionnelle — création et conversion de récurrences sur les 2 plateformes

---

## Phase 6: User Story 4 — Notifications et écran de gestion (Priority: P2)

**Goal**: Le scheduler crée des notifications d'échéance et l'utilisateur agit directement depuis le panneau de notifications

**Independent Test**: Vérifier la création de notifications par le scheduler, agir depuis le panneau (Valider/Passer/Payer)

### Angular — Notifications enrichies

- [x] T054 [US4] Enrichir NotificationPanel — actions contextuelles RECURRING_TRANSACTION_DUE (Valider/Passer) in `app/src/app/features/notifications/notification-panel/notification-panel.component.ts`
- [x] T055 [US4] Enrichir NotificationPanel — action SUBSCRIPTION_DUE (Payer) in `app/src/app/features/notifications/notification-panel/notification-panel.component.ts`
- [x] T056 [US4] Ajouter navigation sur tap notification vers /transactions/recurring ou /subscriptions/:id in `app/src/app/features/notifications/notification-panel/`
- [x] T057 [P] [US4] Tests NotificationPanel enrichi (4 tests) in `app/src/app/features/notifications/notification-panel/notification-panel.component.spec.ts`

### Flutter — Notifications enrichies

- [x] T058 [P] [US4] Ajouter EntityType.BUDGET, TRANSACTION + NotificationType.budgetThreshold, budgetExceeded in `flutter/lib/src/domain/enums/`
- [x] T059 [US4] Enrichir NotificationPanel — actions RECURRING_TRANSACTION_DUE (Valider/Passer) in `flutter/lib/src/features/notifications/presentation/notification_panel.dart`
- [x] T060 [US4] Enrichir NotificationPanel — action SUBSCRIPTION_DUE (Payer) in `flutter/lib/src/features/notifications/presentation/notification_panel.dart`
- [x] T061 [US4] Ajouter navigation deep link depuis notifications vers /recurring ou /subscriptions/:id ou /budgets in `flutter/lib/src/features/notifications/presentation/notification_panel.dart`
- [x] T062 [P] [US4] Tests NotificationPanel enrichi (8 tests) in `flutter/test/src/features/notifications/`

**Checkpoint**: US4 fonctionnelle — workflow notification → action complet sur les 2 plateformes

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transverses et validation finale

- [x] T063 [P] Empêcher double soumission — désactiver boutons pendant appels (Angular + Flutter) in composants d'action (récurrences + paiements)
- [x] T064 [P] Skeleton loading shimmer sur écran récurrences Flutter in `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart`
- [x] T065 [P] Localisation Flutter — 18 clés l10n pour récurrences et paiements in `flutter/lib/src/localization/`
- [x] T066 Valider que GET /transactions ne retourne pas les templates isRecurring=true (test d'intégration) in `api/src/test/`
- [x] T067 Run quickstart.md validation — tester les 8 endpoints curl

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — migration et modèle en premier
- **Foundational (Phase 2)**: Dépend de Phase 1 — services et endpoints backend
- **US1 (Phase 3)**: Dépend de Phase 2 — écran récurrences Angular + Flutter
- **US2 (Phase 4)**: Dépend de Phase 2 — détail abonnement Angular + Flutter
- **US3 (Phase 5)**: Dépend de Phase 2 — formulaire récurrence Angular + Flutter
- **US4 (Phase 6)**: Dépend de Phase 2 + US1/US2 — notifications avec actions
- **Polish (Phase 7)**: Dépend de toutes les US

### User Story Dependencies

- **US1 (P1)**: Indépendante — peut démarrer après Phase 2
- **US2 (P1)**: Indépendante — peut démarrer après Phase 2
- **US3 (P2)**: Indépendante — peut démarrer après Phase 2
- **US4 (P2)**: Dépend de US1 et US2 (actions Valider/Passer/Payer dans les notifications)

### Within Each User Story

- Angular et Flutter peuvent être développés en parallèle
- Modèles/DTOs avant services
- Services avant composants UI
- Tests en parallèle des composants

### Parallel Opportunities

- T003/T004/T005/T006/T007/T008 — tous les DTOs et enums en parallèle
- T017/T018/T019 — tous les tests backend en parallèle
- US1 Angular (T020-T025) ∥ US1 Flutter (T026-T033)
- US2 Angular (T034-T038) ∥ US2 Flutter (T039-T043)
- US3 Angular (T044-T049) ∥ US3 Flutter (T050-T053)
- US4 Angular (T054-T057) ∥ US4 Flutter (T058-T062)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (migration V20 + modèle) ✅
2. Phase 2: Foundational (services + endpoints backend) ✅
3. Phase 3: US1 — écran récurrences (valider/passer/désactiver) ✅
4. **VALIDATE**: Test indépendant US1 ✅

### Incremental Delivery

1. Setup + Foundational → Backend complet ✅ (488 tests)
2. US1 → Écran récurrences ✅ (Angular 375 + Flutter 626 tests)
3. US2 → Paiements abonnements ✅
4. US3 → Formulaire création + conversion ✅ (Angular 379 tests)
5. US4 → Notifications enrichies ✅

---

## Notes

- Spec rétroactive : toutes les 67 tâches sont complétées ([x])
- Consolide les 104 tâches atomiques des specs 085/086/087/088 en 67 tâches regroupées
- Tests : 488 backend + 379 Angular + 626 Flutter = 1493 tests au total
