# Implementation Plan: Flutter Settings — Gestion Comptes

**Branch**: `053-flutter-settings-accounts` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/053-flutter-settings-accounts/spec.md`

## Summary

Sous-page Settings pour la gestion des comptes bancaires dans l'app Flutter. Comprend une liste CRUD avec skeleton loading, menu popup contextuel (⋮), et un formulaire full-screen pour création/édition avec aperçu temps réel, sélecteur de type, emoji picker, palette de couleurs, et ajustement de solde. Mode serveur uniquement (API REST via Dio).

## Technical Context

**Language/Version**: Dart >= 3.6
**Primary Dependencies**: Flutter >= 3.27, flutter_riverpod, go_router, freezed, dio, emoji_picker_flutter, shimmer, intl
**Storage**: API REST uniquement (pas de Drift pour cette feature)
**Testing**: flutter_test + ProviderContainer avec overrides
**Target Platform**: iOS + Android (mobile-first)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Liste affichée en < 2s, création en < 30s
**Constraints**: Mode serveur uniquement, pas de cache local
**Scale/Scope**: ~10 fichiers à créer, ~6 fichiers à modifier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Status | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Tous les endpoints Account existent déjà (GET, POST, PUT, DELETE, setDefault, adjustBalance). Flutter consomme l'API REST. |
| II. Sécurité par défaut | PASS | JWT via Dio interceptor existant. Isolation par user dans l'API. |
| III. Simplicité & YAGNI | PASS | Réutilise le pattern CRUD Notifier existant (AccountNotifier). Pas de nouvelle abstraction. Seule extension : `adjustBalance`. |
| IV. Mobile-First UX | PASS | Formulaire full-screen optimisé mobile. Menu popup (⋮) pour actions. Skeleton loading. Aperçu temps réel. Dérogation offline documentée (R6) : données de configuration nécessitant fraîcheur, mode serveur-only justifié. |
| V. Testabilité | PASS | Tests notifier avec ProviderContainer. Widget tests avec ProviderScope. Pattern should_X_when_Y. |
| VI. Observabilité | N/A | Feature frontend uniquement, pas de logging serveur additionnel. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance cloud. API auto-hébergée. |

**Post-Phase 1 re-check**: Aucune violation. Le design suit les patterns existants sans ajout de complexité.

## Project Structure

### Documentation (this feature)

```text
specs/053-flutter-settings-accounts/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research findings
├── data-model.md        # Entity model documentation
├── quickstart.md        # Dev quickstart guide
├── contracts/
│   └── api-endpoints.md # API contract documentation
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── data/remote/
│   ├── data_sources/
│   │   └── account_remote_data_source.dart  # [MODIFIER] +adjustBalance()
│   └── dtos/
│       └── adjust_balance_request.dart      # [CRÉER] DTO
├── domain/
│   └── repositories/
│       └── account_repository.dart          # [MODIFIER] +adjustBalance()
├── features/accounts/
│   ├── application/
│   │   └── account_notifier.dart            # [MODIFIER] +adjustBalance()
│   ├── data/
│   │   └── account_repository_remote.dart   # [MODIFIER] +adjustBalance()
│   └── presentation/
│       ├── screens/
│       │   ├── account_list_screen.dart     # [CRÉER]
│       │   └── account_form_screen.dart     # [CRÉER]
│       └── widgets/
│           ├── account_list_tile.dart       # [CRÉER]
│           ├── account_list_skeleton.dart   # [CRÉER]
│           ├── account_preview_card.dart    # [CRÉER]
│           ├── account_type_selector.dart   # [CRÉER]
│           └── color_palette_picker.dart    # [CRÉER]
├── localization/
│   └── app_fr.arb                           # [MODIFIER] +clés accounts (app FR-only)
└── routing/
    ├── app_router.dart                      # [MODIFIER] remplacer Stub + routes
    └── route_names.dart                     # [MODIFIER] +constantes routes

flutter/test/src/features/accounts/
├── application/
│   └── account_notifier_test.dart           # [MODIFIER] +tests adjustBalance
└── presentation/
    ├── screens/
    │   ├── account_list_screen_test.dart    # [CRÉER]
    │   └── account_form_screen_test.dart    # [CRÉER]
    └── widgets/
        ├── account_list_tile_test.dart      # [CRÉER]
        ├── account_type_selector_test.dart  # [CRÉER]
        └── color_palette_picker_test.dart   # [CRÉER]
```

**Structure Decision**: Extension du module `features/accounts/` existant (application + data) avec ajout du layer `presentation/` (screens + widgets). Pattern identique aux features transactions/debts/subscriptions.

## Complexity Tracking

Aucune violation de constitution. Pas de tracking nécessaire.
