# Tasks: Settings hub Flutter (refonte complète)

**Issue**: KKS-246 | **Branch**: `feature/flutter-settings-hub-v5` | **Date**: 2026-05-27  
**Prérequis**: spec.md ✅ plan.md ✅ clarify-log.md ✅

---

## Phase 1 — Setup

**Objectif** : Ajouter la dépendance requise avant tout autre travail.

- [x] [T-001] Ajouter `package_info_plus: ^8.1.2` dans `flutter/pubspec.yaml` puis `flutter pub get` — Réf: FR-016

**Checkpoint** : `flutter pub get` sans erreur, `package_info_plus` présent dans `pubspec.lock`.

---

## Phase 2 — Fondations (bloquantes)

**Objectif** : Supprimer les sous-écrans obsolètes, nettoyer le router et étendre ThemeNotifier avant de reconstruire le hub.

⚠️ **CRITIQUE** : Aucune tâche de Phase 3+ ne peut débuter avant que cette phase soit complète.

- [x] [T-011] [P] Étendre `flutter/lib/src/features/settings/application/theme_notifier.dart` : ajouter `ThemeMode.system` (persistance clé `'system'`, fallback dark si préférence absente) — Réf: FR-008
- [x] [T-012] [P] Supprimer les 3 fichiers écrans : `appearance_settings_screen.dart`, `feature_settings_screen.dart`, `flutter/lib/src/features/notifications/presentation/notification_settings_screen.dart` — Réf: FR-001
- [x] [T-013] Nettoyer `flutter/lib/src/routing/app_router.dart` : supprimer les 3 `GoRoute` (settingsAppearance, settingsFeatures, settingsNotifications) — Réf: FR-002 *(dépend T-012)*
- [x] [T-014] [P] Nettoyer `flutter/lib/src/routing/route_names.dart` : supprimer les 6 constantes (settingsAppearance, settingsAppearanceName, settingsFeatures, settingsFeaturesName, settingsNotifications, settingsNotificationsName) — Réf: FR-002
- [x] [T-015] [P] Mettre à jour `flutter/lib/src/features/settings/domain/settings_section.dart` : retirer les 3 sections Apparence, Fonctionnalités & Navigation, Notifications du const `settingsSections[]` — Réf: FR-015

**Checkpoint** : `flutter analyze` sans erreur. Les routes `/settings/appearance`, `/settings/features`, `/settings/notifications` n'existent plus dans le router.

---

## Phase 3 — User Stories (P1 → P2 → P3)

---

### US1 — Hub unifié scrollable (P1) 🎯 MVP

**Objectif** : Réécrire `settings_hub_screen.dart` comme hub intégré avec la structure de base et les sections Compte, Gestion, Administration.

**Test indépendant** : Ouvrir `/settings` → 7 sections visibles en scroll, liens Compte/Comptes/Catégories fonctionnels.

- [x] [T-021] [US1] Créer la structure de base du hub dans `flutter/lib/src/features/settings/presentation/settings_hub_screen.dart` : `ConsumerStatefulWidget`, `CustomScrollView` avec `SliverToBoxAdapter` par section, widgets privés `_SettingsSectionLabel` et `_SettingsRow` — Réf: FR-003
- [x] [T-022] [US1] Implémenter la section **Compte** : `CircleAvatar` 56px (image réseau ou initiales 2 chars uppercase), nom + email, `GestureDetector` → `/settings/profile` — Réf: FR-004 *(dépend T-021)*
- [x] [T-023] [US1] Implémenter la section **Gestion** : 3 `_SettingsRow` (Mon compte → `/settings/profile`, Comptes & Devises → `/settings/accounts`, Catégories → `/settings/categories`) — Réf: FR-005 *(dépend T-021)*
- [x] [T-024] [US1] Implémenter la section **Administration** conditionnelle : `_SettingsRow` Utilisateurs → `/settings/users`, visible si `userNotifierProvider.value?.isAdmin == true` — Réf: FR-006 *(dépend T-021)*

**Checkpoint** : Hub s'ouvre, 4 premières sections visibles, navigation Compte/Comptes/Catégories fonctionnelle, section Admin visible uniquement si admin.

---

### US2a — Apparence inline (P2)

**Objectif** : Thème 3 options + textScale 3 options inline dans le hub, application immédiate.

**Test indépendant** : Sélectionner chaque thème → app change immédiatement. Sélectionner chaque échelle → typographie change. Redémarrer → persistance vérifiée.

- [x] [T-031] [US2] Implémenter widget `_SegmentedThemePicker` dans le hub : 3 boutons (Clair / Sombre / Auto), sélection visuelle (border + bg teinté + checkCircle), `onTap` → `ref.read(themeNotifierProvider.notifier).setThemeMode(mode)` — Réf: FR-007, FR-008 *(dépend T-011, T-021)*
- [x] [T-032] [US2] Implémenter widget `_SegmentedScalePicker` + aperçu typographique dans le hub : 3 boutons (Petit / Normal / Grand), aperçu `fontSize = base * textScale.scaleFactor`, `onTap` → `ref.read(textScaleNotifierProvider.notifier).setTextScale(scale)` — Réf: FR-007 *(dépend T-021)*

