# Implementation Plan: Flutter Emoji Input

**Branch**: `052-flutter-emoji-input` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/052-flutter-emoji-input/spec.md`

## Summary

Widget `EmojiInput` — un `FormField<String>` réutilisable qui affiche un trigger 48x48 et ouvre un bottom sheet avec le package `emoji_picker_flutter`. Supporte validation, état désactivé, thème clair/sombre, recherche par mot-clé. Fichier unique dans `common_widgets/`.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: `emoji_picker_flutter: ^4.4.0` (déjà ajouté au pubspec.yaml)
**Storage**: N/A (widget UI pur, pas de persistance)
**Testing**: `flutter_test` (widget tests)
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: Mobile app — widget partagé (`common_widgets/`)
**Performance Goals**: N/A (widget UI simple, pas de contrainte perf spécifique)
**Constraints**: Aucune contrainte spéciale — widget stateless côté données
**Scale/Scope**: 1 fichier source (247 lignes), 1 fichier test

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Widget UI pur, pas d'endpoint API |
| II. Sécurité par défaut | PASS | Pas de données sensibles, pas d'auth |
| III. Simplicité & YAGNI | PASS | 1 fichier, wrap direct du package, pas d'abstraction |
| IV. Mobile-First UX | PASS | Bottom sheet natif, trigger 48x48 adapté mobile |
| V. Testabilité | PASS | FormField testable via widget tests, pas de deps externes complexes |
| VI. Observabilité | N/A | Widget UI, pas de logging requis |
| VII. Self-Hosted Ready | N/A | Widget client-side uniquement |

**Gate result**: PASS — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/052-flutter-emoji-input/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/common_widgets/
└── emoji_input.dart          # Widget EmojiInput (FormField<String>) — EXISTE

flutter/test/src/common_widgets/
└── emoji_input_test.dart     # Widget tests — À CRÉER
```

**Structure Decision**: Fichier unique dans `common_widgets/` — pattern identique à `select_picker.dart`. Pas de dossier dédié, pas de sous-composants extraits.

## Complexity Tracking

> Aucune violation de constitution — tableau non requis.
