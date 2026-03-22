# Tasks: Flutter Emoji Input

**Input**: Design documents from `/specs/052-flutter-emoji-input/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Context**: Le widget `EmojiInput` est déjà implémenté dans `flutter/lib/src/common_widgets/emoji_input.dart` (247 lignes). La dépendance `emoji_picker_flutter: ^4.4.0` est déjà dans `pubspec.yaml`. Les tâches portent sur la vérification, les tests et la validation qualité.

**Organization**: Tasks groupées par user story pour vérification et tests indépendants.

## Format: `[ID] [Story] Description`

- **[Story]**: User story concernée (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

## Phase 1: Setup

**Purpose**: Vérifier que les prérequis sont en place

- [x] T001 Vérifier que `emoji_picker_flutter: ^4.4.0` est dans `flutter/pubspec.yaml` et que `flutter pub get` passe sans erreur
- [x] T002 Vérifier que `flutter/lib/src/common_widgets/emoji_input.dart` existe et compile (`flutter analyze flutter/lib/src/common_widgets/emoji_input.dart`)

---

## Phase 2: User Story 1 — Sélectionner un emoji via le picker visuel (Priority: P1)

**Goal**: Le trigger 48x48 affiche placeholder ou emoji, ouvre un bottom sheet avec grille par catégories, sélection ferme le sheet et met à jour la valeur.

**Independent Test**: Intégrer le widget seul dans un scaffold de test, vérifier le cycle tap → picker → sélection → fermeture.

**FR couverts**: FR-001, FR-002, FR-003, FR-004, FR-010

### Vérification implémentation US1

- [x] T003 [US1] Vérifier que le trigger est une boîte 48x48 (`AppSpacing.space12`) avec fond `surfaceContainerHighest` et placeholder "..." (FR-001) dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T004 [US1] Vérifier que `_openPicker()` appelle `showModalBottomSheet` avec `isScrollControlled: true` et `useSafeArea: true` (FR-002) dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T005 [US1] Vérifier que `_onEmojiSelected()` appelle `didChange()`, `onChanged`, et `Navigator.pop()` (FR-003) dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T006 [US1] Vérifier que `_EmojiPickerSheet` configure `EmojiPicker` avec `columns: 8`, `CategoryViewConfig` thémée, et `bottomActionBarConfig: enabled: false` (FR-004, FR-010) dans `flutter/lib/src/common_widgets/emoji_input.dart`

### Tests US1

- [x] T007 [US1] Écrire le test `should_display_placeholder_when_no_initial_value` — vérifie que "..." est affiché dans le trigger sans valeur initiale, dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T008 [US1] Écrire le test `should_display_emoji_when_initial_value_provided` — vérifie qu'un emoji passé en `initialValue` est affiché dans le trigger, dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T009 [US1] Écrire le test `should_open_bottom_sheet_when_trigger_tapped` — vérifie que le tap sur le trigger ouvre un bottom sheet contenant `EmojiPicker`, dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T010 [US1] Écrire le test `should_close_bottom_sheet_and_update_value_when_emoji_selected` — vérifie que la sélection d'un emoji ferme le bottom sheet ET met à jour la valeur affichée dans le trigger (FR-003), dans `flutter/test/src/common_widgets/emoji_input_test.dart`

**Checkpoint**: US1 vérifiée et testée — le cycle complet trigger → picker → sélection → fermeture → mise à jour fonctionne.

---

## Phase 3: User Story 2 — Intégration formulaire avec validation (Priority: P2)

**Goal**: Le widget s'intègre dans un `Form` comme `FormField<String>`, supporte validation, erreurs, initialValue, état désactivé.

**Independent Test**: Intégrer dans un Form avec validator requis, soumettre sans sélection → message d'erreur visible.

**FR couverts**: FR-006, FR-007, FR-008, FR-009

### Vérification implémentation US2

- [x] T011 [US2] Vérifier que `EmojiInput` étend `FormField<String>` avec support `validator`, `onSaved`, `autovalidateMode` (FR-006) dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T012 [US2] Vérifier que l'erreur s'affiche via `AnimatedSize` sous le trigger avec `colorScheme.error` (FR-007) dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T013 [US2] Vérifier que `enabled: false` applique `Opacity(opacity: 0.5)` et que `onTap` est `null` (FR-008) dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T014 [US2] Vérifier que `didUpdateWidget` synchronise `initialValue` quand le parent change (FR-009) dans `flutter/lib/src/common_widgets/emoji_input.dart`

### Tests US2

- [x] T015 [US2] Écrire le test `should_show_error_message_when_validation_fails` — intégrer dans un Form, soumettre sans valeur avec validator requis → message d'erreur visible, dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T016 [US2] Écrire le test `should_ignore_tap_when_disabled` — vérifier qu'avec `enabled: false` et `initialValue: '🔒'`, le trigger a opacity 0.5, l'emoji est toujours affiché, et le tap n'ouvre pas de bottom sheet (FR-008, EC-002), dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T017 [US2] Écrire le test `should_call_onChanged_when_emoji_selected` — vérifier que le callback `onChanged` est appelé avec la bonne valeur emoji, dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T018 [US2] Écrire le test `should_display_non_emoji_char_when_initial_value_is_not_emoji` — vérifier qu'un caractère non-emoji en `initialValue` (ex: "A") est affiché tel quel dans le trigger (EC-001), dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T019 [US2] Écrire le test `should_auto_validate_when_autovalidateMode_set` — intégrer dans un Form avec `autovalidateMode: AutovalidateMode.always` et validator requis, vérifier que le message d'erreur s'affiche immédiatement sans submit explicite (FR-006), dans `flutter/test/src/common_widgets/emoji_input_test.dart`
- [x] T020 [US2] Écrire le test `should_call_onSaved_when_form_saved` — intégrer dans un Form avec `initialValue: '🏠'`, appeler `formKey.currentState!.save()`, vérifier que le callback `onSaved` reçoit la bonne valeur (FR-006), dans `flutter/test/src/common_widgets/emoji_input_test.dart`

**Checkpoint**: US2 vérifiée et testée — FormField, validation, autovalidation, onSaved, disabled et initialValue fonctionnent.

---

## Phase 4: User Story 3 — Rechercher un emoji par mot-clé (Priority: P3)

**Goal**: Le picker inclut un champ de recherche pour filtrer les emojis par mot-clé.

**Independent Test**: Ouvrir le picker, vérifier que le SearchViewConfig est présent avec le hint text.

**FR couverts**: FR-005

### Vérification implémentation US3

- [x] T021 [US3] Vérifier que `_EmojiPickerSheet` configure `SearchViewConfig` avec `hintText: 'Rechercher un emoji...'` et `buttonIconColor` thémé (FR-005) dans `flutter/lib/src/common_widgets/emoji_input.dart`

### Tests US3

- [x] T022 [US3] Écrire le test `should_configure_search_view_in_picker` — vérifier que le bottom sheet contient un EmojiPicker avec SearchViewConfig active, dans `flutter/test/src/common_widgets/emoji_input_test.dart`

**Checkpoint**: US3 vérifiée — la recherche est configurée via le package.

---

## Phase 5: Polish & Validation

**Purpose**: Validation qualité transversale

- [x] T023 Exécuter `flutter analyze` dans `flutter/` et corriger toute erreur ou warning dans `flutter/lib/src/common_widgets/emoji_input.dart`
- [x] T024 Exécuter `flutter test` dans `flutter/` pour vérifier l'absence de régression sur les tests existants
- [x] T025 Exécuter `flutter test test/src/common_widgets/emoji_input_test.dart` pour valider tous les nouveaux tests du widget
- [x] T026 Valider SC-001 : vérifier que le widget est utilisable dans un formulaire en 5 lignes de code ou moins, en suivant les exemples de `specs/052-flutter-emoji-input/quickstart.md`
- [x] T027 Écrire le test `should_adapt_colors_to_dark_theme` — pump le widget dans un `MaterialApp` avec `ThemeData.dark()`, vérifier que le trigger et le picker utilisent les couleurs du dark colorScheme (SC-004, FR-010), dans `flutter/test/src/common_widgets/emoji_input_test.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — exécution immédiate
- **US1 (Phase 2)**: Dépend de Phase 1 — vérification + tests du picker core
- **US2 (Phase 3)**: Dépend de Phase 1 — indépendant de US1 pour les tests
- **US3 (Phase 4)**: Dépend de Phase 1 — indépendant de US1/US2 pour les tests
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Aucune dépendance inter-story
- **US2 (P2)**: Aucune dépendance inter-story (FormField est intégré dans le même fichier)
- **US3 (P3)**: Aucune dépendance inter-story (SearchViewConfig est dans _EmojiPickerSheet)

