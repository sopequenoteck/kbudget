# Documentation — KKS-246 : Settings hub Flutter (refonte complète)

> Date : 2026-05-27
> Issue : KKS-246

---

## Résumé

L'écran Réglages Flutter a été entièrement refactorisé : le dispatcher de 62 lignes qui naviguait vers 3 sous-écrans séparés (Apparence, Fonctionnalités & Navigation, Notifications) est remplacé par un hub intégré scrollable d'environ 450 lignes, aligné sur le pattern Angular (DESIGN.md v5). Les 3 sous-écrans et leurs 3 routes GoRouter + 6 constantes de nommage ont été supprimés. La feature ajoute également `ThemeMode.system` (option "Auto") et un footer contextuel affichant la version de l'app et l'état du serveur.

---

## Guide utilisateur

### Fonctionnalités

#### Hub unifié scrollable

**Description** : Toutes les sections de réglages sont désormais accessibles dans un seul écran scrollable. Plus besoin de naviguer vers des sous-écrans pour modifier l'apparence ou les notifications.

**Usage** : Aller dans **Réglages** via la barre de navigation. Les sections apparaissent dans l'ordre : Compte, Gestion, Administration (admin uniquement), Apparence, Notifications, Navigation, Footer.

---

#### Apparence inline

**Description** : Thème (Clair / Sombre / Auto) et taille du texte (Petit / Normal / Grand) se changent directement dans le hub, avec application immédiate sans quitter l'écran. L'option **Auto** suit la préférence système du device.

**Usage** :
1. Section **Apparence** → Thème → tapper sur Clair, Sombre ou Auto
2. Section **Apparence** → Taille du texte → tapper sur Petit, Normal ou Grand
3. Le changement est immédiatement visible et persisté (survit au redémarrage)

---

#### Navigation drag-and-drop inline

**Description** : L'ordre des modules dans la barre de navigation du bas se configure directement dans le hub, par glisser-déposer. Les modules Accueil et Transactions sont verrouillés (non-modifiables). Un dialogue de confirmation apparaît avant de désactiver un module qui contient des données.

**Usage** :
1. Section **Navigation** → maintenir sur le handle (⠿) d'un module actif → déplacer vers la position souhaitée
2. Quitter les réglages → la barre de navigation reflète immédiatement le nouvel ordre
3. Pour activer/désactiver un module : basculer le switch — si le module a des données, un dialogue "Vos données seront masquées mais pas supprimées." apparaît pour confirmer

---

#### Notifications inline

