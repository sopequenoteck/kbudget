# Implementation Plan: Système de Catégories

**Branch**: `018-category-system` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/018-category-system/spec.md`

## Summary

Compléter le système de catégories existant (CRUD déjà en place) en ajoutant : le concept de catégorie système (`isSystem`), le seeding automatique à l'inscription, un composant autocomplete avec création à la volée (modal emoji picker), l'affichage des emojis dans les listes, l'attribution par défaut aux abonnements/dettes, et une page de gestion dans les Paramètres.

## Technical Context

**Language/Version**: Java 21 (backend) / TypeScript 5.9.2 (frontend)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21.1.0, @angular/cdk (overlay, a11y)
**Storage**: PostgreSQL 15+ via Spring Data JPA, Flyway migrations
**Testing**: JUnit 5 + Mockito (backend) / Vitest 4.x (frontend)
**Target Platform**: Web PWA mobile-first
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: Filtrage autocomplete instantané côté client (pas de requête par frappe)
**Constraints**: <200ms réponse API, palette 12 couleurs hex, nom max 30 chars
**Scale/Scope**: Single-user self-hosted, ~50-100 catégories max par utilisateur

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Vérification |
|----------|--------|-------------|
| I. API-First | PASS | Endpoints REST existants, DTOs séparés. Ajout champ `isSystem` dans CategoryResponse. |
| II. Sécurité par défaut | PASS | Isolation par user existante. Ajout garde : interdire DELETE/PUT sur catégories système. |
| III. Simplicité & YAGNI | PASS | Controller → Service → Repository maintenu. Pas de pattern complexe. |
| IV. Mobile-First UX | PASS | Autocomplete avec création à la volée = saisie rapide. Grille emoji simplifiée. |
| V. Testabilité | PASS | Tests unitaires service (isSystem guards), tests composant autocomplete. |
| VI. Observabilité | PASS | Logger les actions catégorie système (seeding, tentative suppression). |
| VII. Self-Hosted Ready | PASS | Pas de dépendance externe ajoutée. Seeding via Flyway + code. |

## Project Structure

### Documentation (this feature)

```text
specs/018-category-system/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── model/Category.java              # MODIFIER: ajouter isSystem boolean
│   ├── dto/
│   │   ├── request/CategoryRequest.java  # INCHANGÉ (pas de isSystem en input)
│   │   └── response/CategoryResponse.java # MODIFIER: ajouter isSystem boolean
│   ├── service/
│   │   ├── CategoryService.java          # MODIFIER: gardes isSystem, seeding, résolution par défaut
│   │   ├── AuthService.java              # MODIFIER: appel seeding après register
│   │   ├── SubscriptionService.java      # MODIFIER: attribution catégorie système par défaut
│   │   └── DebtService.java              # MODIFIER: attribution catégorie système par défaut
│   └── repository/CategoryRepository.java # MODIFIER: findByUserIdAndIsSystem query
├── src/main/resources/db/migration/
│   └── V5__add_is_system_and_seed.sql    # CRÉER: colonne is_system + seed users existants
└── src/test/java/.../service/
    └── CategoryServiceTest.java          # MODIFIER: tests isSystem

app/
├── src/app/
│   ├── core/
│   │   ├── models/category.model.ts      # MODIFIER: ajouter isSystem boolean
│   │   └── services/
│   │       ├── category.ts               # INCHANGÉ (API déjà suffisante)
│   │       └── modal.service.ts          # MODIFIER: ajouter type 'category' (page Settings uniquement)
│   ├── shared/
│   │   └── components/
│   │       ├── category-picker/          # CRÉER: composant autocomplete + création à la volée
│   │       │   ├── category-picker.ts
│   │       │   ├── category-picker.html
│   │       │   └── category-picker.scss
│   │       ├── category-form/            # CRÉER: modal création/édition catégorie (nom + emoji grid)
│   │       │   ├── category-form.ts
│   │       │   ├── category-form.html
│   │       │   └── category-form.scss
│   │       └── emoji-grid/               # CRÉER: grille d'emojis prédéfinis
│   │           ├── emoji-grid.ts
│   │           ├── emoji-grid.html
│   │           └── emoji-grid.scss
│   └── features/
│       ├── transactions/components/
│       │   └── transaction-form/         # MODIFIER: remplacer <select> par category-picker
│       ├── subscriptions/components/
│       │   └── subscription-form/        # MODIFIER: remplacer <select> par category-picker
│       ├── debts/components/
│       │   └── debt-form/                # MODIFIER: remplacer <select> par category-picker
│       ├── settings/                     # CRÉER: page Paramètres avec gestion catégories
│       │   ├── settings.ts
│       │   ├── settings.html
│       │   ├── settings.scss
│       │   └── settings.routes.ts
│       └── dashboard/                    # MODIFIER: afficher emoji catégorie dans listes
├── src/app/shared/components/
│   ├── shell/shell.ts                    # MODIFIER: ajouter lien navigation Paramètres
│   └── shell/shell.html                  # MODIFIER: ajouter lien navigation Paramètres
└── src/app/app.routes.ts                 # MODIFIER: ajouter route /settings
```

**Structure Decision**: Monorepo existant api/ + app/. Pas de nouveau module. Les composants catégorie sont dans `shared/` car réutilisés dans les 3 formulaires + la page Paramètres.

## Complexity Tracking

Aucune violation de la constitution. Pas de pattern complexe ajouté.
