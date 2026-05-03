# Tasks: Flutter Settings — Gestion Catégories

**Input**: Design documents from `/specs/054-flutter-settings-categories/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Organization**: Tasks grouped by user story. US5 (Protection système) est intégrée dans US1 (liste) car elle concerne exclusivement le rendu des items. US3 (Modifier) et US4 (Supprimer) sont regroupées car elles étendent le même écran formulaire (P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Refactoring préalable — promotion du widget partagé et mise à jour des imports

- [X] T001 Move ColorPalettePicker from `flutter/lib/src/features/accounts/presentation/widgets/color_palette_picker.dart` to `flutter/lib/src/common_widgets/color_palette_picker.dart` (copy file, preserve all code)
- [X] T002 Update import of ColorPalettePicker in `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart` (change from `../widgets/color_palette_picker.dart` to `../../../../common_widgets/color_palette_picker.dart`) and delete the old file at `flutter/lib/src/features/accounts/presentation/widgets/color_palette_picker.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: i18n et route names — DOIVENT être complétés avant les écrans

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 [P] Add i18n strings for category management screens (categoriesTitle, categoriesEmpty, categoryFormTitleCreate, categoryFormTitleEdit, categoryNameLabel, categoryNameRequired, categoryNameMaxLength, categoryNameDuplicate, categoryEmojiRequired, categoryDeleteConfirmTitle, categoryDeleteConfirmMessage, categorySystemBadge) in `flutter/lib/src/localization/app_en.arb` and `flutter/lib/src/localization/app_fr.arb`
- [X] T004 [P] Add route names for category sub-routes (`settingsCategoriesNew`, `settingsCategoriesNewName`, `settingsCategoriesEdit`, `settingsCategoriesEditName`) in `flutter/lib/src/routing/route_names.dart`, following the same pattern as accounts routes

**Checkpoint**: Foundation ready — i18n strings and route names available

---

## Phase 3: US1 + US5 — Consulter la liste + Protection catégories système (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur voit toutes ses catégories avec distinction visuelle des catégories système (non cliquables, badge "Système", opacité réduite)

**Independent Test**: Naviguer vers Paramètres > Catégories → la liste s'affiche avec shimmer au chargement, catégories triées par nom, catégories système visuellement distinctes et non cliquables

### Implementation

- [X] T006 [P] [US1] Create `CategoryListSkeleton` widget in `flutter/lib/src/features/categories/presentation/widgets/category_list_skeleton.dart` — shimmer loading placeholder with 5-6 skeleton items following the accounts skeleton pattern (Shimmer + Container with rounded rect placeholders for emoji circle, name text, and color dot)
- [X] T007 [P] [US1] Create `CategoryListTile` widget in `flutter/lib/src/features/categories/presentation/widgets/category_list_tile.dart` — displays category emoji (leading circle with couleur background), nom (title), optional "Système" badge (trailing Text with reduced opacity), `enabled: !category.isSystem` to block tap on system categories, `onTap` callback for navigation to edit form. Follow `AccountListTile` pattern
- [X] T008[US1] Create `CategoryListScreen` in `flutter/lib/src/features/categories/presentation/screens/category_list_screen.dart` — `ConsumerStatefulWidget`, calls `categoryNotifierProvider.notifier.loadItems()` in `initState`, `RefreshIndicator` with `CustomScrollView` + `SliverList.builder`, 4 states: loading (T006 skeleton), error (icon + message + retry button), empty (icon `Icons.label_outlined` + localized empty message), data (list of T007 tiles). AppBar with title "Catégories" and add button (+) navigating to `settingsCategoriesNewName`. Tap on non-system tile navigates to `settingsCategoriesEditName` with category as `extra`
- [X] T008b [US1] Update `flutter/lib/src/routing/app_router.dart` — replace the `StubSettingsScreen(title: 'Catégories')` stub (line ~215) with `CategoryListScreen` and add sub-route: `new` → `CategoryFormScreen()`. Import `CategoryListScreen` and `CategoryFormScreen` from their presentation paths. The edit sub-route (`:id` → `CategoryFormScreen(category: state.extra as Category)`) will be added in Phase 5 (T015)

### Tests

