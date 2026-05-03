# Data Model: Widget filtres segmentés (SegmentedFilter)

**Feature**: 038-flutter-segmentedfilter-widget
**Date**: 2026-02-21

> Widget UI pur — pas d'entité de persistance. Ce document décrit le modèle de données de l'API du widget.

## Entités

### SegmentedFilterItem\<T\>

Représente un segment individuel dans le filtre.

| Attribut | Type | Requis | Description |
|----------|------|--------|-------------|
| `value`  | `T`  | Oui    | Valeur typée associée au segment (enum, String, etc.) |
| `label`  | `String` | Oui | Texte affiché dans le segment |

**Contraintes** :
- `label` ne doit pas être vide (assertion)
- `T` doit supporter l'égalité (`==`) pour la comparaison avec `selectedValue`

### SegmentedFilter\<T\>

Widget conteneur qui affiche les segments.

| Paramètre       | Type                                | Requis | Défaut | Description |
|------------------|-------------------------------------|--------|--------|-------------|
| `items`          | `List<SegmentedFilterItem<T>>`      | Oui    | -      | Liste des segments (2-5 éléments) |
| `selectedValue`  | `T`                                 | Oui    | -      | Valeur du segment actif |
| `onChanged`      | `ValueChanged<T>`                   | Oui    | -      | Callback déclenché au changement |

**Contraintes** :
- `items.length >= 2` (assertion)
- `items.length <= 5` (assertion)
- `selectedValue` doit correspondre à un `value` dans `items` (sinon premier segment sélectionné par défaut)

## Relations

```
SegmentedFilter<T>
  └── items: List<SegmentedFilterItem<T>>  (1..N, N ∈ [2,5])
       └── value: T  (identité du segment)
```

## Cycle de vie

Le widget est **stateless et contrôlé** :

1. Parent crée le widget avec `items`, `selectedValue`, `onChanged`
2. Utilisateur tape un segment → `onChanged(newValue)` appelé
3. Parent met à jour son état → reconstruit le widget avec le nouveau `selectedValue`
4. Pas de cycle de vie interne (pas de `initState`, `dispose`, etc.)
