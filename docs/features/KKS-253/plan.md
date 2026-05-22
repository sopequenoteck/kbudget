# Plan d'implémentation — KKS-253 : Profil / Mon compte Flutter (alignement DESIGN.md v5)

**Branche** : `feature/KKS-253-profile-settings-flutter` | **Date** : 2026-05-22 | **Spec** : [spec.md](./spec.md)
**Research** : [research.md](./research.md)

---

## Résumé de l'approche

Refonte de `profile_settings_screen.dart` (586 L) pour aligner l'écran Flutter sur Angular v5 :
introduction du pattern `_SettingsSection` / `_SettingsRow` avec icônes circulaires 36 px et containers
arrondis `surfaceContainerHighest`, remplacement du `_ReadOnlyField` nom par une édition inline
(`_NameRow` avec pencil trigger + `TextEditingController`), spinners individuels sur les exports
(`_ExportRow`), bandeau d'erreur global inline, et suppression de `_CurrencySelector` /
bouton AppBar save. Aucune modification des couches data/domain/application (NFR-001).

**Décisions techniques intégrées :** RES-001 (widgets privés dans le screen), RES-002
(`TextEditingController` + `setState`), RES-003 (`onSubmitted` + bouton cancel).

---

## Contexte technique

| Dimension | Valeur |
|-----------|--------|
| Langage | Dart ≥ 3.6 |
| Framework | Flutter ≥ 3.27 (stable) |
| State management | flutter_riverpod (`ConsumerStatefulWidget`) |
| Routing | go_router (`context.go`) |
| Design tokens | `AppThemeExtension` + `colorScheme` Material 3 |
| Tests | flutter_test (widget tests) |
| Dépendances nouvelles | **0** |
| Fichiers créés | **0** (widgets privés inline dans le screen) |
| Fichiers modifiés | **2** (screen + tests) |
| Fichier adapté (optionnel) | **1** (skeleton) |

---

## Constitution Check

### I. API-First / Local-First ✅

Feature purement UI (Trajectoire B — Flutter). Aucun nouvel endpoint requis.
`UserProfileRepository.updateName()` (PUT /users/me) existe déjà.
Mode connecté — `UserProfileRepository` est server-only par décision RES-013 (préexistant).

### II. Sécurité par défaut ✅

Aucune modification des couches data/domain/application. Les appels réseau existants passent
déjà par les routes JWT. Pas de nouveau endpoint, pas d'input non validé côté backend.
Côté Flutter : validation locale du nom (non vide, trim, max 100 chars — FR-003).

### III. Simplicité & YAGNI ✅

Widgets privés dans le screen (RES-001 — Option A). Pas d'abstraction prématurée.
`_SettingsSection` / `_SettingsRow` n'intègrent pas `SettingsItem` existant pour éviter
le couplage et les risques de régression (NFR-003 respecté). Suppression nette de
`_CurrencySelector`, `_hasChanged`, `_isSaving` et du bouton AppBar save.

### IV. Mobile-First UX ✅

Édition nom en 2 interactions : tap pencil → saisie → Enter/tap save. Bouton (+) non impacté.
Spinners individuels et bandeau d'erreur persistent sans navigation. Conforme à l'usage mobile.

### V. Testabilité ✅

NFR-006 : tests widget sur les 3 comportements clés (inline edit, export spinner, error banner).
Les 7 tests existants seront adaptés. Infrastructure de test inchangée (`ProviderScope` +
`_MockUserProfileNotifier`). Ajout d'un mock `UserProfileRepository` pour les tests export/name.

### VI. Observabilité ✅

Aucun logging backend modifié. `developer.log` n'est pas utilisé dans ce screen.
Les erreurs remontent via `_errorMessage` → bandeau inline (FR-015) — conformité VI.

### VII. Two Distribution Trajectories ✅

Trajectoire B (Flutter standalone). `UserProfileRepository` est server-only (mode sync).
Pas de migration Drift, pas de schéma local modifié. Contraintes stores non impactées.

**Résultat** : 7/7 gates passées. Aucune dérogation.

---

## Structure projet

### Documentation (cette feature)

```text
docs/features/KKS-253/
├── spec.md           ✅ (complété)
├── research.md       ✅ (complété)
├── plan.md           ← ce fichier
├── quickstart.md     ← généré
└── tasks.md          (prochaine étape — /devflow.tasks)
```

### Code source — fichiers impactés

