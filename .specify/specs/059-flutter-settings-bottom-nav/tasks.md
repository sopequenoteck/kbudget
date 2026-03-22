# Tasks: Configuration de la navigation — Flutter

**Input**: Design documents from `/specs/059-flutter-settings-bottom-nav/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Unit test du notifier (T013) et widget test de la section Navigation (T014) ajoutés en Phase 6 — Constitution V (Testabilité).

**Organization**: Tasks groupées par user story pour permettre l'implémentation et les tests indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts dans les descriptions

## Phase 1: Foundational — navOrder dans toute la stack

**Purpose**: Infrastructure complète pour `navOrder` : domain → data → application. DOIT être terminé avant toute user story.

**Pourquoi bloquant**: Les US1-US4 dépendent toutes de `navOrder` dans le state Riverpod. Sans cette fondation, ni le drag & drop, ni la preview, ni la persistence, ni la navigation ne peuvent fonctionner.

- [X] T001 [P] Ajouter le getter `outlinedIcon` au Feature enum dans `flutter/lib/src/domain/enums/feature.dart` — retourne `Icons.autorenew_outlined` (subscriptions), `Icons.handshake_outlined` (debts), `Icons.storefront_outlined` (shop), en suivant le pattern existant des getters `icon`, `label`, `description`
- [X] T002 [P] Ajouter le champ `navOrder` (`@Default(Feature.values) List<Feature> navOrder`) au modèle Freezed `AppConfig` dans `flutter/lib/src/domain/models/app_config.dart` — contient TOUTES les features (activées et désactivées) pour conserver l'ordre même après désactivation. Ajouter un `@JsonKey(fromJson: _safeParseNavOrder)` avec une fonction privée top-level qui filtre les valeurs enum inconnues lors de la désérialisation JSON : retourner `Feature.values.toList()` si null/vide, sinon ne garder que les entrées correspondant à un `Feature.name` valide via `Feature.values.where((f) => f.name == e).firstOrNull` — protège contre les downgrades d'app (cf. edge case 4 spec)
- [X] T003 [P] Ajouter les méthodes abstraites `Future<List<Feature>> getNavOrder()` et `Future<void> setNavOrder(List<Feature> order)` à `AppConfigRepository` dans `flutter/lib/src/domain/repositories/app_config_repository.dart`
- [X] T004 Exécuter `build_runner` pour régénérer les fichiers Freezed/JSON de `AppConfig` (`cd flutter && dart run build_runner build --delete-conflicting-outputs`)
- [X] T005 Implémenter `getNavOrder()` et `setNavOrder()` dans `AppConfigRepositoryImpl` dans `flutter/lib/src/features/onboarding/data/app_config_repository_impl.dart` — suivre le pattern existant de `getEnabledFeatures()`/`setEnabledFeatures()` : lire/écrire via `getConfig()`/`saveConfig(config.copyWith(navOrder: order))`
- [X] T006 Modifier `FeatureConfigNotifier` dans `flutter/lib/src/features/settings/application/feature_config_notifier.dart` : (1) ajouter `@Default(Feature.values) List<Feature> navOrder` à `FeatureConfigState`, (2) dans `_loadFeatures()` charger navOrder via `repo.getNavOrder()` et mettre à jour le state, (3) dans `_loadFromServer()` lire `prefs.navOrder` et le persister localement via `repo.setNavOrder()`, (4) ajouter `Future<void> reorderNavigation(List<Feature> newOrder)` qui met à jour state, persiste localement, et sync serveur (fire-and-forget avec `unawaited`), (5) dans `_syncToServer()` inclure `navOrder` dans le `UserPreferenceRequest`
- [X] T007 Exécuter `build_runner` pour régénérer les fichiers Freezed de `FeatureConfigState` (`cd flutter && dart run build_runner build --delete-conflicting-outputs`)

**Checkpoint**: navOrder est chargé, persisté et synchronisé. Le state Riverpod expose `navOrder`. Prêt pour les user stories.

---

## Phase 2: User Story 1 — Réordonner les onglets par drag & drop (Priority: P1) — MVP

**Goal**: L'utilisateur peut réordonner les onglets optionnels de la barre de navigation via une section "Navigation" avec drag & drop dans la page Fonctionnalités des paramètres.

**Independent Test**: Ouvrir la page, vérifier que le noyau fixe est grisé et non déplaçable, glisser une feature activée vers une autre position, vérifier que l'ordre change dans la liste.

### Implementation

- [X] T008 [US1] Modifier `FeatureSettingsScreen` dans `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` : (1) renommer le titre AppBar de "Fonctionnalités" à "Fonctionnalités & Navigation", (2) ajouter une section "Navigation" sous la section "Modules" existante avec un titre stylé identique ("Navigation"), (3) afficher le noyau fixe (Dashboard avec Icons.home, Transactions avec Icons.receipt_long) en `ListTile` grisés (opacity réduite ou `colorScheme.outline`) non interactifs, (4) afficher les features activées (filtrées depuis `state.navOrder.where(state.enabledFeatures.contains)`) dans un `ReorderableListView.builder` avec drag handle (`Icons.drag_handle`), icône dans CircleAvatar, et libellé, (5) `onReorder` appelle `ref.read(featureConfigNotifierProvider.notifier).reorderNavigation(newOrder)` — le ReorderableListView ne contient que les features activées ; après reorder, reconstruire la liste complète navOrder en prenant le nouvel ordre des activées et en conservant les features désactivées à leur position relative dans l'ancien navOrder, (6) si aucune feature activée : afficher un message "Activez des fonctionnalités pour personnaliser la navigation" en texte secondaire, (7) le widget doit être `ConsumerStatefulWidget` si nécessaire pour gérer le state local du ReorderableListView, (8) écouter `state.error` : si non null après un reorder, afficher un `SnackBar` avec le message d'erreur de synchronisation (ex: "Synchronisation échouée") puis réinitialiser l'erreur

**Checkpoint**: Le drag & drop fonctionne, le noyau fixe est non déplaçable, l'ordre se met à jour visuellement. FR-001, FR-002, FR-003, FR-004, FR-011, FR-012 couverts.

---

## Phase 3: User Story 2 — Preview du Bottom Nav résultant (Priority: P1)

**Goal**: Une preview visuelle de la barre de navigation résultante est affichée en bas de la section Navigation, reflétant l'ordre actuel.

**Independent Test**: Vérifier que la preview affiche les bons onglets dans le bon ordre (noyau + features ordonnées), réordonner et vérifier la mise à jour instantanée.

### Implementation

- [X] T009 [US2] Ajouter la preview du Bottom Nav en bas de la section Navigation dans `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` : (1) créer un widget privé `_BottomNavPreview` qui prend `List<Feature> orderedEnabledFeatures` en paramètre, (2) le widget construit une rangée simulant un `BottomNavigationBar` : d'abord les items du noyau fixe (Accueil avec Icons.home_outlined, Transactions avec Icons.receipt_long_outlined), puis les features ordonnées (utiliser `feature.outlinedIcon` et `feature.label`), (3) chaque item est une colonne (icône + texte) avec style `theme.colorScheme.onSurfaceVariant`, (4) conteneur avec `decoration` imitant le bottom nav (background surface, elevation/shadow subtile, border-top), (5) intégrer le widget dans le ListView après le ReorderableListView avec un espacement `AppSpacing.space6`, (6) la preview lit directement le state du provider donc se met à jour automatiquement à chaque reorder

**Checkpoint**: La preview reflète l'ordre exact du bottom nav. FR-005, FR-006 couverts. Note SC-002 : le critère "< 500ms" est garanti par le mécanisme Riverpod (rebuild synchrone du widget `_BottomNavPreview` à chaque changement de state) — aucune mesure de performance explicite nécessaire.

---

## Phase 4: User Story 3 — Persistance automatique de l'ordre (Priority: P2)

**Goal**: L'ordre est sauvegardé automatiquement à chaque modification, restauré au redémarrage, et synchronisé avec le serveur.

**Independent Test**: Réordonner, quitter et revenir sur la page — l'ordre est conservé. Fermer et rouvrir l'app — l'ordre est restauré.

**Note**: Cette user story est **entièrement couverte par la Phase 1 (Foundational)**. Le `FeatureConfigNotifier.reorderNavigation()` (T006) gère déjà : mise à jour du state → persistance locale (`AppConfigRepository.setNavOrder`) → sync serveur (`_syncToServer` avec navOrder dans le request). Le chargement au démarrage est couvert par `_loadFeatures()` (local) et `_loadFromServer()` (serveur). Aucune tâche d'implémentation supplémentaire nécessaire.

**Checkpoint**: FR-007, FR-008, FR-009 couverts par T005 et T006.

---

## Phase 5: User Story 4 — Impact immédiat sur la vraie barre de navigation (Priority: P2)

**Goal**: La barre de navigation de l'application reflète immédiatement le nouvel ordre personnalisé sans rechargement.

**Independent Test**: Réordonner les onglets dans les paramètres, naviguer en arrière, vérifier que le bottom nav réel affiche le nouvel ordre.

### Implementation

- [X] T010 [US4] Modifier `_ShellScaffold` dans `flutter/lib/src/routing/app_router.dart` (lignes 289-333) : remplacer l'ajout conditionnel hardcodé des features (3 blocs `if enabledFeatures.contains`) par une boucle sur `navOrder` filtré — (1) lire `featureState.navOrder` en plus de `featureState.enabledFeatures`, (2) calculer `orderedEnabled = navOrder.where(enabledFeatures.contains)`, (3) pour chaque feature dans orderedEnabled, ajouter le path et la destination correspondants (utiliser un map/switch sur Feature pour retrouver RouteNames et NavDestination), (4) conserver le noyau fixe (Dashboard + Transactions) en positions 0 et 1 inchangées, (5) gérer les features absentes de navOrder (les ajouter en fin de liste)

**Checkpoint**: Le bottom nav réel reflète l'ordre personnalisé. FR-010 couvert.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finitions et vérifications transverses.

- [X] T011 Mettre à jour le titre et la description de la section "Fonctionnalités" dans `flutter/lib/src/features/settings/domain/settings_section.dart` : changer `title: 'Fonctionnalités'` en `'Fonctionnalités & Navigation'` et `description: 'Activer/désactiver les modules'` en `'Modules et ordre de navigation'`
- [X] T012 [P] Écrire le unit test de `FeatureConfigNotifier.reorderNavigation()` dans `flutter/test/src/features/settings/application/feature_config_notifier_reorder_test.dart` — suivre le pattern existant (ProviderContainer + overrides pour mocker `AppConfigRepository` et `PreferenceRemoteDataSource`) : (1) `should_update_navOrder_when_reorderNavigation_called` — appeler `reorderNavigation([shop, subscriptions, debts])`, vérifier que `state.navOrder` reflète le nouvel ordre, (2) `should_persist_navOrder_locally_when_reordering` — vérifier que `setNavOrder()` est appelé avec le bon ordre, (3) `should_preserve_disabled_features_position_when_reordering_enabled_only` — activer seulement [subscriptions, debts], réordonner en [debts, subscriptions], vérifier que shop conserve sa position relative dans navOrder complet, (4) `should_include_navOrder_in_server_sync` — vérifier que `updatePreferences()` est appelé avec navOrder dans le request (mode serveur)
- [X] T013 [P] Écrire le widget test de la section Navigation dans `flutter/test/src/features/settings/presentation/feature_settings_navigation_test.dart` — utiliser `ProviderScope` + `MaterialApp.router` + `AppTheme.light` : (1) `should_display_core_items_as_non_draggable` — vérifier que Dashboard et Transactions sont affichés grisés sans drag handle, (2) `should_display_enabled_features_with_drag_handle` — activer [subscriptions, debts], vérifier la présence de `Icons.drag_handle` et des labels, (3) `should_display_empty_message_when_no_features_enabled` — désactiver toutes les features, vérifier le message "Activez des fonctionnalités...", (4) `should_display_preview_with_correct_order` — vérifier que la preview `_BottomNavPreview` affiche Accueil + Transactions + features activées dans l'ordre de navOrder
- [X] T014 Exécuter `flutter analyze` et `flutter test` depuis `flutter/` pour vérifier l'absence de régressions et d'erreurs statiques

**Checkpoint**: Analyse statique propre, tous les tests (existants + nouveaux) passent, libellés cohérents.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Aucune dépendance — commence immédiatement. BLOQUE toutes les user stories.
- **US1 (Phase 2)**: Dépend de Phase 1 (T007). Modifie `feature_settings_screen.dart`.
- **US2 (Phase 3)**: Dépend de Phase 2 (T008). Modifie le même fichier (`feature_settings_screen.dart`).
- **US3 (Phase 4)**: Couvert par Phase 1 — pas de tâche supplémentaire.
- **US4 (Phase 5)**: Dépend de Phase 1 (T007). Modifie `app_router.dart`. **Peut être parallélisé avec Phase 2/3**.
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes. T012 et T013 (tests) parallélisables entre eux, dépendent de T009. T014 (analyse + tests) dépend de T012 + T013.

### User Story Dependencies

```
Phase 1 (Foundation)
  ├──► Phase 2 (US1) ──► Phase 3 (US2)
  └──► Phase 5 (US4)     ← parallélisable avec US1/US2
