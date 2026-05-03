# Implementation Plan: Flutter — Écran Abonnements Liste

**Branch**: `046-flutter-subscriptions-list` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/046-flutter-subscriptions-list/spec.md`

## Summary

Compléter l'écran `SubscriptionListScreen` avec : une carte récapitulative du total mensuel par devise, un filtre segmenté Tous/Actifs/Inactifs, le calcul de la prochaine date de renouvellement, un badge "Inactif" visuel distinct, et un message vide contextualisé par filtre. Le notifier sera étendu avec un state dédié Freezed incluant le filtre actif et les totaux calculés, en suivant le pattern établi par `TransactionListNotifier`.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, freezed, go_router, intl, shimmer
**Storage**: Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + mockito, ProviderContainer avec overrides
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: Mobile app (module `flutter/` du monorepo)
**Performance Goals**: Liste affichée < 2s, changement de filtre instantané
**Constraints**: Filtrage 100% côté client, pas de nouvel appel API
**Scale/Scope**: Single-user, ~50 abonnements max réaliste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Aucun endpoint modifié. Consomme GET `/subscriptions` existant. |
| II. Sécurité par défaut | PASS | JWT + filtrage par user déjà en place côté API. |
| III. Simplicité & YAGNI | PASS | Extension minimale du notifier existant + 1 state Freezed. Pas de nouveau pattern. |
| IV. Mobile-First UX | PASS | FAB toujours accessible, filtre rapide, badge visuel, summary card en haut. |
| V. Testabilité | PASS | Tests notifier (ProviderContainer + mocks), widget tests pour le screen. Nommage `should_..._when_...`. |
| VI. Observabilité | N/A | Feature frontend uniquement. |
| VII. Self-Hosted Ready | N/A | Pas de dépendance infra ajoutée. |

Aucune violation de gate. Pas de re-check nécessaire.

## Project Structure

### Documentation (this feature)

```text
specs/046-flutter-subscriptions-list/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── features/subscriptions/
│   ├── application/
│   │   ├── subscription_notifier.dart        # MODIFIER — state dédié + filtre + totaux
│   │   └── subscription_list_state.dart      # CRÉER — Freezed state avec filter/summary
│   └── presentation/
│       └── subscription_list_screen.dart     # MODIFIER — summary card + filter + badge + next date
├── domain/enums/
│   └── subscription_status_filter.dart       # CRÉER — enum SubscriptionStatusFilter
├── utils/
│   └── next_renewal_date.dart                # CRÉER — calcul prochaine date renouvellement
├── localization/
│   ├── app_fr.arb                            # MODIFIER — clés filtre, summary, empty filtré
│   └── app_en.arb                            # MODIFIER — idem EN

flutter/test/src/
├── features/subscriptions/
│   ├── application/
│   │   └── subscription_notifier_test.dart   # MODIFIER — tests filtre + totaux
│   └── presentation/
│       └── subscription_list_screen_test.dart # CRÉER — widget tests
└── utils/
    └── next_renewal_date_test.dart           # CRÉER — tests calcul date
```

**Structure Decision**: Module Flutter uniquement. Pas de changement backend ni Angular. Les fichiers suivent la structure `features/[feature]/{application,presentation,data}` établie. L'utilitaire de calcul de date va dans `utils/` car réutilisable (potentiellement par le dashboard).

## Complexity Tracking

> Aucune violation de constitution — tableau non applicable.
