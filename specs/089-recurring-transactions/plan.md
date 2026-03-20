# Implementation Plan: Transactions récurrentes & améliorations abonnements (consolidée)

**Branch**: `089-recurring-transactions` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/089-recurring-transactions/spec.md`
**Status**: Done (rétroactive — consolide 085/086/087/088)

## Summary

Ajout de la notion de transactions récurrentes et enrichissement des abonnements pour générer des paiements traçables. Workflow cross-plateforme : notification à échéance → validation manuelle par l'utilisateur → création de transaction. Implémenté en 4 phases : backend (migration V20, services, endpoints, scheduler), Angular (écran récurrences + détail abonnement + notifications), Angular formulaire (création + conversion), Flutter (écran récurrences + détail abonnement + notifications).

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio
**Storage**: PostgreSQL 15+ (Flyway V20), pas de Drift/SQLite pour cette feature (server-only)
**Testing**: JUnit 5 + Spring Boot Test (backend), Vitest (Angular), flutter_test (Flutter)
**Target Platform**: Web (PWA) + Mobile (Flutter iOS/Android)
**Project Type**: Monorepo (api/ + app/ + flutter/)
**Performance Goals**: App single-user self-hosted — pas de contrainte de charge
**Constraints**: Pas de création automatique de transactions — validation manuelle obligatoire
**Scale/Scope**: Single-user, ~50 transactions récurrentes max, ~20 abonnements max

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | PASS | Tous les endpoints REST créés avant les frontends (085 → 086/087/088). DTOs séparés (RecurringTransactionRequest/Response, SubscriptionPaymentResponse) |
| II. Sécurité par défaut | PASS | Tous les endpoints protégés JWT. Filtrage par userId. Bean Validation sur les inputs |
| III. Simplicité & YAGNI | PASS | Controller → Service → Repository. Pas de patterns complexes. Fréquence en enum existant |
| IV. Mobile-First UX | PASS | Actions en 2 interactions max. Swipe Flutter. Badges de statut visuels. Skeleton loading |
| V. Testabilité | PASS | 488 tests backend + 379 Angular + 626 Flutter. Nommage should_X_when_Y |
| VI. Observabilité | PASS | Logs INFO pour chaque action (validate, skip, deactivate, pay). ERROR pour erreurs métier |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dépendance. Scheduler intégré Spring @Scheduled |

**Justification server-only (Flutter)** : Les transactions récurrentes et paiements d'abonnements nécessitent des données fraîches en temps réel (scheduler backend, état de paiement). Conforme à l'exception Constitution IV : "features dont les données doivent être fraîches en temps réel [...] peuvent utiliser le mode server-only".

## Project Structure

### Documentation (this feature)

```text
specs/089-recurring-transactions/
├── plan.md              # This file (consolidé)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── checklists/
    └── requirements.md  # Checklist de validation spec
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/
│   ├── RecurringTransactionController.java    # 5 endpoints /transactions/recurring
│   └── SubscriptionController.java            # +3 endpoints pay/payments/total
├── service/
│   ├── RecurringTransactionService.java        # create, listActive, validate, skip, deactivate
│   ├── SubscriptionPaymentService.java         # pay, getPayments, getTotalPaid
│   └── NotificationScheduler.java              # +checkRecurringTransactions()
├── dto/
│   ├── RecurringTransactionRequest.java
│   ├── RecurringTransactionResponse.java
│   └── SubscriptionPaymentResponse.java
├── model/
│   └── Transaction.java                        # +isRecurring, frequency, nextOccurrence, recurringActive, subscription FK
└── enums/
    ├── NotificationType.java                    # +RECURRING_TRANSACTION_DUE
    └── EntityType.java                          # +RECURRING_TRANSACTION

api/src/main/resources/db/migration/
└── V20__recurring_transactions.sql

app/src/app/
├── features/transactions/
│   ├── recurring-list/                         # RecurringListComponent
│   └── transaction-form/                       # +toggle récurrence, +action "Rendre récurrente"
├── features/subscriptions/
│   └── subscription-detail/                    # +section paiements + bouton Payer
├── services/
│   ├── recurring-transaction.service.ts         # signal-based
│   └── subscription.service.ts                  # +pay, getPayments, getTotalPaid
└── features/notifications/
    └── notification-panel/                      # +actions RECURRING_TRANSACTION_DUE, SUBSCRIPTION_DUE

flutter/lib/src/
├── features/recurring/
│   ├── application/
│   │   └── recurring_list_notifier.dart         # validate, skip, deactivate
│   ├── data/
│   │   └── recurring_transaction_remote_data_source.dart
│   └── presentation/
│       └── recurring_list_screen.dart            # swipe + badges
├── features/subscriptions/
│   └── presentation/
│       └── subscription_detail_screen.dart       # +paiements + total cumulé
└── features/notifications/
    └── presentation/
        └── notification_panel.dart               # +actions récurrences/abonnements
```

**Structure Decision**: Monorepo existant api/ + app/ + flutter/. Chaque plateforme suit ses conventions établies. Pas de nouveau module — enrichissement des features existantes.

## Complexity Tracking

Aucune violation de constitution. Pas de déviation nécessaire.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Aucune | — | — |
