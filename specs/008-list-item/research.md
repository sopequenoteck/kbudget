# Research: Composant ListItem réutilisable

**Feature**: 008-list-item | **Date**: 2026-02-09

## R-001: Pattern de composant shared existant

**Decision**: Suivre le pattern identique à `FormField`, `Fab`, `Modal`
**Rationale**: Cohérence avec le codebase existant. Tous les composants shared utilisent `input()` / `input.required()`, `output()`, `ChangeDetectionStrategy.OnPush`, `standalone: true`, SCSS avec `var(--token)` uniquement.
**Alternatives considered**: Aucune — le pattern est établi et uniforme.

## R-002: Gestion de la classe CSS sur la valeur

**Decision**: Input optionnel `valueClass` de type `string` avec valeur par défaut `''`
**Rationale**: Le parent applique une classe utilitaire existante (`.amount-income`, `.amount-expense`) ou une classe custom. Le composant ne connaît pas la sémantique métier.
**Alternatives considered**:
- Enum interne (`income | expense | debt-owe | debt-owed`) → Rejeté : couple le composant à la logique métier
- `ngClass` object → Rejeté : surcharge inutile pour un cas simple

## R-003: Layout flexbox pour le list item

**Decision**: Flexbox horizontal avec 3 zones : icône (fixe) | contenu (flex: 1, min-width: 0) | valeur (fixe, shrink: 0)
**Rationale**: `min-width: 0` permet le `text-overflow: ellipsis` sur le titre. `flex-shrink: 0` sur la valeur garantit sa visibilité complète.
**Alternatives considered**: CSS Grid → Rejeté : flexbox suffit pour un layout 1D.

## R-004: Accessibilité clavier et interaction

**Decision**: `<div>` avec `role="button"`, `tabindex="0"`, handlers `(click)` + `(keydown.enter)` + `(keydown.space)`
**Rationale**: Conforme aux guidelines ARIA pour les éléments interactifs non-natifs.
**Alternatives considered**:
- `<button>` natif → Rejeté : reset de styles lourd pour un layout complexe
- `<a>` → Rejeté : pas de navigation URL

## R-005: Design tokens utilisés

**Decision**: Mapping complet des tokens existants vers les zones du composant (spacing, typographie, couleurs, transitions). Tous les tokens existent dans `_tokens.scss`.
**Rationale**: Conformité FR-012, cohérence avec le design system.
**Alternatives considered**: Aucune — contrainte spec explicite.
