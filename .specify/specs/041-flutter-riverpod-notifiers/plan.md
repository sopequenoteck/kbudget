# Implementation Plan: Flutter Notifiers Riverpod CRUD

**Branch**: `041-flutter-riverpod-notifiers` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/041-flutter-riverpod-notifiers/spec.md`

## Summary

Creer 5 notifiers Riverpod (Transaction, Account, Category, Subscription, Debt) gerant les operations CRUD avec etats loading/error/data, pagination client-side, suppression optimiste, et etats de mutation par element. Chaque notifier etend `Notifier<ListState<T>>` (pattern existant du projet) et consomme les repositories abstraits existants (local/remote).

## Technical Context

**Language/Version**: Dart >= 3.11 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod ^2.6.1, freezed_annotation ^2.4.4, drift ^2.23.1, dio ^5.8.0+1, mockito ^5.4.5
**Storage**: Drift (SQLite local) + API REST (remote via Dio) — via repositories abstraits existants
**Testing**: flutter_test + mockito (ProviderContainer avec overrides, pattern AuthNotifier)
**Target Platform**: iOS + Android (Flutter cross-platform)
**Project Type**: Mobile
**Performance Goals**: Indicateur de chargement < 1s (SC-001), mise a jour liste < 500ms apres CRUD (SC-002)
**Constraints**: Pagination client-side (getAll() + slice en pages de 20), offline-capable (fallback local)
**Scale/Scope**: Single-user, 5 entites, ~15 fichiers source + ~5 fichiers test

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature frontend-only. L'API REST existe deja, les notifiers consomment les repositories abstraits |
| II. Securite par defaut | PASS | Delegation au JwtInterceptor existant (Dio). Aucune logique securite dans les notifiers |
| III. Simplicite & YAGNI | PASS | Pattern Notifier existant. ListState generique justifie par 5 entites identiques (evite duplication). Pas de CQRS/Event Sourcing |
| IV. Mobile-First UX | PASS | Pagination, loading states, error states, suppression optimiste — tout sert l'UX mobile |
| V. Testabilite | PASS | Chaque notifier testable via ProviderContainer + mocks (pattern AuthNotifier). Nommage should_X_when_Y |
| VI. Observabilite | PASS | Erreurs surfacees via state.error (String?). Pas de backend logging requis |
| VII. Self-Hosted Ready | PASS | Aucun changement d'infrastructure |

**Gate result: ALL PASS** — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/041-flutter-riverpod-notifiers/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (fichiers a creer/modifier)

```text
flutter/lib/src/
├── domain/
│   └── models/
│       └── list_state.dart              # NEW — Etat generique Freezed ListState<T>
├── features/
│   ├── transactions/
│   │   └── application/
│   │       ├── transaction_notifier.dart     # NEW — Notifier CRUD
│   │       └── transaction_notifier_test.dart  # (test in test/)
│   ├── accounts/
│   │   └── application/
│   │       └── account_notifier.dart         # NEW — Notifier CRUD + setDefault
│   ├── categories/
│   │   └── application/
│   │       └── category_notifier.dart        # NEW — Notifier CRUD + protection isSystem
│   ├── subscriptions/
│   │   └── application/
│   │       └── subscription_notifier.dart    # NEW — Notifier CRUD + toggle actif
│   └── debts/
│       └── application/
│           └── debt_notifier.dart            # NEW — Notifier CRUD + markAsRepaid

flutter/test/src/features/
├── transactions/application/
│   └── transaction_notifier_test.dart   # NEW
├── accounts/application/
│   └── account_notifier_test.dart       # NEW
├── categories/application/
│   └── category_notifier_test.dart      # NEW
├── subscriptions/application/
│   └── subscription_notifier_test.dart  # NEW
└── debts/application/
    └── debt_notifier_test.dart          # NEW
```

**Structure Decision**: Les notifiers suivent la convention existante `features/<entity>/application/`. Le ListState generique va dans `domain/models/` car il est partage par les 5 features. Les tests suivent le mirroring `test/src/features/<entity>/application/`.

## Complexity Tracking

> Aucune violation de la constitution — section non applicable.
