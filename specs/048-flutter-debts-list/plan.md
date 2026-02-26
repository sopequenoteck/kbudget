# Implementation Plan: Flutter — Écran Dettes Liste

**Branch**: `048-flutter-debts-list` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/048-flutter-debts-list/spec.md`

## Summary

Implémenter l'écran liste des dettes Flutter avec : une carte récapitulative (totaux emprunts/prêts/solde net par devise, toujours sur les non-remboursées), un filtre segmenté (Tous/En cours/Remboursé) côté client, et une liste organisée en deux sections "Prêts" et "Emprunts" avec sous-totaux par devise. Le tap sur un item ouvre le formulaire DebtForm existant en modal. L'approche suit le pattern établi par `SubscriptionListScreen` (branche 046) : state Freezed custom, filtre dans le notifier, skeleton shimmer, états loading/error/empty.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, freezed, go_router, shimmer, intl
**Storage**: Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + ProviderContainer avec overrides
**Target Platform**: Android + iOS (mobile-first)
**Project Type**: Mobile app (module `flutter/`)
**Performance Goals**: Affichage < 2s, changement de filtre instantané (client-side)
**Constraints**: Offline-capable (mode local Drift), pas de nouvel appel réseau au changement de filtre
**Scale/Scope**: Single-user, volume de dettes faible (< 100 items typiquement)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Aucun changement backend — l'API Debt existe déjà (CRUD complet). Feature purement Flutter/présentation. |
| II. Sécurité par défaut | OK | Les données sont déjà filtrées par user dans le repository (local ou remote). Pas de nouveau endpoint. |
| III. Simplicité & YAGNI | OK | Pattern identique à SubscriptionListScreen. State Freezed custom justifié par filtre + résumé (même pattern éprouvé). Pas d'abstraction nouvelle. |
| IV. Mobile-First UX | OK | FAB accessible, filtre rapide, sections lisibles, skeleton loading, pull-to-refresh. Résumé coloré pour lecture rapide. |
| V. Testabilité | OK | Notifier testable via ProviderContainer + mock repository. Widget testable via ProviderScope. Nommage `should_*_when_*`. |
| VI. Observabilité | N/A | Feature purement frontend Flutter. Pas de logging backend ajouté. |
| VII. Self-Hosted Ready | N/A | Pas d'infrastructure modifiée. |

**Résultat gate** : PASS — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/048-flutter-debts-list/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   └── enums/
│       └── debt_status_filter.dart          # NOUVEAU — enum filtre
├── features/
│   └── debts/
│       ├── application/
│       │   ├── debt_list_state.dart          # NOUVEAU — state Freezed custom
│       │   ├── debt_list_state.freezed.dart  # GÉNÉRÉ — build_runner
│       │   └── debt_notifier.dart            # MODIFIÉ — migration ListState<Debt> → DebtListState
│       └── presentation/
│           └── debt_list_screen.dart         # MODIFIÉ — implémentation complète (remplace stub)
└── localization/
    └── app_en.arb / app_fr.arb              # MODIFIÉ — nouvelles clés i18n

flutter/test/src/features/debts/
├── application/
│   └── debt_notifier_test.dart              # NOUVEAU — tests notifier (filtre, summary, CRUD)
└── presentation/
    └── debt_list_screen_test.dart            # NOUVEAU — tests widget
```

**Structure Decision** : Ajout de 2 nouveaux fichiers (enum + state), modification de 2 existants (notifier + screen), ajout de clés i18n. Pas de nouveau widget commun nécessaire — réutilisation de `ListItem`, `SegmentedFilter`, `AppModal`.

## Complexity Tracking

Aucune violation détectée — tableau non applicable.
