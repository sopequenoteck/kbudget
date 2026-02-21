# Tasks: Widget filtres segmentés (SegmentedFilter)

**Input**: Design documents from `/specs/038-flutter-segmentedfilter-widget/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus — le principe V (Testabilité) de la constitution l'exige, et le projet a ~20-30 tests par widget complexe.

**Organization**: Tasks groupées par user story pour permettre l'implémentation et le test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle avec les tâches d'implémentation de la même phase (fichier test vs fichier source), mais séquentiellement par rapport aux autres tâches [P] (même fichier test)
- **[Story]**: User story concernée (US1, US2, US3, US4)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup

**Purpose**: Création des fichiers et structure de base

- [x] T001 Créer `flutter/lib/src/common_widgets/segmented_filter.dart` avec la classe `SegmentedFilterItem<T>` (champs `value: T` et `label: String`, constructeur const, assertion `label.isNotEmpty`) et le squelette vide du widget `SegmentedFilter<T>` (StatelessWidget, constructeur avec `items`, `selectedValue`, `onChanged`, assertions `items.length >= 2` et `items.length <= 5`, méthode `build` retournant un `Placeholder`)
- [x] T002 Créer `flutter/test/src/common_widgets/segmented_filter_test.dart` avec la fonction helper `pumpSegmentedFilter(WidgetTester tester, SegmentedFilter widget, {ThemeData? theme})` qui wrappe dans `MaterialApp(theme: theme ?? AppTheme.light, home: Scaffold(body: widget))`, et un test smoke `should_render_when_validItemsProvided` vérifiant que le widget s'affiche sans erreur avec 3 segments String

**Checkpoint**: Structure en place, le test smoke passe

---

## Phase 2: US1 - Filtrer une liste par catégorie (Priority: P1) — MVP

**Goal**: Le widget affiche des segments horizontaux, chacun cliquable, et notifie le parent du changement de sélection via callback typé.

**Independent Test**: Afficher le widget avec 3 segments (Tous / Dépenses / Recettes), taper sur chaque segment, vérifier le callback.

### Tests US1

- [x] T003 [P] [US1] Écrire les tests d'interaction dans `flutter/test/src/common_widgets/segmented_filter_test.dart` group `US1 - Filtrage` : `should_callOnChanged_when_inactiveSegmentTapped` (tap sur segment inactif → callback appelé avec la bonne valeur), `should_notCallOnChanged_when_activeSegmentTapped` (tap sur segment déjà actif → callback non appelé), `should_callOnChangedWithCorrectValue_when_thirdSegmentTapped` (tap sur le 3e segment → callback avec la 3e valeur)

### Implementation US1

- [x] T004 [US1] Implémenter le `build()` de `SegmentedFilter<T>` dans `flutter/lib/src/common_widgets/segmented_filter.dart` : `Container` externe (hauteur 36, pleine largeur) contenant un `Row` avec `spacing: AppSpacing.space1` (4px entre segments, conforme FR-004) et `List.generate(items.length)` où chaque segment est un `Expanded` > `GestureDetector(onTap:)` > `Container` > `Text(item.label)`. La logique `onTap` : si `item.value != selectedValue` alors appeler `onChanged(item.value)`, sinon ne rien faire. Déterminer `isSelected` via `item.value == selectedValue`.

**Checkpoint**: Le widget affiche les segments, le tap déclenche le callback — US1 fonctionnelle et testable indépendamment

---

## Phase 3: US2 - Cohérence visuelle et thèmes (Priority: P2)

**Goal**: Le widget utilise les tokens du design system (couleurs, rayons, ombres, typographie) et s'adapte aux thèmes clair/sombre avec des animations cross-fade.

**Independent Test**: Afficher le widget dans les thèmes clair et sombre, vérifier les couleurs et l'animation.

### Tests US2

- [x] T005 [P] [US2] Écrire les tests visuels dans `flutter/test/src/common_widgets/segmented_filter_test.dart` group `US2 - Design` : `should_useCorrectContainerStyle_when_lightTheme` (fond surfaceContainerHighest, borderRadius AppRadius.lg, padding AppSpacing.space1), `should_useCorrectActiveSegmentStyle_when_lightTheme` (fond surface, boxShadow AppShadows.sm, borderRadius AppRadius.md), `should_useCorrectTextStyle_when_segmentActive` (couleur onSurface, fontWeight semiBold, fontSize sizeSm), `should_useCorrectTextStyle_when_segmentInactive` (couleur onSurfaceVariant, fontWeight medium), `should_adaptColors_when_darkTheme` (passer AppTheme.dark et vérifier les couleurs du thème sombre)

### Implementation US2

- [x] T006 [US2] Appliquer les design tokens dans `flutter/lib/src/common_widgets/segmented_filter.dart` : Container externe (`color: colorScheme.surfaceContainerHighest`, `borderRadius: AppRadius.lg`, `padding: EdgeInsets.all(AppSpacing.space1)`, `height: 36`). Row avec `spacing: AppSpacing.space1` (4px entre segments, cohérent avec le gap Angular `--space-1`). Chaque segment : `AnimatedContainer(duration: AppDurations.fast, curve: Curves.easeInOut)` avec fond conditionnel (`colorScheme.surface` + `AppShadows.sm` si actif, transparent sinon), `borderRadius: AppRadius.md`. Texte : `AnimatedDefaultTextStyle(duration: AppDurations.fast)` avec `color: colorScheme.onSurface, fontWeight: semiBold` si actif, `color: colorScheme.onSurfaceVariant, fontWeight: medium` sinon. Importer `app_durations`, `app_radius`, `app_shadows`, `app_spacing`, `app_typography`.

**Checkpoint**: Le widget a le bon style iOS Segmented Control dans les deux thèmes, avec animations fluides

---

## Phase 4: US3 - Adaptabilité à différents contextes (Priority: P2)

**Goal**: Le widget gère correctement 2 à 5 segments, les labels longs (troncature), et fonctionne avec n'importe quel type générique.

**Independent Test**: Instancier avec 2, 3, 5 segments et vérifier l'affichage.

### Tests US3

- [x] T007 [P] [US3] Écrire les tests d'adaptabilité dans `flutter/test/src/common_widgets/segmented_filter_test.dart` group `US3 - Adaptabilité` : `should_renderCorrectly_when_twoSegments`, `should_renderCorrectly_when_fiveSegments`, `should_distributeEqualWidth_when_multipleSegments` (vérifier que chaque segment a la même largeur via `Expanded`), `should_truncateWithEllipsis_when_labelTooLong` (label de 100 caractères → Text a `maxLines: 1, overflow: TextOverflow.ellipsis`), `should_workWithEnumType_when_enumValuesProvided` (utiliser un enum local de test, vérifier callback typé), `should_throwAssertionError_when_lessThanTwoItems`, `should_throwAssertionError_when_moreThanFiveItems`, `should_selectFirstItem_when_selectedValueNotInItems`

### Implementation US3

- [x] T008 [US3] Ajouter la gestion des edge cases dans `flutter/lib/src/common_widgets/segmented_filter.dart` : `Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis)` pour la troncature. Dans `build()`, calculer `effectiveSelectedValue` : si aucun item n'a `value == selectedValue`, utiliser `items.first.value`. S'assurer que chaque `Text` est dans un `Expanded` pour la répartition équitable.

**Checkpoint**: Le widget gère tous les cas de figure (2-5 segments, enums, labels longs)

---

## Phase 5: US4 - Accessibilité (Priority: P3)

**Goal**: Les lecteurs d'écran annoncent chaque segment avec son label et son état de sélection.

**Independent Test**: Vérifier les Semantics avec les finders Flutter.

### Tests US4

- [x] T009 [P] [US4] Écrire les tests d'accessibilité dans `flutter/test/src/common_widgets/segmented_filter_test.dart` group `US4 - Accessibilité` : `should_haveSemanticsLabel_when_segmentRendered` (chaque segment a un Semantics avec label = item.label), `should_haveToggledTrue_when_segmentActive` (Semantics.toggled = true pour le segment actif), `should_haveToggledFalse_when_segmentInactive` (Semantics.toggled = false pour les segments inactifs)

### Implementation US4

- [x] T010 [US4] Ajouter les wrappers Semantics dans `flutter/lib/src/common_widgets/segmented_filter.dart` : chaque segment wrappé dans `Semantics(toggled: isSelected, label: item.label, child: GestureDetector(...))`. Pattern identique à AppToggle.

**Checkpoint**: VoiceOver/TalkBack annoncent correctement chaque segment et son état

---

## Phase 6: Polish & Validation

**Purpose**: Validation finale et nettoyage

- [x] T011 Lancer la suite de tests complète avec `cd flutter && flutter test test/src/common_widgets/segmented_filter_test.dart` et vérifier que tous les tests passent
- [x] T012 Valider les scénarios du quickstart.md : instancier le widget avec un enum, avec des Strings, vérifier la compilation sans erreur

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — démarrage immédiat
- **US1 (Phase 2)**: Dépend de Setup (T001, T002)
- **US2 (Phase 3)**: Dépend de US1 (T004 — le widget doit exister avant d'appliquer le style)
- **US3 (Phase 4)**: Dépend de US2 (T006 — le style doit être en place avant les edge cases)
- **US4 (Phase 5)**: Dépend de US1 (T004 — le widget doit exister). Peut être parallélisé avec US2/US3
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1 (Setup)
  └─→ Phase 2 (US1 - MVP)
       ├─→ Phase 3 (US2 - Design) ──→ Phase 4 (US3 - Edge cases)
       └─→ Phase 5 (US4 - Accessibilité) [parallélisable avec US2/US3]
            └─→ Phase 6 (Polish)
```

