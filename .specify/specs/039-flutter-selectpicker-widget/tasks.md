# Tasks: Widget SelectPicker Flutter

**Input**: Design documents from `/specs/039-flutter-selectpicker-widget/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus — la constitution (V. Testabilité) et les acceptance scenarios de la spec l'exigent.

**Organization**: Tâches groupées par user story. US1 et US2 (toutes deux P1) sont fusionnées car co-dépendantes (le trigger affiche l'état ET permet la sélection).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3, US4, US5, US6)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup

**Purpose**: Créer les fichiers et le squelette du widget

- [x] T001 [P] Créer `flutter/lib/src/common_widgets/select_picker.dart` avec la classe `SelectPickerItem` (id, label, icon?, color?, secondaryText?, const constructor, asserts id/label non vides) et le squelette de `SelectPicker extends FormField<String?>` (constructor avec tous les paramètres de data-model.md, `createState()` retournant `_SelectPickerState`, builder vide retournant un `SizedBox.shrink()`)
- [x] T002 [P] Créer `flutter/test/src/common_widgets/select_picker_test.dart` avec la fonction helper `pumpSelectPicker(WidgetTester, Widget, {ThemeData?})` (pattern identique à `pumpSegmentedFilter` dans segmented_filter_test.dart) et un smoke test `should_render_when_validItemsProvided` vérifiant que le widget se monte sans erreur

**Checkpoint**: Fichiers créés, squelette compilable, smoke test passe

---

## Phase 2: US1+US2 — Sélection & Affichage Trigger (Priority: P1) — MVP

**Goal**: L'utilisateur peut voir le trigger (placeholder ou item sélectionné avec icône/couleur/secondaryText), ouvrir le bottom sheet via AppModal, sélectionner un item, et voir le trigger mis à jour.

**Independent Test**: Afficher le widget avec 5 items, taper sur le trigger, vérifier l'ouverture du bottom sheet, taper sur un item, vérifier la fermeture et la valeur retournée. Afficher sans sélection, vérifier le placeholder.

### Implementation

- [x] T003 [US1] Implémenter le trigger dans le builder de `SelectPicker` dans `flutter/lib/src/common_widgets/select_picker.dart` : label au-dessus (TextStyle sizeSm/medium/onSurfaceVariant), conteneur AnimatedContainer (surfaceContainerHighest, radius xl, padding space3/space4), contenu = placeholder (texte atténué onSurfaceVariant) OU item sélectionné (icône emoji + pastille couleur 12dp + label + secondaryText aligné droite), chevron `Icons.keyboard_arrow_down` trailing, message d'erreur AnimatedSize en dessous (sizeXs, error color). Wrapper GestureDetector pour le tap. Tous les styles DOIVENT utiliser `colorScheme` tokens pour la compatibilité thème clair/sombre (FR-014).
- [x] T004 [US1] Implémenter `_openModal()` dans `_SelectPickerState` dans `flutter/lib/src/common_widgets/select_picker.dart` : appeler `AppModal.show(context, title: widget.placeholder, child: listView, onClose: () {})`. Le `child` est un `Column` avec les items générés par `List.generate` (pas de `ListView.builder` avec `shrinkWrap` car AppModal encapsule déjà dans un `SingleChildScrollView` — le shrinkWrap annulerait le lazy rendering). Pour les cas d'usage typiques (< 50 items : comptes, catégories, fréquences), `Column` est performant. Chaque item affiche : Row avec icône optionnelle (Text emoji 24dp), pastille couleur optionnelle (Container 12dp round), label (Expanded, Text medium, ellipsis), secondaryText optionnel (Text sm, onSurfaceVariant). Si `items.isEmpty`, afficher `emptyMessage` centré (Text sm, onSurfaceVariant) au lieu de la liste (FR-008, edge case liste vide). Taper sur un item appelle `_onItemSelected`.
- [x] T005 [US1] Implémenter `_onItemSelected(String id)` dans `_SelectPickerState` dans `flutter/lib/src/common_widgets/select_picker.dart` : si `id == value` (même item), simplement fermer le modal (`Navigator.pop`). Sinon, appeler `didChange(id)` puis `widget.onChanged?.call(id)` puis `Navigator.pop`. Cela couvre FR-003 et FR-004.
- [x] T006 [US1] Implémenter l'intégration FormField dans `_SelectPickerState` dans `flutter/lib/src/common_widgets/select_picker.dart` : override `didUpdateWidget` pour auto-reset si l'item sélectionné (value) n'existe plus dans la nouvelle liste d'items (`didChange(null)` + `widget.onChanged?.call(null)`). Le `validator` et `errorText` sont gérés par FormFieldState — le builder utilise `state.hasError` et `state.errorText` pour l'affichage de l'erreur sous le trigger. Couvre FR-011 et FR-018.

### Tests

- [x] T007 [US1] Ajouter les tests pour US1+US2 dans `flutter/test/src/common_widgets/select_picker_test.dart` : groupe 'US1+US2 - Sélection & Trigger'. Tests : `should_showPlaceholder_when_noSelection`, `should_showSelectedItem_when_selectionProvided` (vérifier label+icon+secondaryText), `should_showColorDotInTrigger_when_selectedItemHasColor` (FR-001, US2-AC3), `should_openModal_when_triggerTapped`, `should_callOnChanged_when_differentItemTapped`, `should_notCallOnChanged_when_sameItemTapped` (FR-004), `should_closeModal_when_itemSelected`, `should_showChevronDown_when_rendered`, `should_resetSelection_when_selectedItemRemovedFromList` (FR-011), `should_showValidationError_when_validatorFails` (FormField integration)

**Checkpoint**: MVP fonctionnel — trigger affiche placeholder/item, modal s'ouvre, sélection fonctionne, FormField intégré. `flutter test test/src/common_widgets/select_picker_test.dart` passe.

---

## Phase 3: US3 — Effacer la sélection (Priority: P2)

**Goal**: L'utilisateur peut effacer sa sélection via un bouton × quand `clearable: true`.

**Independent Test**: Afficher le widget avec un item sélectionné et clearable=true, taper sur ×, vérifier que la sélection est effacée.

### Implementation

- [x] T008 [US3] Implémenter le bouton clear dans le trigger dans `flutter/lib/src/common_widgets/select_picker.dart` : quand `clearable == true` et `value != null`, afficher un `GestureDetector` avec `Icons.close` (size 18, onSurfaceVariant) à la place du chevron. Le tap appelle `_onClear()` qui fait `didChange(null)` + `widget.onChanged?.call(null)`. Le bouton × n'apparaît PAS si clearable=false ou si aucune sélection. Couvre FR-005.

### Tests

- [x] T009 [US3] Ajouter les tests pour US3 dans `flutter/test/src/common_widgets/select_picker_test.dart` : groupe 'US3 - Clear'. Tests : `should_showClearButton_when_clearableAndSelected`, `should_notShowClearButton_when_notClearable`, `should_notShowClearButton_when_noSelection`, `should_clearSelection_when_clearButtonTapped` (vérifier onChanged(null) + retour placeholder)

**Checkpoint**: Clear fonctionne. Tests passent.

---

## Phase 4: US4 — Recherche (Priority: P2)

**Goal**: Un champ de recherche apparaît en haut du bottom sheet pour filtrer les items en temps réel.

**Independent Test**: Afficher le widget avec 10 items et searchable=true, ouvrir le bottom sheet, taper "Cour", vérifier que seuls les items correspondants sont affichés.

### Implementation

- [x] T010 [US4] Implémenter la recherche dans `_openModal()` dans `flutter/lib/src/common_widgets/select_picker.dart` : déterminer si la recherche est affichée (`widget.searchable == true || (widget.searchable == null && widget.items.length >= widget.searchThreshold)`). Si oui, utiliser `headerActions` d'AppModal pour un `StatefulBuilder` contenant un TextField (InputDecoration.collapsed, hintText 'Rechercher...', conteneur surfaceContainerHighest, radius lg, padding space2/space3). Le TextField met à jour un `searchQuery` local via `setState` du StatefulBuilder. Filtrer `items.where((i) => i.label.toLowerCase().contains(searchQuery.toLowerCase()))`. Si liste filtrée vide, afficher le `emptyMessage` centré (Text sm, onSurfaceVariant). Appeler `widget.onSearchChanged?.call(searchQuery)` à chaque changement. Couvre FR-006, FR-007, FR-008, FR-015.

### Tests

- [x] T011 [US4] Ajouter les tests pour US4 dans `flutter/test/src/common_widgets/select_picker_test.dart` : groupe 'US4 - Recherche'. Tests : `should_showSearchField_when_itemsAboveThreshold` (10 items, seuil 5), `should_notShowSearchField_when_itemsBelowThreshold` (3 items), `should_showSearchField_when_searchableExplicit` (3 items + searchable=true), `should_filterItems_when_searchQueryEntered` (taper "Cour", vérifier filtrage case-insensitive), `should_showEmptyMessage_when_noMatchingItems`, `should_callOnSearchChanged_when_queryChanges`

**Checkpoint**: Recherche fonctionne. Tests passent.

---

## Phase 5: US5 — Highlight sélection & vérification affichage riche (Priority: P2)

**Goal**: L'item actuellement sélectionné est visuellement distingué dans la liste. Vérification que toutes les combinaisons d'affichage (icône, couleur, secondaryText) fonctionnent correctement (implémentées en Phase 2 via T004).

**Independent Test**: Ouvrir le bottom sheet avec un item sélectionné, vérifier le fond distinct. Afficher des items avec différentes combinaisons optionnelles, vérifier l'affichage.

### Implementation

- [x] T012 [US5] Implémenter le highlight de l'item sélectionné dans la liste dans `flutter/lib/src/common_widgets/select_picker.dart` : dans le builder de la liste, si `item.id == value`, appliquer un `BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08))` au Container de l'item. Couvre FR-010.

### Tests

- [x] T013 [US5] Ajouter les tests pour US5 dans `flutter/test/src/common_widgets/select_picker_test.dart` : groupe 'US5 - Affichage riche & highlight'. Tests : `should_showIcon_when_itemHasIcon`, `should_showColorDot_when_itemHasColor`, `should_showSecondaryText_when_itemHasSecondaryText`, `should_showOnlyLabel_when_itemHasNoOptionalFields`, `should_highlightSelectedItem_when_itemSelected` (vérifier background primary avec alpha). Note : ces tests valident le rendu des items construit en T004 (Phase 2).

**Checkpoint**: Highlight et affichage riche vérifiés. Tests passent.

---

## Phase 6: US6 — Accessibilité (Priority: P3)

**Goal**: Le widget est utilisable par les technologies d'assistance.

**Independent Test**: Vérifier les nœuds Semantics du trigger et des items via les finders Flutter.

### Implementation

- [x] T014 [US6] Ajouter les `Semantics` dans `flutter/lib/src/common_widgets/select_picker.dart` : sur le trigger, `Semantics(button: true, label: selectedItem?.label ?? widget.placeholder)`. Sur chaque item de la liste, `Semantics(label: item.label, toggled: item.id == value)`. Wrapper global `MergeSemantics` sur le trigger (comme AppFormField). Couvre FR-017.

### Tests

- [x] T015 [US6] Ajouter les tests pour US6 dans `flutter/test/src/common_widgets/select_picker_test.dart` : groupe 'US6 - Accessibilité'. Tests : `should_haveSemanticsButton_when_triggerRendered`, `should_announcePlaceholder_when_noSelection`, `should_announceSelectedLabel_when_itemSelected`, `should_haveToggledTrue_when_itemSelectedInList`, `should_haveToggledFalse_when_itemNotSelectedInList`

**Checkpoint**: Accessibilité complète. Tests passent.

---

## Phase 7: Polish & Edge Cases

**Purpose**: Comportements transversaux affectant plusieurs user stories

- [x] T016 Implémenter l'état disabled dans `flutter/lib/src/common_widgets/select_picker.dart` : quand `enabled == false`, wrapper le trigger dans un `Opacity(opacity: 0.5)` et désactiver le GestureDetector (onTap: null). Le bouton clear est aussi masqué en disabled. Couvre FR-012.
- [x] T017 Vérifier la troncature ellipsis dans `flutter/lib/src/common_widgets/select_picker.dart` : s'assurer que tous les Text pour label/secondaryText ont `maxLines: 1` et `overflow: TextOverflow.ellipsis` dans le trigger ET dans la liste. Couvre FR-016.
- [x] T018 Ajouter les tests edge cases et thème dans `flutter/test/src/common_widgets/select_picker_test.dart` : groupe 'Edge Cases & Polish'. Tests : `should_showEmptyMessage_when_itemsListEmpty` (liste vide, bottom sheet montre emptyMessage), `should_beNonInteractive_when_disabled`, `should_truncateWithEllipsis_when_labelTooLong`, `should_adaptColors_when_darkTheme` (pomper avec AppTheme.dark, vérifier les couleurs), `should_closeWithoutChange_when_dismissedExternally`
- [x] T019 Exécuter la suite de tests complète (`cd flutter && flutter test test/src/common_widgets/select_picker_test.dart`) et valider la conformité avec quickstart.md

**Checkpoint**: Tous les tests passent. Widget complet et conforme à la spec.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — démarre immédiatement
- **US1+US2 (Phase 2)**: Dépend de Phase 1 — MVP bloquant
- **US3 (Phase 3)**: Dépend de Phase 2 (besoin du trigger et de la sélection)
- **US4 (Phase 4)**: Dépend de Phase 2 (besoin du modal)
- **US5 (Phase 5)**: Dépend de Phase 2 (besoin de la liste dans le modal)
- **US6 (Phase 6)**: Dépend de Phase 2 (besoin du trigger et des items)
- **Polish (Phase 7)**: Dépend de Phase 2 minimum. Idéalement après toutes les phases.

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (US1+US2 — MVP) ─────── CHECKPOINT: tester le MVP
    │
    ├──→ Phase 3 (US3 — Clear)
    ├──→ Phase 4 (US4 — Search)
    ├──→ Phase 5 (US5 — Rich Display)
    └──→ Phase 6 (US6 — A11y)
            │
            ▼
       Phase 7 (Polish)
```