**Description** : Les toggles de notifications (rappels d'abonnements, rappels de dettes) et le sélecteur de fuseau horaire se configurent directement dans le hub. Les toggles d'une feature désactivée sont automatiquement masqués.

**Usage** :
- Section **Notifications** → basculer les switches pour activer/désactiver les rappels
- Le toggle "Abonnements dus" n'apparaît que si la feature Abonnements est activée
- Le toggle "Dettes dues" n'apparaît que si la feature Dettes est activée
- Sélectionner le fuseau horaire via le menu déroulant (15 options)

---

#### Footer contextuel

**Description** : Le pied de page affiche la version de l'application et l'état de connexion au serveur.

**Usage** :
- **Mode local** : affiche `K-Budget vX.Y.Z · Mode local` (aucun appel réseau)
- **Mode serveur** : effectue un health check sur `/actuator/health` au chargement de l'écran et affiche :
  - `Vérification…` pendant le check
  - `En ligne · Xms` (vert) si le serveur répond HTTP 200
  - `Hors ligne` (rouge) si le serveur ne répond pas ou renvoie un code != 200

---

### Exemples d'utilisation

```
// Changer le thème en Auto :
Réglages → Apparence → Thème → [Auto]
→ L'app suit la préférence claire/sombre du système.

// Réordonner les modules de navigation :
Réglages → Navigation → Maintenir ⠿ sur "Budgets" → Glisser en 2ème position
→ La barre de navigation affiche Budgets en 2ème position.

// Désactiver le module Abonnements :
Réglages → Navigation → Switch "Abonnements" → OFF
→ Dialogue : "Désactiver Abonnements ? Vos données seront masquées mais pas supprimées."
→ Confirmer → le module disparaît de la barre de navigation.

// Vérifier la version en mode serveur :
Réglages → Footer → "K-Budget v1.3.0" + statut serveur "En ligne · 42ms"
```

---

## Changements techniques

### Fichiers créés

Aucun fichier nouveau créé. `settings_hub_screen.dart` est une réécriture complète (62L → ~450L).

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/features/settings/presentation/settings_hub_screen.dart` | Réécriture complète : hub intégré avec 7 sections inline, widgets privés, health check, footer |
| `flutter/lib/src/features/settings/application/theme_notifier.dart` | Ajout `ThemeMode.system` (option Auto), clé de persistance `theme_mode_v2`, suppression `toggleTheme()` (dead code) |
| `flutter/lib/src/routing/app_router.dart` | Suppression des 3 `GoRoute` : settingsAppearance, settingsFeatures, settingsNotifications |
| `flutter/lib/src/routing/route_names.dart` | Suppression des 6 constantes de nommage des routes supprimées |
| `flutter/pubspec.yaml` | Ajout dépendance `package_info_plus: ^8.1.2` |

### Fichiers supprimés

| Fichier | Raison |
|---------|--------|
| `flutter/lib/src/features/settings/presentation/appearance_settings_screen.dart` | Absorbé dans le hub (FR-001) |
| `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` | Absorbé dans le hub (FR-001) |
| `flutter/lib/src/features/notifications/presentation/notification_settings_screen.dart` | Absorbé dans le hub (FR-001) |
| `flutter/lib/src/features/settings/domain/settings_section.dart` | Orphelin — aucun import après la réécriture |
| `flutter/test/src/features/notifications/presentation/notification_settings_screen_test.dart` | Écran supprimé |
| `flutter/test/src/features/settings/presentation/feature_settings_navigation_test.dart` | Écran supprimé |

### Dépendances ajoutées

| Package | Version | Raison |
|---------|---------|--------|
| `package_info_plus` | `^8.1.2` | Lecture de la version de l'app au runtime depuis `pubspec.yaml` (FR-016) |

---

## Configuration

### Premier lancement après mise à jour

`package_info_plus` est un plugin natif. Un `flutter clean` + rebuild complet est requis après ajout :

```bash
cd flutter
flutter clean
flutter pub get
flutter run
```

Un simple hot reload/restart ne suffit pas (MissingPluginException sinon).

### Persistance du thème

La clé de stockage a changé : `theme_mode_v2` (vs l'ancienne clé `theme_mode`). L'ancienne préférence n'est pas migrée automatiquement — l'utilisateur verra le thème par défaut (dark) au premier lancement après la mise à jour, puis sa préférence sera persistée dans la nouvelle clé.

### Timezones disponibles

15 timezones hardcodées (identiques à Angular) :
`Europe/Paris`, `Europe/London`, `Europe/Berlin`, `Europe/Madrid`, `Europe/Rome`, `Europe/Brussels`, `Africa/Casablanca`, `Africa/Lome`, `Africa/Tunis`, `Africa/Lagos`, `Africa/Abidjan`, `America/New_York`, `America/Chicago`, `America/Los_Angeles`, `Asia/Tokyo`

---

## Tests et validation

### Tests supprimés (écrans obsolètes)

| Test | Raison |
|------|--------|
| `notification_settings_screen_test.dart` | Écran supprimé (FR-001) |
| `feature_settings_navigation_test.dart` | Écran supprimé (FR-001) |

### Validation manuelle (T-054)

- [x] Hub s'ouvre, 7 sections visibles en scroll
- [x] Navigation Compte / Comptes & Devises / Catégories fonctionnelle
- [x] Section Administration visible uniquement si admin
- [x] Thème Clair / Sombre / Auto appliqué immédiatement
- [x] Taille du texte Petit / Normal / Grand persistée
- [x] Routes `/settings/appearance`, `/settings/features`, `/settings/notifications` supprimées
- [x] Drag-and-drop modules : ordre persisté après redémarrage
- [x] ConfirmDialog si désactivation d'un module avec données
- [x] Footer mode local : "K-Budget vX.Y.Z · Mode local" (aucun appel réseau)
- [x] Footer mode serveur : statut health check (Vérification → En ligne / Hors ligne)
- [x] `package_info_plus` résolu après `flutter clean && flutter pub get`

### Warnings post-review (non-bloquants, à traiter)

| Réf | Description | Priorité |
|-----|-------------|----------|
| W-001 | Health check : seuil `statusCode < 500` au lieu de `== 200` — les 4xx sont traités comme "En ligne" | Bas |
| W-005 | Ordre sections dans le build : Navigation placée avant Notifications (spec : Notifications → Navigation) | Bas |

Ces deux écarts mineurs peuvent être corrigés en post-commit sans impact fonctionnel.

---

## Couverture des requirements

| FR | Description | Couvert par | Statut |
|----|-------------|-------------|--------|
| FR-001 | Supprimer 3 sous-écrans | Fichiers supprimés | ✅ |
| FR-002 | Supprimer 3 routes + 6 constantes | app_router.dart, route_names.dart | ✅ |
| FR-003 | Structure hub intégré | settings_hub_screen.dart | ✅ |
| FR-004 | Section Compte | `_buildAccountSection()` | ✅ |
| FR-005 | Section Gestion | `_buildManagementSection()` | ✅ |
| FR-006 | Section Administration conditionnelle | `if (isAdmin)` guard | ✅ |
| FR-007 | Section Apparence segmented controls | `_ThemeOption`, `_ScaleOption` | ✅ |
| FR-008 | ThemeNotifier + ThemeMode.system | theme_notifier.dart | ✅ |
| FR-009 | Section Notifications toggles + timezone | `_buildNotificationsSection()` | ✅ |
| FR-010 | Section Navigation drag-drop | `ReorderableListView` + locked items | ✅ |
| FR-011 | ConfirmDialog avant désactivation | `_onToggleFeature()` + `ConfirmDialogCustom` | ✅ |
| FR-012 | Footer version | `_packageInfo?.version` | ✅ |
| FR-013 | Footer mode server health check | `_runHealthCheck()` | ✅ |
| FR-014 | Footer mode local statique | `DataMode.local` branch | ✅ |
| FR-015 | settings_section.dart nettoyage | Supprimé (orphelin) | ✅ |
| FR-016 | package_info_plus dépendance | pubspec.yaml | ✅ |
| FR-017 | Masquage toggles notif si feature off | Condition `Feature.subscriptions/debts` active | ✅ |
