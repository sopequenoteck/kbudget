# Tasks: Améliorations dettes — compte bancaire, solde, rappels, remboursement

**Input**: Design documents from `/specs/080-debt-enhancements/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/api-endpoints.md, research.md
**Tests**: Inclus (feature critique avec logique métier complexe)
**Organization**: Tasks groupées par user story pour implémentation et test indépendants. Chaque US couvre les 3 modules (backend → Angular → Flutter).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1–US5)
- Chemins exacts inclus dans chaque description

## Path Conventions

- **Backend**: `api/src/main/java/fr/kksdev/budget/api/`
- **Angular**: `app/src/app/`
- **Flutter**: `flutter/lib/src/`
- **Tests backend**: `api/src/test/java/fr/kksdev/budget/api/`
- **Tests Angular**: `app/src/app/features/debts/__tests__/`
- **Tests Flutter**: `flutter/test/src/features/debts/`

---

## Phase 1: Setup (Infrastructure partagée)

**Purpose**: Migration DB, enrichissement entité Debt, DTOs de base

- [x] T001 Créer la migration Flyway V18 : ajout colonnes `account_id`, `include_in_balance`, `reminder_date`, `reminder_time` sur `debts` + colonne `debt_id` sur `transactions` + index dans `api/src/main/resources/db/migration/V18__debt_enhancements.sql`
- [x] T002 Enrichir l'entité Debt JPA : ajouter champs `account` (ManyToOne Account), `includeInBalance`, `reminderDate`, `reminderTime` dans `api/src/main/java/fr/kksdev/budget/api/model/Debt.java`
- [x] T003 Enrichir l'entité Transaction JPA : ajouter champ `debt` (ManyToOne Debt) dans `api/src/main/java/fr/kksdev/budget/api/model/Transaction.java`
- [x] T004 [P] Créer/enrichir les DTOs backend : `DebtRequest` (+accountId, includeInBalance, reminderDate, reminderTime), `DebtResponse` (+montantRestant, accountId, accountName, includeInBalance, reminder*), `DebtRepayRequest` (accountId, amount), `DebtSnoozeRequest` (reminderDate, reminderTime), `DebtPaymentResponse` (id, amount, date, accountName) dans `api/src/main/java/fr/kksdev/budget/api/dto/`
- [x] T005 [P] Ajouter les queries au TransactionRepository : `sumByDebtId()`, `sumByDebtIds()`, `findByDebtIdOrderByDateDesc()` dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`
- [x] T006 [P] Ajouter les queries au DebtRepository : `findDueReminders()`, `findUsersWithActiveReminders()`, `findByIdForUpdate()` (pessimistic lock) dans `api/src/main/java/fr/kksdev/budget/api/repository/DebtRepository.java`

**Checkpoint**: Schéma DB prêt, entités et DTOs en place, queries disponibles

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Logique métier partagée dans DebtService (toResponse, currency forcing, buildPaidMap) utilisée par TOUTES les user stories

**CRITICAL**: Pas d'implémentation US possible avant cette phase

- [x] T007 Enrichir `DebtService.create()` : support accountId (forçage devise, includeInBalance=false si compte), reminderDate/reminderTime (validation XOR), fallback devise utilisateur dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T008 Enrichir `DebtService.update()` : conversion devise lors du changement de compte (via taux de change), conversion des paiements liés, dissociation de compte dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T009 Enrichir `DebtService.delete()` : détacher et annoter les transactions liées (debt_id=null) dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T010 Implémenter les helpers DebtService : `toResponse()` (calcul montantRestant), `buildPaidMap()` (batch query anti-N+1), `findPivotRate()` (lookup bi-directionnel taux de change) dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T011 [P] Enrichir le modèle Freezed Debt Flutter : ajouter `accountId`, `accountName`, `includeInBalance`, `dueDate`, `reminderDate`, `reminderTime`, `remainingAmount` dans `flutter/lib/src/domain/models/debt.dart`
- [x] T012 [P] Enrichir les DTOs Debt Flutter : mettre à jour `DebtResponse` mapping (nouveaux champs), `DebtRequest` mapping dans `flutter/lib/src/data/remote/dtos/debt_dtos.dart`
- [x] T013 [P] Enrichir le modèle Angular Debt : ajouter interfaces `DebtRepayRequest`, `DebtPaymentResponse`, `DebtSnoozeRequest` + champs Debt (montantRestant, accountId, accountName, includeInBalance, reminder*) dans `app/src/app/core/models/debt.model.ts`

**Checkpoint**: Foundation prête — implémentation des user stories peut commencer

