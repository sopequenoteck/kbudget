# Implementation Plan: Flutter — Système Modal / Bottom Sheet

**Branch**: `036-flutter-modal-system` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/036-flutter-modal-system/spec.md`

## Summary

Implémenter un système de modale global dans le shell Flutter : bottom sheet sur mobile, dialog centré sur tablette. Inclut un header avec toggle type (Dépense/Recette, Mensuel/Annuel, Emprunt/Prêt) et un état centralisé via Riverpod Notifier. Le système supporte 6 types de modale (transaction, abonnement, dette, virement, catégorie, compte) en mode création et édition. Les formulaires sont hors scope — seul le conteneur modal et son header sont livrés.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod ^2.6.1, go_router ^14.8.1, freezed_annotation ^2.4.4
**Storage**: N/A (composant UI pur, pas de persistance)
**Testing**: flutter_test (widget tests), mockito ^5.4.5 (mocking), ProviderContainer (Riverpod tests)
**Target Platform**: Android / iOS (mobile-first), tablette iPad/Android (layout adaptatif)
**Project Type**: Mobile (Flutter)
**Performance Goals**: Animation 60fps, toggle < 100ms perçu, ouverture/fermeture fluide sur milieu de gamme
**Constraints**: Bottom sheet max 90% hauteur écran, scroll interne, repositionnement clavier, survie rotation
**Scale/Scope**: 6 types de modale, 2 modes (création/édition), 3 toggles (transaction, abonnement, dette)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
| -------- | ------ | ------------- |
| I. API-First | N/A | Feature Flutter UI uniquement, aucun endpoint API créé ou modifié |
| II. Sécurité par défaut | N/A | Composant UI pur, pas de manipulation de données sensibles |
| III. Simplicité & YAGNI | PASS | Architecture simple : 1 Notifier + 1 State + 1 Widget modal + 1 Widget toggle. Pas de pattern complexe. |
| IV. Mobile-First UX | PASS | Bottom sheet natif sur mobile, dialog sur tablette. FAB → type = 2 taps pour créer. Toggle 1 tap. |
| V. Testabilité | PASS | Notifier testable via ProviderContainer, widgets testables via flutter_test. Nommage should_*_when_*. |
| VI. Observabilité | N/A | Composant UI pur, pas de logging serveur. Debug via Flutter DevTools. |
| VII. Self-Hosted Ready | N/A | Aucune dépendance infra ajoutée. |

**Résultat** : PASS — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/036-flutter-modal-system/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── common_widgets/
│   ├── adaptive_scaffold.dart       # Existant — intègre la modale dans le shell
│   ├── fab_menu.dart                # Existant — modifié pour déclencher l'ouverture modale
│   ├── app_modal.dart               # NOUVEAU — Widget modal adaptatif (bottom sheet / dialog)
│   └── app_toggle.dart              # NOUVEAU — Widget toggle réutilisable (2 options)
├── domain/
│   └── enums/
│       └── modal_type.dart          # NOUVEAU — Enum des types de modale
└── features/
    └── modal/
        └── application/
            ├── modal_notifier.dart  # NOUVEAU — Notifier état global modale
            └── modal_state.dart     # NOUVEAU — State freezed (type, mode, entité, sous-type)

flutter/test/
├── common_widgets/
│   ├── app_modal_test.dart          # NOUVEAU — Tests widget modal
│   └── app_toggle_test.dart         # NOUVEAU — Tests widget toggle
└── features/
    └── modal/
        └── application/
            └── modal_notifier_test.dart  # NOUVEAU — Tests notifier
```

**Structure Decision** : La modale est un widget commun (`common_widgets/`) car elle est utilisée par le shell global, pas par une feature spécifique. L'état est dans `features/modal/application/` car il suit le pattern Clean Architecture existant (application layer = notifiers + states). Le toggle est un widget réutilisable dans `common_widgets/`.

## Complexity Tracking

> Aucune violation — tableau non requis.