**Checkpoint** : Thème Auto résout selon préférence système, textScale persiste après redémarrage.

---

### US2b — Features & Navigation inline (P2)

**Objectif** : Activer/désactiver modules et réordonner la barre de navigation inline dans le hub.

**Test indépendant** : Toggle Budgets → bottom nav mise à jour. Drag réorder → persiste après redémarrage. Désactiver Abonnements avec données → dialog confirmation.

- [x] [T-033] [US3] Implémenter les items verrouillés dans la section Navigation : `_NavFeatureItem` pour Accueil et Transactions, opacity 0.5, sans drag handle ni toggle — Réf: FR-010 *(dépend T-021)*
- [x] [T-034] [US3] Implémenter `ReorderableListView` features actives : `_NavFeatureItem` avec drag handle (`PhosphorIcons.dotsSixVertical`), `onReorder` → `_onReorder()` → `featureConfigNotifier.reorderNavigation(newOrder)`, `NeverScrollableScrollPhysics` pour éviter conflits scroll — Réf: FR-010 *(dépend T-033)*
- [x] [T-035] [US3] Implémenter la liste features désactivées : `_NavFeatureItem` opacity 0.5, `Switch` off, `onChanged` → `_onToggleFeature(feature, true)` — Réf: FR-010 *(dépend T-033)*
- [x] [T-036] [US3] Implémenter `_onToggleFeature` + `ConfirmDialog` : désactivation avec données existantes → `ConfirmDialog` ("Vos données seront masquées mais pas supprimées."), activation directe sans confirmation — Réf: FR-011 *(dépend T-034, T-035)*

**Checkpoint** : Drag-drop persiste. Dialog apparaît si données existantes. Items verrouillés non modifiables.

---

### US4 — Notifications inline (P3)

**Objectif** : Toggles notifications et sélecteur timezone inline, avec masquage conditionnel si feature désactivée.

**Test indépendant** : Désactiver toggle → préférence persistée. Désactiver feature Abonnements → toggle "Abonnements dus" disparaît.

- [x] [T-041] [US4] Implémenter les toggles notifications avec masquage conditionnel : `subscriptionDue` visible si `Feature.subscriptions` active, `debtDue` visible si `Feature.debts` active, `Switch` → `featureConfigNotifier.updateNotificationTypes(...)` — Réf: FR-009, FR-017 *(dépend T-021)*
- [x] [T-042] [US4] Implémenter le select timezone : `DropdownButton` avec 15 timezones hardcodées (liste Angular), valeur courante = `featureConfigState.timezone`, `onChange` → `featureConfigNotifier.updateTimezone(tz)` — Réf: FR-009 *(dépend T-041)*

**Checkpoint** : Toggle debtDue invisible si Feature.debts désactivée. Timezone persiste après redémarrage.

---

### US5 — Footer contextuel (P3)

**Objectif** : Footer affichant version + statut server (mode server) ou "Mode local" (mode local).

**Test indépendant** : Mode local → "K-Budget vX.Y.Z · Mode local" sans appel réseau. Mode server → statut health check affiché.

- [x] [T-043] [US5] Charger `PackageInfo` dans `initState` du hub : `PackageInfo.fromPlatform().then((info) => if (mounted) setState(() => _packageInfo = info))`, afficher `_packageInfo?.version ?? '...'` — Réf: FR-012, FR-016 *(dépend T-001, T-021)*
- [x] [T-044] [US5] Implémenter le footer **mode local** : widget `_buildFooter()` affiche "K-Budget v{version} · Mode local" si `DataMode.local`, style `AppTypography.bodyXSmall`, `AppColors.textTertiary`, centré — Réf: FR-014 *(dépend T-043)*
- [x] [T-045] [US5] Implémenter le footer **mode server** : `_runHealthCheck()` dans `initState` si `DataMode.server` (GET `/actuator/health`, timeout 10s, tout code != 200 ou exception → `HealthCheckResult.offline()`), afficher statut + latence avec couleur `AppColors.income`/`AppColors.expense`, guard `if (mounted)` — Réf: FR-013 *(dépend T-044)*

**Checkpoint** : Mode local : aucun appel réseau. Mode server : statut "Vérification…" → "En ligne · Xms" ou "Hors ligne".

---

## Phase 4 — Polish

**Objectif** : Vérifications transverses, robustesse et validation quickstart.

- [x] [T-051] [P] Vérifier la scrollabilité sur 375px (iPhone SE) : tester que toutes les sections sont accessibles sans overflow ni troncature — Réf: NFR-001
- [x] [T-052] [P] Audit `mounted` guards : vérifier que tous les callbacks async (`_runHealthCheck`, `PackageInfo.fromPlatform`) vérifient `if (mounted)` avant `setState` — Réf: NFR-005
- [x] [T-053] [P] Vérifier `NeverScrollableScrollPhysics` sur `ReorderableListView` : tester drag-and-drop dans un scroll parent sans conflit — Réf: NFR-003
- [ ] [T-054] Validation complète `quickstart.md` : exécuter les 5 scénarios de validation (hub, thème auto, footer, drag-drop, routes supprimées) et confirmer qu'ils passent

