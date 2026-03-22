# Tasks: Widget FormField

**Input**: Design documents from `/specs/035-flutter-formfield-widget/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Inclus — widget UI testable unitairement.

**Organization**: Tâches groupées par user story. Le widget est construit incrémentalement dans un seul fichier (`app_form_field.dart`) avec les tests dans un fichier séparé (`app_form_field_test.dart`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Aucun setup nécessaire — le projet Flutter existe déjà, les design tokens sont en place.

_(Phase vide — passer directement à Phase 2)_

---

## Phase 2: Foundational

**Purpose**: Aucun prérequis bloquant — les tokens `AppSpacing`, `AppRadius`, `AppColors`, `AppTypography`, `AppDurations` existent déjà.

_(Phase vide — passer directement à Phase 3)_

---

## Phase 3: User Story 1 - Affichage avec label et focus (Priority: P1)

**Goal**: Créer le widget `AppFormField` avec label au-dessus, conteneur stylé iOS (fond gris, radius xl, pas de bordure), slot enfant par composition, et bordure amber animée au focus.

**Independent Test**: Placer un TextField dans le widget, vérifier le label, le style du conteneur, les thèmes clair/sombre, et la bordure au focus/unfocus.

### Tests US1

- [X] T001 [P] [US1] Créer le fichier de test avec helper buildWidget et tests du rendu de base (label affiché, enfant visible, pas d'erreur par défaut, largeur 100% du parent) dans `flutter/test/src/common_widgets/app_form_field_test.dart`
- [X] T002 [P] [US1] Ajouter les tests thème sombre (conteneur avec surfaceContainerHighest dark, label lisible) dans `flutter/test/src/common_widgets/app_form_field_test.dart`
- [X] T003 [P] [US1] Ajouter les tests de focus (bordure amber au focus, pas de bordure au unfocus, AnimatedContainer présent) dans `flutter/test/src/common_widgets/app_form_field_test.dart`

### Implementation US1

- [X] T004 [US1] Créer le widget `AppFormField` avec label (sizeSm, medium, onSurfaceVariant), espacement space2, conteneur AnimatedContainer (surfaceContainerHighest, xl radius, space3/space4 padding), Focus wrapper avec onFocusChange pour bordure primary, slot child dans `flutter/lib/src/common_widgets/app_form_field.dart`

**Checkpoint**: Le widget affiche label + conteneur + enfant avec bordure animée au focus. Tests US1 passent.

---

## Phase 4: User Story 2 - Affichage des erreurs (Priority: P2)

**Goal**: Ajouter l'affichage conditionnel d'un message d'erreur sous le conteneur, contrôlé par `showError` et `errorMessage`.

**Independent Test**: Passer showError=true avec un message, vérifier qu'il apparaît en rouge sous le conteneur. Passer showError=false, vérifier qu'il n'apparaît pas.

**Depends on**: Phase 3 (le widget de base doit exister)

### Tests US2

- [X] T005 [P] [US2] Ajouter les tests d'erreur (message visible quand showError=true, message caché quand showError=false, couleur error, taille sizeXs) dans `flutter/test/src/common_widgets/app_form_field_test.dart`

### Implementation US2

- [X] T006 [US2] Ajouter les paramètres `showError` (bool, défaut false) et `errorMessage` (String, défaut '') au widget, afficher conditionnellement le message en colorScheme.error avec sizeXs sous le conteneur, enveloppé dans un AnimatedSize (duration: 200ms, curve: easeInOut) pour la transition fluide dans `flutter/lib/src/common_widgets/app_form_field.dart`

**Checkpoint**: Le widget affiche/masque le message d'erreur selon showError. Tests US1 + US2 passent.

---

## Phase 5: User Story 3 - Composition multi-types (Priority: P3)

**Goal**: Vérifier que le widget accepte et affiche correctement différents types d'enfants (TextField, DropdownButton, Switch, widget custom).

**Independent Test**: Placer différents widgets enfants et vérifier qu'ils s'affichent sans conflit de style.

**Depends on**: Phase 3 (composition via child est déjà intégrée dans US1)

### Tests US3

- [X] T007 [US3] Ajouter les tests de composition (TextField avec InputDecoration.collapsed, DropdownButton, Switch, widget Row personnalisé — tous doivent s'afficher dans le conteneur stylé) dans `flutter/test/src/common_widgets/app_form_field_test.dart`
- [X] T007b [P] [US3] Ajouter les tests edge cases (label vide, label long >50 chars avec ellipsis, message d'erreur long >100 chars multi-lignes, enfant à hauteur variable, conteneur étroit <200px) dans `flutter/test/src/common_widgets/app_form_field_test.dart`

**Checkpoint**: Le widget accepte au moins 3 types de widgets enfants différents et gère les cas limites. Tests US1 + US2 + US3 passent.

---

## Phase 6: User Story 4 - Accessibilité (Priority: P4)

**Goal**: Associer sémantiquement le label au champ enfant et annoncer les erreurs via live region.

**Independent Test**: Vérifier que Semantics contient le label et que l'erreur est annoncée.

**Depends on**: Phase 4 (l'erreur doit exister pour être annoncée)

### Tests US4

- [X] T008 [P] [US4] Ajouter les tests d'accessibilité (Semantics avec label associé, MergeSemantics pour label+champ, erreur avec liveRegion quand showError=true) dans `flutter/test/src/common_widgets/app_form_field_test.dart`

### Implementation US4

- [X] T009 [US4] Ajouter MergeSemantics autour du widget, Semantics avec label sur le conteneur, et Semantics liveRegion sur le message d'erreur dans `flutter/lib/src/common_widgets/app_form_field.dart`

**Checkpoint**: Le widget est accessible. Tests US1 + US2 + US3 + US4 passent.

---

## Phase 7: Polish & Validation

**Purpose**: Validation finale, analyse statique, exécution de tous les tests.

- [X] T010 Exécuter `flutter analyze` sur `flutter/lib/src/common_widgets/app_form_field.dart` et corriger les warnings
- [X] T011 Exécuter `flutter test test/src/common_widgets/app_form_field_test.dart` et vérifier que tous les tests passent
- [X] T012 Valider les scénarios du quickstart.md (vérifier que l'API du widget correspond aux exemples documentés)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Vide — rien à faire
- **Phase 2 (Foundational)**: Vide — tokens déjà en place
- **Phase 3 (US1)**: Aucune dépendance — commence immédiatement
- **Phase 4 (US2)**: Dépend de Phase 3 (widget de base)
- **Phase 5 (US3)**: Dépend de Phase 3 (composition via child)
- **Phase 6 (US4)**: Dépend de Phase 4 (erreur pour liveRegion)
- **Phase 7 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Aucune dépendance — crée le widget de base
- **US2 (P2)**: Dépend de US1 — ajoute l'erreur au widget existant
- **US3 (P3)**: Dépend de US1 — valide la composition (tests uniquement)
- **US4 (P4)**: Dépend de US2 — ajoute Semantics et liveRegion sur l'erreur

### Parallel Opportunities

- **T001, T002, T003** peuvent être écrits en parallèle (tests US1 dans le même fichier mais sections indépendantes)
- **T005, T007 et T007b** : les tests US2, US3 et edge cases sont indépendants après que T004 soit complété
- **T008** peut être écrit en parallèle avec T007 (tests US4 vs tests US3)
- **T010 et T011** peuvent s'exécuter en parallèle (analyze vs test)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 3 (T001-T004) → Widget fonctionnel avec label + conteneur + focus
2. **STOP et VALIDER** : le widget s'affiche correctement avec un TextField
3. Livrable minimal utilisable dans les formulaires

### Incremental Delivery

1. Phase 3 (US1) → Widget de base fonctionnel (MVP)
2. Phase 4 (US2) → Ajout des erreurs → Widget complet pour les formulaires avec validation
3. Phase 5 (US3) → Validation de la composition → Confiance pour usage multi-contexte
4. Phase 6 (US4) → Accessibilité → Widget production-ready
5. Phase 7 (Polish) → Validation finale → Prêt à merger

---

## Notes

- Le widget est dans un SEUL fichier source (`app_form_field.dart`) — les phases ajoutent incrémentalement des fonctionnalités au même fichier
- Les tests sont dans un SEUL fichier (`app_form_field_test.dart`) — chaque phase ajoute un groupe de tests
- US3 (composition) n'a pas de tâche d'implémentation car la composition est intrinsèquement supportée par le `child` slot de US1
- Le widget utilise `StatefulWidget` car il a besoin d'un état local `_hasFocus` pour le Focus wrapper
