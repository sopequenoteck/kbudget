# Implementation Plan: Settings hub Flutter (refonte complète)

**Branch**: `feature/flutter-settings-hub-v5` | **Date**: 2026-05-27 | **Spec**: [spec.md](spec.md)

---

## Summary

Réécriture de `settings_hub_screen.dart` (62L → hub intégré ~400L) sur le pattern Angular `settings.ts`. Suppression de 3 sous-écrans settings séparés (`appearance`, `feature`, `notification`) et de leurs routes. Extension de `ThemeNotifier` avec l'option `auto` (ThemeMode.system). Ajout de `package_info_plus` pour lire la version depuis `pubspec.yaml`. Aucun changement backend ni schéma Drift.

---

## Technical Context

**Language/Version** : Dart >= 3.6, Flutter >= 3.27  
**Primary Dependencies** : flutter_riverpod, go_router, package_info_plus (à ajouter)  
**Storage** : SharedPreferences (thème, textScale) + Drift optionnel (préférences en mode local) + API REST (sync mode server)  
**Testing** : flutter_test + Mockito  
**Target Platform** : iOS (App Store) + Android (Google Play) — Trajectoire B standalone  
**Project Type** : Mobile app  
**Constraints** : Hub scrollable sur 375px, changement thème < 100ms, health check non-bloquant (async)  
**Scale/Scope** : 1 écran hub (~400L), 3 écrans supprimés, 1 notifier étendu, 1 dépendance ajoutée

---

## Constitution Check

| Principe | Gate | Statut | Note |
|----------|------|--------|------|
| I — API-First / Local-First | Préférences : source de vérité Drift/SharedPreferences en mode local, sync API fire-and-forget en mode server | ✅ PASS | `FeatureConfigNotifier._syncToServer()` et `ThemeNotifier` utilisent déjà ce pattern |
| II — Sécurité par défaut | Aucune nouvelle route API. Données utilisateur lues depuis providers authentifiés existants | ✅ PASS | `userNotifierProvider` déjà filtré par user authentifié |
| III — Simplicité & YAGNI | Réécriture d'un seul fichier, suppression nette de 3 fichiers. Aucune abstraction nouvelle | ✅ PASS | La complexité totale diminue |
| IV — Mobile-First UX | Hub scrollable, sections inline = moins de navigation, accès aux réglages en 1 tap | ✅ PASS | Améliore l'UX mobile |
| V — Testabilité | Widget tests avec `ProviderScope` + overrides. Sections testables via état des providers | ✅ PASS | Pattern identique aux autres écrans |
| VI — Observabilité | Aucun `print()`. Pas de nouveau logging nécessaire (UI-only) | ✅ PASS | — |
| VII — Trajectoire B | Feature Flutter-only, locale par défaut. Sync server optionnelle via `FeatureConfigNotifier` | ✅ PASS | Conforme Trajectoire B |

**Résultat** : ✅ Tous les gates passent. Aucune dérogation.

---

## Project Structure

### Documentation (cette feature)

```text
docs/features/KKS-246/
├── spec.md          ✅
├── clarify-log.md   ✅
├── review-log.md    ✅
├── plan.md          ← ce fichier
└── tasks.md         (généré par /devflow.tasks)
```

### Fichiers source impactés

```text
flutter/
├── pubspec.yaml                                        (M) ajouter package_info_plus
├── lib/src/
│   ├── features/settings/
│   │   ├── presentation/
│   │   │   ├── settings_hub_screen.dart               (M) réécriture complète
│   │   │   ├── appearance_settings_screen.dart         (D) supprimé
│   │   │   ├── feature_settings_screen.dart            (D) supprimé
│   │   │   └── [notification_settings_screen.dart]     (D) supprimé → features/notifications/
│   │   ├── application/
│   │   │   └── theme_notifier.dart                    (M) ajouter ThemeMode.system
│   │   └── domain/
│   │       └── settings_section.dart                  (M) retirer 3 sections inline
│   ├── features/notifications/presentation/
│   │   └── notification_settings_screen.dart           (D) supprimé
│   └── routing/
│       ├── app_router.dart                            (M) supprimer 3 routes
│       └── route_names.dart                           (M) supprimer 6 constantes
```

**Légende** : (M) Modifier — (D) Supprimer

---

## Approche détaillée

### Étape 1 — Dépendance `package_info_plus` (FR-016)

Ajouter dans `pubspec.yaml` :
```yaml
package_info_plus: ^8.1.2
```

Usage dans le hub : `PackageInfo info = await PackageInfo.fromPlatform()` dans `initState`.

---

### Étape 2 — Extension `ThemeNotifier` (FR-008)

**Fichier** : `flutter/lib/src/features/settings/application/theme_notifier.dart`

Changement : l'état passe de `ThemeMode` (light | dark) à `ThemeMode` (light | dark | **system**).