```text
flutter/lib/src/features/user_profile/presentation/
├── screens/
│   └── profile_settings_screen.dart          (M) — refonte principale
└── widgets/
    ├── avatar_picker.dart                     (—) conservé sans modification (NFR-004)
    ├── change_password_sheet.dart             (—) conservé sans modification (NFR-003)
    ├── delete_account_sheet.dart              (—) conservé sans modification (NFR-003)
    └── profile_settings_skeleton.dart        (M*) adapter la structure skeleton sections

flutter/test/src/features/user_profile/
└── profile_settings_screen_test.dart         (M) adapter 7 tests + ajouter SC-001→SC-009
```

> `(M*)` = modification optionnelle, non bloquante pour SC-010 / SC-011.

---

## Architecture — Composants

### 1. `_ProfileSettingsScreenState` (refonte) — `ConsumerStatefulWidget`

**Couvre** : FR-001, FR-002, FR-003, FR-004, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016

**Variables d'état à ajouter** (RES-002) :
```dart
bool _isEditingName = false;
bool _isSavingName = false;
late TextEditingController _nameController;
bool _isExportingJson = false;
bool _isExportingCsv = false;
String? _errorMessage;
```

**Variables d'état à supprimer** (FR-011) :
```dart
// Supprimer :
Currency? _selectedCurrency;
bool _hasChanged;
bool _isSaving;
// + méthode _save()
```

**Lifecycle** :
- `initState()` : `_nameController = TextEditingController()`
- `dispose()` : `_nameController.dispose()`

**Méthodes à ajouter** :
```dart
Future<void> _saveName() async {
  final name = _nameController.text.trim();
  if (name.isEmpty || name.length > 100) return;
  setState(() { _isSavingName = true; _errorMessage = null; });
  try {
    final repo = await ref.read(userProfileRepositoryProvider.future);
    await repo.updateName(name);
    await ref.read(userProfileNotifierProvider.notifier).loadProfile();
    setState(() { _isEditingName = false; _isSavingName = false; });
  } catch (e) {
    setState(() { _isSavingName = false; _errorMessage = 'Impossible de mettre à jour le nom'; });
  }
}

Future<void> _exportJson() async { ... }  // refactorisé
Future<void> _exportCsv() async { ... }   // refactorisé
```

**`_runExport` refactorisé** : `setState(() => _isExportingJson = true)` en début,
`finally { setState(() => _isExportingJson = false); }` — suppression `ScaffoldMessenger`,
remplacement par `setState(() => _errorMessage = ...)` en cas d'erreur.

**AppBar** : `actions: []` — bouton save supprimé (FR-011).

**Scaffold body** : colonne `Column([if (_errorMessage != null) _ErrorBanner(_errorMessage!), Expanded(child: ...)])`

---

### 2. `_SettingsSection` (nouveau widget privé)

**Couvre** : FR-005, FR-006, FR-007, FR-009

```dart
class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  // ...
}
```

**Rendu** :
```
Text(label.toUpperCase(), style: textTheme.labelSmall + onSurfaceVariant + fontWeight.w600)
SizedBox(height: AppSpacing.space2)
ClipRRect(
  borderRadius: AppRadius.xl,
  child: Container(
    color: colorScheme.surfaceContainerHighest,
    child: Column(children séparés par Divider(height:0, thickness:0.5, color: outlineVariant)),
  ),
)
```

> **Note token** : `AppRadius.xl` doit exister dans `AppRadius`. Vérifier ou utiliser `BorderRadius.circular(16)` en fallback.

---

### 3. `_SettingsRow` (nouveau widget privé)

**Couvre** : FR-008

```dart
class _SettingsRow extends StatelessWidget {
  final PhosphorIconData? icon;
  final Color? iconBg;
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  // ...
}
```

**Rendu** :
- Icône circulaire 36 px : `Container(width:36, height:36, decoration: BoxDecoration(shape:circle, color:iconBg), child: PhosphorIcon(icon, size:18))`
- Trailing par défaut : chevron `PhosphorIconsRegular.caretRight` si `onTap != null` et `trailing == null`
- `InkWell(onTap: enabled ? onTap : null, borderRadius: AppRadius.md)`
- Padding : `EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3)`

---

### 4. `_NameRow` (cas spécial inline edit)

**Couvre** : FR-001, FR-002, FR-003

