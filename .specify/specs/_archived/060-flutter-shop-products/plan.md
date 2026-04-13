# Implementation Plan: Écran Boutique — Liste produits + stock (Flutter)

**Branch**: `060-flutter-shop-products` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/060-flutter-shop-products/spec.md`

## Summary

Créer l'écran principal de la feature Boutique dans l'app Flutter : une liste de produits avec stock et compteur de ventes. L'écran consomme l'API REST existante (`GET /products`) via le pattern CRUD Notifier standard du projet. Inclut les états loading (shimmer), vide (CTA), erreur (retry) et pull-to-refresh. Navigation vers le détail et la création préparée en no-op.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl
**Storage**: API REST uniquement (pas de Drift/SQLite pour cette feature)
**Testing**: flutter_test + Mockito
**Target Platform**: iOS, Android (mobile-first)
**Project Type**: Mobile app (module feature dans monorepo)
**Performance Goals**: Affichage liste < 2 secondes
**Constraints**: Server-only (pas de mode offline), Feature toggle `SHOP` requis
**Scale/Scope**: Single-user, catalogue personnel (< 100 produits typiquement)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | L'API REST Product est déjà implémentée (CRUD + sell/restock). Le Flutter consomme via DTOs séparés. |
| II. Sécurité par défaut | PASS | JWT sur tous les endpoints. Isolation par user via le backend. Endpoint protégé par `Feature.SHOP` toggle. |
| III. Simplicité & YAGNI | PASS | Pattern CRUD Notifier standard. Pas de logique complexe. Server-only (pas de Drift inutile). Tri alphabétique côté client. |
| IV. Mobile-First UX | PASS | ListItem réutilisé (cohérence visuelle). Shimmer loading. Pull-to-refresh. CTA pour création. Rupture de stock visible. |
| V. Testabilité | PASS | Notifier testable via ProviderContainer + mock repository. Widget test avec ProviderScope. |
| VI. Observabilité | N/A | Feature Flutter uniquement — logs gérés côté backend. |
| VII. Self-Hosted Ready | PASS | Pas de dépendance cloud. API self-hosted. |

**Gate result**: PASS — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/060-flutter-shop-products/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── product-api.md   # API contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   ├── models/
│   │   ├── models.dart                     # MODIFY: export product.dart
│   │   └── product.dart                    # CREATE: @freezed Product
│   └── repositories/
│       ├── repositories.dart               # MODIFY: export product_repository.dart
│       └── product_repository.dart         # CREATE: abstract class
├── data/
│   ├── data_mode_provider.dart             # MODIFY: + productRepositoryProvider
│   └── remote/
│       ├── data_sources/
│       │   └── product_remote_data_source.dart  # CREATE: Dio HTTP
│       └── dtos/
│           └── product_dtos.dart           # CREATE: Request/Response
├── features/
│   └── shop/
│       ├── application/
│       │   ├── product_list_state.dart     # CREATE: @freezed state
│       │   └── product_notifier.dart       # CREATE: CRUD Notifier
│       ├── data/
│       │   └── product_repository_remote.dart  # CREATE: Remote impl
│       └── presentation/
│           └── product_list_screen.dart    # CREATE: List UI
└── routing/
    └── app_router.dart                     # MODIFY: placeholder → ProductListScreen

flutter/test/src/features/shop/
└── application/
    └── product_notifier_test.dart          # CREATE: Unit tests
```

**Structure Decision**: Feature module standard dans `features/shop/` suivant le pattern existant (subscriptions, debts). Pas de Drift local — uniquement remote via Dio.

## Complexity Tracking

> Aucune violation de la constitution — section non applicable.