### Within Each User Story

1. Tests écrits en premier (TDD) → doivent échouer
2. Implementation → tests doivent passer
3. Story complète avant de passer à la suivante (sauf US4 parallélisable)

### Parallel Opportunities

- T003, T005, T007, T009 : peuvent être écrits en parallèle avec leurs tâches d'implémentation respectives (fichier test vs fichier source), mais doivent être exécutés séquentiellement entre eux (même fichier test `segmented_filter_test.dart`)
- US4 (Accessibilité) peut être implémentée en parallèle avec US2/US3

---

## Parallel Example: US1

```bash
# Écrire les tests US1 (T003) pendant que le setup (T001, T002) se termine
# Puis implémenter le widget (T004) — les tests US1 doivent alors passer
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Compléter Phase 1: Setup (T001, T002)
2. Compléter Phase 2: US1 (T003, T004)
3. **STOP et VALIDER**: Le widget affiche des segments, le tap fonctionne
4. Le MVP est livrable — les écrans parents peuvent commencer à l'intégrer

### Incremental Delivery

1. Setup → US1 → Widget fonctionnel (MVP)
2. + US2 → Widget avec le bon design system
3. + US3 → Widget robuste (edge cases, 2-5 segments)
4. + US4 → Widget accessible
5. Polish → Validation finale

---

## Notes

- Fichier unique : `flutter/lib/src/common_widgets/segmented_filter.dart` contient `SegmentedFilterItem<T>` + `SegmentedFilter<T>`
- Fichier test unique : `flutter/test/src/common_widgets/segmented_filter_test.dart`
- Pattern identique à AppToggle pour les conventions (Semantics, AnimatedContainer, callbacks)
- Commit après chaque phase complétée
- Total : 12 tâches, ~20-25 tests attendus