### Parallel Opportunities

- **Phase 1**: T001 et T002 sont parallélisables [P] (fichiers différents)
- **Phases 3-6**: Peuvent démarrer en parallèle après Phase 2 (chacune touche des aspects différents du même fichier, mais les ajouts sont additifs et non conflictuels)
- **Note**: Toutes les tâches d'une même phase sont séquentielles (même fichier source et/ou test)

---

## Parallel Example: Post-MVP

```bash
# Après Phase 2 (MVP), lancer en parallèle :
Task: "T008 [US3] Clear button" → T009 tests
Task: "T010 [US4] Search" → T011 tests
Task: "T012 [US5] Highlight" → T013 tests
Task: "T014 [US6] Semantics" → T015 tests
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2 uniquement)

1. Compléter Phase 1: Setup (2 tâches, ~10 min)
2. Compléter Phase 2: US1+US2 (5 tâches, ~40 min)
3. **STOP et VALIDER**: Tester la sélection d'item end-to-end
4. Livrable minimal utilisable pour les issues dépendantes

### Incremental Delivery

1. Setup → US1+US2 → **Test + Commit** (MVP)
2. + US3 (Clear) → **Test + Commit**
3. + US4 (Search) → **Test + Commit**
4. + US5 (Rich Display) → **Test + Commit**
5. + US6 (A11y) → **Test + Commit**
6. Polish + Edge Cases → **Test + Commit final**

Chaque incrément ajoute de la valeur sans casser les précédents.

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [USx] = user story pour traçabilité
- Fichier source unique : `flutter/lib/src/common_widgets/select_picker.dart`
- Fichier test unique : `flutter/test/src/common_widgets/select_picker_test.dart`
- Commit recommandé après chaque checkpoint de phase
- Pattern de test : identique à `segmented_filter_test.dart` (pumpHelper + groupes par US)
