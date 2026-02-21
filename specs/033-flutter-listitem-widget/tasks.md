# Tasks: Widget ListItem réutilisable (Flutter)

**Input**: Design documents from `/specs/033-flutter-listitem-widget/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus (SC-003 exige 100% des tests unitaires).

**Organization**: Tâches groupées par user story pour permettre l'implémentation et le test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans chaque description

## Path Conventions

- **Mobile (Flutter)**: `flutter/lib/src/` pour le code source, `flutter/test/src/` pour les tests

---

## Phase 1: Setup

**Purpose**: Ajout de la dépendance shimmer et création des fichiers

- [x] T001 Ajouter la dépendance `shimmer: ^3.0.0` dans `flutter/pubspec.yaml` et exécuter `flutter pub get`
- [x] T002 [P] Créer `flutter/lib/src/common_widgets/list_item.dart` avec la classe `ListItem extends StatelessWidget`, le champ `final bool _isSkeleton`, le constructeur principal avec les 8 paramètres (icon, title, value, subtitle?, rightSubtitle?, valueColor?, iconBackgroundColor?, onPressed?) et `: _isSkeleton = false`, assertions debug `assert(icon.isNotEmpty)`, `assert(title.isNotEmpty)`, `assert(value.isNotEmpty)` dans le constructeur principal (cf. data-model.md Validation Rules), et un `build()` retournant `const SizedBox.shrink()`
- [x] T003 [P] Créer `flutter/test/src/common_widgets/list_item_test.dart` avec le scaffold de test (imports, helper `pumpListItem` wrappant le widget dans `MaterialApp` + `Theme` avec `AppThemeExtension`, groupe de tests vide). Convention de nommage des tests : `should_[résultat]_when_[condition]` (Constitution V)

**Checkpoint**: Les fichiers existent, `flutter pub get` passe, le test scaffold compile.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Aucune tâche fondationnelle requise — tous les design tokens (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppThemeExtension`) et utilitaires (`AmountFormatter`, `RelativeDateFormatter`) existent déjà.

**Checkpoint**: N/A — passage direct aux user stories.

---

## Phase 3: User Story 1 — Affichage d'une transaction dans une liste (Priority: P1) MVP

**Goal**: Le widget ListItem affiche les 5 zones (icône cercle, titre, sous-titre, valeur colorée, date relative) avec le layout fidèle au composant Angular app-list-item.

**Independent Test**: Instancier le widget avec des données de transaction et vérifier le rendu visuel de chaque zone.

### Implementation for User Story 1

- [x] T004 [US1] Implémenter la zone icône dans `ListItem.build()` : `Container` 40x40 (`AppSpacing.space10`), cercle (`AppRadius.round`), fond `iconBackgroundColor ?? AppColors.amber100`, emoji centré (`AppTypography.sizeLg`) dans `flutter/lib/src/common_widgets/list_item.dart`
- [x] T005 [US1] Implémenter la zone contenu central : `Expanded` + `Column(crossAxisAlignment: start)` avec `Text` title (medium 16px, ellipsis maxLines:1) et `Text?` subtitle conditionnel (regular 14px, secondary, ellipsis), gap 4px (`AppSpacing.space1`) dans `flutter/lib/src/common_widgets/list_item.dart`
- [x] T006 [US1] Implémenter la zone valeur droite : `Column(crossAxisAlignment: end)` avec `Text` value (semiBold 16px, `valueColor ?? onSurface`) et `Text?` rightSubtitle conditionnel (regular 14px, secondary), gap 4px dans `flutter/lib/src/common_widgets/list_item.dart`
- [x] T007 [US1] Assembler le layout complet dans `build()` : wrapper conditionnel `InkWell` (si onPressed != null) ou `Padding` (si null), padding 12px/16px (`AppSpacing.space3`/`space4`), `Row` gap 12px (`AppSpacing.space3`) contenant les 3 zones dans `flutter/lib/src/common_widgets/list_item.dart`
- [x] T008 [US1] Écrire les tests US1 dans `flutter/test/src/common_widgets/list_item_test.dart` : (1) les 5 zones sont rendues avec données complètes, (2) valueColor rouge appliquée sur le montant, (3) valueColor verte appliquée sur le montant, (4) onPressed callback déclenché au tap