Phase 4 (US3) = couvert par Phase 1
Phase 6 (Polish) = après tout
```

### Within Each Phase

- T001, T002, T003 sont parallélisables (fichiers différents)
- T004 dépend de T002
- T005 dépend de T003 + T004
- T006 dépend de T005
- T007 dépend de T006
- T008 dépend de T007
- T009 dépend de T008 (même fichier)
- T010 dépend de T007 (pas de T008/T009 — fichier différent)
- T011 indépendant (fichier séparé)
- T012 dépend de T009 (teste le notifier qui inclut reorder)
- T013 dépend de T009 (teste le widget navigation + preview)
- T012 + T013 parallélisables (fichiers de test différents)
- T014 dépend de tout (T012 + T013 inclus)

### Parallel Opportunities

- **T001 + T002 + T003** : 3 fichiers différents, aucune dépendance mutuelle
- **T008 (US1) + T010 (US4)** : fichiers différents (`feature_settings_screen.dart` vs `app_router.dart`), même dépendance (T007)
- **T010 (US4) + T011 (Polish)** : fichiers différents
- **T012 (test notifier) + T013 (test widget)** : fichiers de test différents, même dépendance (T009)

---

## Parallel Example: Foundation

```bash
# Lancer en parallèle (3 fichiers différents) :
Task T001: "outlinedIcon getter dans flutter/lib/src/domain/enums/feature.dart"
Task T002: "navOrder field dans flutter/lib/src/domain/models/app_config.dart"
Task T003: "getNavOrder/setNavOrder dans flutter/lib/src/domain/repositories/app_config_repository.dart"
```

## Parallel Example: US1 + US4

```bash
# Après T007, lancer en parallèle (2 fichiers différents) :
Task T008: "Section Navigation + ReorderableListView dans feature_settings_screen.dart"
Task T010: "_ShellScaffold navOrder dans app_router.dart"
```

---

## Implementation Strategy

### MVP First (US1 uniquement)

1. Complete Phase 1: Foundational (T001-T007)
2. Complete Phase 2: US1 — Drag & drop (T008)
3. **STOP and VALIDATE**: La section Navigation est fonctionnelle, le drag & drop réordonne les features.
4. L'ordre est déjà persisté (US3 couvert par foundation).

### Incremental Delivery

1. Foundation (Phase 1) → navOrder dans toute la stack
2. + US1 (Phase 2) → Drag & drop fonctionnel → **MVP livrable**
3. + US2 (Phase 3) → Preview visuelle → feedback immédiat
4. + US4 (Phase 5) → Bottom nav réel reflète l'ordre → **feature complète**
5. + Polish (Phase 6) → Libellés, tests, analyse statique → **prêt pour merge**

### Scope suggéré MVP

**US1 seule** = section Navigation avec drag & drop + persistance automatique (héritée de la foundation). L'utilisateur peut déjà réordonner et l'ordre est sauvegardé. La preview et l'impact sur le vrai nav viennent après.

---

## Notes

- [P] tasks = fichiers différents, pas de dépendance
- US3 (persistance) est intégralement couvert par la Phase 1 — aucune tâche séparée
- 2 exécutions de `build_runner` nécessaires (après AppConfig et après FeatureConfigState)
- Commiter après chaque phase ou groupe logique de tâches
- S'arrêter à chaque checkpoint pour valider la story indépendamment
- T002 inclut un `@JsonKey(fromJson:)` pour filtrer les valeurs enum inconnues dans navOrder (edge case 4 : downgrade app)
- T012 + T013 ajoutés pour conformité Constitution V (Testabilité) — unit test notifier + widget test navigation
- SC-002 (preview < 500ms) garanti par le mécanisme Riverpod — documenté au checkpoint Phase 3
