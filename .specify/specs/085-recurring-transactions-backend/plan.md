# Implementation Plan: Transactions Recurrentes & Paiements Abonnements (Backend)

**Branch**: `085-recurring-transactions-backend` | **Date**: 2026-03-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/085-recurring-transactions-backend/spec.md`

## Summary

Enrichir l'entite Transaction avec des champs de recurrence (isRecurring, frequency, nextOccurrence, recurringActive) et un lien vers Subscription (subscriptionId). Creer deux services dedies (RecurringTransactionService, SubscriptionPaymentService), integrer un nouveau job quotidien (8h) dans le NotificationScheduler existant, et exposer 8 nouveaux endpoints REST. Migration Flyway V20.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (Flyway V20)
**Testing**: JUnit 5, Spring Boot Test, Mockito, H2 (profil test)
**Target Platform**: Linux server (self-hosted)
**Project Type**: web-service (API REST)
**Performance Goals**: N/A (single-user)
**Constraints**: Scheduler quotidien a 8h UTC, pas de creation automatique de transactions
**Scale/Scope**: Single-user, ~100 recurrences max

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | 8 nouveaux endpoints REST, DTOs request/response dedies, jamais d'entite JPA exposee |
| II. Securite par defaut | PASS | Tous les endpoints proteges JWT, isolation par userId, Bean Validation sur les inputs |
| III. Simplicite & YAGNI | PASS | Architecture Controller → Service → Repository. Deux services dedies plutot qu'un service monolithique. Pas de pattern complexe |
| IV. Mobile-First UX | N/A | Feature backend-only, UX traitee dans KKS-192/193 |
| V. Testabilite | PASS | Tests unitaires services + tests @WebMvcTest controllers + tests scheduler. Nommage should_X_when_Y |
| VI. Observabilite | PASS | INFO sur actions (validation, paiement, skip), ERROR sur exceptions. SLF4J/Logback |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dependance infra, scheduler Spring natif |

## Project Structure

### Documentation (this feature)

```text
specs/085-recurring-transactions-backend/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── api-endpoints.md
└── tasks.md              # /speckit.tasks
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/
│   └── RecurringTransactionController.java   # NEW — endpoints recurrences
├── dto/
│   ├── request/
│   │   └── RecurringTransactionRequest.java  # NEW
│   └── response/
│       ├── RecurringTransactionResponse.java # NEW
│       └── SubscriptionPaymentResponse.java  # NEW
├── enums/
│   ├── EntityType.java                       # MODIFIED — +TRANSACTION
│   └── NotificationType.java                 # MODIFIED — +RECURRING_TRANSACTION_DUE
├── model/
│   └── Transaction.java                      # MODIFIED — +5 champs
├── repository/
│   └── TransactionRepository.java            # MODIFIED — +4 queries
├── service/
│   ├── RecurringTransactionService.java      # NEW
│   ├── SubscriptionPaymentService.java       # NEW
│   └── NotificationScheduler.java            # MODIFIED — +1 job @Scheduled(8h) dedie recurrences
└── ...

api/src/main/resources/db/migration/
└── V20__add_recurring_to_transactions.sql    # NEW

api/src/test/java/fr/kksdev/budget/api/
├── service/
│   ├── RecurringTransactionServiceTest.java  # NEW
│   └── SubscriptionPaymentServiceTest.java   # NEW
└── controller/
    └── RecurringTransactionControllerTest.java # NEW
```

**Structure Decision**: Backend-only, module `api/` existant. Pas de nouveau module Maven. Le SubscriptionController existant est enrichi avec les endpoints de paiement (meme ressource `/subscriptions`).

## Complexity Tracking

> Aucune violation de constitution. Pas de complexite ajoutee.