```
Persistance : 'light' | 'dark' | 'system' dans SharedPreferences
Lecture initiale : restaurer depuis SharedPreferences
Résolution auto : ThemeMode.system → Flutter le résout automatiquement via MaterialApp.themeMode
Fallback si préférence absente : ThemeMode.dark (comportement actuel)
```

Nouvelle méthode publique : `setThemeMode(ThemeMode mode)` (déjà existante — vérifier que 'system' est géré).

**Couvre** : FR-008

---

### Étape 3 — Suppression des 3 sous-écrans et routes (FR-001, FR-002)

**3 fichiers à supprimer** :
- `flutter/lib/src/features/settings/presentation/appearance_settings_screen.dart`
- `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart`
- `flutter/lib/src/features/notifications/presentation/notification_settings_screen.dart`

**`app_router.dart`** — supprimer les 3 GoRoute :
```dart
GoRoute(path: RouteNames.settingsAppearance, ...)   // retirer
GoRoute(path: RouteNames.settingsFeatures, ...)     // retirer
GoRoute(path: RouteNames.settingsNotifications, ...) // retirer
```

**`route_names.dart`** — supprimer 6 constantes :
```dart
static const String settingsAppearance = 'appearance';       // retirer
static const String settingsAppearanceName = 'settings-appearance'; // retirer
static const String settingsFeatures = 'features';           // retirer
static const String settingsFeaturesName = 'settings-features';     // retirer
static const String settingsNotifications = 'notifications'; // retirer
static const String settingsNotificationsName = 'settings-notifications'; // retirer
```

**`settings_section.dart`** — supprimer les 3 `SettingsSection` correspondantes (Apparence, Fonctionnalités & Navigation, Notifications). Retirer les entrées du const `settingsSections[]`.

**Couvre** : FR-001, FR-002, FR-015

---

### Étape 4 — Réécriture de `settings_hub_screen.dart` (FR-003 à FR-015)

**Classe** : `SettingsHubScreen extends ConsumerStatefulWidget`

**State** :
```dart
PackageInfo? _packageInfo
HealthCheckResult _healthResult = HealthCheckResult.checking()
```

**initState** :
```dart
PackageInfo.fromPlatform().then((info) => setState(() => _packageInfo = info));
if (dataMode == DataMode.server) _runHealthCheck();
```

**Structure build** :
```dart
Scaffold(
  body: CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _buildAccountSection()),
      SliverToBoxAdapter(child: _buildSectionLabel('Gestion')),
      SliverToBoxAdapter(child: _buildManagementSection()),
      if (isAdmin) SliverToBoxAdapter(child: _buildAdminSection()),
      SliverToBoxAdapter(child: _buildSectionLabel('Apparence')),
      SliverToBoxAdapter(child: _buildAppearanceSection()),
      SliverToBoxAdapter(child: _buildSectionLabel('Notifications')),
      SliverToBoxAdapter(child: _buildNotificationsSection()),
      SliverToBoxAdapter(child: _buildSectionLabel('Navigation')),
      SliverToBoxAdapter(child: _buildNavigationSection()),
      SliverToBoxAdapter(child: _buildFooter()),
    ],
  ),
)
```

#### Section Compte (FR-004)
```
- CircleAvatar 56px : image réseau si avatarUrl non null, sinon initiales (2 chars, uppercase)
- Text : nom utilisateur (fontWeight semibold)
- Text : email (style secondaire)
- GestureDetector → context.push('/settings/profile')
- Centré verticalement, padding vertical 24px
```

#### Section Gestion (FR-005)
```
- 3 _SettingsRow (lien navigable) :
  1. Mon compte → /settings/profile
  2. Comptes & Devises → /settings/accounts
  3. Catégories → /settings/categories
- Pattern _SettingsRow : icône colorée + titre + description + chevron
```

#### Section Administration (FR-006)
```
- Visible uniquement si ref.watch(userNotifierProvider).isAdmin == true
- 1 _SettingsRow : Utilisateurs → /settings/users
```

#### Section Apparence (FR-007, FR-008)
```
Thème :
- Label "Thème"
- Row avec 3 boutons segmentés custom (Clair / Sombre / Auto)
  - Sélectionné : bg primary.withValues(alpha:0.08), border primaryColor width 2, checkCircle
  - Non sélectionné : border outline width 1, text secondaire
  - onTap : ref.read(themeNotifierProvider.notifier).setThemeMode(mode)

Taille du texte :
- Label "Taille du texte"
- Row avec 3 boutons segmentés (Petit / Normal / Grand)
  - Même logique visuelle
  - onTap : ref.read(textScaleNotifierProvider.notifier).setTextScale(scale)

Aperçu :
- Container arrondi avec texte de prévisualisation
- fontSize = AppTypography.bodyMedium * textScale.scaleFactor
```

