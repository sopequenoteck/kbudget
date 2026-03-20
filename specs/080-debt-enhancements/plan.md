# Implementation Plan: Améliorations dettes — compte bancaire, solde, rappels, remboursement

**Branch**: `080-debt-enhancements` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/080-debt-enhancements/spec.md`

**Note**: Les 3 sous-tâches (backend KKS-194, Angular KKS-195, Flutter KKS-196) sont terminées. Ce plan documente l'implémentation réalisée.

## Summary

Enrichissement complet de la gestion des dettes : remboursement partiel/total avec création automatique de transactions liées, association optionnelle à un compte bancaire avec forçage de devise et conversion, toggle d'inclusion dans le patrimoine, rappels avec notifications DEBT_REMINDER et actions (reporter/rembourser), historique des paiements avec barre de progression, et agrégation du solde total multi-devises incluant les dettes éligibles.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio, Phosphor Icons
**Storage**: PostgreSQL 15+ (Flyway V18), SQLite/Drift non utilisé (server-only pour les opérations de dette)
**Testing**: JUnit 5 + Mockito (backend, ~58 tests), Vitest (Angular, ~59 tests), flutter_test (Flutter, 30 tests)
**Target Platform**: Web PWA (Angular) + Mobile natif (Flutter) + API REST (Spring Boot)
**Project Type**: Monorepo web-service + mobile-app
**Performance Goals**: N/A (single-user, self-hosted)
**Constraints**: Server-only pour repay/snooze/payments (pas de mode local Drift — opérations atomiques nécessitant cohérence serveur)
**Scale/Scope**: 3 modules (api, app, flutter), 9 endpoints, ~147 tests liés à la feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | 9 endpoints REST créés avant les frontends. DTOs séparent API/persistance (DebtRequest/DebtResponse, RepayRequest, SnoozeRequest, DebtPaymentResponse). |
| II. Sécurité par défaut | PASS | Tous les endpoints protégés JWT. Filtrage par userId systématique. Bean Validation sur tous les DTOs (@Valid, @NotNull, @Positive). Pessimistic lock sur repay. |
| III. Simplicité & YAGNI | PASS | Architecture Controller → Service → Repository. Pas de patterns complexes. DebtType enum existant réutilisé. |
| IV. Mobile-First UX | PASS | Remboursement en 2-3 interactions (bouton → compte → valider). Actions rapides depuis les notifications. FAB accessible. |
| V. Testabilité | PASS | 58 tests backend (27 service + 22 controller + 5 notification + 4 account), 59 tests Angular, 30 tests Flutter. Nommage should_X_when_Y. |
| VI. Observabilité | PASS | Actions loggées INFO (repay, snooze, reminder creation). Erreurs loggées ERROR. SLF4J/Logback uniquement. |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dépendance. Scheduler intégré (Spring @Scheduled). Pas de service cloud externe. |

**Server-only justification** (Constitution IV exception) : Les opérations de remboursement, snooze et historique des paiements nécessitent une cohérence transactionnelle serveur (pessimistic lock, création atomique transaction + mise à jour dette). Le mode local (Drift) n'est pas applicable — conforme à l'exception documentée dans la constitution IV.

## Project Structure

### Documentation (this feature)

```text
specs/080-debt-enhancements/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-endpoints.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── controller/DebtController.java        # 9 endpoints (CRUD + repay + payments + snooze)
│   ├── service/DebtService.java              # Repay, snooze, currency conversion, balance
│   ├── service/AccountService.java           # getTotalBalance (agrégation multi-devises)
│   ├── service/NotificationScheduler.java    # checkDebtReminders (job minutaire)
│   ├── repository/DebtRepository.java        # findDueReminders, findUsersWithActiveReminders
│   ├── repository/TransactionRepository.java # sumByDebtId, sumByDebtIds, findByDebtId
│   ├── dto/DebtRequest.java                  # accountId, includeInBalance, reminder*
│   ├── dto/DebtResponse.java                 # montantRestant, account summary
│   ├── dto/DebtRepayRequest.java             # accountId + amount (optionnel)
│   ├── dto/DebtSnoozeRequest.java            # reminderDate + reminderTime
│   ├── dto/DebtPaymentResponse.java          # id, amount, date, accountName
│   └── dto/TotalBalanceResponse.java         # CurrencyBalance list
│   └── model/Debt.java                       # +accountId, includeInBalance, reminder*
├── src/main/resources/db/migration/
│   └── V18__debt_enhancements.sql            # 4 colonnes, 3 index, 1 FK
└── src/test/java/.../
    ├── service/DebtServiceTest.java          # 27 tests
    ├── controller/DebtControllerTest.java    # 22 tests
    ├── service/NotificationSchedulerTest.java # 5 tests debt-related
    └── service/AccountServiceTest.java        # 4 tests totalBalance

app/src/app/
├── core/
│   ├── services/debt.ts                      # repay(), getPayments(), snooze(), refreshTrigger
│   └── models/debt.model.ts                  # DebtRepayRequest, DebtPaymentResponse, DebtSnoozeRequest
├── features/debts/
│   ├── debts.ts                              # Liste enrichie (activeDebts, totalByCurrency, navigation)
│   ├── debts.routes.ts                       # + route :id (DebtDetail lazy-loaded)
│   └── components/
│       ├── debt-detail/debt-detail.ts        # Progress bar, payments, actions
│       ├── repay-dialog/repay-dialog.ts      # Compte + montant, validation max
│       ├── snooze-dialog/snooze-dialog.ts    # Date future + heure, futureDateValidator
│       └── debt-form/debt-form.ts            # +accountId, currency forcing, reminder, includeInBalance
└── features/debts/__tests__/                 # 59 tests (5 fichiers)

flutter/lib/src/
├── domain/
│   ├── models/debt.dart                      # +accountId, accountName, includeInBalance, reminder*, remainingAmount
│   └── models/debt_payment.dart              # NEW: id, montant, date, accountName
├── features/debts/
│   ├── application/debt_notifier.dart        # +repay(), snooze(), getDebtById(), debtPaymentsProvider
│   ├── data/debt_repository_remote.dart      # +repay(), getPayments(), snooze()
│   └── presentation/
│       ├── debt_detail_screen.dart           # Progress, payments, badges, actions
│       └── widgets/
│           ├── repay_bottom_sheet.dart        # Compte + montant, validation
│           ├── snooze_dialog.dart             # Date future + heure
│           └── debt_form.dart                 # +account, currency forcing, reminder, includeInBalance
├── data/remote/
│   ├── data_sources/debt_remote_data_source.dart  # +repay(), getPayments(), snooze()
│   └── dtos/debt_dtos.dart                        # RepayRequest, SnoozeRequest, PaymentResponse
├── features/notifications/presentation/
│   └── notification_panel.dart               # Actions Rembourser/Reporter sur notifications dette
└── routing/app_router.dart                   # +/debts/:id route
flutter/test/src/features/debts/
└── application/debt_notifier_test.dart       # 30 tests
```

**Structure Decision**: Monorepo tri-module existant (api/, app/, flutter/). Chaque module enrichi dans ses patterns existants — pas de nouvelle structure créée.

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau vide.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
