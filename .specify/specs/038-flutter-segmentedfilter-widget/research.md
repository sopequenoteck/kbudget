# Research: Widget filtres segmentés (SegmentedFilter)

**Feature**: 038-flutter-segmentedfilter-widget
**Date**: 2026-02-21

## Decision 1 : Pattern de widget (Controlled vs Uncontrolled)

**Decision**: Widget contrôlé (StatelessWidget) — le parent gère l'état via `selectedValue` + `onChanged`.

**Rationale**: Cohérent avec AppToggle (contrôlé, StatelessWidget). Le filtrage de liste est une responsabilité du parent (écran), pas du widget de filtre lui-même. Simplifie la testabilité (pas d'état interne à vérifier).

**Alternatives considered**:
- StatefulWidget uncontrolled (comme MonthSelector) — rejeté car le filtre actif doit être synchronisé avec la liste filtrée dans l'écran parent.
- StatefulWidget avec callback — complexité inutile, le parent doit connaître la valeur courante.

## Decision 2 : API générique typée

**Decision**: Utiliser un type paramétré `T` avec une liste de `SegmentedFilterItem<T>` contenant `value` et `label`.

**Rationale**: Permet de passer des enums (`TransactionType`), des String, ou tout autre type. Évite la conversion index ↔ valeur (contrairement à AppToggle qui utilise `int selectedIndex`). Plus expressif et type-safe.

**Alternatives considered**:
- `List<String> labels` + `int selectedIndex` (pattern AppToggle) — rejeté car perd le typage de la valeur et force la conversion index → valeur dans chaque écran parent.
- `Map<T, String>` (valeur → label) — rejeté car ne préserve pas l'ordre d'insertion garanti en Dart mais moins lisible à l'usage.

## Decision 3 : Style d'animation

**Decision**: Cross-fade via `AnimatedContainer` (fond) + `AnimatedDefaultTextStyle` (texte), durée `AppDurations.fast` (120ms), courbe `Curves.easeInOut`.

**Rationale**: Pattern identique à AppToggle. Cross-fade choisi en clarification (pas de sliding pill). 120ms = animation subtile, perçue mais pas lente. Cohérent avec le reste du DS.

**Alternatives considered**:
- Sliding pill (iOS natif) — rejeté en clarification (complexité AnimatedPositioned, pas de précédent dans le DS).
- `AppDurations.normal` (200ms) — rejeté car trop lent pour un simple changement de filtre.

## Decision 4 : Layout et répartition des segments

**Decision**: `Row` avec `Expanded` sur chaque segment pour répartition équitable pleine largeur.

**Rationale**: Pattern simple et fiable. Chaque segment occupe exactement 1/N de la largeur disponible. Pas besoin de `Flexible` ni de `LayoutBuilder`.

**Alternatives considered**:
- `Flexible` avec flex ratio — même résultat mais moins explicite.
- `LayoutBuilder` + calcul manuel — sur-ingénierie pour ce cas.

## Decision 5 : Dimensions et tokens visuels

**Decision**: Hauteur conteneur 36px (identique à AppToggle). Conteneur : `surfaceContainerHighest`, `AppRadius.lg` (12px), padding `AppSpacing.space1` (4px). Segment actif : `surface`, `AppShadows.sm`, `AppRadius.md` (8px). Texte : `AppTypography.sizeSm` (14px).

**Rationale**: Mapping direct des tokens Angular (`--bg-tertiary` → `surfaceContainerHighest`, `--surface-default` → `surface`, `--shadow-sm` → `AppShadows.sm`, `--radius-lg` → `AppRadius.lg`, `--radius-md` → `AppRadius.md`, `--space-1` → `AppSpacing.space1`). Hauteur 36px identique à AppToggle pour cohérence visuelle.

**Alternatives considered**:
- Hauteur 40px — rejeté, AppToggle utilise 36px et la cohérence prime.
- `AppRadius.xl` (16px) pour le conteneur — rejeté, le mapping Angular indique `--radius-lg` (12px).

## Decision 6 : Gestion du edge case < 2 segments

**Decision**: Assertion dans le constructeur `assert(items.length >= 2)`, identique au pattern AppToggle.

**Rationale**: Un filtre avec 0 ou 1 segment n'a pas de sens fonctionnel. L'assertion en debug aide le développeur à détecter l'erreur tôt. Le edge case "1 segment" de la spec est couvert par cette assertion (comportement défensif documenté).

**Alternatives considered**:
- Dégradation gracieuse (afficher 1 segment) — rejeté car masque un bug du code appelant.
- Pas de validation — rejeté car source de confusion en debug.

## Decision 7 : Sémantique d'accessibilité

**Decision**: `Semantics` wrapper sur chaque segment avec `toggled: isSelected` et `label: item.label`. Pas de `role: "tablist"` Flutter natif (n'existe pas). Pattern identique à AppToggle.

**Rationale**: Pattern identique à AppToggle. Flutter ne supporte pas nativement `role="group"` comme HTML, mais `Semantics(toggled:)` fournit l'information équivalente pour VoiceOver/TalkBack.

**Alternatives considered**:
- `ToggleButtons` Material — rejeté car style non personnalisable (Material design, pas iOS style).
- `CupertinoSegmentedControl` — rejeté car impose le style Cupertino complet, non personnalisable avec les tokens du DS.