### Within Each User Story

- Vérification implémentation AVANT écriture des tests
- Tests écrits dans le même fichier `emoji_input_test.dart` (groupés par `group()`)

### Parallel Opportunities

- Les phases US1, US2, US3 sont indépendantes et peuvent être travaillées en parallèle
- Les tâches test d'une même US écrivent dans le même fichier (`emoji_input_test.dart`) — exécution séquentielle au sein d'une US

---

## Parallel Example: Phases US

```bash
# Les 3 phases US peuvent tourner en parallèle (vérification + tests indépendants par story) :
Phase 2: US1 — vérification picker + tests trigger/selection
Phase 3: US2 — vérification FormField + tests validation/disabled/edge cases
Phase 4: US3 — vérification search + test config
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (vérification prérequis)
2. Compléter Phase 2: US1 (vérification + tests picker)
3. **STOP et VALIDER**: Tests US1 passent, widget fonctionnel
4. Continuer avec US2 et US3

### Incremental Delivery

1. Setup → Prérequis validés
2. US1 → Tests picker core passent (MVP)
3. US2 → Tests FormField/validation passent
4. US3 → Tests recherche passent
5. Polish → `flutter analyze` clean, `flutter test` 100% vert

---

## Notes

- Le widget est déjà implémenté — les tâches de "vérification" consistent à relire le code et confirmer l'alignement avec les FR
- Tous les tests sont dans un seul fichier : `flutter/test/src/common_widgets/emoji_input_test.dart`
- Nommage des tests : `should_[résultat]_when_[condition]` (convention projet)
- Commit après chaque phase complétée