---

## Phase 3: User Story 1 — Rembourser une dette (Priority: P1) MVP

**Goal**: L'utilisateur rembourse partiellement ou totalement une dette. Une transaction liée est créée automatiquement, le montant restant est mis à jour, et la dette est marquée remboursée au solde zéro.

**Independent Test**: Créer une dette de 200€, rembourser 50€ → montant restant 150€. Rembourser 150€ → badge "Remboursé".

### Backend US1

- [x] T014 [US1] Implémenter `DebtService.repay()` : validation (non remboursé, montant <= restant, compte actif), création Transaction (DEPENSE pour EMPRUNT / RECETTE pour PRET), auto-marquage rembourse=true si restant=0, pessimistic lock dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T015 [US1] Ajouter endpoint `POST /debts/{id}/repay` dans `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`
- [x] T016 [P] [US1] Tests DebtService repay : partiel, total, amount=null (full remaining), montant > restant, déjà remboursé, compte inactif, amount=0 dans `api/src/test/java/fr/kksdev/budget/api/service/DebtServiceTest.java`
- [x] T017 [P] [US1] Tests DebtController repay : 200 partiel, 200 total, 400 montant excessif, 400 déjà remboursé, 404 non trouvé dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java`

### Angular US1

- [x] T018 [US1] Ajouter `repay()` au DebtService Angular + `refreshTrigger` signal dans `app/src/app/core/services/debt.ts`
- [x] T019 [US1] Créer RepayDialog : formulaire compte + montant, validation max=montantRestant, auto-fill restant, appel DebtService.repay() dans `app/src/app/features/debts/components/repay-dialog/repay-dialog.ts`
- [x] T020 [P] [US1] Tests RepayDialog : prefill montant, validation min/max, preselection compte, submit payload, form invalide bloqué, erreur API dans `app/src/app/features/debts/__tests__/repay-dialog.spec.ts`

### Flutter US1

- [x] T021 [US1] Créer modèle DebtPayment (Freezed) dans `flutter/lib/src/domain/models/debt_payment.dart`
- [x] T022 [US1] Ajouter méthodes `repay()` au data layer : DebtRemoteDataSource + DebtRepositoryRemote + DebtRepository (interface, throws en local) dans `flutter/lib/src/data/remote/data_sources/debt_remote_data_source.dart`, `flutter/lib/src/features/debts/data/debt_repository_remote.dart`, `flutter/lib/src/domain/repositories/debt_repository.dart`
- [x] T023 [US1] Créer DTOs `RepayRequest` (Freezed) dans `flutter/lib/src/data/remote/dtos/debt_dtos.dart`
- [x] T024 [US1] Ajouter `repay()` au DebtNotifier : update state.mutatingIds, refresh pagination dans `flutter/lib/src/features/debts/application/debt_notifier.dart`
- [x] T025 [US1] Créer RepayBottomSheet : SelectPicker compte, montant avec DecimalTextInputFormatter, validation, SnackBar feedback dans `flutter/lib/src/features/debts/presentation/widgets/repay_bottom_sheet.dart`
- [x] T026 [P] [US1] Tests DebtNotifier repay : full, partiel, auto-marquage remboursé, erreur, mutatingIds dans `flutter/test/src/features/debts/application/debt_notifier_test.dart`

**Checkpoint**: Remboursement fonctionnel sur les 3 plateformes

---

## Phase 4: User Story 2 — Associer une dette à un compte bancaire (Priority: P1)

**Goal**: L'utilisateur attache une dette à un compte. La devise est forcée à celle du compte. Conversion automatique si devise différente.

**Independent Test**: Créer une dette sans compte, l'associer à un compte EUR → devise forcée. Associer à un compte USD → conversion du montant.

### Backend US2

- [x] T027 [US2] Enrichir endpoints CRUD dette existants pour supporter accountId, currency forcing, includeInBalance dans `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`
- [x] T028 [P] [US2] Tests DebtService account association : forçage devise, conversion montant, conversion paiements, taux indisponible, dissociation dans `api/src/test/java/fr/kksdev/budget/api/service/DebtServiceTest.java`
- [x] T029 [P] [US2] Tests DebtController account association : POST avec accountId 201, PUT changement compte 200 dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java`

### Angular US2

- [x] T030 [US2] Enrichir DebtForm : champ accountId (select), currency forcing via valueChanges, includeInBalance auto-set. Inclut aussi le scaffolding des champs reminderDate/reminderTime (réutilisés par US5) dans `app/src/app/features/debts/components/debt-form/debt-form.ts`
- [x] T031 [P] [US2] Tests DebtForm : currency forcing, includeInBalance auto, prefill edit, validation dans `app/src/app/features/debts/__tests__/debt-form.spec.ts`

