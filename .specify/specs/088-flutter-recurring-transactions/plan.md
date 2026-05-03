# Implementation Plan: Flutter Recurring Transactions & Subscription Payments

**Branch**: `088-flutter-recurring-transactions` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/088-flutter-recurring-transactions/spec.md`

## Summary

Implémenter dans l'app Flutter mobile : (1) l'écran de gestion des transactions récurrentes (liste, valider, passer, désactiver), (2) l'enrichissement du détail abonnement avec historique des paiements et bouton payer, (3) les actions depuis les notifications push. Consomme les endpoints API REST existants (KKS-085). Pas de stockage local Drift — mode server-only.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl, phosphor_flutter
**Storage**: API REST uniquement (pas de Drift/SQLite pour cette feature)
**Testing**: flutter_test + mockito
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: mobile-app (module Flutter du monorepo)
**Performance Goals**: Liste récurrences affichée < 2s, actions en < 2 interactions
**Constraints**: Server-only (données toujours fraîches depuis l'API), pas d'offline
**Scale/Scope**: Single-user, ~5-20 récurrences actives, ~10-50 paiements par abonnement

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Consomme les endpoints REST existants (KKS-085). DTOs Freezed séparés des modèles domaine. |
| II. Sécurité par défaut | PASS | JWT géré par DioInterceptor existant. Isolation user via API backend. |
| III. Simplicité & YAGNI | PASS | Notifier custom (pas CrudNotifier — actions spéciales validate/skip/deactivate). Pas d'abstraction superflue. |
| IV. Mobile-First UX | PASS | Swipe + long press bottom sheet. Skeleton loading. Snackbar feedback. Actions en 2 interactions max. |
| V. Testabilité | PASS | Tests unitaires notifier + widget tests. Repository mockable via interface abstraite. |
| VI. Observabilité | N/A | Côté Flutter, pas de logging serveur. Erreurs remontées via snackbar. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance SaaS ajoutée. |

**Exception Constitution IV (offline)** : Mode server-only justifié — les récurrences nécessitent des données fraîches en temps réel (validation crée une transaction, skip avance la date). Aligné avec l'exception documentée dans la constitution.

## Project Structure

### Documentation (this feature)

```text
specs/088-flutter-recurring-transactions/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1
│   └── api-contracts.md
└── tasks.md             # Phase 2 (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   ├── models/
│   │   ├── recurring_transaction.dart          # NEW — Freezed model
│   │   ├── subscription_payment.dart           # NEW — Freezed model
│   │   └── subscription_total_paid.dart        # NEW — Freezed model
│   ├── enums/
│   │   ├── notification_type.dart              # MODIFY — +recurringTransactionDue
│   │   └── entity_type.dart                    # MODIFY — +recurringTransaction
│   └── repositories/
│       ├── recurring_transaction_repository.dart # NEW — interface abstraite
│       └── subscription_repository.dart         # MODIFY — +pay, +getPayments, +getTotalPaid
├── data/remote/
│   ├── data_sources/
│   │   ├── recurring_transaction_remote_data_source.dart  # NEW — Dio
│   │   └── subscription_remote_data_source.dart           # MODIFY — +pay, +payments, +totalPaid
│   └── dtos/
│       ├── recurring_transaction_dtos.dart      # NEW — Request/Response
│       └── subscription_payment_dtos.dart       # NEW — Response DTO
├── features/
│   ├── recurring/                               # NEW feature module
│   │   ├── application/
│   │   │   └── recurring_list_notifier.dart     # NEW — Notifier<ListState<RecurringTransaction>>
│   │   ├── data/
│   │   │   └── recurring_transaction_repository_remote.dart  # NEW
│   │   └── presentation/
│   │       ├── recurring_list_screen.dart        # NEW — ConsumerWidget
│   │       └── widgets/
│   │           ├── recurring_list_item.dart      # NEW — item avec swipe + badge statut
│   │           └── recurring_list_skeleton.dart  # NEW — shimmer
│   ├── subscriptions/
│   │   ├── application/
│   │   │   └── subscription_notifier.dart       # MODIFY — +pay, +loadPayments, +loadTotalPaid
│   │   └── presentation/
│   │       ├── subscription_detail_screen.dart   # NEW — ConsumerWidget
│   │       └── widgets/
│   │           └── payment_history_section.dart  # NEW — liste + total cumulé
│   └── notifications/
│       └── presentation/
│           └── notification_panel.dart           # MODIFY — +actions recurring + subscription deep links
└── routing/
    ├── app_router.dart                          # MODIFY — +routes recurring + subscription detail
    └── route_names.dart                         # MODIFY — +constantes routes
```

**Structure Decision** : Module `features/recurring/` dédié suivant le pattern existant (features/debts/, features/subscriptions/). Repository remote-only (pas de local). Enrichissement du module subscriptions existant pour le détail et les paiements.

### Tests

```text
flutter/test/src/features/
├── recurring/
│   └── application/
│       └── recurring_list_notifier_test.dart    # NEW — loadItems, validate, skip, deactivate
├── subscriptions/
│   └── application/
│       └── subscription_notifier_test.dart      # MODIFY — +tests pay, loadPayments
└── notifications/
    └── presentation/
        └── notification_panel_test.dart         # NEW — widget test actions recurring
```

## Design Decisions

### D1 — Notifier custom vs CrudNotifier

**Choix** : `Notifier<ListState<RecurringTransaction>>` custom (comme `DebtNotifier`).
**Raison** : `CrudNotifier` est conçu pour le CRUD classique (create/update/delete). Les récurrences ont des actions spéciales (validate → crée une transaction, skip → avance la date, deactivate → désactive). Les méthodes ne mappent pas sur le CRUD standard.

### D2 — SubscriptionDetailScreen (nouveau)

**Choix** : Créer un écran de détail complet au lieu d'enrichir le modal existant.
**Raison** : Le modal `AppModal` est conçu pour les formulaires. L'historique des paiements + le total cumulé + le bouton payer nécessitent un écran dédié. Le tap sur un item de la liste naviguera vers le détail (comme pour les dettes), et le FAB/action ouvrira toujours le formulaire via modal.

### D3 — Interaction swipe via Dismissible natif

**Choix** : `Dismissible` natif Flutter avec `confirmDismiss` pour les actions (pas d'ajout de `flutter_slidable`).
**Raison** : Le projet utilise déjà `Dismissible` dans le notification panel. Swipe droite → valider (vert), swipe gauche → passer (orange). Le long press ouvre un bottom sheet avec les 3 actions (valider, passer, désactiver).

### D4 — Enums NotificationType et EntityType

**Choix** : Ajouter `recurringTransactionDue` et `recurringTransaction` aux enums existants.
**Raison** : Aligne avec le backend qui a déjà `RECURRING_TRANSACTION_DUE` et `RECURRING_TRANSACTION` dans ses enums. Le notification panel doit pouvoir identifier ces types pour afficher les bonnes actions.

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau vide.
