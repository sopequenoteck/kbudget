# Research — KKS-253 : Profil / Mon compte Flutter (alignement DESIGN.md v5)

> Date : 2026-05-22
> Issue : KKS-253
> Spec : [spec.md](./spec.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Architecture UI | Pattern `_SettingsSection` / `_SettingsRow` : widgets privés dans le screen ou extension de `SettingsItem` commun ? | Haute |
| RES-002 | State management | Inline name edit : `TextEditingController` + `setState` ou gestion via Riverpod ? | Moyenne |
| RES-003 | UX/Interactions | Gestion de l'Enter/Escape sur l'input inline name edit en Flutter | Basse |

---

## Décisions techniques

### RES-001 — Widgets `_SettingsSection` / `_SettingsRow` : privés vs `SettingsItem` commun

- **Contexte** : L'écran nécessite plusieurs variantes de "row" : row avec icône + chevron (sécurité, données), row avec inline edit (nom), row avec badge texte (email), row avec spinner trailing (exports), row danger sans icône (delete account). Le `SettingsItem` existant (`common_widgets/settings/settings_item.dart`) couvre uniquement le cas icon+title+description+chevron|placeholder.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Widgets privés dans le screen | Zero couplage ; variantes libres ; conforme au pattern des autres screens KKS-240/252 ; aucun risque de régression sur les screens existants | Duplication partielle vs `SettingsItem` | ★★★★★ |
| B — Étendre `SettingsItem` avec nouveaux params (`isLoading`, `trailingBadge`, `isDanger`, `inlineEdit`) | Centralisation des composants settings | API complexe, trop de paramètres optionnels ; risque de régression sur `FeatureSettingsScreen` ; contrainte NFR-004 (ne pas modifier les widgets existants) | ★★☆☆☆ |
| C — Créer un `ProfileSettingsRow` dans `common_widgets` | Testabilité indépendante | Prématuré — pas d'autre écran settings avec les mêmes besoins actuellement | ★★★☆☆ |

- **Décision** : **Option A — Widgets privés dans le screen**
- **Rationale** : Le screen `profile_settings_screen.dart` est le seul à nécessiter ces variantes complexes (inline edit, spinner, badge, danger). Les variantes sont trop spécifiques pour justifier un composant commun. `SettingsItem` n'est pas modifié (NFR-004 respecté). Pattern cohérent avec les autres features KKS-240/250/252.
- **Alternatives rejetées** :
  - B : over-engineering + risque de régression sur `FeatureSettingsScreen`
  - C : prématuré — extraction justifiée seulement si ≥ 2 features partagent le même besoin
- **Impact sur le plan** :
  - Créer `_SettingsSection({required String label, required List<Widget> children})` — container `surfaceContainerHighest` + `border-radius-xl` + label uppercase
  - Créer `_SettingsRow({icon?, iconBg?, title, description?, trailing?})` — layout horizontal standard avec Divider entre rows
  - Créer `_NameRow` — cas spécial avec inline edit state
  - Créer `_ExportRow` — cas spécial avec `_isLoading` + sous-titre dynamique

---

### RES-002 — Inline name edit : `TextEditingController` + `setState`

- **Contexte** : L'édition inline du nom nécessite un état local (mode édition actif/inactif, valeur saisie, état de sauvegarde) et un focus automatique sur l'input. La question est de savoir si cet état doit vivre dans Riverpod ou en local `setState`.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `TextEditingController` + `setState` dans `ConsumerStatefulWidget` | Pattern établi dans `ChangePasswordSheet` et `DeleteAccountSheet` ; simple ; pas de provider supplémentaire | None dans ce contexte | ★★★★★ |
| B — Riverpod `StateNotifier` dédié | Testabilité indépendante | Surengineering pour de l'état UI local éphémère ; aucun autre consumer de cet état | ★★☆☆☆ |

- **Décision** : **Option A — `TextEditingController` + `setState`**
- **Rationale** : L'état d'édition est strictement local à l'écran, éphémère, et ne nécessite pas d'être partagé. `TextEditingController` gère nativement la valeur du champ + dispose. Cohérent avec tous les sheets existants du projet.
- **Variables d'état à ajouter** :
  - `bool _isEditingName = false`
  - `bool _isSavingName = false`
  - `TextEditingController _nameController` (initialisé dans `initState`, disposé dans `dispose`)
  - `bool _isExportingJson = false`
  - `bool _isExportingCsv = false`
  - `String? _errorMessage`
- **Impact sur le plan** : `initState` initialise `_nameController` ; `dispose` le libère + annule timers éventuels.

---

### RES-003 — Enter/Escape sur l'input inline

- **Contexte** : Angular gère Enter (`keydown.enter`) et Escape (`keydown.escape`) sur l'input nom. En Flutter mobile, Escape est absent (pas de clavier physique). Enter est géré via `TextField.onSubmitted`.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `onSubmitted` pour Enter + bouton cancel explicite | Simple, natif Flutter, mobile-first | Escape non géré (acceptable mobile) | ★★★★★ |
| B — `RawKeyboardListener` pour Escape en plus | Prise en charge clavier physique (tablette, desktop) | Complexité inutile pour l'usage mobile cible | ★★★☆☆ |

- **Décision** : **Option A — `onSubmitted` + bouton cancel**
- **Rationale** : L'app cible est mobile (constitution Principe IV). Escape est pertinent seulement avec un clavier physique. Les boutons save/cancel sont toujours visibles → cas d'usage couvert. `autofocus: true` sur le `TextField` pour que le clavier s'ouvre automatiquement.
- **Impact sur le plan** : `TextField(autofocus: true, onSubmitted: (_) => _saveName(), ...)` + bouton cancel `IconButton`.

---

## Analyse du codebase

### Patterns existants identifiés

- **`SettingsItem`** (`features/settings/presentation/widgets/`) : icon-circle 40px avec `iconColor.withValues(alpha: 0.15)` comme fond, chevron `caretRight`, `InkWell` avec `borderRadius: AppRadius.md`. → Référence de style pour les rows standard.
- **`FeatureSettingsScreen`** : utilise `ListView` + `colorScheme.surfaceContainerHighest` pour containers, `textTheme.titleSmall` avec `colorScheme.primary` + `fontWeight.w600` pour les section headers. → Convention tokens settings à reproduire.
- **`ChangePasswordSheet` / `DeleteAccountSheet`** : `TextEditingController` + `setState` + `ConsumerStatefulWidget`. → Pattern validé pour état local + Riverpod.
- **`AvatarPicker`** : `onUploadSuccess` callback → appel `loadProfile()` dans le screen parent. → Interface inchangée (NFR-004).
- **`_runExport` dans le screen actuel** : `try/catch` async avec `ScaffoldMessenger.showSnackBar` → à remplacer par `setState(() => _errorMessage = ...)` + banner inline.
- **`userProfileRepositoryProvider`** : `FutureProvider<UserProfileRepository>` — accès via `ref.read(userProfileRepositoryProvider.future)`. → Utilisé pour `updateName`, `exportJson`, `exportCsv`.
- **`userProfileNotifierProvider`** : `AsyncNotifierProvider<UserProfileNotifier, User>` — expose `loadProfile()`. → Appel après `updateName` pour rafraîchir l'état.

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `phosphor_flutter` | Existante | Icônes (lock, database, fileCsv, signOut, trash, pencil, check, x) | Aucun |
| `flutter_riverpod` | Existante | `ConsumerStatefulWidget`, `ref.read` providers | Aucun |
| `go_router` | Existante | `context.go(RouteNames.login)` après logout/delete | Aucun |

Aucune nouvelle dépendance requise.

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 3 |
| Décisions prises | 3 |
| Nouvelles dépendances | 0 |
| Patterns réutilisés | 6 (`SettingsItem` style, `FeatureSettingsScreen` tokens, `ChangePasswordSheet` state, `AvatarPicker` interface, `_runExport` pattern, `userProfileRepositoryProvider` usage) |