**Checkpoint** : `flutter analyze` sans warning. Tous les scénarios quickstart validés.

---

## Mapping Requirements → Tâches

| FR | Description courte | Tâches |
|----|-------------------|--------|
| FR-001 | Supprimer 3 sous-écrans | T-012 |
| FR-002 | Supprimer 3 routes + 6 constantes | T-013, T-014 |
| FR-003 | Structure hub intégré | T-021 |
| FR-004 | Section Compte | T-022 |
| FR-005 | Section Gestion | T-023 |
| FR-006 | Section Administration conditionnelle | T-024 |
| FR-007 | Section Apparence segmented controls | T-031, T-032 |
| FR-008 | ThemeNotifier + ThemeMode.system | T-011, T-031 |
| FR-009 | Section Notifications toggles + timezone | T-041, T-042 |
| FR-010 | Section Navigation drag-drop | T-033, T-034, T-035 |
| FR-011 | ConfirmDialog avant désactivation | T-036 |
| FR-012 | Footer version | T-043 |
| FR-013 | Footer mode server health check | T-045 |
| FR-014 | Footer mode local statique | T-044 |
| FR-015 | settings_section.dart nettoyage | T-015 |
| FR-016 | package_info_plus dépendance | T-001, T-043 |
| FR-017 | Masquage toggles notif si feature off | T-041 |

---

## Tableau résumé

| Phase | Tâches | Parallélisables | Priorité dominante |
|-------|--------|-----------------|-------------------|
| 1 — Setup | 1 | 0 | — |
| 2 — Fondations | 5 | 4 (T-011, T-012, T-014, T-015) | Bloquant |
| 3 — US1 P1 | 4 | 0 | P1 |
| 3 — US2a P2 | 2 | 0 | P2 |
| 3 — US2b P2 | 4 | 0 | P2 |
| 3 — US4 P3 | 2 | 0 | P3 |
| 3 — US5 P3 | 3 | 0 | P3 |
| 4 — Polish | 4 | 3 | — |
| **Total** | **25** | **7** | |

---

## Phase 5 — Dépendances & ordre d'exécution

### Graphe de dépendances

```
T-001 (pubspec)
  └── T-043 (PackageInfo)
        └── T-044 (footer local)
              └── T-045 (footer server)

T-011 (ThemeNotifier.system)
  └── T-031 (SegmentedThemePicker)

T-012 (suppr. fichiers) → T-013 (router cleanup)

T-014 (route_names) ─── indépendant
T-015 (settings_section) ─── indépendant

T-021 (structure hub)
  ├── T-022 (section Compte)
  ├── T-023 (section Gestion)
  ├── T-024 (section Admin)
  ├── T-031 (Apparence thème)  ← aussi T-011
  ├── T-032 (Apparence scale)
  ├── T-033 (nav locked items)
  │     ├── T-034 (ReorderableListView)
  │     │     └── T-036 (ConfirmDialog)
  │     └── T-035 (features off)
  │           └── T-036
  ├── T-041 (notif toggles)
  │     └── T-042 (timezone)
  └── T-043 (PackageInfo)
        └── T-044 → T-045
```

### Dépendances par User Story

| US | Tâches | Dépend de |
|----|--------|-----------|
| US1 P1 | T-021, T-022, T-023, T-024 | Phase 2 complète |
| US2a P2 | T-031, T-032 | T-011, T-021 |
| US2b P2 | T-033, T-034, T-035, T-036 | T-021 |
| US4 P3 | T-041, T-042 | T-021 |
| US5 P3 | T-043, T-044, T-045 | T-001, T-021 |

### Opportunités de parallélisme

| Groupe | Condition | Tâches |
|--------|-----------|--------|
| Fondations | Dès Phase 1 terminée | T-011, T-012, T-014, T-015 en parallèle |
| Post-hub structure | T-021 terminé | T-022, T-023, T-024, T-032, T-033, T-041, T-043 en parallèle |
| Polish | Phase 3 terminée | T-051, T-052, T-053 en parallèle |

---

## Implementation Strategy

### MVP First (US1 uniquement)

1. Phase 1 : T-001
2. Phase 2 : T-011 à T-015
3. Phase 3 US1 : T-021 → T-022, T-023, T-024
4. **STOP et VALIDER** : hub s'ouvre, sections Compte/Gestion/Admin fonctionnelles
5. Sections Apparence/Navigation/Notifications/Footer = empty containers pour l'instant

### Livraison incrémentale recommandée

1. Setup + Fondations → router propre, analyzer sans erreur
2. US1 → hub navigable (Compte, Gestion, Admin)
3. US2a + US2b → Apparence + Features/Nav inline fonctionnels
4. US4 + US5 → Notifications + Footer
5. Polish → validation quickstart complète
