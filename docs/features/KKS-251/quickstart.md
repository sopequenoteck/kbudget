# Quickstart — KKS-251 : Récurrences liste Flutter

**Date** : 2026-05-21 | **Branch** : `develop`

---

## Fichiers clés

```
flutter/lib/src/features/recurring/presentation/
├── recurring_list_screen.dart          # Écran principal — refonte complète
└── widgets/
    ├── recurring_list_item.dart        # Item liste — interface simplifiée
    └── recurring_list_skeleton.dart    # Skeleton — 5 items, icône cercle

flutter/lib/src/features/recurring/application/
└── recurring_list_notifier.dart        # Notifier — ajout validateAll()

flutter/lib/src/utils/
└── relative_date_formatter.dart        # Ajout formatCompact()

flutter/lib/src/localization/
└── app_fr.arb                          # Source l10n — modifier ici, puis gen-l10n
```

---

## Ordre d'implémentation

### Étape 1 — Utilitaires (sans dépendances)

1. **`relative_date_formatter.dart`** — ajouter `formatCompact()` (~15L)
2. **`app_fr.arb`** — 3 mises à jour + 4 nouvelles clés
3. **`flutter gen-l10n`** — régénérer les fichiers l10n

```bash
cd flutter && flutter gen-l10n
```

### Étape 2 — Notifier

4. **`recurring_list_notifier.dart`** — ajouter `validateAll(List<String> ids)`

### Étape 3 — Widgets

5. **`recurring_list_skeleton.dart`** — 6→5, icône cercle, suppression badge droit
6. **`recurring_list_item.dart`** — interface `{onTap}`, icône cercle, sous-titre, montant coloré

### Étape 4 — Screen

7. **`recurring_list_screen.dart`** — refonte complète (CustomScrollView, groupes, summary, action sheet)

### Étape 5 — Tests

8. **`recurring_list_notifier_test.dart`** — ajouter tests `validateAll`
9. **`recurring_list_screen_test.dart`** — adapter + nouveaux tests

---

## Commandes utiles

```bash
# Tests
cd flutter && flutter test test/src/features/recurring/

# Test ciblé
cd flutter && flutter test test/src/features/recurring/application/recurring_list_notifier_test.dart
cd flutter && flutter test test/src/features/recurring/presentation/recurring_list_screen_test.dart

# Analyse statique
cd flutter && flutter analyze lib/src/features/recurring/ lib/src/utils/relative_date_formatter.dart

# Régénération l10n (après modification app_fr.arb)
cd flutter && flutter gen-l10n
```

---

## Points d'attention

### L10n — ne pas modifier les fichiers générés

`app_localizations.dart` et `app_localizations_fr.dart` sont **auto-générés**. Toujours modifier uniquement `app_fr.arb`, puis lancer `flutter gen-l10n`.

### `primaryCurrency` peut être null

Si `dashboardState.currencies` est vide (premier lancement, données non chargées), `primaryCurrency = null`. La `_MonthlySummaryCard` gère ce cas : `displayCurrency = primaryCurrency ?? Currency.eur`.

### `validateAll` et `mutatingIds`

Le sentinel `'__all__'` est retiré dans le `finally` de `validateAll()`. Si le test vérifie l'état intermédiaire, ajouter un `Completer` pour capturer l'état avant la fin de l'opération.

### `_ActionButton` dans le bottom sheet

Le `_ActionButton` de ce screen est distinct de celui dans `account_list_tile.dart` — deux widgets privés avec des APIs différentes dans des fichiers séparés, pas de conflit.

### Tests screen — providers additionnels

`RecurringListScreen` en v2 nécessite 3 overrides dans `buildApp()` des tests :
```dart
ProviderScope(
  overrides: [
    recurringTransactionRepositoryProvider.overrideWith((_) async => mockRepo),
    exchangeRateListProvider.overrideWith((_) => ListState()),          // état vide
    dashboardNotifierProvider.overrideWith((_) => DashboardState()),   // état vide
  ],
  child: MaterialApp(...),
)
```
