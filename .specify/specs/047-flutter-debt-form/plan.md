# Implementation Plan: Formulaire Dette Flutter

**Branch**: `047-flutter-debt-form` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/047-flutter-debt-form/spec.md`

## Summary

Implémenter le formulaire CRUD de dette dans l'app Flutter, présenté dans une modale avec toggle Emprunt/Prêt. Le formulaire suit exactement les patterns existants (TransactionForm, SubscriptionForm). L'infrastructure (modale, toggle, repository, notifier, DAO) est déjà en place — il s'agit principalement de créer le widget DebtForm et de l'intégrer dans le système de modale via `app_router.dart`.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, intl
**Storage**: Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + ProviderContainer avec overrides
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: Mobile app (module Flutter du monorepo)
**Performance Goals**: 60 fps, ouverture modale instantanée
**Constraints**: Offline-capable (Drift local-first), cohérence UI avec formulaires existants
**Scale/Scope**: Single-user, 1 nouveau widget + 1 intégration modale + clés i18n

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Post-design re-check (2026-02-23): All 7 principles still PASS — no new abstractions, no schema changes, no new dependencies.*

| Principe | Statut | Justification |
| -------- | ------ | ------------- |
| I. API-First | **PASS** | L'API REST Debt existe déjà (CRUD complet). Ce feature ajoute uniquement l'UI Flutter. |
| II. Sécurité par défaut | **PASS** | JWT auth et isolation par user déjà implémentés dans la couche repository. |
| III. Simplicité & YAGNI | **PASS** | Suit les patterns existants (TransactionForm, SubscriptionForm). Pas de nouvelle abstraction. |
| IV. Mobile-First UX | **PASS** | FAB (+) accessible, saisie en 2-3 interactions, modale mobile-friendly. |
| V. Testabilité | **PASS** | Le widget et le notifier sont testables via les patterns existants. Les tests seront ajoutés dans la feature list screen (hors scope ici — feature UI-only sans nouvelle logique métier). |
| VI. Observabilité | **PASS** | N/A — pas de changement backend, logging déjà en place. |
| VII. Self-Hosted Ready | **PASS** | Pas de nouvelle dépendance infrastructure. |

## Project Structure

### Documentation (this feature)

```text
specs/047-flutter-debt-form/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── features/debts/
│   ├── application/
│   │   └── debt_notifier.dart          # EXISTE — Notifier CRUD
│   ├── data/
│   │   ├── debt_repository_local.dart  # EXISTE — Impl Drift
│   │   └── debt_repository_remote.dart # EXISTE — Impl Dio
│   └── presentation/
│       ├── debt_list_screen.dart       # EXISTE (stub) — hors scope
│       └── widgets/
│           └── debt_form.dart          # À CRÉER — Widget formulaire
├── routing/
│   └── app_router.dart                 # À MODIFIER — Intégration modale
└── localization/
    └── app_fr.arb                      # À MODIFIER — Clés i18n dette
```

**Structure Decision**: Module `features/debts/` existant, ajout uniquement du widget `debt_form.dart` dans `presentation/widgets/`. Intégration dans le routeur existant (`_buildModalChild`) et ajout de clés de localisation.

## Complexity Tracking

> Aucune violation de constitution — tableau non applicable.
