# Research: Fix checkboxes non fonctionnelles

**Date**: 2026-02-12
**Feature**: 020-fix-checkbox-forms

## Résumé

Aucune recherche externe nécessaire. La cause racine a été identifiée par analyse directe du code source.

## Décision : Exclusion via `:not()` dans le sélecteur global

- **Decision**: Modifier `_forms.scss` pour exclure `input[type="checkbox"]` et `input[type="radio"]` du sélecteur global `input` via `:not()`
- **Rationale**: Correction en un seul point, protège les futurs formulaires, support navigateur >99%
- **Alternatives considered**:
  - Override par composant : rejeté (duplication, fragile)
  - Classe `.text-input` : rejeté (nécessite modification de tous les templates, sur-ingénierie)

## Analyse du bug

### Cause racine

`app/src/styles/_forms.scss` lignes 5-7 :

```scss
input,
textarea,
select {
```

Ce sélecteur cible TOUS les `input`, y compris les checkboxes. Les propriétés problématiques :
- `appearance: none` (ligne 21) — supprime le rendu natif
- `width: 100%` (ligne 8) — étire la checkbox
- `padding`, `border-radius`, `background-color` — styles texte inadaptés

### Vérification logique

La logique ReactiveForm est correcte :
- `formControlName="actif"` et `formControlName="rembourse"` sont bien liés
- Les valeurs par défaut (`true`/`false`) sont correctement définies
- `getRawValue()` retourne le booléen attendu

Le problème est exclusivement CSS.