#### Section Notifications (FR-009, FR-017)
```
- Afficher uniquement les NotificationType dont la feature associée est activée :
  - subscriptionDue : visible si Feature.subscriptions activée
  - debtDue : visible si Feature.debts activée
- Pour chaque type visible :
  - Row : label + Switch
  - onChanged : ref.read(featureConfigNotifierProvider.notifier).updateNotificationTypes(...)
- Select timezone :
  - DropdownButton (ou DropdownMenu) avec 15 timezones hardcodées
  - Valeur actuelle : featureConfigState.timezone
  - onChange : ref.read(...notifier).updateTimezone(tz)
```

Liste timezones hardcodée (identique Angular) :
```
Europe/Paris, Europe/London, Europe/Berlin, Europe/Madrid, Europe/Rome,
Europe/Brussels, Africa/Casablanca, Africa/Lome, Africa/Tunis, Africa/Lagos,
Africa/Abidjan, America/New_York, America/Chicago, America/Los_Angeles, Asia/Tokyo
```

#### Section Navigation (FR-010, FR-011)
```
Items verrouillés (non-modifiables) :
- Accueil (house icon) + Transactions (receipt icon)
- Opacity 0.5, pas de drag handle, pas de toggle

Features activées (ReorderableListView) :
- Items : feature.label + feature.icon + drag handle (PhosphorIcons.dotsSixVertical)
- Switch : true → onChanged appelle _onToggleFeature(feature, false)
- onReorder : _onReorder(oldIndex, newIndex) → featureConfigNotifier.reorderNavigation(newOrder)

Features désactivées (liste statique) :
- Items : feature.label + feature.icon + Switch off
- Opacity 0.5, pas de drag handle
- Switch : false → onChanged appelle _onToggleFeature(feature, true)

_onToggleFeature(feature, isEnabling) :
- Si désactivation ET _hasExistingData(feature) → ConfirmDialog
  - Titre : "Désactiver {feature.label} ?"
  - Message : "Vos données seront masquées mais pas supprimées."
  - Boutons : Annuler / Désactiver
- Sinon → featureConfigNotifier.toggleFeature(feature)
```

**Note W-01** : features désactivées affichées en liste statique APRÈS la ReorderableListView des actives. Position fixe dans la liste, pas de drag possible.

#### Footer (FR-012, FR-013, FR-014)
```
DataMode.local :
- Text "K-Budget v{_packageInfo?.version ?? '...'} · Mode local"
- Style : font-size xs, text-tertiary, centré

DataMode.server :
- Text "K-Budget v{version}"
- Health status :
  - checking → "Vérification…"
  - online → "En ligne · {responseTimeMs}ms" (AppColors.income — vert)
  - offline → "Hors ligne" (AppColors.expense — rouge)
- Erreurs HTTP non-timeout (4xx, 5xx) → traiter comme offline

_runHealthCheck() :
- GET /actuator/health via Dio, timeout 10s
- setState avec HealthCheckResult résultant
- Tout code != 200 ET toute exception → HealthCheckResult.offline()
```

**Couvre** : FR-003 à FR-015, FR-017

---

## Widgets privés à extraire

| Widget | Rôle | Réutilisable hors hub |
|--------|------|----------------------|
| `_SettingsSectionLabel` | Label de section (uppercase, xs, tertiary) | Non — privé hub |
| `_SettingsRow` | Ligne navigable (icon + titre + description + chevron) | Non — privé hub |
| `_SegmentedThemePicker` | 3 boutons thème (Clair/Sombre/Auto) | Non — privé hub |
| `_SegmentedScalePicker` | 3 boutons textScale | Non — privé hub |
| `_NavFeatureItem` | Ligne feature (icon + label + switch + drag handle optionnel) | Non — privé hub |

---

## Risques & mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| ReorderableListView dans CustomScrollView → conflit scroll | Medium | Wrapper avec `NeverScrollableScrollPhysics()` sur la ReorderableListView + `shrinkWrap: true` |
| Health check `setState` après `dispose` | Low | Guard `if (mounted)` avant chaque `setState` dans les callbacks async |
| `package_info_plus` async → version vide au premier frame | Low | Afficher `'...'` pendant le chargement (`_packageInfo == null`) |
| Suppression routes → lien mort si navigation legacy | Low | Vérifié : 0 référence externe aux 3 routes (grep confirmé en session) |
| ThemeMode.system non géré dans `MaterialApp.themeMode` | Low | Vérifier que `AppTheme` propage `ThemeMode.system` correctement |

---

## Hors scope

- Toute modification backend (aucun endpoint nouveau)
- Migration de données lors de la désactivation d'une feature (logique existante dans `FeatureConfigNotifier`)
- Tests widget exhaustifs (couverts séparément par `test-qa`)
- Modifications côté Angular
- Notification settings écran de remplacement (absorbé dans le hub)

---

## Complexity Tracking

> Aucune violation de la constitution. Tableau vide.
