# Data Model: Widget SelectPicker

**Feature**: 039-flutter-selectpicker-widget
**Date**: 2026-02-21

## Entities

### SelectPickerItem

Modèle de données représentant un item sélectionnable dans le SelectPicker.

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Oui | Identifiant unique de l'item |
| `label` | `String` | Oui | Texte principal affiché |
| `icon` | `String?` | Non | Emoji affiché avant le label |
| `color` | `Color?` | Non | Couleur de la pastille circulaire |
| `secondaryText` | `String?` | Non | Texte secondaire aligné à droite |

**Contraintes**:
- `id` ne doit pas être vide (assert)
- `label` ne doit pas être vide (assert)
- Unicité de `id` dans une liste donnée (responsabilité du parent)

**Pas de state transitions** : modèle immuable (const constructor).

### SelectPicker (Widget API)

Le widget principal étend `FormField<String?>`.

| Paramètre | Type | Obligatoire | Défaut | Description |
|-----------|------|-------------|--------|-------------|
| `items` | `List<SelectPickerItem>` | Oui | — | Liste des items sélectionnables |
| `selectedId` | `String?` | Non | `null` | Id de l'item actuellement sélectionné |
| `onChanged` | `ValueChanged<String?>?` | Non | `null` | Callback quand la sélection change |
| `label` | `String` | Oui | — | Label affiché au-dessus du trigger (style AppFormField) |
| `placeholder` | `String` | Non | `'Sélectionner...'` | Texte affiché quand aucun item sélectionné |
| `clearable` | `bool` | Non | `false` | Affiche le bouton × pour effacer |
| `searchable` | `bool?` | Non | `null` | Force la recherche. `null` = auto (>= `searchThreshold`) |
| `searchThreshold` | `int` | Non | `5` | Seuil auto d'affichage de la recherche |
| `emptyMessage` | `String` | Non | `'Aucun résultat'` | Message quand la recherche ne retourne rien |
| `enabled` | `bool` | Non | `true` | Active/désactive le widget |
| `onSearchChanged` | `ValueChanged<String>?` | Non | `null` | Callback émettant le terme de recherche |
| `validator` | `FormFieldValidator<String?>?` | Non | `null` | Validation FormField |
| `onSaved` | `FormFieldSetter<String?>?` | Non | `null` | Callback Form.save() |
| `autovalidateMode` | `AutovalidateMode?` | Non | `null` | Mode de validation automatique |

## Relations

```
SelectPicker (FormField<String?>)
  ├── possède → List<SelectPickerItem> (1:N)
  ├── utilise → AppModal.show() (dépendance)
  └── émule → Style visuel AppFormField (pattern)
```

## Validation Rules

| Règle | Source | Impact |
|-------|--------|--------|
| `id` et `label` non vides | SelectPickerItem constructor | Assert en dev |
| `selectedId` doit exister dans `items` ou être `null` | `_SelectPickerState.didUpdateWidget` | Auto-reset à `null` si item absent |
| Validation FormField | `validator` parameter | `errorText` affiché sous le trigger |
