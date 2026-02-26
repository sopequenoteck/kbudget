# Research: Widget ListItem réutilisable (Flutter)

**Feature**: 033-flutter-listitem-widget | **Date**: 2026-02-21

## R1 — Package shimmer pour ListItem.skeleton()

**Decision**: Utiliser `shimmer: ^3.0.0`

**Rationale**: Package le plus populaire et stable pour les effets shimmer sur pub.dev (3k+ likes). API simple via `Shimmer.fromColors()` qui wrap les placeholders. Léger, pas de dépendances lourdes. Supporté activement.

**Alternatives considered**:
- `skeletonizer` : Plus moderne, wraps automatiquement un widget existant. Mais surdimensionné pour un seul widget avec des placeholders manuels simples. Ajoute de la magie implicite contraire au principe YAGNI.
- Shimmer custom (`AnimationController` + `ShaderMask`) : Contrôle total mais réinvente la roue pour un besoin standard. Plus de code à maintenir.
- Pas de shimmer (gris statique) : Fonctionnel mais UX inférieure. L'animation shimmer indique clairement un état de chargement.

## R2 — Pattern Flutter pour interactivité conditionnelle

**Decision**: Utiliser `InkWell` quand `onPressed != null`, sinon `Padding` simple (pas de wrapper interactif).

**Rationale**: Conforme au pattern Material Flutter. `InkWell` fournit nativement le ripple/splash et la sémantique `button`. Quand `onPressed` est null, éviter `InkWell` supprime le ripple, le curseur pointer et la sémantique bouton sans code conditionnel dans le build.

**Alternatives considered**:
- `GestureDetector` : Pas de ripple natif, nécessiterait un feedback visuel custom. Contre-productif.
- `InkWell` avec `onTap: null` : Flutter désactive automatiquement le ripple quand `onTap` est null, mais garde un wrapper inutile dans l'arbre. Pas de différence de perf significative, mais plus propre sémantiquement de ne pas wrapper.
- `ListTile` Material : Widget Material trop opinioné (hauteur fixe, padding non customisable, leading/trailing contraints). Ne correspond pas au layout 3 zones de la spec.

## R3 — Accessibilité (Semantics) pour lecteur d'écran

**Decision**: Utiliser `Semantics` avec `label` combinant titre et valeur, `button: true` seulement quand `onPressed` fourni.

**Rationale**: Flutter `Semantics` widget est le standard pour l'accessibilité. Le label combiné permet au lecteur d'écran d'annoncer l'information essentielle en une fois (ex: "Courses Lidl, moins 45 euros 90"). La distinction button/non-button respecte la spec FR-007.

**Alternatives considered**:
- `MergeSemantics` : Fusionne automatiquement les enfants mais donne moins de contrôle sur l'ordre d'annonce.
- `ExcludeSemantics` sur les sous-éléments + `Semantics` parent : Plus explicite mais plus verbeux. Réservé si les tests d'accessibilité révèlent des doublons.

## R4 — Gestion du texte long (ellipsis)

**Decision**: `Text` avec `maxLines: 1`, `overflow: TextOverflow.ellipsis` sur title, subtitle, et value.

**Rationale**: Reproduction exacte du comportement Angular (`white-space: nowrap; overflow: hidden; text-overflow: ellipsis`). Le `Expanded` sur la colonne centrale garantit que le titre prend l'espace disponible sans pousser la colonne droite.

**Alternatives considered**:
- `FittedBox` : Réduit la taille du texte au lieu de tronquer. Mauvaise UX, texte illisible sur petits écrans.
- `maxLines: 2` avec wrap : Plus d'information visible mais hauteur variable, incohérent dans une liste scrollable.

## R5 — Design tokens existants : couverture complète

**Decision**: Tous les tokens nécessaires existent déjà dans le codebase Flutter.

**Rationale**: Vérification exhaustive :
- `AppSpacing` : space1 (4), space3 (12), space4 (16), space10 (40) — tous présents
- `AppTypography` : sizeSm (14), sizeMd (16), sizeLg (18), medium (w500), semiBold (w600) — tous présents
- `AppColors` : amber100 (#FEF3C7) pour fond icône par défaut — présent
- `AppRadius` : round (999) pour cercle icône — présent
- `AppThemeExtension` : incomeColor, expenseColor, debtOweColor, debtOwedColor — tous présents
- Couleurs de texte : via `theme.colorScheme.onSurface` et `onSurfaceVariant`

**Aucun token à créer.** Le widget utilise exclusivement l'existant.
