# Research: Angular Text Scale

**Branch**: `093-angular-text-scale` | **Date**: 2026-03-15

## R1 — Technique de scaling texte global en CSS

**Decision**: Modifier `document.documentElement.style.fontSize` (en %) pour scaler tous les textes via `rem`.

**Rationale**: Le projet utilise `rem` pour toutes les tailles de police (via tokens `--font-size-xs` à `--font-size-3xl` définis en `rem` dans `_primitives.scss`). Changer le `font-size` de `<html>` (qui est la référence du `rem`) scale automatiquement tous les textes. Les icônes utilisant `px` (ex: `size="24"`) ne sont pas affectées.

**Implementation**: `fontSize = factor * 100 + '%'` → `85%`, `100%`, `130%`.

**Alternatives rejected**:
- CSS custom property `--text-scale` + `calc()` sur chaque token : trop invasif, nécessite de modifier tous les tokens
- `transform: scale()` sur le body : affecte aussi les icônes et le layout
- `zoom` CSS : non standard, comportement variable entre navigateurs

## R2 — Pattern de persistance : réutiliser ThemeService

**Decision**: Créer un `TextScaleService` avec le même pattern que `ThemeService` : signal + localStorage + effect.

**Rationale**: Le `ThemeService` est le pattern de référence dans l'app pour les préférences d'affichage persistées localement. Même structure : `const STORAGE_KEY`, `restoreX()` privée dans le constructeur, `setX()` publique, `effect()` pour appliquer sur le DOM.

**Clé localStorage**: `budget_text_scale` (même convention que `budget_theme`).

## R3 — Facteurs de scale : parité Flutter

**Decision**: Utiliser exactement les mêmes facteurs que Flutter.

| Label | Facteur | CSS fontSize |
|-------|---------|-------------|
| Petit | 0.85 | 85% |
| Normal | 1.0 | 100% |
| Grand | 1.3 | 130% |

**Rationale**: Parité fonctionnelle explicite demandée dans la spec (FR-007). L'utilisateur doit retrouver la même expérience visuelle entre les deux apps.