- [X] T009 [P] [US1] Widget test for `CategoryListTile` in `flutter/test/src/features/categories/presentation/widgets/category_list_tile_test.dart` — test: should_display_name_emoji_color_when_rendered, should_show_system_badge_when_isSystem_true, should_not_trigger_onTap_when_isSystem_true, should_trigger_onTap_when_isSystem_false
- [X] T010 [US1] Widget test for `CategoryListScreen` in `flutter/test/src/features/categories/presentation/screens/category_list_screen_test.dart` — mock `categoryNotifierProvider` with `ProviderScope` overrides, test: should_show_skeleton_when_loading, should_show_error_with_retry_when_error, should_show_empty_state_when_no_user_categories, should_show_list_when_categories_exist, should_show_system_categories_as_disabled

**Checkpoint**: US1 + US5 complets — la liste est fonctionnelle avec protection système visible

---

## Phase 4: US2 — Créer une nouvelle catégorie (Priority: P1)

**Goal**: L'utilisateur crée une catégorie via formulaire (nom, emoji, couleur) avec validation et couleur aléatoire pré-sélectionnée

**Independent Test**: Tap + → formulaire s'ouvre avec couleur aléatoire → remplir nom + emoji → valider → retour liste avec nouvelle catégorie

### Implementation

- [X] T011 [P] [US2] Create `CategoryPreviewCard` widget in `flutter/lib/src/features/categories/presentation/widgets/category_preview_card.dart` — card showing emoji (large, centered in circle with couleur background), nom text, and color accent bar. Updates in real-time as user types. Follow `AccountPreviewCard` pattern but simpler (no balance/type)
- [X] T012 [US2] Create `CategoryFormScreen` (create mode) in `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` — `ConsumerStatefulWidget` with constructor `CategoryFormScreen({super.key, this.category})`, `_isEditMode = widget.category != null`. Create mode: random color from palette selected via `_selectedColor = kCategoryColors[Random().nextInt(kCategoryColors.length)]`. Form fields in `ListView`: (1) `CategoryPreviewCard` at top, (2) Row with `EmojiInput` + `Expanded(ColorPalettePicker)`, (3) `TextFormField` for nom (max 30 chars, required validation). AppBar with check icon button to submit. On submit: validate form → call `categoryNotifierProvider.notifier.create(category)` → on success `context.pop()` → on error show SnackBar with error message (use localized `categoryNameDuplicate` string from T003 when API returns duplicate name error, generic error message otherwise)

### Tests

- [X] T013 [P] [US2] Widget test for `CategoryPreviewCard` in `flutter/test/src/features/categories/presentation/widgets/category_preview_card_test.dart` — test: should_display_emoji_name_color_when_rendered, should_update_preview_when_props_change
- [X] T014 [US2] Widget test for `CategoryFormScreen` (create mode) in `flutter/test/src/features/categories/presentation/screens/category_form_screen_test.dart` — mock `categoryNotifierProvider`, test: should_show_random_color_when_create_mode, should_show_validation_error_when_name_empty, should_show_validation_error_when_emoji_empty, should_call_create_when_form_valid

**Checkpoint**: US2 complet — création de catégories fonctionnelle

---

## Phase 5: US3 + US4 — Modifier + Supprimer une catégorie (Priority: P2)

**Goal**: L'utilisateur modifie ou supprime une catégorie personnalisée depuis le formulaire d'édition pré-rempli, avec confirmation avant suppression

**Independent Test**: Tap catégorie → formulaire pré-rempli → modifier nom → valider → retour liste mise à jour. Tap supprimer → confirmation → retour liste sans la catégorie

### Implementation

- [X] T015 [US3] Extend `CategoryFormScreen` with edit mode in `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` — when `widget.category != null`: pre-fill `_nameController.text`, `_selectedEmoji`, `_selectedColor` from category values in `initState`. On submit: call `categoryNotifierProvider.notifier.update(category.copyWith(...))` instead of create. AppBar title changes to localized edit title. Also add the edit sub-route (`:id` → `CategoryFormScreen(category: state.extra as Category)`) in `flutter/lib/src/routing/app_router.dart` under the categories route
- [X] T016 [US4] Add delete functionality to `CategoryFormScreen` in `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` — edit mode only: add `TextButton.icon` delete button at bottom (styled with `colorScheme.error`). On tap: show `AlertDialog` with localized warning about linked items dissociation. On confirm: call `categoryNotifierProvider.notifier.delete(category.id)` → on success `context.pop()` → on error show SnackBar