Logique gérée depuis le screen parent (pas de widget séparé) :
- Mode lecture → `_SettingsRow(title: user.name, trailing: IconButton(pencil))`
- Mode édition → remplace le `_SettingsRow` par un `Padding` avec `TextField(autofocus, onSubmitted: _saveName)` + `IconButton(check)` + `IconButton(x cancel)`

Implémentation dans `_buildNameRow(User user)` — méthode du screen :
```dart
Widget _buildNameRow(User user) {
  if (_isEditingName) {
    return Padding(..., child: Row([
      Expanded(child: TextField(controller: _nameController, autofocus: true,
                                onSubmitted: (_) => _saveName())),
      if (_isSavingName) CircularProgressIndicator()
      else ...[
        IconButton(PhosphorIcons.check, onPressed: _saveName),
        IconButton(PhosphorIcons.x, onPressed: () => setState(() => _isEditingName = false)),
      ],
    ]));
  }
  return _SettingsRow(
    title: user.name ?? 'Non renseigné',
    trailing: IconButton(PhosphorIconsRegular.pencil,
               onPressed: () => setState(() {
                 _nameController.text = user.name ?? '';
                 _isEditingName = true;
               })),
  );
}
```

---

### 5. `_ExportRow` (cas spécial avec spinner)

**Couvre** : FR-012, FR-013, FR-014

```dart
class _ExportRow extends StatelessWidget {
  final PhosphorIconData icon;
  final Color iconBg;
  final String title;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;
}
```

**Rendu** :
- Description dynamique : `isLoading ? 'Téléchargement en cours…' : null`
- Trailing : `isLoading ? SizedBox(20×20, child: CircularProgressIndicator(strokeWidth:2)) : PhosphorIcon(caretRight)`
- `enabled` : false si `isExportingJson || isExportingCsv` (désactivation croisée — FR-014)

---

### 6. Error Banner (inline)

**Couvre** : FR-015, FR-016

Widget inline dans le `Scaffold.body` :
```dart
if (_errorMessage != null)
  Container(
    width: double.infinity,
    color: colorScheme.errorContainer,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
    child: Row([
      PhosphorIcon(PhosphorIconsRegular.warning, color: colorScheme.error, size:16),
      SizedBox(width: AppSpacing.space2),
      Expanded(child: Text(_errorMessage!, style: textTheme.bodySmall + colorScheme.onErrorContainer)),
    ]),
  )
```

Effacement : `setState(() => _errorMessage = null)` en début de chaque action (FR-016).

---

### 7. `_EmailRow` (row email avec badge)

Row pour l'email — lecture seule avec badge "Géré par l'administrateur" comme description :
```dart
_SettingsRow(
  title: user.email,
  description: 'Géré par l\'administrateur',
  // pas d'icône, pas de trailing
)
```

---

### 8. Structure des 4 sections

```dart
ListView(
  padding: const EdgeInsets.all(AppSpacing.space4),
  children: [
    // Section Identité
    Center(child: AvatarPicker(...)),   // avatar en dehors du container section
    const SizedBox(height: AppSpacing.space4),
    _SettingsSection(
      label: 'Identité',
      children: [
        _buildNameRow(user),
        _EmailRow(user),
      ],
    ),
    const SizedBox(height: AppSpacing.space4),

    // Section Sécurité
    _SettingsSection(
      label: 'Sécurité',
      children: [
        _SettingsRow(icon: lock, iconBg: ext.primarySubtle, title: 'Changer le mot de passe',
                     onTap: _openChangePassword),
      ],
    ),
    const SizedBox(height: AppSpacing.space4),

    // Section Données
    _SettingsSection(
      label: 'Données',
      children: [
        _ExportRow(icon: database, iconBg: ext.secondaryColor.withAlpha(30),
                   title: 'Exporter mes données (JSON)',
                   isLoading: _isExportingJson,
                   enabled: !_isExportingJson && !_isExportingCsv,
                   onTap: _exportJson),
        _ExportRow(icon: fileCsv, iconBg: ext.secondaryColor.withAlpha(30),
                   title: 'Exporter mes transactions (CSV)',
                   isLoading: _isExportingCsv,
                   enabled: !_isExportingJson && !_isExportingCsv,
                   onTap: _exportCsv),
      ],
    ),
    const SizedBox(height: AppSpacing.space4),

    // Zone de danger
    _SettingsSection(
      label: 'Zone de danger',
      children: [
        _SettingsRow(title: 'Déconnexion', onTap: _logout),
        _SettingsRow(title: 'Supprimer mon compte',
                     titleColor: colorScheme.error, onTap: _openDeleteAccount),
      ],
    ),
    const SizedBox(height: AppSpacing.space8),
  ],
)
```

