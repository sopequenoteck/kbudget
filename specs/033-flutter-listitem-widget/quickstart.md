# Quickstart: Widget ListItem (Flutter)

**Feature**: 033-flutter-listitem-widget | **Date**: 2026-02-21

## Prérequis

- Flutter SDK >= 3.27 (stable)
- Projet `flutter/` compilable (`flutter build` sans erreur)

## Setup

### 1. Ajouter la dépendance shimmer

```bash
cd flutter && flutter pub add shimmer
```

Vérifie que `pubspec.yaml` contient `shimmer: ^3.0.0`.

### 2. Créer le fichier widget

```bash
touch flutter/lib/src/common_widgets/list_item.dart
```

### 3. Créer le fichier de test

```bash
mkdir -p flutter/test/src/common_widgets
touch flutter/test/src/common_widgets/list_item_test.dart
```

## Vérification rapide

```bash
cd flutter && flutter test test/src/common_widgets/list_item_test.dart
```

## Fichiers à créer/modifier

| Action | Fichier | Description |
|--------|---------|-------------|
| Modifier | `flutter/pubspec.yaml` | Ajouter `shimmer: ^3.0.0` |
| Créer | `flutter/lib/src/common_widgets/list_item.dart` | Widget ListItem + ListItem.skeleton() |
| Créer | `flutter/test/src/common_widgets/list_item_test.dart` | Tests unitaires |

## Dépendances existantes utilisées (pas de modification)

- `flutter/lib/src/constants/app_colors.dart` — `AppColors.amber100`
- `flutter/lib/src/constants/app_spacing.dart` — `AppSpacing.space1/3/4/10`
- `flutter/lib/src/constants/app_typography.dart` — `AppTypography.sizeSm/Md/Lg/medium/semiBold`
- `flutter/lib/src/constants/app_radius.dart` — `AppRadius.round`
- `flutter/lib/src/theme/app_theme_extension.dart` — couleurs sémantiques (pour les écrans consommateurs)
- `flutter/lib/src/utils/amount_formatter.dart` — formatage montants (usage dans les écrans)
- `flutter/lib/src/utils/relative_date_formatter.dart` — formatage dates (usage dans les écrans)
