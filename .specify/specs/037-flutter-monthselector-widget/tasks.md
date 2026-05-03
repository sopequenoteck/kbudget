# Tasks: Flutter MonthSelector Widget

**Input**: Design documents from `/specs/037-flutter-monthselector-widget/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: Inclus — les tests sont détaillés dans le plan (section Tests prévus).

**Organization**: Tâches groupées par user story. US1 et US2 (toutes deux P1) sont combinées en une seule phase car elles sont indissociables (navigation = callback).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts depuis la racine du repo

---

## Phase 1: Setup

**Purpose**: Création des fichiers et scaffolding du widget et des tests

- [X] T001 Créer le scaffold du widget MonthSelector (StatefulWidget, constructeur avec initialMonth/initialYear/onChanged, State vide) dans `flutter/lib/src/common_widgets/month_selector.dart`
- [X] T002 Créer le scaffold des tests avec helper `pumpMonthSelector`, imports, et `initializeDateFormatting('fr_FR')` dans setUpAll dans `flutter/test/common_widgets/month_selector_test.dart`

**Checkpoint**: Les deux fichiers existent, `flutter test test/common_widgets/month_selector_test.dart` s'exécute (0 tests)

---

## Phase 2: US1 + US2 — Navigation & Callback (Priority: P1) MVP

**Goal**: Le widget affiche le mois formaté, permet la navigation prev/next avec rollover année, et notifie le parent via callback

**Independent Test**: Afficher le widget, taper sur les boutons, vérifier le label et le callback

### Tests US1 + US2

> **NOTE: Écrire ces tests AVANT l'implémentation — ils doivent ÉCHOUER**

- [X] T003 [US1] Écrire les tests de navigation : `should_display_current_month_when_no_initial_values`, `should_display_initial_month_when_provided`, `should_show_next_month_when_next_pressed`, `should_show_previous_month_when_prev_pressed`, `should_wrap_to_january_when_next_from_december`, `should_wrap_to_december_when_prev_from_january`, `should_increment_year_when_next_from_december`, `should_decrement_year_when_prev_from_january`, `should_capitalize_month_label`, `should_fallback_to_current_month_when_initial_month_invalid` dans `flutter/test/common_widgets/month_selector_test.dart`
- [X] T004 [US2] Écrire les tests de callback : `should_call_onChanged_with_new_month_year_when_next_pressed`, `should_call_onChanged_with_new_month_year_when_prev_pressed`, `should_call_onChanged_with_wrapped_values_on_year_boundary`, `should_not_crash_when_onChanged_is_null` dans `flutter/test/common_widgets/month_selector_test.dart`

### Implémentation US1 + US2

- [X] T005 [US1] Implémenter la gestion d'état dans `_MonthSelectorState` : `initState()` (initialisation depuis params ou DateTime.now(), avec fallback si initialMonth hors 1-12), `_month` (1-12), `_year`, `_prevMonth()` avec wrap jan→déc, `_nextMonth()` avec wrap déc→jan dans `flutter/lib/src/common_widgets/month_selector.dart`
- [X] T006 [US1] Implémenter le formatage du label : `DateFormat('MMMM yyyy', 'fr_FR')` + capitalisation première lettre, getter `_formattedLabel` dans `flutter/lib/src/common_widgets/month_selector.dart`
- [X] T007 [US1] [US2] Implémenter la méthode `build()` : Row avec IconButton chevron_left, SizedBox+Text label centré, IconButton chevron_right. Appeler `widget.onChanged?.call(_month, _year)` après chaque navigation dans `flutter/lib/src/common_widgets/month_selector.dart`

**Checkpoint**: Le widget navigue entre les mois, le label est formaté en français, le callback fonctionne. Tous les tests T003/T004 passent.

---

## Phase 3: US3 — Design System (Priority: P2)

**Goal**: Le widget utilise exclusivement les tokens du design system et s'adapte aux thèmes clair/sombre

**Independent Test**: Rendre le widget en thème clair et sombre, vérifier les couleurs, tailles, ombres

### Tests US3

- [X] T008 [US3] Écrire les tests design system : `should_use_design_tokens_for_button_styling` (container rond 48dp, ombre sm, surface), `should_use_design_tokens_for_label_styling` (font-size lg, semiBold, textPrimary), `should_adapt_to_dark_theme` dans `flutter/test/common_widgets/month_selector_test.dart`

### Implémentation US3

- [X] T009 [US3] Appliquer les tokens design system dans `build()` : boutons dans Container rond (AppRadius.round, 48x48, AppShadows.sm, colorScheme.surface), label avec style TextStyle(fontSize: AppTypography.lg, fontWeight: AppTypography.semiBold, color: colorScheme.onSurface), gap AppSpacing.space4, SizedBox width fixe pour label dans `flutter/lib/src/common_widgets/month_selector.dart`

**Checkpoint**: Le widget est visuellement conforme au design system en thème clair et sombre. Tests T008 passent.

---

## Phase 4: US4 — Accessibilité (Priority: P2)

**Goal**: Les boutons ont des labels sémantiques pour les lecteurs d'écran

**Independent Test**: Vérifier les propriétés Semantics des boutons

### Tests US4

- [X] T010 [US4] Écrire les tests d'accessibilité : `should_have_prev_button_semantics_label` ("Mois précédent"), `should_have_next_button_semantics_label` ("Mois suivant") dans `flutter/test/common_widgets/month_selector_test.dart`

### Implémentation US4

- [X] T011 [US4] Ajouter `Semantics(label: 'Mois précédent')` sur le bouton gauche et `Semantics(label: 'Mois suivant')` sur le bouton droit. Ajouter `excludeSemantics: true` sur les Icon enfants dans `flutter/lib/src/common_widgets/month_selector.dart`

**Checkpoint**: Les labels sémantiques sont présents. Tests T010 passent.

---

## Phase 5: Polish & Edge Cases

**Purpose**: Tests aux limites et validation finale

- [X] T012 Écrire les tests edge cases : `should_handle_long_month_name_without_overflow` (Septembre), `should_render_in_narrow_container` (ConstrainedBox 200px) dans `flutter/test/common_widgets/month_selector_test.dart`
- [X] T013 Exécuter `flutter analyze` et `flutter test` sur tout le projet Flutter, corriger les éventuels warnings ou erreurs

**Checkpoint**: Tous les tests passent (≈20 tests), aucun warning analyze. Widget prêt.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : Aucune dépendance — peut commencer immédiatement
- **US1+US2 (Phase 2)** : Dépend de Phase 1 (scaffold nécessaire)
- **US3 (Phase 3)** : Dépend de Phase 2 (le build() doit exister pour y appliquer les tokens)
- **US4 (Phase 4)** : Dépend de Phase 2 (les boutons doivent exister pour y ajouter Semantics)
- **Polish (Phase 5)** : Dépend de Phase 3 et Phase 4

### User Story Dependencies

- **US1 + US2 (P1)** : Indissociables — implémentées ensemble dans Phase 2
- **US3 (P2)** : Peut commencer après Phase 2. Indépendante de US4
- **US4 (P2)** : Peut commencer après Phase 2. Indépendante de US3
- **US3 et US4 peuvent être exécutées en parallèle** (US3 modifie le styling, US4 ajoute Semantics — zones différentes du build)

### Within Each Phase

- Tests AVANT implémentation (TDD)
- Les tests doivent ÉCHOUER avant l'implémentation
- Commiter après chaque phase complétée

### Parallel Opportunities

- Phase 3 (US3) et Phase 4 (US4) peuvent être exécutées en parallèle

---

## Parallel Example: Phase 3 + Phase 4

```text
# Après Phase 2 complétée, lancer en parallèle :
Phase 3 (US3): T008 → T009 (design tokens)
Phase 4 (US4): T010 → T011 (accessibilité)
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2)

1. Compléter Phase 1: Setup (scaffold)
2. Compléter Phase 2: US1 + US2 (navigation + callback)
3. **STOP et VALIDER** : Le widget fonctionne, navigue entre les mois, notifie le parent
4. Le widget est déjà utilisable sur dashboard et transactions

### Incremental Delivery

1. Phase 1 + Phase 2 → Widget fonctionnel (MVP)
2. Phase 3 → Widget conforme au design system
3. Phase 4 → Widget accessible
4. Phase 5 → Tests aux limites, validation finale
5. Chaque phase ajoute de la valeur sans casser les précédentes

---

## Notes

- Tout le code source est dans **2 fichiers** : `month_selector.dart` (widget) et `month_selector_test.dart` (tests)
- Les tests utilisent `initializeDateFormatting('fr_FR')` dans `setUpAll` (pattern existant dans `relative_date_formatter_test.dart`)
- Le helper `pumpMonthSelector` wrappera le widget dans `MaterialApp` avec thème complet (pattern existant dans les tests ListItem et AppFormField)
- Commiter après chaque phase complétée