### Flutter US2

- [x] T032 [US2] Enrichir DebtForm Flutter : SelectPicker compte, currency forcing (_forcedCurrency), includeInBalance switch (masqué si compte), reminderDate/reminderTime pickers dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`

**Checkpoint**: Association compte-dette fonctionnelle, devise forcée, conversion automatique

---

## Phase 5: User Story 3 — Consulter l'historique des paiements (Priority: P2)

**Goal**: L'utilisateur consulte le détail d'une dette et voit l'historique complet des paiements avec une barre de progression.

**Independent Test**: Effectuer 3 remboursements partiels → vérifier que les 3 paiements apparaissent avec date, montant, compte. Barre de progression reflète le ratio.

### Backend US3

- [x] T033 [US3] Implémenter `DebtService.getPayments()` dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T034 [US3] Ajouter endpoint `GET /debts/{id}/payments` dans `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`
- [x] T035 [P] [US3] Tests endpoint payments : 200 avec historique, 200 liste vide, 404 dette non trouvée dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java`

### Angular US3

- [x] T036 [US3] Ajouter `getPayments()` au DebtService Angular dans `app/src/app/core/services/debt.ts`
- [x] T037 [US3] Créer DebtDetailComponent : route /debts/:id, chargement dette + payments async, progress bar (computed progressPercent), badge "Remboursé", montant restant, actions (repay/snooze/edit), gestion erreur 404/500 dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`
- [x] T038 [US3] Ajouter route `:id` lazy-loaded vers DebtDetail dans `app/src/app/features/debts/debts.routes.ts`
- [x] T039 [US3] Enrichir DebtList : navigation vers /debts/:id au clic, computed activeDebts/totalByCurrency, refresh via effect() dans `app/src/app/features/debts/debts.ts`
- [x] T040 [P] [US3] Tests DebtDetail : affichage dette, progress bar, badge remboursé, 404 redirect, 500 retry dans `app/src/app/features/debts/__tests__/debt-detail.spec.ts`

### Flutter US3

- [x] T041 [US3] Ajouter méthodes `getPayments()` au data layer Flutter : DebtRemoteDataSource + DebtRepositoryRemote + DTOs PaymentResponse dans `flutter/lib/src/data/remote/data_sources/debt_remote_data_source.dart`, `flutter/lib/src/data/remote/dtos/debt_dtos.dart`
- [x] T042 [US3] Créer `debtPaymentsProvider` (FutureProvider.family) + `getDebtById()` cache helper dans `flutter/lib/src/features/debts/application/debt_notifier.dart`
- [x] T043 [US3] Créer DebtDetailScreen : progress bar, badges (EMPRUNT/PRET + REMBOURSÉ), montant initial/restant, info section (date, devise, compte, échéance, catégorie, inclusion patrimoine, rappel), section paiements, boutons Rembourser/Reporter/Modifier, skeleton loading dans `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart`
- [x] T044 [US3] Ajouter route `/debts/:id` dans GoRouter (rootNavigatorKey, extra: Debt?) dans `flutter/lib/src/routing/app_router.dart`
- [x] T045 [US3] Câbler navigation DebtListScreen → DebtDetailScreen au tap dans `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`
- [x] T046 [P] [US3] Tests debtPaymentsProvider : chargement, liste vide, erreur API dans `flutter/test/src/features/debts/application/debt_notifier_test.dart`
- [x] T047 [P] [US3] Ajouter clés de localisation debt detail (18 clés) dans `flutter/lib/src/localization/`

**Checkpoint**: Détail dette avec historique et progression fonctionnel sur les 3 plateformes

---

## Phase 6: User Story 4 — Inclure/exclure une dette du patrimoine (Priority: P2)

**Goal**: L'utilisateur peut inclure une dette sans compte dans le calcul du solde total. Les dettes avec compte sont automatiquement incluses.

**Independent Test**: Créer une dette sans compte, activer toggle → vérifier impact sur GET /accounts/total-balance.

### Backend US4

- [x] T048 [US4] Implémenter `AccountService.getTotalBalance()` : agrégation comptes actifs + dettes éligibles par devise (PRET→+, EMPRUNT→-), batch query sumByDebtIds() dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T049 [US4] Créer DTOs `TotalBalanceResponse` + `CurrencyBalance` dans `api/src/main/java/fr/kksdev/budget/api/dto/`
- [x] T050 [US4] Ajouter endpoint `GET /accounts/total-balance` dans `api/src/main/java/fr/kksdev/budget/api/controller/AccountController.java`
- [x] T051 [P] [US4] Tests AccountService getTotalBalance : multi-devises, dettes incluses/exclues, EMPRUNT/PRET dans `api/src/test/java/fr/kksdev/budget/api/service/AccountServiceTest.java`

### Angular US4

- [x] T052 [US4] Validation croisée : confirmer que le toggle includeInBalance (implémenté dans T030) est masqué quand un compte est sélectionné et visible sinon dans `app/src/app/features/debts/components/debt-form/debt-form.ts`

### Flutter US4

- [x] T053 [US4] Validation croisée : confirmer que le switch includeInBalance (implémenté dans T032) est masqué quand un compte est sélectionné, et que la valeur est affichée dans DebtDetailScreen dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`

