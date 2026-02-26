# Tasks: Settings — Apparence

**Input**: Design documents from `/specs/051-flutter-settings-appearance/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Non demandés dans la spec — non inclus.

**Organization**: Tâches groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, aucune dépendance)
- **[Story]**: User story associée (US1, US2)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Créer l'enum TextScale utilisé par les phases suivantes

- [x] T001 [P] Create `TextScale` enum with `small` (0.85), `medium` (1.0), `large` (1.3) values and `scaleFactor`/`label` getters in `flutter/lib/src/domain/enums/text_scale.dart`
- [x] T002 [P] Add `export 'text_scale.dart';` to barrel file `flutter/lib/src/domain/enums/enums.dart`

---

## Phase 2: Foundational (TextScale Persistence & Application)

**Purpose**: Infrastructure de persistance et application globale du text scaling — BLOQUE US2

**Note**: US1 peut démarrer en parallèle de cette phase (n'utilise que l'infrastructure thème existante).

- [x] T003 Add `@Default(TextScale.medium) TextScale textScale` field to `AppConfig` model in `flutter/lib/src/domain/models/app_config.dart`
- [x] T004 [P] Add `setTextScale(TextScale)` and `getTextScale()` methods to `AppConfigRepository` interface in `flutter/lib/src/domain/repositories/app_config_repository.dart`
- [x] T005 Implement `setTextScale()` and `getTextScale()` in `flutter/lib/src/features/onboarding/data/app_config_repository_impl.dart` following existing `setTheme`/`getTheme` pattern
- [x] T006 Run `dart run build_runner build --delete-conflicting-outputs` from `flutter/` to regenerate Freezed and json_serializable code for AppConfig
- [x] T007 Create `TextScaleNotifier` (Notifier\<TextScale\>) with `_loadTextScale()`, `setTextScale(TextScale)` methods in `flutter/lib/src/features/settings/application/text_scale_notifier.dart` — follow `ThemeNotifier` pattern exactly
- [x] T008 Modify `KBudgetApp.build()` in `flutter/lib/app.dart` to watch `textScaleNotifierProvider` and wrap `MaterialApp.router` with a `Builder` that overrides `MediaQuery` using `TextScaler.linear(textScale.scaleFactor)`

**Checkpoint**: Infrastructure text scaling complète. `flutter analyze` doit passer.

---

## Phase 3: User Story 1 — Choisir le thème (Priority: P1) — MVP

**Goal**: L'utilisateur peut basculer entre thème clair et sombre via des tile cards sur l'écran Apparence, avec application immédiate et persistance.

**Independent Test**: Ouvrir Paramètres → Apparence → basculer entre Clair/Sombre → vérifier changement immédiat. Fermer et rouvrir → vérifier persistance.

### Implementation for User Story 1

- [x] T009 [US1] Create `AppearanceSettingsScreen` (ConsumerWidget) in `flutter/lib/src/features/settings/presentation/appearance_settings_screen.dart` with Scaffold, AppBar "Apparence", and theme section: section label "Thème" + Row of 2 tile cards (light: sun icon + "Clair", dark: moon icon + "Sombre") using `themeNotifierProvider` — active tile has primary border + check icon, inactive has outline border
- [x] T010 [US1] Update route in `flutter/lib/src/routing/app_router.dart` to replace `StubSettingsScreen(title: 'Apparence')` with `const AppearanceSettingsScreen()` for the `settingsAppearance` route

**Checkpoint**: Écran Apparence fonctionnel avec sélecteur de thème. Le placeholder "À venir" est remplacé. Testable indépendamment.

---

## Phase 4: User Story 2 — Ajuster la taille du texte (Priority: P2)

**Goal**: L'utilisateur peut changer la taille du texte parmi 3 niveaux via tile cards, avec aperçu temps réel et application immédiate sur toute l'app.

**Independent Test**: Ouvrir Paramètres → Apparence → changer taille texte entre les 3 niveaux → vérifier aperçu + changement global. Fermer et rouvrir → vérifier persistance.

**Requires**: Phase 2 (Foundational) complète.

### Implementation for User Story 2

- [x] T011 [US2] Add text size section to `AppearanceSettingsScreen` in `flutter/lib/src/features/settings/presentation/appearance_settings_screen.dart`: section label "Taille du texte" + Row of 3 tile cards (each showing "Aa" at respective scale + label "Petit"/"Normal"/"Grand") using `textScaleNotifierProvider` — active tile has primary border + check icon
- [x] T012 [US2] Add text preview widget below the text size tiles in `appearance_settings_screen.dart`: a Card with sample text (e.g. "Voici un aperçu de la taille du texte choisie.") that reflects the current text scale in real-time

**Checkpoint**: Les deux sélecteurs (thème + taille texte) fonctionnent. Les changements coexistent sans conflit. Aperçu visible.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation et nettoyage final

- [x] T013 Run `flutter analyze` from `flutter/` and fix any warnings or errors
- [x] T014 Run `flutter test` from `flutter/` and verify no regressions on existing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — démarrage immédiat
- **Foundational (Phase 2)**: Dépend de Phase 1 (T001-T002) — BLOQUE US2
- **US1 (Phase 3)**: Aucune dépendance — peut démarrer immédiatement (utilise uniquement l'infrastructure thème existante)
- **US2 (Phase 4)**: Dépend de Phase 2 (T003-T008) ET Phase 3 (T009 — l'écran doit exister)
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Indépendant de US2. Utilise `themeNotifierProvider` existant uniquement.
- **US2 (P2)**: Dépend de l'infrastructure TextScale (Phase 2) et de l'écran créé en US1 (T009).

### Within Each User Story

- US1: Écran d'abord (T009) → Route ensuite (T010)
- US2: Tiles d'abord (T011) → Preview ensuite (T012)

### Parallel Opportunities

- T001 et T002 en parallèle (Setup)
- T003 et T004 en parallèle (fichiers différents)
- Phase 3 (US1) peut démarrer en parallèle de Phase 2
- T011 et T012 sont séquentiels (même fichier)

---

## Parallel Example: Setup + US1 Fast Track

```bash
# Lancer Setup en parallèle:
Task: "T001 Create TextScale enum in flutter/lib/src/domain/enums/text_scale.dart"
Task: "T002 Add export to flutter/lib/src/domain/enums/enums.dart"

