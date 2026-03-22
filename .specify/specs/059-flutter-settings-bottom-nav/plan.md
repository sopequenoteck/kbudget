# Implementation Plan: Configuration de la navigation — Flutter

**Branch**: `059-flutter-settings-bottom-nav` | **Date**: 2026-02-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/059-flutter-settings-bottom-nav/spec.md`

## Summary

Ajouter une section "Navigation" dans la page Fonctionnalités des paramètres Flutter, permettant de réordonner les onglets optionnels du Bottom Nav par drag & drop. Le champ `navOrder` existe déjà dans les DTOs API mais n'est ni stocké localement ni utilisé — cette feature complète le circuit : stockage local (AppConfig) → state management (FeatureConfigNotifier) → UI (ReorderableListView + preview) → navigation réelle (_ShellScaffold).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, flutter_secure_storage
**Storage**: FlutterSecureStorage (AppConfig JSON sérialisé) + API REST (mode serveur)
**Testing**: flutter_test
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: Mobile app (module Flutter du monorepo)
**Performance Goals**: Preview update < 500ms après drag & drop
**Constraints**: Offline-capable (local-first), max 3 features réordonnables
**Scale/Scope**: Single-user, 1 écran modifié, 8 fichiers touchés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | `navOrder` déjà dans les DTOs (Request/Response). PUT `/users/me/preferences` accepte déjà le champ. Pas de nouvel endpoint. |
| II. Sécurité par défaut | PASS | Pas de nouvelle route. Données filtrées par user authentifié (JWT existant). |
| III. Simplicité & YAGNI | PASS | Pas de nouveau pattern. Extension du FeatureConfigNotifier existant. ReorderableListView natif Flutter. |
| IV. Mobile-First UX | PASS | Drag & drop tactile, sauvegarde automatique, preview immédiate. |
| V. Testabilité | PASS | State Riverpod testable via ProviderContainer. Widget testable indépendamment. |
| VI. Observabilité | N/A | Feature purement client-side. Le backend log déjà les PUT /preferences. |
| VII. Self-Hosted Ready | PASS | Aucune nouvelle dépendance externe. |

**Post-design re-check**: Aucune violation. Le design n'introduit aucune complexité additionnelle — il complète une infrastructure existante (DTOs déjà prêts).

## Project Structure

### Documentation (this feature)

```text
specs/059-flutter-settings-bottom-nav/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   ├── enums/
│   │   └── feature.dart                  # [MODIFY] Ajouter outlinedIcon getter
│   ├── models/
│   │   └── app_config.dart               # [MODIFY] Ajouter champ navOrder
│   └── repositories/
│       └── app_config_repository.dart    # [MODIFY] Ajouter getNavOrder/setNavOrder
├── features/
│   ├── onboarding/
│   │   └── data/
│   │       └── app_config_repository_impl.dart  # [MODIFY] Implémenter navOrder methods
│   └── settings/
│       ├── application/
│       │   └── feature_config_notifier.dart     # [MODIFY] navOrder dans state + reorderNavigation
│       ├── domain/
│       │   └── settings_section.dart            # [MODIFY] Titre/description Features & Navigation
│       └── presentation/
│           └── feature_settings_screen.dart     # [MODIFY] Section Navigation + preview
└── routing/
    └── app_router.dart                          # [MODIFY] _ShellScaffold utilise navOrder
```

**Structure Decision**: Flutter uniquement. Pas de modification backend (navOrder déjà supporté par l'API). 8 fichiers existants modifiés, 0 nouveau fichier.

## Complexity Tracking

> Aucune violation de constitution à justifier.
