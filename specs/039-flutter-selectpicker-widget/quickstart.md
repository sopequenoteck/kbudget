# Quickstart: Widget SelectPicker

**Feature**: 039-flutter-selectpicker-widget

## Prérequis

- Flutter >= 3.27 (stable)
- Le projet `flutter/` avec les widgets existants : `AppModal`, `AppFormField`, design tokens

## Fichiers à créer

| Fichier | Contenu |
|---------|---------|
| `flutter/lib/src/common_widgets/select_picker.dart` | SelectPickerItem + SelectPicker (FormField) |
| `flutter/test/src/common_widgets/select_picker_test.dart` | Tests unitaires widget |

## Usage basique

```dart
// Dans un formulaire
Form(
  key: _formKey,
  child: Column(
    children: [
      SelectPicker(
        label: 'Compte',
        items: [
          SelectPickerItem(id: '1', label: 'Courant', icon: '🏦', secondaryText: '1 234 €'),
          SelectPickerItem(id: '2', label: 'Épargne', icon: '💰', secondaryText: '5 678 €'),
        ],
        selectedId: _selectedAccountId,
        onChanged: (id) => setState(() => _selectedAccountId = id),
        clearable: true,
        validator: (value) => value == null ? 'Champ requis' : null,
      ),
    ],
  ),
)
```

## Build & Test

```bash
# Tests
cd flutter && flutter test test/src/common_widgets/select_picker_test.dart

# Tous les tests
cd flutter && flutter test
```

## Architecture interne

```
SelectPicker (FormField<String?>)
├── builder → _SelectPickerTrigger (label + conteneur + chevron/clear)
│   ├── Tap → AppModal.show(title: placeholder, headerActions: search, child: list)
│   └── Clear → state.didChange(null) + onChanged(null)
└── _SelectPickerState (FormFieldState<String?>)
    ├── didUpdateWidget → auto-reset si item sélectionné absent
    ├── _openModal() → AppModal.show() + gestion recherche locale
    └── _onItemSelected(id) → state.didChange(id) + onChanged(id)
```