**Checkpoint**: Patrimoine reflète correctement les dettes éligibles

---

## Phase 7: User Story 5 — Configurer des rappels de dette avec actions (Priority: P3)

**Goal**: L'utilisateur configure un rappel sur une dette. À l'échéance, une notification est créée avec actions "Reporter" et "Rembourser".

**Independent Test**: Configurer un rappel → attendre l'échéance → vérifier notification avec actions → tester Reporter et Rembourser.

### Backend US5

- [x] T054 [US5] Implémenter `DebtService.snooze()` : validation rappel existant, mise à jour reminderDate/reminderTime dans `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java`
- [x] T055 [US5] Ajouter endpoint `POST /debts/{id}/snooze` dans `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`
- [x] T056 [US5] Implémenter `NotificationScheduler.checkDebtReminders()` : fixedDelay 60s, lookup utilisateurs avec rappels actifs, vérification timezone, déduplication 24h, création notification DEBT_REMINDER dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationScheduler.java`
- [x] T057 [US5] Ajouter `NotificationType.DEBT_REMINDER` à l'enum (si pas déjà présent) dans `api/src/main/java/fr/kksdev/budget/api/enums/NotificationType.java`
- [x] T058 [P] [US5] Tests DebtService snooze : mise à jour réussie, rejet sans rappel existant dans `api/src/test/java/fr/kksdev/budget/api/service/DebtServiceTest.java`
- [x] T059 [P] [US5] Tests NotificationScheduler debt reminders : création notification, skip si remboursé, skip si déjà notifié 24h, skip si type désactivé, multi-dettes dans `api/src/test/java/fr/kksdev/budget/api/service/NotificationSchedulerTest.java`
- [x] T060 [P] [US5] Tests DebtController snooze : 200 réussi, 400 sans rappel, 404 non trouvé dans `api/src/test/java/fr/kksdev/budget/api/controller/DebtControllerTest.java`

### Angular US5

- [x] T061 [US5] Ajouter `snooze()` au DebtService Angular dans `app/src/app/core/services/debt.ts`
- [x] T062 [US5] Créer SnoozeDialog : date future (futureDateValidator), heure, prefill depuis dette, appel DebtService.snooze() dans `app/src/app/features/debts/components/snooze-dialog/snooze-dialog.ts`
- [x] T063 [US5] Intégrer SnoozeDialog dans DebtDetail : bouton conditionnel (visible si reminderDate), output snoozed → refresh + toast dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`
- [x] T064 [P] [US5] Tests SnoozeDialog : validation date requise/future, prefill, submit payload, erreur API, cancel dans `app/src/app/features/debts/__tests__/snooze-dialog.spec.ts`

### Flutter US5

- [x] T065 [US5] Ajouter méthodes `snooze()` au data layer Flutter : DTOs SnoozeRequest + DebtRemoteDataSource + DebtRepositoryRemote dans `flutter/lib/src/data/remote/dtos/debt_dtos.dart`, `flutter/lib/src/data/remote/data_sources/debt_remote_data_source.dart`
- [x] T066 [US5] Ajouter `snooze()` au DebtNotifier dans `flutter/lib/src/features/debts/application/debt_notifier.dart`
- [x] T067 [US5] Créer SnoozeDialog Flutter : date future + heure (défaut 09:00), validation, SnackBar feedback dans `flutter/lib/src/features/debts/presentation/widgets/snooze_dialog.dart`
- [x] T068 [US5] Intégrer actions Rembourser/Reporter dans NotificationPanel : trailing icons sur notifications dette, fetch debt → open RepayBottomSheet/SnoozeDialog, mark as read dans `flutter/lib/src/features/notifications/presentation/notification_panel.dart`
- [x] T069 [P] [US5] Tests DebtNotifier snooze : mise à jour réussie, erreur, mutatingIds dans `flutter/test/src/features/debts/application/debt_notifier_test.dart`
- [x] T070 [P] [US5] Ajouter clés de localisation snooze + notification actions (12 clés) dans `flutter/lib/src/localization/`

