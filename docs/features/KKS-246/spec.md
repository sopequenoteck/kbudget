# Feature Specification: Settings hub Flutter (refonte complète)

**Issue**: KKS-246  
**Feature Branch**: `feature/flutter-settings-hub-v5`  
**Created**: 2026-05-27  
**Status**: Draft  
**Priorité**: High — 5 Points

---

## Contexte

L'écran Flutter actuel (`settings_hub_screen.dart`) est un dispatcher de 62 lignes qui navigue vers des sous-écrans séparés (`appearance_settings_screen.dart`, `feature_settings_screen.dart`, `notification_settings_screen.dart`). L'Angular (source de vérité DESIGN.md v5) implémente toutes ces sections **inline dans un seul hub scrollable**.

**Décision actée** : Flutter adopte le pattern Angular — hub intégré, suppression des sous-écrans settings. Les 3 fichiers écrans et leurs routes sont supprimés dans cette issue.

**Décisions de session** :
- Thème : 3 options (light / dark / auto) — ThemeNotifier à étendre
- Notifications : 2 types exposés dans l'UI (subscriptionDue, debtDue) comme Angular
- Footer : conditionnel selon DataMode (server → health check, local → mention statique)

---

## User Scenarios & Testing

### User Story 1 — Hub unifié scrollable (Priorité : P1)

L'utilisateur ouvre les réglages et voit toutes les sections (Compte, Gestion, Administration, Apparence, Notifications, Navigation, Footer) dans un seul écran scrollable, sans naviguer vers des sous-écrans pour les sections inline.

**Why this priority** : C'est la refonte structurelle centrale. Sans ce hub, les US suivantes n'ont pas de support.

**Independent Test** : Ouvrir `/settings` → vérifier que les 7 sections sont visibles en scrollant, que Mon compte / Comptes & Devises / Catégories naviguent toujours correctement, et qu'aucune route `/settings/appearance`, `/settings/features`, `/settings/notifications` n'est accessible.

**Acceptance Scenarios** :

1. **Given** l'app en mode server avec utilisateur connecté non-admin, **When** l'utilisateur navigue vers Réglages, **Then** il voit les sections Compte, Gestion, Apparence, Notifications, Navigation et Footer — sans section Administration.
2. **Given** l'app avec utilisateur admin connecté, **When** l'utilisateur navigue vers Réglages, **Then** la section Administration avec le lien Utilisateurs est visible entre Gestion et Apparence.
3. **Given** les routes `/settings/appearance` et `/settings/features`, **When** une navigation est tentée vers ces routes, **Then** elles n'existent plus (supprimées du router).

---

### User Story 2 — Apparence inline (Priorité : P2)

L'utilisateur change son thème (light / dark / auto) et son échelle de texte (Petit / Normal / Grand) directement dans le hub, avec application immédiate visible sur l'UI sans quitter l'écran.

**Why this priority** : Section la plus utilisée au quotidien. Bloquerait les tests UI si absent.

**Independent Test** : Dans le hub, sélectionner chaque thème → vérifier que l'app change de thème immédiatement. Sélectionner chaque échelle → vérifier que la taille du texte change. Fermer et rouvrir l'app → vérifier la persistance.

**Acceptance Scenarios** :

1. **Given** thème actuel = dark, **When** l'utilisateur sélectionne "Auto", **Then** le thème s'adapte à la préférence système du device et la sélection est persistée.
2. **Given** textScale actuel = medium, **When** l'utilisateur sélectionne "Grand", **Then** la typographie de l'app grossit immédiatement (scaleFactor = 1.3) et l'aperçu dans la section reflète le changement.
3. **Given** thème = auto sur un device sans préférence système définie, **When** l'écran est affiché, **Then** le thème par défaut est dark (comportement identique à Angular).

---

### User Story 3 — Features & Navigation inline (Priorité : P2)

L'utilisateur active / désactive les modules (Abonnements, Dettes, Budgets) et réordonne la barre de navigation par drag-and-drop, directement dans le hub.

**Why this priority** : Fonctionnalité structurante — l'ordre nav et les features actives conditionnent l'ensemble de l'app.

**Independent Test** : Activer/désactiver Budgets → vérifier que la bottom nav est mise à jour. Réordonner Abonnements avant Dettes → relancer l'app → vérifier l'ordre persisté. Désactiver Abonnements avec des abonnements existants → vérifier l'apparition du dialog de confirmation.

**Acceptance Scenarios** :