# US1 peut démarrer immédiatement (thème infrastructure déjà existante):
Task: "T009 Create AppearanceSettingsScreen in flutter/lib/src/features/settings/presentation/appearance_settings_screen.dart"
Task: "T010 Update route in flutter/lib/src/routing/app_router.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001-T002)
2. Compléter Phase 3: US1 (T009-T010) — **peut sauter Phase 2**
3. **STOP and VALIDATE**: Écran Apparence avec thème clair/sombre fonctionnel
4. Livrable : sélecteur thème sans taille texte

### Incremental Delivery

1. Phase 1 (Setup) + Phase 3 (US1) → Thème fonctionnel → Commit
2. Phase 2 (Foundational) → Infrastructure TextScale → Commit
3. Phase 4 (US2) → Taille texte + preview → Commit
4. Phase 5 (Polish) → Validation finale → Commit

### Optimal Single-Developer Flow

1. T001 + T002 (Setup)
2. T009 + T010 (US1 — MVP)
3. T003 + T004 → T005 → T006 → T007 → T008 (Foundational)
4. T011 → T012 (US2)
5. T013 → T014 (Polish)

---

## Notes

- [P] tasks = fichiers différents, aucune dépendance
- [Story] label mappe chaque tâche à sa user story
- Chaque user story est testable indépendamment
- Commiter après chaque checkpoint
- Le `StubSettingsScreen` existant n'est plus utilisé par la route Apparence après T010