**Checkpoint**: Rappels avec notifications et actions fonctionnels sur les 3 plateformes

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Cohérence multi-plateforme, toast feedback, code generation

- [x] T071 [P] Ajouter toast/SnackBar feedback sur repay et snooze dans DebtDetail Angular (success avec montant restant ou "Remboursé") dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`
- [x] T072 [P] Exécuter `dart run build_runner build --delete-conflicting-outputs` pour regénérer les fichiers .g.dart et .freezed.dart dans `flutter/`
- [x] T073 [P] Vérifier les tests backend : `cd api && mvn test`
- [x] T074 [P] Vérifier les tests Angular : `cd app && ng test`
- [x] T075 [P] Vérifier les tests Flutter : `cd flutter && flutter test test/src/features/debts/`
- [x] T076 Valider le flux quickstart.md : exécuter les 8 étapes de test manuel

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut démarrer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **US1 Repay (Phase 3)**: Dépend de Phase 2 — MVP
- **US2 Account (Phase 4)**: Dépend de Phase 2 — parallélisable avec US1
- **US3 History (Phase 5)**: Dépend de Phase 2 + US1 (pour avoir des paiements à afficher)
- **US4 Balance (Phase 6)**: Dépend de Phase 2 + US2 (pour le toggle includeInBalance)
- **US5 Reminders (Phase 7)**: Dépend de Phase 2 — parallélisable avec US1/US2
- **Polish (Phase 8)**: Dépend de toutes les phases US terminées

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
    ├── US1 (P1 Repay)  ──────→  US3 (P2 History) ← needs payments to display
    ├── US2 (P1 Account) ─────→  US4 (P2 Balance) ← needs includeInBalance toggle
    └── US5 (P3 Reminders) ← independent
    ↓
Phase 8 (Polish)
```

### Within Each User Story

- Backend avant frontends (API-First, Constitution I)
- Tests backend en parallèle des tests frontend
- Models → Data layer → Notifier/Service → UI (bottom-up)

### Parallel Opportunities

**Phase 1** : T004, T005, T006 en parallèle (fichiers différents)
**Phase 2** : T011, T012, T013 en parallèle (Flutter/Angular, fichiers différents)
**Phase 3 (US1)** : T016+T017 en parallèle, T020+T026 en parallèle
**Phase 4 (US2)** : T028+T029 en parallèle, T031 en parallèle
**Phase 5 (US3)** : T040+T046+T047 en parallèle
**Phase 7 (US5)** : T058+T059+T060 en parallèle, T069+T070 en parallèle
**Phase 8** : T071–T075 tous en parallèle

---

## Parallel Example: User Story 1

```bash
# Backend en premier (API-First):
Task T014: DebtService.repay()
Task T015: POST /debts/{id}/repay endpoint

# Tests backend en parallèle:
Task T016: Tests service repay
Task T017: Tests controller repay

# Puis Angular et Flutter en parallèle:
# Angular:
Task T018: DebtService.repay() Angular
Task T019: RepayDialog
Task T020: Tests RepayDialog

# Flutter (en parallèle avec Angular):
Task T021: DebtPayment model
Task T022: Data layer repay
Task T023: RepayRequest DTO
Task T024: DebtNotifier.repay()
Task T025: RepayBottomSheet
Task T026: Tests notifier repay
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (migration + entités + DTOs)
2. Compléter Phase 2: Foundational (DebtService helpers, modèles frontend)
3. Compléter Phase 3: US1 Repay (backend → Angular → Flutter)
4. **STOP et VALIDER**: Tester le remboursement sur les 3 plateformes
5. Le remboursement fonctionne indépendamment de toutes les autres features

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1 (Repay) → Test → **MVP livrable**
3. US2 (Account) → Test → Association compte fonctionnelle
4. US3 (History) → Test → Détail dette avec progression
5. US4 (Balance) → Test → Patrimoine reflète les dettes
6. US5 (Reminders) → Test → Notifications et actions
7. Polish → Validation complète

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [US*] = label story pour traçabilité
- Chaque US testable indépendamment
- Commit après chaque task ou groupe logique
- Feature déjà implémentée — ces tasks documentent l'implémentation réalisée (KKS-194, KKS-195, KKS-196)
