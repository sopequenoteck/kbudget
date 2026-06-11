# Quickstart — KKS-253 : Profil / Mon compte Flutter

> Guide de démarrage rapide pour implémenter ou tester cette feature.

---

## Contexte en 30 secondes

Refonte **UI uniquement** de `profile_settings_screen.dart`. Aucune modification de la couche
data/domain. Le screen passe de widgets flat à un pattern `_SettingsSection` / `_SettingsRow`
avec icônes circulaires, plus une édition inline du nom et un bandeau d'erreur global.

---

## Fichiers clés

| Rôle | Chemin |
|------|--------|
| Screen à modifier | `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` |
| Tests à adapter | `flutter/test/src/features/user_profile/profile_settings_screen_test.dart` |
| Tokens design | `flutter/lib/src/theme/app_theme_extension.dart` |
| Repository interface | `flutter/lib/src/features/user_profile/domain/repositories/user_profile_repository.dart` |
| Notifier profil | `flutter/lib/src/features/user_profile/application/user_profile_notifier.dart` |
| Widgets conservés | `avatar_picker.dart`, `change_password_sheet.dart`, `delete_account_sheet.dart` |

---

## Séquence d'implémentation recommandée

```
1. Créer _SettingsSection + _SettingsRow (widgets privés dans le screen)
2. Restructurer les 4 sections (Identité, Sécurité, Données, Zone de danger)
3. Supprimer _CurrencySelector, _hasChanged, _isSaving, bouton AppBar
4. Ajouter _buildNameRow() avec inline edit (_isEditingName, _nameController, _saveName)
5. Ajouter _ExportRow avec spinners individuels (_isExportingJson, _isExportingCsv)
6. Ajouter error banner global (_errorMessage)
7. Adapter les 7 tests existants + ajouter SC-001 → SC-009
```

---

## Commandes

```bash
# Lancer les tests de la feature
cd flutter && flutter test test/src/features/user_profile/profile_settings_screen_test.dart

# Analyse statique
cd flutter && flutter analyze lib/src/features/user_profile/

# Tous les tests (régression)
cd flutter && flutter test test/src/features/user_profile/
```

---

## Points d'attention

- **Tokens** : utiliser `AppThemeExtension` (via `Theme.of(context).extension<AppThemeExtension>()`)
  pour `iconCircleBg`, `primarySubtle`, `incomeColor`, `expenseColor` — et `colorScheme` pour
  `surfaceContainerHighest`, `onSurfaceVariant`, `outlineVariant`.
- **`updateName`** : s'appelle via `await ref.read(userProfileRepositoryProvider.future)` puis
  `.updateName(name.trim())` — puis `ref.read(userProfileNotifierProvider.notifier).loadProfile()`
  pour rafraîchir l'UI.
- **Exports** : reset des flags dans `finally` pour éviter un état bloquant en cas d'exception.
- **Avatar** : `currentAvatarUrl: null` conservé — ne pas modifier l'interface `AvatarPicker`.
- **`_CurrencySelector`** : supprimer entièrement (classe + import `Currency` si inutilisée ailleurs).

---

## Vérification finale (SC-010 / SC-011)

```bash
cd flutter && flutter analyze lib/src/features/user_profile/
# → No issues found

cd flutter && flutter test test/src/features/user_profile/
# → All tests PASS
```
