# Implementation Plan: Formulaire Produit (creation/edition)

**Branch**: `061-flutter-product-form` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/061-flutter-product-form/spec.md`

## Summary

Formulaire produit en bottom sheet modal (AppModal) pour creer et editer des produits du module Boutique. Widget `ProductForm` (ConsumerStatefulWidget) integre au systeme ModalNotifier existant, avec validation temps reel, calcul de marge dynamique, selecteur photo camera/galerie via `image_picker`, et soumission API via `ProductNotifier`. Deux nouvelles dependances (`image_picker`, `path_provider`) et un nouveau formatter decimal.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, dio, image_picker (a ajouter), path_provider (a ajouter)
**Storage**: API REST uniquement (pas de Drift/SQLite — remote only). Images stockees en fichier local (app documents directory).
**Testing**: flutter_test
**Target Platform**: iOS / Android
**Project Type**: mobile-app (module shop)
**Performance Goals**: marge temps reel < 100ms, sauvegarde percue < 2s
**Constraints**: mobile-first, single-user, single-device, API-only (pas d'offline)
**Scale/Scope**: 1 widget formulaire, 1 formatter decimal, integration modal + liste existante

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principe | Statut | Justification |
|---|----------|--------|---------------|
| I | API-First | PASS | Utilise l'API CRUD existante (POST/PUT /products). Pas de logique metier cote client. La marge est un calcul d'affichage pur. |
| II | Securite par defaut | PASS | Requetes authentifiees via JWT (Dio interceptor existant). Validation client ET serveur (Bean Validation). |
| III | Simplicite & YAGNI | PASS | Un seul widget ProductForm. Reutilise ModalNotifier, AppModal, AppFormField existants. Pas d'abstraction nouvelle. |
| IV | Mobile-First UX | PASS | Bottom sheet modal, saisie rapide (SC-001: < 30s), marge temps reel, selecteur photo natif. |
| V | Testabilite | PASS | Widget testable via ProviderScope + mocks repository. Validation testable unitairement. |
| VI | Observabilite | PASS | L'API logge deja les operations CRUD produit. Pas de logging Flutter supplementaire necessaire. |
| VII | Self-Hosted Ready | PASS | Pas de dependance cloud. Images stockees localement sur device. |

## Project Structure

### Documentation (this feature)

```text
specs/061-flutter-product-form/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/
├── pubspec.yaml                                           # MODIFY — ajouter image_picker + path_provider
├── lib/src/
│   ├── domain/enums/
│   │   └── modal_type.dart                                # MODIFY — ajouter ModalType.product
│   ├── features/
│   │   ├── modal/application/
│   │   │   └── modal_notifier.dart                        # EXISTING — pas de modification (generique)
│   │   └── shop/
│   │       ├── application/
│   │       │   └── product_notifier.dart                  # EXISTING — utilise create()/update() tels quels
│   │       └── presentation/
│   │           ├── product_list_screen.dart                # MODIFY — wire create/edit vers ModalNotifier
│   │           └── widgets/
│   │               └── product_form.dart                  # NEW — formulaire produit (ConsumerStatefulWidget)
│   ├── routing/
│   │   └── app_router.dart                                # MODIFY — ajouter case ModalType.product dans _buildModalChild
│   └── utils/
│       └── decimal_input_formatter.dart                   # NEW — TextInputFormatter limitant a 2 decimales
```

**Structure Decision**: Module shop existant. Le widget formulaire va dans `presentation/widgets/` (meme emplacement que `transaction_form.dart`, `subscription_form.dart`). Integration au systeme ModalNotifier centralise pour coherence avec les autres formulaires.

## Design Decisions

### D1 — Integration modale via ModalNotifier (pas AppModal direct)

**Choix**: Ajouter `ModalType.product` au systeme ModalNotifier centralise.

**Raison**: Coherence avec les 6 autres types de modals (transaction, subscription, debt, transfer, category, account). Le systeme gere deja le cycle create/edit, le toggle, les titres, et la fermeture.

**Alternative rejetee**: Appel direct `AppModal.show()` depuis ProductListScreen — plus simple mais introduit un second pattern d'ouverture de modal, ce qui complexifie la maintenance.

**Note**: Pas d'ajout d'item "Produit" dans le FabMenu global. Le formulaire est accessible uniquement depuis le module shop (ProductListScreen).

### D2 — Item tap de la liste = edit form (temporaire)

**Choix**: Le tap sur un produit dans la liste ouvre le formulaire d'edition en bottom sheet.

**Raison**: Le spec (US2) dit "L'utilisateur selectionne un produit existant dans la liste pour l'editer". L'ecran detail (KKS-125) n'existe pas encore.

**Note**: Quand KKS-125 sera implemente, le tap redirigera vers le detail, et l'edition sera accessible depuis le detail.

### D3 — Image picker + stockage local

**Choix**: `image_picker` pour camera/galerie. Copie du fichier dans le repertoire documents de l'app via `path_provider`. Le chemin local est envoye tel quel a l'API dans le champ `imageUrl`.

**Raison**: Single-user, single-device. Le chemin local est stable tant que l'app n'est pas reinstallee.

**Trade-off accepte**: Le chemin n'est pas portable cross-device. Acceptable pour une app self-hosted single-user.

### D4 — Champ `icone` non utilise dans le formulaire

**Choix**: Le formulaire ne montre pas d'EmojiInput. Le selecteur photo remplace l'emoji (clarification spec).

**Impact**: Le champ `icone` du Product model reste nullable mais ne sera plus renseigne par le formulaire. La liste utilise `product.imageUrl` (image) en priorite, fallback `product.icone ?? '📦'`.

### D5 — DecimalTextInputFormatter nouveau

**Choix**: Creer un `DecimalTextInputFormatter` dans `utils/` qui limite la saisie a N decimales.

**Raison**: FR-009 exige 2 decimales max. Aucun formatter existant dans le projet ne fait cela. Le `FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))` existant (AccountFormScreen) n'empeche pas les decimales excessives.

## Complexity Tracking

| # | Principe | Deviation | Justification |
|---|----------|-----------|---------------|
| IV | Mobile-First UX (offline) | Module Shop remote-only (pas de Drift/SQLite) | Heritage feature 060. Le catalogue produit necessite des donnees serveur fraiches (prix, stock). Le stockage local n'apporte pas de valeur pour un module de vente. Les images sont deja stockees localement. |
