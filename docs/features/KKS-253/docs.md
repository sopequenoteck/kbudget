# Documentation — KKS-253 : Profil / Mon compte Flutter

> Date : 2026-05-22 | Issue : KKS-253 | Priorité : High (P2) | Parent : KKS-242

---

## Résumé

L'écran **Mon compte** (`ProfileSettingsScreen`) Flutter a été entièrement refactorisé pour s'aligner sur la source de vérité Angular v5. La structure visuelle adopte désormais le pattern `_SettingsSection` / `_SettingsRow` avec containers arrondis, icônes circulaires 36 px et séparateurs — conforme à DESIGN.md v5. Trois fonctionnalités clés ont été ajoutées ou améliorées : l'édition inline du nom (auparavant en lecture seule), les spinners individuels sur les exports avec désactivation croisée, et un bandeau d'erreur global persistant. Le sélecteur de devise (`_CurrencySelector`) a été retiré de cet écran — la devise reste modifiable via le `CurrencyPillSelector` du Dashboard.

---

## Guide utilisateur

### Édition du nom (nouveau)

1. Ouvrir l'écran **Mon compte** (icône profil → profil)
2. Dans la section **Identité**, tapper l'icône crayon ✏️ à droite du nom affiché
3. Un champ de saisie s'ouvre avec le nom actuel pré-rempli
4. Modifier le nom (max 100 caractères, non vide)
5. Tapper le bouton ✓ ou appuyer sur **Entrée** pour sauvegarder — ou ✕ pour annuler sans changement
6. En cas d'erreur réseau, un bandeau rouge apparaît sous la barre de titre avec le message d'erreur

### Sections de l'écran

