# Implementation Plan: Widget FormField

**Branch**: `035-flutter-formfield-widget` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/035-flutter-formfield-widget/spec.md`

## Summary

Widget `AppFormField` réutilisable pour envelopper n'importe quel champ de formulaire avec un label, un conteneur stylé iOS (fond gris, pas de bordure, radius xl), une bordure amber au focus, et un message d'erreur conditionnel. Widget purement visuel, sans logique métier. Utilise les design tokens existants du projet.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter (SDK)
**Storage**: N/A (widget UI pur, pas de persistance)
**Testing**: flutter_test (widget tests)
**Target Platform**: iOS, Android, Web (multi-plateforme Flutter)
**Project Type**: Mobile
**Performance Goals**: 60 fps, pas de jank sur les animations de focus
**Constraints**: Widget stateful avec un seul état interne (hasFocus booléen via Focus widget)
**Scale/Scope**: 1 widget + 1 fichier de test

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Applicable | Statut | Notes |
|----------|------------|--------|-------|
| I. API-First | Non | N/A | Widget UI pur, pas d'endpoint |
| II. Sécurité par défaut | Non | N/A | Pas de données sensibles |
| III. Simplicité & YAGNI | Oui | PASS | Widget simple, pas d'abstraction prématurée, suit le pattern ListItem |
| IV. Mobile-First UX | Oui | PASS | Style iOS-first, optimisé tactile (padding 12/16px) |
| V. Testabilité | Oui | PASS | Widget testable unitairement avec flutter_test |
| VI. Observabilité | Non | N/A | Widget UI, pas de logging |
| VII. Self-Hosted Ready | Non | N/A | Pas d'infrastructure |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/035-flutter-formfield-widget/
├── plan.md              # This file
├── research.md          # Décisions techniques (nommage, focus, style)
├── quickstart.md        # Scénarios d'utilisation avec API du widget
├── checklists/
│   └── requirements.md  # Checklist qualité spec
└── tasks.md             # Tâches (généré par /speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/common_widgets/
└── app_form_field.dart          # Widget AppFormField

flutter/test/src/common_widgets/
└── app_form_field_test.dart     # Tests du widget
```

**Structure Decision**: Le widget est placé dans `common_widgets/` comme le `ListItem` existant, car c'est un composant UI générique réutilisable dans toute l'application. Pas dans `features/settings/` car il n'est pas spécifique aux settings.

## Design Decisions

### Nommage : `AppFormField`

Préfixe `App` pour éviter la collision avec `FormField<T>` natif Flutter. Cohérent avec `AppSpacing`, `AppRadius`, `AppColors`, `AppTypography`.

### API du widget

```dart
class AppFormField extends StatefulWidget {
  final String label;           // Requis — texte du label
  final Widget child;           // Requis — widget enfant (champ de saisie)
  final bool showError;         // Optionnel, défaut: false
  final String errorMessage;    // Optionnel, défaut: ''

  const AppFormField({
    required this.label,
    required this.child,
    this.showError = false,
    this.errorMessage = '',
    super.key,
  });
}
```

### Mapping des tokens de design

| Spec (FR) | Token utilisé | Valeur |
|-----------|---------------|--------|
| FR-001: espacement label-champ 8px | `AppSpacing.space2` | 8px |
| FR-002: fond conteneur gris | `colorScheme.surfaceContainerHighest` | gray100/gray800 |
| FR-003: radius xl | `AppRadius.xl` | 16px |
| FR-007: taille erreur 12px | `AppTypography.sizeXs` | 12px |
| FR-008: taille label 14px | `AppTypography.sizeSm` | 14px |
| FR-008: poids label medium | `AppTypography.medium` | w500 |
| FR-008: couleur label secondaire | `colorScheme.onSurfaceVariant` | textSecondary |
| FR-009: padding vertical 12px | `AppSpacing.space3` | 12px |
| FR-009: padding horizontal 16px | `AppSpacing.space4` | 16px |
| FR-004: bordure focus amber | `colorScheme.primary` | amber500/amber400 |
| FR-004: épaisseur bordure focus | Hardcoded `1.5` | 1.5px |
| FR-007: couleur erreur | `colorScheme.error` | red |
| FR-004: animation focus | `AppDurations.normal` | 200ms |
| US2-AS3: animation erreur | `AppDurations.normal` | 200ms (AnimatedSize) |

### Pattern de détection du focus

Le child est enveloppé dans un `Focus` widget avec `onFocusChange` pour détecter le focus/unfocus. Un `AnimatedContainer` gère la transition de `BoxDecoration` (ajout/retrait de la bordure).

```
Column
├── Text (label)
├── SizedBox (space2 = 8px)
├── Focus(onFocusChange: ...)
│   └── AnimatedContainer (duration: 200ms)
│       └── Padding (space3 vertical, space4 horizontal)
│           └── child
├── AnimatedSize (duration: 200ms, curve: easeInOut)
│   └── if showError:
│       ├── SizedBox (space1 = 4px)
│       └── Text (errorMessage, error color, sizeXs)
```

### Accessibilité

- `Semantics` wrapper avec `label` combinant le label du champ
- `MergeSemantics` pour fusionner label + champ enfant
- Erreur annoncée via `Semantics` avec `liveRegion: true` quand `showError` passe à `true`

### Interaction avec InputDecoration des TextField enfants

Les `TextField` placés dans `AppFormField` doivent utiliser `InputDecoration.collapsed()` ou une décoration sans bordure/fond pour éviter les doubles styles (le conteneur `AppFormField` fournit déjà le fond et la bordure).

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau non requis.
