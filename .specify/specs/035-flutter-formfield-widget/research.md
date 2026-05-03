# Research: Widget FormField

**Feature**: 035-flutter-formfield-widget
**Date**: 2026-02-21

## R1 — Nommage du widget (collision avec FormField natif)

**Decision**: Nommer le widget `AppFormField` avec le préfixe `App` pour éviter la collision avec `FormField<T>` natif de Flutter.

**Rationale**: Flutter expose `FormField<T>` dans `package:flutter/widgets.dart`. Utiliser le même nom causerait des conflits d'import et de la confusion. Le préfixe `App` est cohérent avec les conventions du projet (AppSpacing, AppRadius, AppColors, AppTypography, AppThemeExtension).

**Alternatives considered**:
- `KFormField` — préfixe projet `K`, mais moins lisible et incohérent avec les tokens existants qui utilisent `App`
- `FormFieldWrapper` — trop verbeux et pas aligné avec la convention de nommage du projet
- `StyledFormField` — décrit l'implémentation plutôt que la responsabilité

## R2 — Pattern de détection du focus enfant

**Decision**: Utiliser un `FocusNode` passé en paramètre optionnel ou un `Focus` widget interne qui écoute les changements de focus pour animer la bordure du conteneur.

**Rationale**: Le widget doit détecter quand son enfant a le focus pour afficher la bordure amber. Deux approches possibles :
1. **Focus widget wrapper** (recommandé) : Envelopper le child dans un `Focus` widget avec `onFocusChange` callback. Simple, pas de gestion manuelle du FocusNode.
2. **FocusNode en paramètre** : Le parent passe un FocusNode, le widget l'écoute. Plus flexible mais ajoute de la complexité côté appelant.

L'approche Focus widget wrapper est retenue car elle est transparente pour l'appelant et cohérente avec FR-011 (pas d'état interne complexe — le Focus widget gère un seul booléen `hasFocus`).

**Alternatives considered**:
- `FocusScope` — trop large, conçu pour gérer la navigation entre champs, pas la détection de focus d'un seul champ
- Écouter le `FocusNode` du `TextField` enfant — impossible car le widget ne connaît pas le type de son enfant (composition)

## R3 — Style du conteneur vs InputDecorationTheme existant

**Decision**: Le widget `AppFormField` fournit son propre style de conteneur (fond gris, pas de bordure, radius xl) indépendamment de l'`InputDecorationTheme` global. Les `TextField` enfants devront utiliser `InputDecoration.collapsed` ou une décoration sans bordure pour éviter les doubles bordures.

**Rationale**: L'`InputDecorationTheme` actuel utilise un style Material 3 avec bordures visibles (`OutlineInputBorder` + `gray300`). Le DESIGN.md spécifie un style iOS différent (fond gris, pas de bordure). Modifier l'`InputDecorationTheme` global impacterait tous les formulaires existants. Il est plus sûr de gérer le style localement dans le widget wrapper.

**Alternatives considered**:
- Modifier l'`InputDecorationTheme` global — risque de régression sur les écrans existants (login, data settings)
- Créer un deuxième thème — complexité inutile, violation de YAGNI

## R4 — Animation de la bordure au focus

**Decision**: Utiliser `AnimatedContainer` avec `AppDurations.normal` (200ms) et `AppDurations.easeInOut` pour la transition de bordure focus/unfocus.

**Rationale**: Cohérent avec les tokens d'animation existants. `AnimatedContainer` gère automatiquement la transition entre deux états de `BoxDecoration` sans nécessiter un `AnimationController` explicite.

**Alternatives considered**:
- `AnimationController` + `Tween` — plus flexible mais over-engineering pour un changement de bordure
- Pas d'animation — transition abrupte, mauvaise UX

## R5 — Couleurs du conteneur par thème

**Decision**: Utiliser `colorScheme.surfaceContainerHighest` pour le fond du conteneur. Cette propriété Material 3 correspond au `bgSecondary` du DESIGN.md et s'adapte automatiquement au thème clair/sombre.

**Rationale**: Le token `surfaceContainerHighest` est la surface la plus élevée dans Material 3, donnant un fond gris clair en thème clair et gris foncé en thème sombre. C'est le mapping le plus proche de `bgSecondary` (gray100 light / gray800 dark) sans ajouter de couleur custom au ThemeExtension.

**Alternatives considered**:
- `surfaceContainer` — trop subtil, contraste insuffisant avec le fond de page
- `surfaceContainerHigh` — acceptable mais moins visible
- Ajouter `bgSecondary` au `AppThemeExtension` — ajout d'un token pour un seul widget, violation de YAGNI
