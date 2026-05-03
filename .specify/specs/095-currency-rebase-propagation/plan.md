# Implementation Plan: Currency Rebase Propagation

**Branch**: `095-currency-rebase-propagation` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/095-currency-rebase-propagation/spec.md`

## Summary

Quand l'utilisateur change sa devise principale (réordonnancement de `currencies[0]` dans ses préférences), le backend doit automatiquement rebaser tous les taux de change via `rebaseRates()` dans une transaction atomique. Les frontends (Angular, Flutter) doivent ensuite recharger les taux depuis le serveur pour que l'UI se mette à jour instantanément via les mécanismes réactifs existants (Signals, Riverpod). Un indicateur visuel sur le total agrégé du dashboard signale les taux manquants.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Dio
**Storage**: PostgreSQL 15+ (table `exchange_rates`, table `user_preferences`)
**Testing**: JUnit 5 + Mockito (backend), Vitest (Angular), flutter_test (Flutter)
**Target Platform**: Web PWA + Mobile natif (iOS/Android)
**Project Type**: Web application + Mobile app (monorepo)
**Performance Goals**: Mise à jour UI < 2 secondes après changement de devise
**Constraints**: Opération transactionnelle (rollback complet si rebase échoue)
**Scale/Scope**: Single-user, ~7 devises max, ~10-20 taux de change max

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Le rebase est déclenché côté serveur dans `PreferenceService`. Les frontends consomment l'API existante GET `/exchange-rates`. |
| II. Sécurité | PASS | Tous les endpoints sont protégés par JWT. Le rebase utilise le `userId` authentifié. Pas de nouvel endpoint exposé. |
| III. Simplicité & YAGNI | PASS | 3 lignes ajoutées dans `PreferenceService` (détection changement + appel `rebaseRates`). Côté frontend : rechargement des taux + indicateur visuel. Pas de nouvelle abstraction. |
| IV. Mobile-First UX | PASS | La mise à jour est transparente et instantanée sur les deux plateformes. |
| V. Testabilité | PASS | Test unitaire du rebase automatique dans `PreferenceServiceTest`. Tests Angular/Flutter pour le rechargement des taux. |
| VI. Observabilité | PASS | Le rebase existant logge déjà les actions. Ajout d'un log INFO pour le déclenchement automatique. |
| VII. Self-Hosted Ready | PASS | Pas de dépendance externe ajoutée. PostgreSQL uniquement. |

## Project Structure

### Documentation (this feature)

```text
specs/095-currency-rebase-propagation/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── preferences-api.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   └── service/
│       └── PreferenceService.java          # Ajout rebase automatique
└── src/test/java/fr/kksdev/budget/api/
    └── service/
        └── PreferenceServiceTest.java      # Tests rebase automatique

app/
└── src/app/
    ├── core/services/
    │   ├── exchange-rate.ts                # Rechargement taux après changement devise
    │   └── conversion.ts                   # Flag hasMissingRate (existant, déjà ok)
    └── features/dashboard/
        └── dashboard.ts                    # Indicateur visuel taux manquant

flutter/
└── lib/src/
    ├── features/exchange_rates/application/
    │   └── currency_config_notifier.dart   # Rechargement taux après changement devise
    └── features/dashboard/
        ├── application/
        │   └── dashboard_notifier.dart     # Flag hasMissingRate
        └── presentation/
            └── dashboard_screen.dart       # Indicateur visuel taux manquant
```

**Structure Decision**: Modifications ciblées dans les fichiers existants. Aucun nouveau fichier créé. Le backend change ~15 lignes dans `PreferenceService` (rebase auto + WebSocket push), les frontends changent dans les services de devises (reload + WebSocket listener + error handling) et le dashboard (indicateur taux manquant).
