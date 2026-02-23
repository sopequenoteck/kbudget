# Quickstart: Flutter Emoji Input

**Feature**: 052-flutter-emoji-input | **Date**: 2026-02-23

## Prérequis

- Flutter >= 3.27, Dart >= 3.6
- Dépendance `emoji_picker_flutter: ^4.4.0` dans `pubspec.yaml` (déjà ajoutée)

## Utilisation

### Basique (dans un Form)

```dart
EmojiInput(
  label: 'Icône',
  onChanged: (emoji) => setState(() => _icon = emoji),
)
```

### Avec validation

```dart
EmojiInput(
  label: 'Icône',
  validator: (value) =>
      value == null || value.isEmpty ? 'Une icône est requise' : null,
  onChanged: (emoji) => setState(() => _icon = emoji),
)
```

### Avec valeur initiale (mode édition)

```dart
EmojiInput(
  label: 'Icône',
  initialValue: category.icone,  // ex: '🏠'
  onChanged: (emoji) => setState(() => _icon = emoji),
)
```

### État désactivé

```dart
EmojiInput(
  label: 'Icône',
  enabled: false,
  initialValue: '🔒',
)
```

## Vérification

```bash
cd flutter && flutter analyze
cd flutter && flutter test test/src/common_widgets/emoji_input_test.dart
```

## Fichiers

| Fichier | Rôle |
|---------|------|
| `flutter/lib/src/common_widgets/emoji_input.dart` | Widget source |
| `flutter/test/src/common_widgets/emoji_input_test.dart` | Tests |
