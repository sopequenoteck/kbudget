# Implementation Plan: Flutter Dashboard Complet

**Branch**: `042-flutter-dashboard` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/042-flutter-dashboard/spec.md`

## Summary

Remplacement du dashboard placeholder Flutter par un ecran complet compose de 4 sections verticales : Hero Compte (compte par defaut + liste comptes), Resume mensuel (via `GET /transactions/summary`), Mini-cards modules (Abonnements + Dettes), Dernieres operations (5 transactions). Approche : un `DashboardNotifier` Riverpod qui orchestre le chargement de toutes les donnees, des widgets de section dedies, et un `RefreshIndicator` global.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod ^2.6.1, go_router ^14.8.1, dio ^5.8.0+1, shimmer ^3.0.0, freezed_annotation ^2.4.4, intl
**Storage**: Drift (SQLite local) + API REST (remote via Dio) — via data mode provider
**Testing**: flutter_test + mockito ^5.4.5
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: < 2s chargement initial (SC-001), < 1s changement de mois (SC-003), ~60fps scroll
**Constraints**: ~1.5 ecrans scroll vertical, pas de scroll horizontal, pull-to-refresh
**Scale/Scope**: Single user, app personnelle

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Consomme l'endpoint existant `GET /transactions/summary`. Pas de nouveau endpoint backend. |
| II. Securite par defaut | PASS | JWT gere par `JwtInterceptor` existant. Aucune route publique ajoutee. |
| III. Simplicite & YAGNI | PASS | Pas de nouveau pattern. Utilise les notifiers Riverpod existants. Modules hardcodes (pas de systeme de toggles). |
| IV. Mobile-First UX | PASS | Dashboard est l'ecran principal mobile. Pull-to-refresh, layout vertical compact. |
| V. Testabilite | PASS | Widget tests pour chaque section, unit tests pour le notifier dashboard. |
| VI. Observabilite | N/A | Frontend Flutter — pas de logging backend requis. |
| VII. Self-Hosted Ready | PASS | Aucune dependance infra ajoutee. |

Aucune violation detectee.

## Project Structure

### Documentation (this feature)

```text
specs/042-flutter-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── features/dashboard/
│   ├── application/
│   │   ├── dashboard_state.dart           # NEW — state Freezed du dashboard
│   │   └── dashboard_notifier.dart        # NEW — orchestre le chargement dashboard
│   └── presentation/
│       ├── dashboard_screen.dart           # MODIFY — refonte complete
│       └── widgets/
│           ├── hero_account_section.dart   # NEW — section hero + liste comptes
│           ├── monthly_summary_section.dart # NEW — resume mensuel + barres
│           ├── mini_cards_section.dart     # NEW — cards Abonnements + Dettes
│           └── recent_transactions_section.dart # NEW — 5 dernieres operations
├── data/remote/
│   ├── data_sources/
│   │   └── transaction_remote_data_source.dart  # MODIFY — ajouter getMonthlySummary()
│   └── dtos/
│       └── transaction_dtos.dart           # MODIFY — ajouter MonthlySummaryResponse DTO
├── domain/models/
│   └── monthly_summary.dart               # NEW — modele domaine MonthlySummary
└── data/
    └── data_mode_provider.dart             # MODIFY — ajouter monthlySummaryProvider
```

**Structure Decision**: Feature-based structure existante. Le dashboard est une feature deja presente (`features/dashboard/`). On ajoute un sous-dossier `widgets/` pour les sections, un notifier dedie, et on etend la couche data pour le summary API.

## Complexity Tracking

Aucune violation de la constitution — tableau non requis.
