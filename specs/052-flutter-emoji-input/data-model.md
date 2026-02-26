# Data Model: Flutter Emoji Input

**Feature**: 052-flutter-emoji-input | **Date**: 2026-02-23

## Entités

### EmojiInput (Widget)

Widget `FormField<String>` — pas de modèle de données persisté.

| Propriété | Type | Requis | Default | Description |
|-----------|------|--------|---------|-------------|
| `label` | `String` | oui | — | Label affiché au-dessus du trigger |
| `onChanged` | `ValueChanged<String>?` | non | `null` | Callback appelé à chaque sélection |
| `placeholder` | `String` | non | `'...'` | Texte affiché quand aucun emoji sélectionné |
| `initialValue` | `String?` | non | `null` | Emoji pré-rempli (hérité de FormField) |
| `validator` | `FormFieldValidator<String>?` | non | `null` | Fonction de validation (hérité de FormField) |
| `onSaved` | `FormFieldSetter<String>?` | non | `null` | Callback onSaved (hérité de FormField) |
| `autovalidateMode` | `AutovalidateMode?` | non | `null` | Mode de validation auto (hérité de FormField) |
| `enabled` | `bool` | non | `true` | Active/désactive le widget (hérité de FormField) |

### Valeur interne

| Champ | Type | Description |
|-------|------|-------------|
| `value` | `String?` | Caractère emoji sélectionné (ex: `'🏠'`). Géré par `FormFieldState<String>` |

## Relations

```
Form
└── EmojiInput (FormField<String>)
    ├── value: String? (emoji character)
    └── _EmojiPickerSheet (bottom sheet temporaire)
        └── EmojiPicker (package emoji_picker_flutter)
```

## Cycle de vie

```
[Aucune valeur] → tap trigger → [Picker ouvert] → tap emoji → [Valeur mise à jour]
                                                 → tap close/drag → [Retour sans changement]
```

## Pas de persistance

Ce widget est purement UI. La valeur emoji est passée au parent via `onChanged` / `onSaved` et persiste dans le modèle parent (Account, Category, etc.).