**Checkpoint**: Le widget affiche correctement une transaction complète. 4 tests passent.

---

## Phase 4: User Story 2 — Affichage avec données partielles (Priority: P2)

**Goal**: Le widget reste cohérent et élégant quand subtitle et/ou rightSubtitle sont absents.

**Independent Test**: Instancier avec uniquement icon, title, value et vérifier que les zones optionnelles n'apparaissent pas et ne laissent pas de vide.

### Implementation for User Story 2

- [x] T009 [US2] Écrire les tests US2 dans `flutter/test/src/common_widgets/list_item_test.dart` : (1) sans subtitle → `Text` subtitle absent du widget tree, (2) sans rightSubtitle → seul le montant affiché dans la colonne droite, (3) sans subtitle ni rightSubtitle → widget affiche uniquement icône, titre et montant

**Checkpoint**: Le rendu est correct avec données partielles. 3 tests supplémentaires passent. (L'implémentation conditionnelle est déjà en place depuis T005/T006 via les checks `if (subtitle != null)`)

---

## Phase 5: User Story 3 — Adaptabilité aux contextes métier (Priority: P2)

**Goal**: Le même widget ListItem est utilisable pour les 4 contextes (dashboard, transactions, abonnements, dettes) sans modification.

**Independent Test**: Instancier avec des données de chaque type métier et vérifier un rendu correct.

### Implementation for User Story 3

- [x] T010 [US3] Écrire les tests US3 dans `flutter/test/src/common_widgets/list_item_test.dart` : (1) rendu avec données abonnement (icône 📺, titre "Netflix", value "12,99 €", subtitle "Mensuel"), (2) rendu avec données dette (icône 📤, titre "Jean Dupont", value "150,00 €", valueColor income, subtitle "Prêt"), (3) rendu avec données dashboard (icône 🛒, titre "Courses Lidl", value "-45,90 €", valueColor expense, rightSubtitle "Hier")

**Checkpoint**: Le widget rend correctement les 4 contextes métier. 3 tests supplémentaires passent. (Aucune modification du widget — seule la diversité des données en entrée change)

---

## Phase 6: User Story 4 — Accessibilité et interaction tactile (Priority: P3)

**Goal**: Le widget fournit un feedback tactile (ripple) et une sémantique pour lecteurs d'écran, plus un constructeur skeleton pour l'état de chargement.

**Independent Test**: Vérifier le déclenchement du callback, la présence du feedback visuel et l'annonce correcte par le lecteur d'écran.

### Implementation for User Story 4

- [x] T011 [US4] Ajouter le wrapper `Semantics` avec `label` combinant title et value, `button: true` seulement quand `onPressed != null`, dans `flutter/lib/src/common_widgets/list_item.dart`
- [x] T012 [US4] Implémenter le constructeur nommé `ListItem.skeleton({super.key})` initialisant les champs requis avec des valeurs vides et `_isSkeleton = true`. Dans `build()`, brancher sur `_isSkeleton` pour afficher des placeholders shimmer animés (`Shimmer.fromColors` wrappant des `Container` arrondis gris reproduisant la forme du widget) dans `flutter/lib/src/common_widgets/list_item.dart`
- [x] T013 [US4] Écrire les tests US4 dans `flutter/test/src/common_widgets/list_item_test.dart` : (1) `Semantics` avec label combiné présent, (2) `Semantics` button:true quand onPressed fourni, (3) pas de sémantique button quand onPressed null, (4) `ListItem.skeleton()` rend des placeholders shimmer (widget `Shimmer` trouvé dans l'arbre)

**Checkpoint**: Accessibilité et skeleton fonctionnels. 4 tests supplémentaires passent.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Tests edge cases et validation finale

- [x] T014 Écrire les tests edge cases dans `flutter/test/src/common_widgets/list_item_test.dart` : (1) titre très long (> 30 car.) → `TextOverflow.ellipsis` dans le style, (2) emoji multi-byte (drapeau 🇫🇷) → widget rend sans erreur, (3) onPressed null → pas d'`InkWell` dans le widget tree, (4) `iconBackgroundColor` custom → couleur appliquée sur le cercle, (5) montant "0,00 €" sans valueColor → couleur par défaut onSurface (EC-002), (6) rendu avec dark theme → couleurs onSurface/onSurfaceVariant du thème sombre (EC-004), (7) assertions debug : icon vide lève `AssertionError`, title vide lève `AssertionError`, value vide lève `AssertionError` (3 tests, cf. data-model.md Validation Rules)
- [x] T015 Exécuter la suite complète de tests (`flutter test test/src/common_widgets/list_item_test.dart`) et valider que tous les tests passent
- [x] T016 Valider SC-005 (scroll fluide) : créer un test de rendu avec `ListView.builder` de 50 items `ListItem` et vérifier que le build ne lève pas d'erreur et que le scroll fonctionne (`dragFrom`/`dragUntilVisible`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — démarrage immédiat
- **Foundational (Phase 2)**: N/A — tout est déjà en place
- **US1 (Phase 3)**: Dépend de Phase 1 (T001, T002, T003) — MVP
- **US2 (Phase 4)**: Dépend de US1 (T004-T007 pour l'implémentation)
- **US3 (Phase 5)**: Dépend de US1 (T004-T007 pour l'implémentation)
- **US4 (Phase 6)**: Dépend de US1 (T004-T007 pour l'implémentation)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes (T014-T016)

### User Story Dependencies

- **US1 (P1)**: Dépend de Setup — Aucune dépendance inter-story
- **US2 (P2)**: Dépend de US1 (widget implémenté) — Tests uniquement, pas de modification du widget
- **US3 (P2)**: Dépend de US1 (widget implémenté) — Tests uniquement, pas de modification du widget
- **US4 (P3)**: Dépend de US1 (widget implémenté) — Ajoute Semantics + skeleton au widget

### Within Each User Story

- Implémentation (zones du widget) avant tests
- Core layout avant wrapper interactif
- Tests vérifient les acceptance scenarios de la spec

### Parallel Opportunities

- T002 et T003 peuvent s'exécuter en parallèle (fichiers différents)
- US2 et US3 sont indépendantes entre elles (tests uniquement) et peuvent s'exécuter en parallèle après US1
- T011 et T012 (US4) modifient le même fichier mais des zones différentes (Semantics vs skeleton constructor)

---

## Parallel Example: User Story 1

```bash
# Après Phase 1, lancer l'implémentation des zones en séquence (même fichier) :
# T004 → T005 → T006 → T007 (build incrémental du même fichier)
# Puis les tests :
# T008 (vérifie les 4 acceptance scenarios)
```

## Parallel Example: User Stories 2 & 3

```bash
# Après US1 terminée, ces deux stories sont parallélisables (tests uniquement) :
Task: "T009 [US2] Tests données partielles"
Task: "T010 [US3] Tests multi-contexte"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001-T003)
2. Compléter Phase 3: US1 (T004-T008)
3. **STOP et VALIDER**: Le widget affiche correctement une transaction avec les 5 zones
4. Commit et démo possible

### Incremental Delivery

1. Setup (T001-T003) → Fichiers prêts
2. US1 (T004-T008) → Widget fonctionnel avec transaction → Commit (MVP)
3. US2 (T009) → Données partielles validées → Commit
4. US3 (T010) → Multi-contexte validé → Commit
5. US4 (T011-T013) → Accessibilité + skeleton → Commit
6. Polish (T014-T016) → Edge cases + scroll perf + validation → Commit final

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label = traçabilité vers la user story de la spec
- US2 et US3 ne modifient pas le widget — uniquement des tests validant le comportement déjà implémenté en US1
- US4 est la seule story post-MVP qui modifie le fichier widget (Semantics + skeleton)
- Commiter après chaque phase/checkpoint
