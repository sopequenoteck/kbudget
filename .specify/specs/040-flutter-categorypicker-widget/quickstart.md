# Quickstart: Flutter — Widget CategoryPicker

**Feature**: 040-flutter-categorypicker-widget
**Date**: 2026-02-22

## Usage basique — Sélection de catégorie

```dart
CategoryPicker(
  categories: categories, // List<Category>
  selectedId: selectedCategoryId,
  onChanged: (id) => setState(() => selectedCategoryId = id),
  label: 'Catégorie',
)
```

## Avec validation dans un formulaire

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      CategoryPicker(
        categories: categories,
        selectedId: selectedCategoryId,
        onChanged: (id) => setState(() => selectedCategoryId = id),
        label: 'Catégorie',
        validator: (value) => value == null ? 'Catégorie requise' : null,
      ),
      // ... autres champs
    ],
  ),
)
```

## Avec bouton "+ Créer" (callback création)

```dart
CategoryPicker(
  categories: categories,
  selectedId: selectedCategoryId,
  onChanged: (id) => setState(() => selectedCategoryId = id),
  label: 'Catégorie',
  clearable: true,
  onCreateRequested: (searchTerm) {
    // Le parent gère la création
    // Ex: ouvrir un formulaire de catégorie
    showCategoryForm(initialName: searchTerm);
  },
)
```

## Mode effaçable

```dart
CategoryPicker(
  categories: categories,
  selectedId: selectedCategoryId,
  onChanged: (id) => setState(() => selectedCategoryId = id),
  label: 'Catégorie',
  clearable: true, // Affiche le bouton × quand une catégorie est sélectionnée
)
```

## Mode désactivé

```dart
CategoryPicker(
  categories: categories,
  selectedId: selectedCategoryId,
  onChanged: null,
  label: 'Catégorie',
  enabled: false, // Apparence atténuée, pas d'interaction
)
```

## API complète

| Paramètre | Type | Requis | Défaut | Description |
|-----------|------|--------|--------|-------------|
| `categories` | `List<Category>` | Oui | — | Liste des catégories disponibles |
| `selectedId` | `String?` | Non | `null` | ID de la catégorie sélectionnée |
| `onChanged` | `ValueChanged<String?>?` | Non | `null` | Callback de changement de sélection |
| `label` | `String` | Oui | — | Label affiché au-dessus du champ |
| `placeholder` | `String` | Non | `'Sélectionner...'` | Texte quand rien n'est sélectionné |
| `clearable` | `bool` | Non | `false` | Affiche le bouton × pour effacer |
| `onCreateRequested` | `ValueChanged<String>?` | Non | `null` | Callback quand "+ Créer" est pressé. Si null, le bouton n'apparaît pas |
| `onSearchChanged` | `ValueChanged<String>?` | Non | `null` | Callback de changement de terme de recherche |
| `searchThreshold` | `int` | Non | `5` | Nombre minimum de catégories pour activer la recherche |
| `enabled` | `bool` | Non | `true` | Active/désactive le champ |
| `validator` | `FormFieldValidator<String?>?` | Non | `null` | Validation de formulaire |
| `onSaved` | `FormFieldSetter<String?>?` | Non | `null` | Callback Form.save() |
| `autovalidateMode` | `AutovalidateMode?` | Non | `null` | Mode de validation automatique |

## Comportements clés

1. **Recherche** : activée automatiquement si `categories.length >= searchThreshold`
2. **Bouton "+ Créer"** : apparaît uniquement quand la recherche ne retourne aucun résultat ET `onCreateRequested` est fourni
3. **Auto-reset** : si la catégorie sélectionnée disparaît de la liste, la sélection est réinitialisée automatiquement
4. **Affichage riche** : chaque catégorie montre son emoji + pastille couleur + nom