### Tests

- [X] T017 [US3][US4] Widget test for `CategoryFormScreen` (edit + delete modes) in `flutter/test/src/features/categories/presentation/screens/category_form_screen_test.dart` — add tests: should_prefill_fields_when_edit_mode, should_call_update_when_form_submitted_in_edit_mode, should_show_delete_button_when_edit_mode, should_show_confirmation_dialog_when_delete_tapped, should_call_delete_when_confirmed, should_not_delete_when_cancelled

**Checkpoint**: US3 + US4 complets — CRUD complet fonctionnel

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [X] T018 Run `flutter analyze` in `flutter/` and fix any issues
- [X] T019 Run `flutter test test/src/features/categories/` and verify all tests pass
- [X] T020 Manual verification: navigate full CRUD flow (list → create → edit → delete) and verify system category protection

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (i18n + route names only, pas d'import de screens)
- **US1+US5 (Phase 3)**: Depends on Phase 2 (i18n must exist). T008b câble le router après création des écrans
- **US2 (Phase 4)**: Depends on Phase 2 (i18n must exist). Can start in parallel with Phase 3 (different files)
- **US3+US4 (Phase 5)**: Depends on Phase 3 (T008b ajoute la route `new`) et Phase 4 (extends CategoryFormScreen created in T012). T015 ajoute la sous-route edit (`:id`) au router
- **Polish (Phase 6)**: Depends on all previous phases

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                        ↓
         ┌──────────────┴──────────────┐
         ↓                             ↓
  Phase 3 (US1+US5)            Phase 4 (US2)
  [Liste + Système]            [Créer]
         │                        │
         └──────────┬─────────────┘
                    ↓
             Phase 5 (US3+US4)
             [Modifier + Supprimer]
                    ↓
             Phase 6 (Polish)
```

### Parallel Opportunities

Within Phase 2: T003, T004 can run in parallel (different files)
Within Phase 3: T006, T007 can run in parallel (different widget files), T009 can run in parallel with T006/T007
Within Phase 4: T011 can run in parallel with T013 (widget + test)
Phase 3 and Phase 4 can start concurrently after Phase 2 (different files)

---

## Parallel Example: Phase 3 (US1+US5)

```bash
# Launch widget creation in parallel (different files):
Task: "Create CategoryListSkeleton in .../widgets/category_list_skeleton.dart"
Task: "Create CategoryListTile in .../widgets/category_list_tile.dart"

# Then sequentially (depends on widgets):
Task: "Create CategoryListScreen in .../screens/category_list_screen.dart"

# Tests can start once their target widget exists:
Task: "Widget test for CategoryListTile in .../category_list_tile_test.dart"
Task: "Widget test for CategoryListScreen in .../category_list_screen_test.dart"
```

---

## Implementation Strategy

### MVP First (Phase 1 + 2 + 3)

1. Complete Phase 1: Setup (move ColorPalettePicker)
2. Complete Phase 2: Foundational (routes, i18n)
3. Complete Phase 3: US1+US5 (liste + protection système)
4. **STOP and VALIDATE**: Navigation fonctionnelle, liste visible, catégories système protégées
5. Commit checkpoint MVP

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. Add US1+US5 (liste) → Test indépendamment → **MVP consultable** ✅
3. Add US2 (création) → Test indépendamment → Ajout possible de catégories ✅
4. Add US3+US4 (modification + suppression) → Test indépendamment → CRUD complet ✅
5. Polish → Validation finale → Feature complète ✅

---

## Notes

- La couche données (model, repository, notifier, DTOs) est 100% existante — aucune modification nécessaire
- Le `CategoryNotifier` gère déjà la protection des catégories système (blocage update/delete)
- Le `ColorPalettePicker` déplacé utilise les mêmes 12 couleurs que l'Angular
- Le formulaire est simple (3 champs) vs comptes (7+ champs) — preview card plus simple
- Commit recommandé après chaque phase complète
