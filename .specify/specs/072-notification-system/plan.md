# Implementation Plan: Notification System

**Branch**: `072-notification-system` | **Date**: 2026-03-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/072-notification-system/spec.md`

## Summary

Systeme de notifications multi-canal (in-app, STOMP WebSocket temps reel, push locale Flutter) avec panneau drawer, rappels automatiques d'abonnements/dettes via job quotidien, et preferences utilisateur configurables. Infrastructure generique permettant l'ajout futur de types de notifications (KKS-157 budgets, KKS-159 transactions recurrentes).

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Spring WebSocket + STOMP, Angular 21 + @stomp/stompjs, Flutter >= 3.27 + stomp_dart_client + flutter_local_notifications
**Storage**: PostgreSQL 15+ (table `notifications`, enrichissement `user_preferences`)
**Testing**: JUnit 5 + Spring Boot Test (backend), Vitest (Angular), flutter_test (Flutter)
**Target Platform**: Linux server (API), PWA mobile-first (Angular), iOS/Android (Flutter)
**Project Type**: Web service + PWA + mobile app (monorepo)
**Performance Goals**: Notification delivree < 3s (app ouverte), panneau charge < 1s, reconnexion WebSocket < 5s
**Constraints**: Zero dependance externe (SC-007), mono-user self-hosted, STOMP over WebSocket (pas de Web Push PWA)
**Scale/Scope**: Mono-user, retention 90 jours, pagination 20 items/page

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Notifications exposees via API REST (CRUD + mark read + bulk) avant consommation frontend. DTOs separes (request/response). |
| II. Securite par defaut | PASS | Endpoints proteges par JWT. WebSocket authentifie via ChannelInterceptor STOMP (JWT dans header CONNECT). Donnees filtrees par userId. |
| III. Simplicite & YAGNI | PASS | Architecture Controller -> Service -> Repository. Pas de pattern complexe. 4 types de notifications couvrant les FRs actuels. |
| IV. Mobile-First UX | PASS | Drawer lateral slide-in (mobile-first), badge cloche, swipe-to-delete, push locale Flutter. |
| V. Testabilite | PASS | Tests d'integration sur endpoints notification. Tests unitaires sur NotificationService + job scheduling. Tests unitaires Angular (NotificationService, StompService). Tests widget Flutter sur le panneau. |
| VI. Observabilite | PASS | Logs INFO sur creation/lecture/suppression notifications. ERROR sur echecs WebSocket/push. |
| VII. Self-Hosted Ready | PASS | Zero dependance SaaS. STOMP embarque dans Spring. Push locale native (pas de Firebase). PostgreSQL seule infra. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/072-notification-system/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API endpoints)
│   └── notification-api.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── config/
│   ├── WebSocketConfig.java          # @EnableWebSocketMessageBroker, STOMP endpoints
│   └── StompAuthInterceptor.java     # ChannelInterceptor JWT validation on CONNECT
├── controller/
│   └── NotificationController.java   # REST endpoints CRUD notifications
├── service/
│   ├── NotificationService.java      # Core logic: create, mark read, delete, purge
│   └── NotificationScheduler.java    # @Scheduled job quotidien rappels J-1
├── repository/
│   └── NotificationRepository.java   # JpaRepository + custom queries
├── model/
│   └── Notification.java             # @Entity JPA
├── dto/
│   └── NotificationResponse.java     # Response DTO (preferences via UserPreferenceRequest existant)
└── enums/
    ├── NotificationType.java         # BUDGET_THRESHOLD, BUDGET_EXCEEDED, SUBSCRIPTION_DUE, DEBT_DUE
    └── EntityType.java               # BUDGET, SUBSCRIPTION, DEBT

api/src/main/resources/db/migration/
└── V15__add_notifications.sql        # Table notifications + enrichissement user_preferences

app/src/app/
├── core/
│   └── services/
│       ├── notification.ts           # NotificationService (signal-based, REST + STOMP)
│       └── stomp.ts                  # StompService (connexion, reconnexion, auth)
├── shared/
│   └── components/
│       ├── notification-panel/       # Drawer lateral (slide-in droite)
│       └── notification-badge/       # Badge cloche avec compteur
└── features/
    └── settings/
        └── notification-settings/    # Preferences de notification

flutter/lib/src/
├── data/
│   └── remote/
│       └── notification_remote_data_source.dart  # REST API calls
├── domain/
│   ├── enums/
│   │   ├── notification_type.dart    # NotificationType enum
│   │   └── entity_type.dart          # EntityType enum
│   ├── models/
│   │   └── notification.dart         # Freezed model
│   └── repositories/
│       └── notification_repository.dart  # Interface abstraite
├── features/
│   └── notifications/
│       ├── application/
│       │   └── notification_notifier.dart  # Riverpod notifier (REST + STOMP)
│       ├── data/
│       │   └── notification_repository_remote.dart  # Implementation
│       └── presentation/
│           ├── notification_panel.dart     # Drawer widget (Scaffold.endDrawer)
│           └── notification_badge.dart     # Badge widget
├── common_widgets/
│   └── adaptive_scaffold.dart        # Modifier: ajouter badge cloche + endDrawer
└── services/
    └── stomp_service.dart            # STOMP client (connexion, reconnexion, auth)
```

**Structure Decision**: Monorepo existant (api/ + app/ + flutter/). Chaque module recoit ses composants notification dans la structure existante. Pas de nouveau module — extension des packages existants.

## Complexity Tracking

> Aucune violation de constitution a justifier. Pas d'entree requise.