| Section | Contenu |
|---------|---------|
| **Identité** | Avatar (initiales en fallback), nom (éditable), email (lecture seule — géré par l'admin) |
| **Sécurité** | Changer le mot de passe → ouvre `ChangePasswordSheet` |
| **Données** | Exporter mes données (JSON) · Exporter mes transactions (CSV) |
| **Zone de danger** | Déconnexion · Supprimer mon compte → ouvre `DeleteAccountSheet` |

### Export de données

- Tapper **Exporter mes données (JSON)** ou **Exporter mes transactions (CSV)**
- Pendant le téléchargement : un spinner remplace le chevron, le sous-titre affiche « Téléchargement en cours… », les deux boutons d'export sont désactivés (protection contre les doubles clics)
- En cas d'erreur : le bandeau rouge indique « Erreur lors de l'export JSON/CSV »

### Bandeau d'erreur global

- Apparaît sous la barre de titre (sans se superposer au contenu)
- Reste visible jusqu'à la prochaine action (toute nouvelle action efface le bandeau précédent)
- Couvre : erreur de sauvegarde du nom, erreur d'export JSON/CSV

### Ce qui a été retiré

- **Sélecteur de devise** : retiré de cet écran — toujours accessible via la pilule de devise sur le Dashboard
- **Bouton « Enregistrer » dans la barre de titre** : supprimé (obsolète avec le retrait du sélecteur de devise)

---

## Changements techniques

### Fichiers modifiés

| Fichier | Type | Nature des changements |
|---------|------|------------------------|
| `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` | M | Refonte complète — voir détail ci-dessous |
| `flutter/lib/src/features/user_profile/presentation/widgets/profile_settings_skeleton.dart` | M | Skeleton adapté à la structure 4 sections |
| `flutter/test/src/features/user_profile/profile_settings_screen_test.dart` | M | 7 tests adaptés + 7 nouveaux tests |

### Fichiers conservés sans modification (contraintes NFR)

| Fichier | Raison |
|---------|--------|
| `avatar_picker.dart` | NFR-004 — interface publique inchangée |
| `change_password_sheet.dart` | NFR-003 |
| `delete_account_sheet.dart` | NFR-003 |
| `user_profile_notifier.dart` | NFR-001 — couche application inchangée |
| `user_profile_repository.dart` | NFR-001 — couche domain inchangée |
| `user_profile_repository_remote.dart` | NFR-001 — couche data inchangée |

### Détail des changements — `profile_settings_screen.dart`

**Supprimé :**
- Classe `_CurrencySelector` (entière — ~70 lignes)
- Classe `_ProfileContent` (délégation déplacée dans le state)
- Classe `_SectionHeader`, `_ReadOnlyField`, `_ActionRow` (remplacés par le nouveau pattern)
- Variables `_selectedCurrency`, `_hasChanged`, `_isSaving`
- Méthode `_save()` (mise à jour de la devise)
- `actions:` dans l'`AppBar`
- Import `enums.dart` (Currency)

**Ajouté :**
- Variables d'état : `_isEditingName`, `_isSavingName`, `_nameController`, `_isExportingJson`, `_isExportingCsv`, `_errorMessage`
- `initState()` / `dispose()` pour le `TextEditingController`
- Widget privé `_SettingsSection` — container arrondi avec label uppercase et dividers
- Widget privé `_SettingsRow` — row générique avec icône circulaire 36 px optionnelle, description, trailing
- Widget privé `_ExportRow` — spécialisation avec `isLoading` + sous-titre dynamique
- Méthode `_buildNameRow(User user)` — bascule lecture/édition inline
- Méthode `_buildErrorBanner()` — bandeau rouge `errorContainer`
- Méthode `_saveName()` — appel `UserProfileRepository.updateName()` + refresh `userProfileNotifierProvider`
- `_exportJson()` et `_exportCsv()` refactorisés avec `try/catch/finally` et flags d'état

**Import ajouté :** `package:k_budget/src/theme/app_theme_extension.dart`

### Architecture des widgets privés

```
ProfileSettingsScreen (ConsumerStatefulWidget)
├── ProfileSettingsSkeleton         (loading)
├── _ErrorView                      (error)
└── Column                          (data)
    ├── _buildErrorBanner()         (conditionnel)
    └── ListView
        ├── AvatarPicker            (widget existant)
        ├── _SettingsSection "Identité"
        │   ├── _buildNameRow()     (lecture | édition inline)
        │   └── _SettingsRow        (email, read-only)
        ├── _SettingsSection "Sécurité"
        │   └── _SettingsRow        (→ ChangePasswordSheet)
        ├── _SettingsSection "Données"
        │   ├── _ExportRow          (JSON, isLoading + enabled)
        │   └── _ExportRow          (CSV, isLoading + enabled)
        └── _SettingsSection "Zone de danger"
            ├── _SettingsRow        (Déconnexion)
            └── _SettingsRow        (Supprimer mon compte, rouge)
```

### Tokens design utilisés

| Token | Source | Usage |
|-------|--------|-------|
| `colorScheme.surfaceContainerHighest` | Material 3 | Fond des containers section |
| `colorScheme.outlineVariant` | Material 3 | Séparateurs entre rows |
| `colorScheme.onSurfaceVariant` | Material 3 | Label section + texte description |
| `colorScheme.error` / `errorContainer` / `onErrorContainer` | Material 3 | Bandeau d'erreur + titre Supprimer |
| `AppThemeExtension.primarySubtle` | AppThemeExtension | Fond icône circulaire |
| `AppRadius.xl` (16.0) | AppRadius | `border-radius` des containers section |
| `AppRadius.md` | AppRadius | `border-radius` InkWell des rows |

### Dépendances nouvelles

**Aucune.** L'implémentation s'appuie exclusivement sur les packages existants : `flutter_riverpod`, `phosphor_flutter`, `go_router`.

---

## Configuration

Aucune configuration requise. L'écran s'appuie sur les providers existants :

| Provider | Rôle |
|----------|------|
| `userProfileNotifierProvider` | Chargement et refresh du profil (`loadProfile()`) |
| `userProfileRepositoryProvider` | Appels `updateName()`, `exportJson()`, `exportCsv()` |
| `authNotifierProvider` | Déconnexion (`logout()`) |

---

## Tests et validation

### Couverture automatique

```bash
# Analyse statique
cd flutter && flutter analyze lib/src/features/user_profile/
# → 0 issue (2 infos sur avatar_picker.dart — fichier non modifié)

# Tests widget
cd flutter && flutter test test/src/features/user_profile/profile_settings_screen_test.dart
# → 14/14 PASS
```

### Tests présents

| Test | SC | Comportement validé |
|------|----|---------------------|
| `should_showAllSections_when_userLoaded` | — | 4 sections visibles |
| `should_showLogoutRow_when_userLoaded` | — | Row Déconnexion présente |
| `should_showChangePasswordRow_when_userLoaded` | — | Row Changer le mot de passe présente |
| `should_showAdminLabel_when_emailDisplayed` | — | Sous-titre « Géré par l'administrateur » |
| `should_showDataSection_when_userLoaded` | — | Section Données visible |
| `should_showExportJsonRow_when_userLoaded` | — | Row export JSON présente |
| `should_showExportCsvRow_when_userLoaded` | — | Row export CSV présente |
| `should_hideCurrencySelector_when_rendered` | SC-006 | Pas de sélecteur de devise |
| `should_showInlineTextField_when_pencilTapped` | SC-001 | Tap pencil → TextField visible |
| `should_closeEditMode_when_cancelTapped` | SC-003 | Tap ✕ → TextField fermé |
| `should_callUpdateName_when_saveTapped` | SC-002 | Tap ✓ → `updateName()` appelé |
| `should_showSpinner_when_exportJsonStarted` | SC-007 | Export JSON → spinner visible |
| `should_disableCsvRow_when_exportingJson` | SC-008 | Export JSON → row CSV désactivée |
| `should_showErrorBanner_when_nameUpdateFails` | SC-009 | Erreur updateName → bandeau rouge |

### Validation manuelle requise

| SC | Vérification |
|----|-------------|
| SC-004 | 4 sections avec containers arrondis et labels uppercase visibles |
| SC-005 | Icônes circulaires colorées dans les sections Sécurité et Données |

---

## Points hors scope (tickets futurs)

| Élément | Raison | Ticket |
|---------|--------|--------|
| Affichage de l'avatar actuel dans `AvatarPicker` | Endpoint `GET /users/me/avatar` + `avatarUrlProvider` requis | Ticket dédié (CL-001) |
| Modification de devise depuis l'écran Profil | Retiré volontairement (CL-004) — accès via Dashboard | — |

---

## Warnings de polish (à corriger)

Identifiés lors de la review-impl (itération 3) — non bloquants pour la livraison :

| # | Fichier | Correction |
|---|---------|-----------|
| W-003 | `profile_settings_screen.dart:196` | `Colors.green` → `colorScheme.primary` (NFR-002) |
| W-004 | `profile_settings_screen.dart:327` | `_openDeleteAccount` : ajouter `setState(() => _errorMessage = null)` (FR-016) |
| W-001 | `profile_settings_screen.dart:117,124` | `iconBg` exports : `primarySubtle` → `ext(context).secondaryColor.withAlpha(30)` (plan) |
| W-002 | `profile_settings_screen_test.dart:336` | SC-008 : vérifier `onTap == null` sur la row CSV désactivée |
