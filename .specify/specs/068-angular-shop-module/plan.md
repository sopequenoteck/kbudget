# Implementation Plan: Module Boutique Angular

**Branch**: `068-angular-shop-module` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/068-angular-shop-module/spec.md`

## Summary

Implementer le module Boutique complet dans Angular avec parite fonctionnelle Flutter : liste des produits (avec filtre actifs/inactifs), formulaire creation/edition (modal global), page detail avec statistiques, actions vendre/restocker (detail + FAB vente rapide), et historique des ventes. Necessite des modifications backend mineures (parametre `includeInactive` sur GET /products, SellRequest sur POST sell) et la creation/modification d'environ 18 fichiers.

## Technical Context

**Language/Version**: TypeScript 5.9 (Angular), Java 21 (backend modification mineure)
**Primary Dependencies**: Angular 21, Angular Reactive Forms, Angular Router, Angular Signals
**Storage**: N/A (server-only, pas de stockage local)
**Testing**: Vitest (Angular), JUnit 5 (backend)
**Target Platform**: Web PWA (mobile-first responsive)
**Project Type**: Web application (frontend Angular + backend Spring Boot)
**Performance Goals**: Liste chargee en < 2s, interactions vente/restock en < 3-4 clics
**Constraints**: Feature gated par toggle SHOP, JWT auth obligatoire
**Scale/Scope**: Single-user, ~18 fichiers a creer/modifier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | L'API backend Product existe deja (CRUD + sell + restock + sales). Modification mineure pour le filtre inactifs. Les DTOs separent bien API et persistance. |
| II. Securite par defaut | PASS | JWT sur tous les endpoints. Feature SHOP verifiee cote serveur (`checkShopEnabled`). Isolation par user. Bean Validation sur DTOs. |
| III. Simplicite & YAGNI | PASS | Pattern Controller → Service → Repository respecte. Pas de nouvelle abstraction. Suit les patterns existants (ListItem, ModalService, FormField). |
| IV. Mobile-First UX | PASS | Liste verticale ListItem (pattern mobile-first). FAB sur /shop avec "Nouveau produit" + "Vente rapide". Dialogs simples pour restock (detail) et vente (FAB). |
| V. Testabilite | PASS | Tests unitaires prevus pour service et composants. Pattern Arrange-Act-Assert. |
| VI. Observabilite | PASS | Backend deja logge les actions product. Pas de changement necessaire. |
| VII. Self-Hosted Ready | PASS | Pas de nouvelle dependance infra. PostgreSQL seul. |

**Post-Phase 1 re-check**: Tous les principes restent satisfaits. La modification backend (ajout param query) est minimale et ne viole aucun principe.

## Project Structure

### Documentation (this feature)

```text
specs/068-angular-shop-module/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 — decisions et patterns
├── data-model.md        # Phase 1 — modele de donnees Angular
├── quickstart.md        # Phase 1 — guide demarrage rapide
├── contracts/
│   └── product-api.md   # Phase 1 — contrat API produits
├── checklists/
│   └── requirements.md  # Checklist qualite spec
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/ProductController.java       # MODIFIER — ajouter @RequestParam includeInactive + SellRequest body optionnel
├── service/ProductService.java             # MODIFIER — brancher logique includeInactive + sell quantity
├── repository/ProductRepository.java       # MODIFIER — ajouter query tous produits
└── dto/SellRequest.java                    # CREER — record SellRequest(@Positive Integer quantity)

app/src/app/
├── core/
│   ├── models/product.model.ts             # CREER — Product, ProductRequest, ProductUpdateRequest, RestockRequest, SellRequest
│   └── services/
│       ├── product.ts                      # CREER — ProductService (CRUD + sell + restock + sales)
│       └── modal.service.ts                # MODIFIER — ajouter 'product' et 'sell' a ModalType
├── features/shop/
│   ├── shop.routes.ts                      # CREER — routes /shop, /shop/:id
│   ├── shop-list/
│   │   ├── shop-list.ts                    # CREER — composant liste produits
│   │   ├── shop-list.html                  # CREER — template liste
│   │   └── shop-list.scss                  # CREER — styles liste
│   ├── shop-detail/
│   │   ├── shop-detail.ts                  # CREER — composant detail produit
│   │   ├── shop-detail.html                # CREER — template detail (stats, actions, historique)
│   │   └── shop-detail.scss                # CREER — styles detail
│   ├── components/
│   │   ├── product-form/
│   │   │   ├── product-form.ts             # CREER — formulaire creation/edition
│   │   │   ├── product-form.html           # CREER — template formulaire
│   │   │   └── product-form.scss           # CREER — styles formulaire
│   │   ├── restock-dialog/
│   │   │   ├── restock-dialog.ts           # CREER — dialog restock (quantite)
│   │   │   ├── restock-dialog.html         # CREER — template dialog
│   │   │   └── restock-dialog.scss         # CREER — styles dialog
│   │   └── sell-dialog/
│   │       ├── sell-dialog.ts              # CREER — dialog vente (selecteur produit + quantite)
│   │       ├── sell-dialog.html            # CREER — template dialog
│   │       └── sell-dialog.scss            # CREER — styles dialog
│   └── shop-placeholder.ts                 # SUPPRIMER — remplace par ShopList
├── shared/components/
│   ├── shell/shell.ts                      # MODIFIER — import ProductForm + handlers
│   ├── shell/shell.html                    # MODIFIER — ajouter @case('product') et @case('sell')
│   └── fab/fab.ts                          # MODIFIER — ajouter actions product + sell conditionnelles sur /shop
└── app.routes.ts                           # MODIFIER — loadComponent → loadChildren pour /shop
```

**Structure Decision**: Web application avec modification mineure backend (3 fichiers) et creation module Angular complet (15 fichiers). Suit le pattern feature-based existant (`features/shop/`).

## Complexity Tracking

Aucune violation de la constitution. Pas de complexite additionnelle.