> L'avatar reste centré au-dessus du container section Identité (cohérent avec la structure Angular).

---

### 9. Tests — adaptation + ajouts

**Couvre** : NFR-006, SC-001 → SC-011

**Tests à adapter** (7 existants) :
- `should_showAllSections_when_userLoaded` : ajouter override `userProfileRepositoryProvider`
- `should_showAdminLabel_when_emailDisplayed` : texte toujours présent via `_EmailRow.description`
- `should_showExportJsonRow_when_userLoaded` : le texte change — adapter le finder
- `should_showExportCsvRow_when_userLoaded` : idem
- `should_showChangePasswordRow_when_userLoaded` : conserver
- `should_showLogoutRow_when_userLoaded` : conserver
- `should_showDataSection_when_userLoaded` : conserver

**Tests à ajouter** :
| Test | SC | Comportement |
|------|----|--------------|
| `should_showInlineInput_when_pencilTapped` | SC-001 | Tap pencil → TextField visible |
| `should_updateName_when_saveTapped` | SC-002 | Tap save → `updateName` appelé, input fermé |
| `should_cancelEdit_when_cancelTapped` | SC-003 | Tap cancel → input fermé, nom inchangé |
| `should_hideCurrencySelector_when_rendered` | SC-006 | `_CurrencySelector` absent |
| `should_showSpinner_when_exportJsonStarted` | SC-007 | Tap Export JSON → spinner visible |
| `should_disableCsvRow_when_exportingJson` | SC-008 | Export JSON → row CSV désactivée |
| `should_showErrorBanner_when_actionFails` | SC-009 | Erreur → bandeau rouge visible |

**Infrastructure tests** :
```dart
class _MockUserProfileRepository implements UserProfileRepository {
  Future<void> updateName(String name) async {}
  Future<File> exportJson() async => throw Exception('error');
  // ...
}
```

Override dans `ProviderScope` :
```dart
userProfileRepositoryProvider.overrideWith(
  (ref) => Future.value(_MockUserProfileRepository()),
)
```

---

## Risques

| # | Risque | Probabilité | Impact | Mitigation |
|---|--------|-------------|--------|-----------|
| R-001 | Les 7 tests existants cassent à cause de la suppression `_CurrencySelector` et de la nouvelle structure sections | Certaine | Modéré | Adapter les tests dans la même tâche que le screen |
| R-002 | `AppRadius.xl` n'existe pas → `BorderRadius.circular(16)` hardcodé | Faible | Mineur | Vérifier `AppRadius` avant l'implémentation, utiliser la constante si elle existe |
| R-003 | `_runExport` refactorisé sans bloc `finally` → état bloqué si exception | Faible | Modéré | Systématiquement wrapper en `try/catch/finally` avec reset des flags |
| R-004 | `userProfileRepositoryProvider` est `FutureProvider` → `await ref.read(provider.future)` peut throw si backend down | Faible | Faible | Déjà géré via `catch` dans `_saveName` et export — `_errorMessage` capte |

---

## Hors scope

| Élément | Raison |
|---------|--------|
| US-005 — Câblage avatar (`currentAvatarUrl`) | CL-001 — ticket dédié requis pour `GET /users/me/avatar` |
| Modification `ChangePasswordSheet` | NFR-003 |
| Modification `DeleteAccountSheet` | NFR-003 |
| Modification `AvatarPicker` | NFR-004 |
| Modification couches data/domain/application | NFR-001 |
| Gestion Escape sur clavier physique | RES-003 — mobile-first, bouton cancel suffisant |
| Migration devise dans l'écran Profil | CL-004 — accès via `CurrencyPillSelector` Dashboard |

---

## Complexity Tracking

Aucune violation de constitution. Aucune complexité ajoutée hors du scope fonctionnel.

---

## Artefacts complémentaires

| Artefact | Statut |
|----------|--------|
| [spec.md](./spec.md) | ✅ Complété |
| [research.md](./research.md) | ✅ Complété |
| [quickstart.md](./quickstart.md) | ✅ Généré |
| data-model.md | ✗ Non applicable — Key Entities existantes, aucune migration Drift |
| tasks.md | ⏳ Prochaine étape (`/devflow.tasks`) |