1. **Given** feature Budgets désactivée, **When** l'utilisateur active Budgets, **Then** l'icône Budgets apparaît dans la bottom nav preview et l'état est persisté.
2. **Given** feature Abonnements active avec des abonnements existants, **When** l'utilisateur désactive Abonnements, **Then** un dialog de confirmation s'affiche ("Vos données seront masquées mais pas supprimées") avec boutons Annuler / Désactiver.
3. **Given** features Abonnements et Dettes actives, **When** l'utilisateur drag Dettes avant Abonnements dans la liste, **Then** l'ordre est appliqué à la bottom nav immédiatement et persisté.
4. **Given** les items Accueil et Transactions, **When** l'utilisateur tente de les déplacer ou désactiver, **Then** ils restent verrouillés (opacity réduite, pas de drag handle, pas de toggle).

---

### User Story 4 — Notifications inline (Priorité : P3)

L'utilisateur configure ses préférences de notifications (types activés et fuseau horaire) directement dans le hub sans naviguer vers un sous-écran.

**Why this priority** : Moins critique pour le MVP standalone — les notifications fonctionnent même sans configuration.

**Independent Test** : Désactiver "Abonnements dus" → vérifier que le toggle passe à off et que la préférence est persistée. Changer le timezone → vérifier la persistance.

**Acceptance Scenarios** :

1. **Given** notifications subscriptionDue actives, **When** l'utilisateur désactive le toggle "Abonnements dus", **Then** l'état est mis à jour dans FeatureConfigNotifier et persisté (local + sync serveur si mode server).
2. **Given** timezone = "Europe/Paris", **When** l'utilisateur sélectionne "Africa/Lomé", **Then** la préférence est mise à jour et persistée.
3. **Given** feature Abonnements désactivée, **When** l'utilisateur affiche la section Notifications, **Then** le toggle "Abonnements dus" est masqué (feature désactivée = notification non pertinente, afficher uniquement les types dont la feature est active).

---

### User Story 5 — Footer contextuel (Priorité : P3)

Le footer affiche la version de l'app et, selon le mode de données, soit le statut du serveur (mode server), soit une mention "Mode local" statique.

**Why this priority** : Informatif uniquement — n'impacte pas les fonctionnalités core.

**Independent Test** : En mode local → vérifier l'affichage "vX.Y.Z · Mode local". Passer en mode server → vérifier que le health check s'exécute et affiche le statut (online/offline).

**Acceptance Scenarios** :

1. **Given** DataMode = local, **When** le hub est ouvert, **Then** le footer affiche "K-Budget vX.Y.Z · Mode local" sans requête réseau.
2. **Given** DataMode = server et serveur joignable, **When** le hub est ouvert, **Then** le health check s'exécute (timeout 10s), le footer affiche "En ligne · Xms" en vert.
3. **Given** DataMode = server et serveur injoignable, **When** le health check expire, **Then** le footer affiche "Hors ligne" en rouge (couleur color-expense).

---

### Edge Cases

