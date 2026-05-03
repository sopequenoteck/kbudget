# Quickstart: Flutter MonthSelector Widget

## Prérequis

- Flutter >= 3.27 installé
- Repo cloné, branche `037-flutter-monthselector-widget`

## Lancer les tests

```bash
cd flutter && flutter test test/common_widgets/month_selector_test.dart
```

## Utilisation du widget

```dart
import 'package:k_budget/src/common_widgets/month_selector.dart';

// Avec valeurs par défaut (mois courant)
MonthSelector(
  onChanged: (month, year) {
    print('Sélection: $month/$year');
  },
)

// Avec mois initial
MonthSelector(
  initialMonth: 6,
  initialYear: 2025,
  onChanged: (month, year) {
    // Recharger les données pour ce mois
  },
)
```

## Fichiers créés

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/common_widgets/month_selector.dart` | Widget MonthSelector |
| `flutter/test/common_widgets/month_selector_test.dart` | Tests widget |

## Vérification rapide

1. `cd flutter && flutter test` — tous les tests passent
2. `cd flutter && flutter analyze` — aucun warning
