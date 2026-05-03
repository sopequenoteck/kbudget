# Implementation Plan: Detail Produit — Actions vente, restock et historique

**Branch**: `062-flutter-product-detail` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/062-flutter-product-detail/spec.md`

## Summary

Ecran de detail produit Flutter avec affichage des statistiques (marge, CA, stock), actions rapides (vendre en 1 tap, restocker via dialogue quantite), historique des transactions liees, et navigation vers le formulaire d'edition. Premiere "detail screen" du codebase — introduit une sous-route `/shop/:id` dans go_router. Necessite l'ajout des methodes `sell`, `restock` et `getSales` dans le repository et data source Flutter, ainsi qu'un correctif backend mineur pour inclure les restocks dans l'historique.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl
**Storage**: API REST uniquement (pas de Drift/SQLite pour cette feature)
**Testing**: flutter_test + mockito
**Target Platform**: iOS + Android
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Affichage < 2s, feedback vente < 1s
**Constraints**: Remote-only (API), single-user
**Scale/Scope**: 1 ecran detail + 1 dialogue restock + extensions notifier/repository/data source

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Toutes les actions (sell, restock, sales history) consomment l'API REST existante. DTOs separes (request/response). |
| II. Securite par defaut | PASS | JWT via Dio interceptor existant. Filtrage par user authentifie cote API. |
| III. Simplicite & YAGNI | PASS | Un ecran, pas d'abstractions nouvelles. Reutilise CrudNotifier/ProductNotifier existant + widgets communs. |
| IV. Mobile-First UX | PASS | Vente en 1 tap, restock en 3 interactions. Stats visibles d'un coup d'oeil. |
| V. Testabilite | PASS | Widget tests avec ProviderContainer + mock repository. Notifier testable unitairement. |
| VI. Observabilite | PASS | Logging cote API existant. Pas de logique metier Flutter a logger. |
| VII. Self-Hosted Ready | PASS | Aucune dependance cloud. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/062-flutter-product-detail/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-contracts.md # Endpoints consommes
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── data/remote/data_sources/
│   └── product_remote_data_source.dart    # +sell(), +restock(), +getSales()
├── domain/repositories/
│   └── product_repository.dart            # +sell(), +restock(), +getSales()
├── features/shop/
│   ├── application/
│   │   └── product_notifier.dart          # +sellProduct(), +restockProduct(), +salesHistory provider
│   ├── data/
│   │   └── product_repository_remote.dart # +sell(), +restock(), +getSales()
│   └── presentation/
│       ├── product_detail_screen.dart      # NOUVEAU — ecran principal
│       └── widgets/
│           └── restock_dialog.dart         # NOUVEAU — dialogue saisie quantite
├── routing/
│   └── app_router.dart                    # +sous-route /shop/:id
api/src/main/java/fr/kksdev/budget/api/
└── service/
    └── ProductService.java                # Fix: getSalesHistory retourne RECETTE + DEPENSE
```

**Structure Decision**: Extension de la feature `shop/` existante. Le detail est une sous-route de `/shop`. Pas de nouveau module — on enrichit le module existant avec un ecran et un dialogue.

## Complexity Tracking

> Aucune violation de constitution.