- Utilisateur désactive toutes les features optionnelles → bottom nav n'affiche que Accueil et Transactions (minimum viable).
- Avatar URL null ou erreur de chargement → afficher les initiales (2 chars, uppercase) sur fond coloré.
- Liste timezones : 15 entrées hardcodées (identique à Angular, pas d'auto-détection).
- Health check en cours → afficher "Vérification…" en attendant la réponse.
- ThemeMode.system sur device sans préférence système → fallback dark.

---

## Requirements

### Functional Requirements

- **FR-001** : Supprimer `appearance_settings_screen.dart`, `feature_settings_screen.dart` et `notification_settings_screen.dart`.
- **FR-002** : Supprimer les routes `/settings/appearance`, `/settings/features`, `/settings/notifications` du router et les constantes associées dans `route_names.dart`.
- **FR-003** : Réécrire `settings_hub_screen.dart` comme hub intégré scrollable avec 7 sections inline.
- **FR-004** : Section **Compte** — avatar circulaire avec fallback initiales + nom + email de l'utilisateur connecté.
- **FR-005** : Section **Gestion** — 3 liens navigables : Mon compte (`/settings/profile`), Comptes & Devises (`/settings/accounts`), Catégories (`/settings/categories`).
- **FR-006** : Section **Administration** — lien Utilisateurs (`/settings/users`) visible uniquement si `isAdmin == true`.
- **FR-007** : Section **Apparence** — segmented control 3 thèmes (Clair / Sombre / Auto) + segmented control 3 échelles (Petit / Normal / Grand) avec aperçu typographique.
- **FR-008** : Étendre `ThemeNotifier` avec `ThemeMode.system` (option "Auto") — persistance via SharedPreferences, résolution au runtime via `MediaQuery.platformBrightness`.
- **FR-009** : Section **Notifications** — 2 toggles (subscriptionDue, debtDue) + select timezone (15 entrées hardcodées).
- **FR-010** : Section **Navigation** — items verrouillés non-modifiables (Accueil, Transactions) + features activées réordonnables par drag (ReorderableListView) + features désactivées avec toggle d'activation.
- **FR-011** : Dialog de confirmation avant désactivation d'une feature si des données existent (texte : "Vos données seront masquées mais pas supprimées.").
- **FR-012** : Section **Footer** — version app toujours affichée.
- **FR-013** : Footer en mode server → health check async au chargement (GET `/actuator/health`, timeout 10s), affichage statut + latence.
- **FR-014** : Footer en mode local → affichage statique "Mode local", aucune requête réseau.
- **FR-015** : Mettre à jour `settings_section.dart` pour retirer les sections Apparence, Fonctionnalités & Navigation, Notifications (désormais inline).
- **FR-016** : Ajouter `package_info_plus` aux dépendances Flutter pour lire la version depuis `pubspec.yaml` au runtime.
- **FR-017** : Section Notifications — masquer les toggles dont la feature associée est désactivée (ex: toggle "Abonnements dus" masqué si feature Abonnements désactivée).

### Non-Functional Requirements

- **NFR-001** : Le hub est scrollable sur tous les formats (y compris iPhone SE, 375px).
- **NFR-002** : Le changement de thème et d'échelle de texte est appliqué en moins de 100ms (pas d'animation de transition d'écran).
- **NFR-003** : Le drag-and-drop de navigation fournit un feedback visuel (elevation + opacité) pendant le drag.
- **NFR-004** : Les dialogs de confirmation utilisent le widget `ConfirmDialog` existant (composant shared KKS-238).
- **NFR-005** : Le health check ne bloque pas l'affichage du hub (async, état "Vérification…" pendant la requête).

### Key Entities

- **UserPreference** : enabledFeatures, navOrder, enabledNotificationTypes, timezone, textScale — persisté localement et synchronisé serveur (mode server).
- **Feature** : enum (subscriptions, debts, budgets) avec label, icon, description, defaultEnabled.
- **TextScale** : enum (small, medium, large) avec scaleFactor (0.85 / 1.0 / 1.3) et label.
- **ThemeMode** : light | dark | system — étendu depuis l'état actuel (light | dark).
- **NotificationType** : subset visible = subscriptionDue, debtDue (6 types disponibles dans l'enum, 2 exposés).
- **DataMode** : local | server — détermine le comportement du footer.
- **HealthCheckResult** : status (online | offline | checking), responseTimeMs, error, checkedAt.

### Assumptions

- L'avatar utilisateur est une URL fournie par `userService` — si null ou erreur, on génère les initiales (2 chars, uppercase) depuis le nom.
- `isAdmin` est disponible via le provider utilisateur existant sans requête supplémentaire.
- La version de l'app Flutter est lue depuis `pubspec.yaml` via le package `package_info_plus` (à ajouter aux dépendances). La version Flutter (`1.0.0+1`) est indépendante de la version Angular (`5.0.0`) — Flutter est un produit standalone. Le footer affichera la version Flutter, pas la version Angular.
- Les 15 timezones sont hardcodées (liste identique à Angular).
- ThemeMode.system résout via `MediaQuery.platformBrightness` — pas de listener système permanent.

---

## Success Criteria

- **SC-001** : L'écran `/settings` affiche les 7 sections en un seul scroll sans navigation vers sous-écrans pour Apparence, Notifications, Navigation.
- **SC-002** : Le changement de thème (y compris Auto) est appliqué immédiatement et persiste après redémarrage.
- **SC-003** : L'ordre de navigation drag-and-drop est persisté et reflété dans la bottom nav après redémarrage.
- **SC-004** : Le footer affiche "Mode local" sans appel réseau en mode local, et le statut serveur avec latence en mode server.
- **SC-005** : Les routes `/settings/appearance`, `/settings/features` et `/settings/notifications` n'existent plus dans le router.
- **SC-006** : Aucune régression sur les routes settings conservées (profile, accounts, categories, data, currencies).
