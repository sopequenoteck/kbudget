# Implementation Plan: Flutter Settings — Gestion Catégories

**Branch**: `054-flutter-settings-categories` | **Date**: 2026-02-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/054-flutter-settings-categories/spec.md`

## Summary

Port de l'écran de gestion des catégories Angular vers Flutter. Sous-page paramètres avec liste CRUD (nom, icône emoji, couleur) et protection des catégories système. La couche données (model, repository, notifier, DTOs) existe déjà — le travail est concentré sur la couche présentation (écrans liste + formulaire) et le routing.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, emoji_picker_flutter, shimmer, intl
**Storage**: API REST uniquement (pas de Drift pour cette feature — données toujours fraîches depuis l'API)
**Testing**: flutter_test, mockito
**Target Platform**: iOS / Android (mobile natif)
**Project Type**: Mobile app (module Flutter du monorepo)
**Performance Goals**: Liste chargée en <2s, défilement fluide 60fps
**Constraints**: Réutilisation des patterns 053-accounts, widgets existants (EmojiInput, ColorPalettePicker)
**Scale/Scope**: Single-user, ~20-50 catégories max par utilisateur

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Endpoints CRUD `/categories` existants, DTOs request/response en place |
| II. Sécurité par défaut | PASS | JWT requis sur tous les endpoints, isolation par user authentifié |
| III. Simplicité & YAGNI | PASS | Réutilise patterns existants (053-accounts), pas de nouvelle abstraction |
| IV. Mobile-First UX | PASS | CRUD en 2-3 interactions, formulaire simple (3 champs) |
| V. Testabilité | PASS | Notifier testable via ProviderContainer, widget tests via ProviderScope |
| VI. Observabilité | N/A | Feature UI Flutter, pas de changement backend |
| VII. Self-Hosted Ready | N/A | Client mobile, pas d'impact infra |

**Résultat** : Tous les gates passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/054-flutter-settings-categories/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── common_widgets/
│   ├── emoji_input.dart                          # EXISTANT — réutilisé tel quel
│   └── color_palette_picker.dart                 # À DÉPLACER depuis accounts/widgets/
├── features/
│   └── categories/
│       ├── application/
│       │   └── category_notifier.dart            # EXISTANT — réutilisé tel quel
│       ├── data/
│       │   ├── category_repository_local.dart    # EXISTANT
│       │   └── category_repository_remote.dart   # EXISTANT
│       └── presentation/
│           ├── screens/
│           │   ├── category_list_screen.dart      # À CRÉER
│           │   └── category_form_screen.dart      # À CRÉER
│           └── widgets/
│               ├── category_list_tile.dart         # À CRÉER
│               ├── category_preview_card.dart      # À CRÉER
│               └── category_list_skeleton.dart     # À CRÉER
├── routing/
│   └── app_router.dart                            # À MODIFIER (remplacer stub, ajouter sous-routes)
└── domain/
    ├── models/
    │   └── category.dart                          # EXISTANT
    └── repositories/
        └── category_repository.dart               # EXISTANT

flutter/test/src/features/categories/
├── application/
│   └── category_notifier_test.dart                # EXISTANT
└── presentation/
    ├── screens/
    │   ├── category_list_screen_test.dart          # À CRÉER
    │   └── category_form_screen_test.dart          # À CRÉER
    └── widgets/
        ├── category_list_tile_test.dart            # À CRÉER
        └── category_preview_card_test.dart         # À CRÉER
```

**Structure Decision** : Feature module `categories/` existant, enrichi avec la couche `presentation/`. Le `ColorPalettePicker` est déplacé vers `common_widgets/` car réutilisé par 2 features (accounts + categories). Les imports dans `account_form_screen.dart` seront mis à jour.

## Complexity Tracking

> Aucune violation — tableau non applicable.
