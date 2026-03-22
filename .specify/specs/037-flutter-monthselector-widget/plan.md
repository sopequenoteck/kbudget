# Implementation Plan: Flutter MonthSelector Widget

**Branch**: `037-flutter-monthselector-widget` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/037-flutter-monthselector-widget/spec.md`

## Summary

Widget Flutter réutilisable de sélection de mois avec boutons précédent/suivant et label formaté en français. StatefulWidget gérant son propre état interne (mois/année), notifiant le parent via callback `onChanged`. Port du month-selector Angular existant. Composant pur de présentation sans dépendance métier, placé dans `common_widgets/`.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter (SDK), intl (déjà présent via flutter_localizations)
**Storage**: N/A (widget UI pur, pas de persistance)
**Testing**: flutter_test (déjà configuré)
**Target Platform**: iOS + Android (mobile-first)
**Project Type**: mobile
**Performance Goals**: Rendu instantané, aucun frame drop lors de la navigation
**Constraints**: Taille de touche minimum 48x48dp, tokens design system exclusivement
**Scale/Scope**: 1 widget, 1 fichier test, utilisé sur 2+ écrans

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I. API-First | Non | N/A | Widget UI pur, pas d'API |
| II. Sécurité par défaut | Non | N/A | Pas de données sensibles |
| III. Simplicité & YAGNI | Oui | PASS | StatefulWidget simple, pas d'abstraction superflue |
| IV. Mobile-First UX | Oui | PASS | Boutons 48dp, navigation en 1 tap |
| V. Testabilité | Oui | PASS | Tests widget isolés, nommage should_X_when_Y |
| VI. Observabilité | Non | N/A | Widget UI, pas de logging requis |
| VII. Self-Hosted Ready | Non | N/A | Frontend uniquement |

Aucune violation. Aucune justification requise.

## Project Structure

### Documentation (this feature)

```text
specs/037-flutter-monthselector-widget/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── spec.md              # Feature specification
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
flutter/lib/src/common_widgets/
└── month_selector.dart          # Widget MonthSelector

flutter/test/common_widgets/
└── month_selector_test.dart     # Tests widget
```

**Structure Decision** : Le widget est placé dans `common_widgets/` comme les autres widgets réutilisables du projet (ListItem, AppFormField, AppModal, AppToggle). Pas de sous-dossier — un seul fichier suffit pour ce widget simple.

## Complexity Tracking

> Aucune violation de constitution — tableau non applicable.

## Design Details

### API du widget

```dart
class MonthSelector extends StatefulWidget {
  const MonthSelector({
    super.key,
    this.initialMonth,    // 1-12, défaut: mois courant
    this.initialYear,     // défaut: année courante
    this.onChanged,       // callback(int month, int year)
  });

  final int? initialMonth;
  final int? initialYear;
  final void Function(int month, int year)? onChanged;
}
```

### État interne

- `_month` (int, 1-12) : mois sélectionné
- `_year` (int) : année sélectionnée
- Initialisés dans `initState()` à partir des paramètres ou `DateTime.now()`

### Label formaté

- Utilise `DateFormat('MMMM yyyy', 'fr_FR')` du package `intl`
- Capitalise la première lettre (ex: "février 2026" → "Février 2026")
- Référence existante : `RelativeDateFormatter` utilise déjà `DateFormat` avec `fr_FR`

### Navigation

- `_prevMonth()` : décrémente mois, wrap janvier → décembre (année - 1)
- `_nextMonth()` : incrémente mois, wrap décembre → janvier (année + 1)
- Appelle `onChanged` après chaque changement

### Layout

```
[IconButton ◀] ---- [Label "Février 2026"] ---- [IconButton ▶]
     48dp          min-width ~160dp, centered         48dp
```

- `Row` avec `MainAxisAlignment.center`
- Boutons : `IconButton` avec `Icons.chevron_left` / `Icons.chevron_right`
- Container boutons : rond (`AppRadius.round`), surface par défaut, ombre légère
- Label : `AppTypography.lg`, `semiBold`, couleur `textPrimary`, centré
- Espacement : `AppSpacing.space4` entre boutons et label

### Tokens utilisés

| Token | Source | Usage |
|-------|--------|-------|
| `AppSpacing.space4` | `app_spacing.dart` | Gap entre boutons et label |
| `AppTypography.lg` | `app_typography.dart` | Taille du label (18px) |
| `AppTypography.semiBold` | `app_typography.dart` | Poids du label (600) |
| `AppRadius.round` | `app_radius.dart` | Rayon boutons (999px → cercle) |
| `AppShadows.sm` | `app_shadows.dart` | Ombre boutons au repos |
| `AppColors` / `colorScheme` | `app_theme.dart` | Couleurs surface, texte, icônes |

### Accessibilité

- Boutons : `Semantics(label: 'Mois précédent')` / `Semantics(label: 'Mois suivant')`
- Label mois : texte lisible par les lecteurs d'écran par défaut
- `excludeSemantics: true` sur les icônes (le label sémantique est sur le bouton parent)

### Tests prévus

Organisés par user story, nommage `should_X_when_Y` :

**US1 — Navigation** :
- `should_display_current_month_when_no_initial_values`
- `should_display_initial_month_when_provided`
- `should_show_next_month_when_next_pressed`
- `should_show_previous_month_when_prev_pressed`
- `should_wrap_to_january_when_next_from_december`
- `should_wrap_to_december_when_prev_from_january`
- `should_increment_year_when_next_from_december`
- `should_decrement_year_when_prev_from_january`
- `should_capitalize_month_label`

**US2 — Callback** :
- `should_call_onChanged_with_new_month_year_when_next_pressed`
- `should_call_onChanged_with_new_month_year_when_prev_pressed`
- `should_call_onChanged_with_wrapped_values_on_year_boundary`
- `should_not_crash_when_onChanged_is_null`

**US3 — Design system** :
- `should_use_design_tokens_for_button_styling`
- `should_use_design_tokens_for_label_styling`
- `should_adapt_to_dark_theme`

**US4 — Accessibilité** :
- `should_have_prev_button_semantics_label`
- `should_have_next_button_semantics_label`

**Edge cases** :
- `should_handle_long_month_name_without_overflow`
- `should_render_in_narrow_container`
