# Implementation Plan: Widget ListItem réutilisable (Flutter)

**Branch**: `033-flutter-listitem-widget` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/033-flutter-listitem-widget/spec.md`

## Summary

Créer un widget Flutter `ListItem` stateless et réutilisable affichant une icône dans un cercle coloré, un titre, un sous-titre optionnel, une valeur formatée avec couleur dynamique et un sous-titre droit optionnel. Le widget est utilisé dans 4 contextes métier (dashboard, transactions, abonnements, dettes) sans logique métier interne. Un constructeur factory `ListItem.skeleton()` fournit un état de chargement avec shimmer animé (P3).

## Technical Context

**Language/Version**: Dart >= 3.11 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter (SDK), shimmer ^3.0.0 (pour skeleton P3)
**Storage**: N/A (widget UI pur, pas de persistance)
**Testing**: flutter_test (SDK)
**Target Platform**: iOS 15+ / Android API 24+ (mobile-first)
**Project Type**: mobile (Flutter, monorepo `flutter/`)
**Performance Goals**: Scroll fluide de 50+ items sans jank (SC-005), pas de rebuild inutile
**Constraints**: Widget stateless, zéro logique métier, données pré-formatées, design tokens uniquement
**Scale/Scope**: 1 widget + 1 fichier de test, utilisé par 4 écrans

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Applicable | Statut | Justification |
|----------|-----------|--------|---------------|
| I. API-First | Non | N/A | Widget frontend pur, pas d'endpoint API |
| II. Sécurité par défaut | Non | N/A | Composant UI sans données sensibles |
| III. Simplicité & YAGNI | Oui | PASS | Widget stateless simple, pas d'abstraction (pas de classes héritées, pas de pattern complex) |
| IV. Mobile-First UX | Oui | PASS | Widget optimisé mobile : tap feedback, taille tactile, ellipsis texte long |
| V. Testabilité | Oui | PASS | Widget testable unitairement via `flutter_test`, cas nominaux + limites couverts |
| VI. Observabilité | Non | N/A | Widget UI sans logging |
| VII. Self-Hosted Ready | Non | N/A | Composant frontend, pas d'infra |

**Gate Result**: PASS - Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/033-flutter-listitem-widget/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (widget API)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/
├── pubspec.yaml                          # + shimmer: ^3.0.0
└── lib/
    └── src/
        └── common_widgets/
            └── list_item.dart            # Widget ListItem + ListItem.skeleton()

flutter/
└── test/
    └── src/
        └── common_widgets/
            └── list_item_test.dart       # Tests unitaires
```

**Structure Decision**: Le widget s'insère dans `common_widgets/` conformément au pattern existant (`loading_indicator.dart`, `adaptive_scaffold.dart`, `fab_menu.dart`). Un seul fichier Dart contient le widget principal et le constructeur skeleton. Les tests suivent la convention miroir `test/src/common_widgets/`.

## Complexity Tracking

Aucune violation de la constitution. Pas de déviation nécessaire.

## Design Details

### Layout Architecture

Reproduction fidèle du composant Angular `app-list-item` avec adaptation Flutter :

```
┌─────────────────────────────────────────────────────────┐
│  ┌──────┐                                               │
│  │ 🛒   │  Courses Lidl              -45,90 €          │
│  │      │  Alimentation              Hier               │
│  └──────┘                                               │
│  [40×40]  [flex:1, min-width:0]      [shrink:0, end]   │
│           gap:4px entre lignes       gap:4px            │
│  gap:12px                      gap:12px                 │
│  padding: 12px vertical, 16px horizontal                │
└─────────────────────────────────────────────────────────┘
```

### Widget Tree

```
InkWell (ou Padding si onPressed == null)
└── Padding (vertical: 12, horizontal: 16)
    └── Row (gap: 12, crossAxisAlignment: center)
        ├── Container (40×40, cercle, backgroundColor)
        │   └── Center
        │       └── Text (emoji, fontSize: 18)
        ├── Expanded (flex: 1)
        │   └── Column (crossAxisAlignment: start, gap: 4)
        │       ├── Text (title, medium 16, ellipsis, maxLines: 1)
        │       └── Text? (subtitle, regular 14, secondary, ellipsis)
        └── Column (crossAxisAlignment: end, gap: 4)
            ├── Text (value, semiBold 16, valueColor)
            └── Text? (rightSubtitle, regular 14, secondary)
```

### Token Mapping (Angular SCSS → Flutter)

| Token Angular | Valeur | Token Flutter |
|---------------|--------|---------------|
| `--space-1` | 4px | `AppSpacing.space1` |
| `--space-3` | 12px | `AppSpacing.space3` |
| `--space-4` | 16px | `AppSpacing.space4` |
| `--space-10` | 40px | `AppSpacing.space10` |
| `--font-size-sm` | 14px | `AppTypography.sizeSm` |
| `--font-size-base` | 16px | `AppTypography.sizeMd` |
| `--font-size-lg` | 18px | `AppTypography.sizeLg` |
| `--font-weight-medium` | 500 | `AppTypography.medium` |
| `--font-weight-semibold` | 600 | `AppTypography.semiBold` |
| `--color-primary-light` | #FEF3C7 | `AppColors.amber100` (statique, identique light/dark) |
| `--radius-round` | 999px | `AppRadius.round` |
| `--text-primary` | colorScheme.onSurface | `theme.colorScheme.onSurface` |
| `--text-secondary` | colorScheme.onSurfaceVariant | `theme.colorScheme.onSurfaceVariant` |

### Interaction Behavior

| État | `onPressed` fourni | `onPressed` null |
|------|-------------------|-----------------|
| Wrapper | `InkWell` | `Padding` (pas de wrapper interactif) |
| Tap | Ripple/splash + callback | Aucun effet |
| Semantics | `button` label | Pas de sémantique bouton |
| Cursor | Clickable | Default |

### Skeleton Constructor (P3)

`ListItem.skeleton()` affiche des placeholders animés shimmer :
- Cercle gris 40×40 (icône)
- Rectangle arrondi 120×14 (titre)
- Rectangle arrondi 80×12 (sous-titre)
- Rectangle arrondi 60×14 (valeur)
- Rectangle arrondi 40×12 (date)

Package : `shimmer: ^3.0.0` (léger, stable, 3k+ likes pub.dev).

### Constructor Signature

```dart
class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.rightSubtitle,
    this.valueColor,
    this.iconBackgroundColor,
    this.onPressed,
  }) : _isSkeleton = false;

  /// Constructeur nommé pour l'état de chargement shimmer.
  /// Initialise les champs requis avec des valeurs vides (non affichées).
  const ListItem.skeleton({super.key})
      : icon = '',
        title = '',
        value = '',
        subtitle = null,
        rightSubtitle = null,
        valueColor = null,
        iconBackgroundColor = null,
        onPressed = null,
        _isSkeleton = true;

  final bool _isSkeleton;
}
```

## Constitution Re-Check (Post-Design)

| Principe | Statut |
|----------|--------|
| III. Simplicité & YAGNI | PASS - 1 fichier, 1 classe, constructeurs simples |
| IV. Mobile-First UX | PASS - Tap feedback, taille tactile 48px min, ellipsis |
| V. Testabilité | PASS - Widget sans dépendance externe, testable avec `pumpWidget` |

**Final Gate Result**: PASS
