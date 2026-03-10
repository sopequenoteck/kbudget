# Implementation Plan: Backend Debt Enhancements

**Branch**: `077-backend-debt-enhancements` | **Date**: 2026-03-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/077-backend-debt-enhancements/spec.md`

## Summary

Enrichir la gestion des dettes avec : remboursement via transactions liées (calcul dynamique du montant restant), association optionnelle à un compte bancaire (devise forcée), inclusion dans le patrimoine total, rappels personnalisés (date+heure) via notifications. Approche : enrichissement des entités Debt et Transaction existantes, 3 nouveaux endpoints Debt + 1 endpoint Account, scheduler de rappels à la minute.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (Flyway V18)
**Testing**: JUnit 5, Spring Boot Test, Mockito, H2 (profil test)
**Target Platform**: Linux server (self-hosted)
**Project Type**: web-service (API REST backend)
**Performance Goals**: Single-user, pas de contrainte de débit. Scheduler rappels < 1 min de latence.
**Constraints**: Pas de champ persisté pour le montant restant (calcul dynamique). Pas de @Version (single-user).
**Scale/Scope**: ~20 fichiers modifiés/créés, 1 migration Flyway, ~40-50 tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Tous les comportements exposés via endpoints REST. DTOs séparés des entités. |
| II. Sécurité par défaut | PASS | Tous les endpoints protégés JWT. Filtrage par userId. Bean Validation sur les DTOs. Validation ownership sur compte/dette. |
| III. Simplicité & YAGNI | PASS | Architecture Controller → Service → Repository. Pas de pattern complexe. Calcul dynamique via SUM SQL. Scheduler simple @Scheduled. |
| IV. Mobile-First UX | N/A | Feature backend only. |
| V. Testabilité | PASS | Tests unitaires DebtService (mocks). Tests intégration DebtController. Pattern should_X_when_Y. |
| VI. Observabilité | PASS | Logging INFO sur remboursement, rappel, association compte. ERROR sur échecs de conversion/validation. SLF4J. |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dépendance. Pas de service externe. |

**Re-check post-design**: PASS — aucune violation détectée.

## Project Structure

### Documentation (this feature)

```text
specs/077-backend-debt-enhancements/
├── plan.md
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── debt-endpoints.md
└── tasks.md              # /speckit.tasks
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── model/
│   ├── Debt.java                    # +account, +includeInBalance, +reminderDate, +reminderTime
│   └── Transaction.java            # +debt (FK nullable)
├── enums/
│   └── NotificationType.java       # +DEBT_REMINDER
├── dto/
│   ├── request/
│   │   ├── DebtRequest.java         # +accountId, +includeInBalance, +reminderDate, +reminderTime
│   │   ├── DebtRepayRequest.java    # NOUVEAU
│   │   └── DebtSnoozeRequest.java   # NOUVEAU
│   └── response/
│       ├── DebtResponse.java        # +account, +includeInBalance, +reminder*, +montantRestant
│       ├── DebtPaymentResponse.java # NOUVEAU
│       ├── TransactionResponse.java # +debtId
│       ├── TotalBalanceResponse.java # NOUVEAU
│       └── CurrencyBalance.java     # NOUVEAU (inner class ou record)
├── repository/
│   ├── DebtRepository.java          # +findByReminderDateAndReminderTime..., +findByIncludeInBalance...
│   └── TransactionRepository.java   # +sumByDebtId(), +findByDebtIdOrderByDateDesc()
├── service/
│   ├── DebtService.java             # +repay(), +getPayments(), +snooze(), logique devise/compte
│   ├── AccountService.java          # +getTotalBalance()
│   └── NotificationScheduler.java   # +checkDebtReminders() @Scheduled chaque minute
├── controller/
│   ├── DebtController.java          # +POST repay, +GET payments, +POST snooze
│   └── AccountController.java       # +GET total-balance
└── ...

api/src/main/resources/db/migration/
└── V18__add_debt_enhancements.sql   # NOUVEAU

api/src/test/java/fr/kksdev/budget/api/
├── service/
│   └── DebtServiceTest.java         # Tests unitaires enrichis
└── controller/
    ├── DebtControllerTest.java      # Tests intégration enrichis
    └── AccountControllerTest.java   # +test total-balance
```

**Structure Decision**: Backend Spring Boot uniquement (module `api/`). Pas de modification frontend dans cette feature.

## Complexity Tracking

Aucune violation de la constitution. Pas de complexité additionnelle justifiée.
