# Tasks: Page Fonctionnalités (Feature Toggles) — Flutter

**Input**: Design documents from `/specs/058-flutter-settings-features/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/preferences-api.md

**Tests**: Non demandés explicitement dans la spec. Non inclus.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts depuis la racine du projet

## Path Conventions

- **Flutter**: `flutter/lib/src/` pour le code source
- **Tests**: `flutter/test/src/` pour les tests

---

## Phase 1: Setup (Enum & Modèle)

**Purpose**: Créer l'enum Feature et étendre AppConfig pour la persistance locale

- [X] T001 [P] Create Feature enum with JSON serialization in `flutter/lib/src/domain/enums/feature.dart` — 3 valeurs (subscriptions, debts, shop) avec `@JsonValue('SUBSCRIPTIONS')` etc. Ajouter les propriétés metadata : `label` (String), `icon` (IconData), `description` (String), `defaultEnabled` (bool). Cf. data-model.md pour les valeurs exactes.
- [X] T002 [P] Export Feature enum in barrel file `flutter/lib/src/domain/enums/enums.dart` — ajouter `export 'feature.dart';`
- [X] T003 [P] Add `enabledFeatures` field to AppConfig in `flutter/lib/src/domain/models/app_config.dart` — champ `@Default([Feature.subscriptions, Feature.debts]) List<Feature> enabledFeatures`. Importer le nouvel enum.
- [X] T004 Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` to regenerate Freezed/JSON files for AppConfig

---

## Phase 2: Foundational (Persistance & Notifier)

**Purpose**: Infrastructure de persistance locale et state management — BLOQUE toutes les user stories

**CRITICAL**: Aucune user story ne peut commencer avant cette phase

- [X] T005 Add getter/setter for enabledFeatures in `flutter/lib/src/domain/repositories/app_config_repository.dart` — `Future<List<Feature>> getEnabledFeatures()` et `Future<void> setEnabledFeatures(List<Feature> features)`
- [X] T006 Implement getter/setter in `flutter/lib/src/features/onboarding/data/app_config_repository_impl.dart` — pattern read → copyWith → save identique aux autres setters
- [X] T007 Create FeatureConfigNotifier and FeatureConfigState in `flutter/lib/src/features/settings/application/feature_config_notifier.dart` — Freezed state avec `enabledFeatures`, `isLoading`, `error`. Notifier avec `build()` (défaut synchrone + `_loadFeatures()` fire-and-forget), `toggleFeature(Feature)`, `isEnabled(Feature)`. Persistance locale via `appConfigRepositoryProvider`. Exposer `featureConfigNotifierProvider`.
- [X] T008 Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` to regenerate Freezed files for FeatureConfigState
- [X] T009 [P] Add route constants in `flutter/lib/src/routing/route_names.dart` — `settingsFeatures = 'features'` (relatif) et `shop = '/shop'` (absolu pour le ShellRoute)
- [X] T010 [P] Add "Fonctionnalités" section in `flutter/lib/src/features/settings/domain/settings_section.dart` — nouvelle entrée dans `settingsSections` list, groupe `general`, icône `Icons.toggle_on`, route `/settings/features`, avant la section Apparence
- [X] T011 Add GoRoute for feature settings in `flutter/lib/src/routing/app_router.dart` — sous le noeud `/settings`, path `RouteNames.settingsFeatures`, builder → `FeatureSettingsScreen()`

**Checkpoint**: Fondation prête — le notifier fonctionne, la route existe, les user stories peuvent commencer

---

## Phase 3: User Story 1 - Activer/désactiver des fonctionnalités (Priority: P1) MVP

**Goal**: Page Fonctionnalités accessible depuis Settings avec 3 toggles fonctionnels et persistance locale

**Independent Test**: Ouvrir Settings > Fonctionnalités, basculer un toggle, quitter et revenir — l'état est restauré

### Implementation for User Story 1

- [X] T012 [US1] Create FeatureSettingsScreen in `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` — ConsumerWidget, Scaffold + AppBar("Fonctionnalités") + ListView. Pour chaque `Feature.values` : SwitchListTile avec icône (cercle coloré), titre (label), sous-titre (description), switch lié à `featureConfigNotifierProvider`. Le toggle appelle `notifier.toggleFeature(feature)`. Pattern visuel identique à appearance_settings_screen.dart (padding AppSpacing.space4, titres titleSmall).

**Checkpoint**: US1 fonctionnel — toggles marchent, état persisté localement, page accessible depuis le hub Settings

---

## Phase 4: User Story 2 - Impact immédiat sur la navigation (Priority: P1)

**Goal**: La bottom nav et le FAB reflètent immédiatement les features activées

**Independent Test**: Désactiver "Abonnements" → l'onglet disparaît de la bottom nav et du FAB instantanément

### Implementation for User Story 2

- [X] T013 [US2] Refactor AdaptiveScaffold to accept dynamic destinations in `flutter/lib/src/common_widgets/adaptive_scaffold.dart` — rendre la classe `_Destination` publique (renommer en `NavDestination`, déplacer hors du underscore). Remplacer `static const List<_Destination> _destinations` par un paramètre `required List<NavDestination> destinations` passé au constructeur. Le widget n'est plus responsable de la liste des destinations — il la reçoit. Adapter `_buildNarrowLayout` et `_buildWideLayout` pour utiliser `widget.destinations` au lieu du static const.
- [X] T014 [US2] Refactor _ShellScaffold for dynamic nav in `flutter/lib/src/routing/app_router.dart` — faire du `_ShellScaffoldState` un `ConsumerState`. Watch `featureConfigNotifierProvider`. Construire dynamiquement `_paths` et `_destinations` : noyau permanent (Dashboard, Transactions) + features activées (SUBSCRIPTIONS → /subscriptions, DEBTS → /debts, SHOP → /shop). Passer les destinations à AdaptiveScaffold. Calculer `currentIndex` sur la liste dynamique. Si la route courante n'est plus dans `_paths` → `context.go(RouteNames.dashboard)`.
- [X] T015 [US2] Add /shop route and redirect guard in `flutter/lib/src/routing/app_router.dart` — ajouter `/shop` dans les routes du ShellRoute (builder → placeholder screen avec titre "Boutique" et "À venir"). Ajouter dans le redirect global : si la route est `/subscriptions`, `/debts`, ou `/shop` et que la feature correspondante est désactivée → redirect `/dashboard`.
- [X] T016 [P] [US2] Filter FabMenu items by enabled features in `flutter/lib/src/common_widgets/fab_menu.dart` — FabMenu est déjà un ConsumerStatefulWidget. Ajouter un watch sur `featureConfigNotifierProvider` dans `build()`. Filtrer `_allItems` dynamiquement : masquer "Abonnement" si SUBSCRIPTIONS OFF, "Dette" si DEBTS OFF. Conserver "Transaction" et "Virement" (noyau permanent).

**Checkpoint**: US2 fonctionnel — la nav reflète les toggles, le FAB est filtré, les routes désactivées redirigent vers Dashboard

---

## Phase 5: User Story 3 - Synchronisation serveur (Priority: P2)

**Goal**: En mode serveur, les préférences sont chargées depuis l'API et synchronisées lors des modifications

**Independent Test**: En mode serveur, modifier un toggle → vérifier que le serveur reçoit la mise à jour (PUT) et que le GET au rechargement retourne l'état correct

### Implementation for User Story 3

- [X] T017 [P] [US3] Create UserPreferenceResponse DTO in `flutter/lib/src/data/remote/dtos/user_preference_response.dart` — Freezed + json_serializable. Champs : `enabledFeatures` (List\<Feature\>), `navOrder` (List\<Feature\>), `shopAccountId` (String?), `includeShopInBalance` (bool). Cf. contracts/preferences-api.md.
- [X] T018 [P] [US3] Create UserPreferenceRequest DTO in `flutter/lib/src/data/remote/dtos/user_preference_request.dart` — Freezed + json_serializable. Champs : `enabledFeatures` (List\<Feature\>), `navOrder` (List\<Feature\>?), `shopAccountId` (String?), `includeShopInBalance` (bool?). Cf. contracts/preferences-api.md.
- [X] T019 [US3] Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` to regenerate Freezed/JSON files for DTOs
- [X] T020 [US3] Create PreferenceRemoteDataSource in `flutter/lib/src/data/remote/data_sources/preference_remote_data_source.dart` — Dio-based, pattern identique à AccountRemoteDataSource. Méthodes : `getPreferences()` → GET `/users/me/preferences` → UserPreferenceResponse, `updatePreferences(UserPreferenceRequest)` → PUT `/users/me/preferences` → UserPreferenceResponse. Exposer un provider `preferenceRemoteDataSourceProvider`.
- [X] T021 [US3] Add server sync logic to FeatureConfigNotifier in `flutter/lib/src/features/settings/application/feature_config_notifier.dart` — dans `build()`: si mode serveur (via `dataModeProvider`) → appeler `_loadFromServer()` (GET preferences, écraser state + AppConfig local). Dans `toggleFeature()`: après persist local, si mode serveur → PUT en arrière-plan (fire-and-forget, optimiste). En cas d'échec PUT → set `error` dans state (snackbar dans le screen). Ne pas rollback le state local.

**Checkpoint**: US3 fonctionnel — les préférences sont synchronisées avec le serveur en mode serveur

---

## Phase 6: User Story 4 - Confirmation avant désactivation (Priority: P3)

**Goal**: Dialogue de confirmation avant désactivation d'une feature contenant des données existantes

**Independent Test**: Avoir des abonnements créés → désactiver "Abonnements" → un dialogue de confirmation apparaît

### Implementation for User Story 4

- [X] T022 [US4] Add confirmation dialog logic to FeatureSettingsScreen in `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` — avant d'appeler `toggleFeature()` pour une désactivation, vérifier l'existence de données via les providers existants : SUBSCRIPTIONS → `subscriptionListNotifierProvider` (state.items.isNotEmpty), DEBTS → `debtListNotifierProvider` (state.items.isNotEmpty), SHOP → toujours false (pas de provider products Flutter). Si le state n'est pas encore chargé (items vide par lazy loading), considérer comme "pas de données" (éviter un appel réseau bloquant). Si données existent → `showDialog` avec titre "Désactiver {feature.label} ?", message "Vos données seront masquées mais pas supprimées. Vous pourrez les retrouver en réactivant cette fonctionnalité.", boutons "Annuler" / "Désactiver". Si confirmé → toggle. Si annulé → rien. Si pas de données → toggle direct.

**Checkpoint**: US4 fonctionnel — le dialogue protège les données existantes

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [X] T023 Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` — build final pour s'assurer que tout est généré
- [X] T024 Run `flutter analyze` in `flutter/` — vérifier aucun warning/error
- [X] T025 Validate quickstart.md scenarios — parcourir les 5 étapes de vérification rapide manuellement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut démarrer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2
- **US2 (Phase 4)**: Dépend de Phase 2 (+ US1 pour le test intégré, mais indépendamment implémentable)
- **US3 (Phase 5)**: Dépend de Phase 2 (+ US1 pour le test intégré)
- **US4 (Phase 6)**: Dépend de US1 (Phase 3) — ajoute le dialogue à l'écran existant
- **Polish (Phase 7)**: Dépend de toutes les phases

### User Story Dependencies

- **US1 (P1)**: Après Phase 2 — aucune dépendance sur d'autres stories
- **US2 (P1)**: Après Phase 2 — implémentable en parallèle avec US1 (fichiers différents)
- **US3 (P2)**: Après Phase 2 — implémentable en parallèle avec US1/US2 (fichiers différents sauf T021 qui modifie feature_config_notifier.dart)
- **US4 (P3)**: Après US1 — modifie le même fichier (feature_settings_screen.dart)

### Within Each User Story

- Modèles/DTOs avant services/datasources
- Services avant écrans
- Code generation (build_runner) après chaque ajout Freezed

### Parallel Opportunities

- T001, T002, T003 — Phase 1 : fichiers différents, parallélisables
- T009, T010 — Phase 2 : fichiers différents, parallélisables
- T013 (AdaptiveScaffold) et T016 (FabMenu) — US2 : fichiers différents, parallélisables
- T017 et T018 — US3 : fichiers différents, parallélisables
- US1 et US2 — phases entières parallélisables (fichiers différents sauf T014 qui est dans app_router)

---

## Parallel Example: User Story 3

```bash
# DTOs en parallèle (fichiers différents) :
T017: Create UserPreferenceResponse in dtos/user_preference_response.dart
T018: Create UserPreferenceRequest in dtos/user_preference_request.dart

# Puis séquentiellement :
T019: build_runner (dépend de T017 + T018)
T020: PreferenceRemoteDataSource (dépend de T019)
T021: Sync logic dans notifier (dépend de T020)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001-T004)
2. Phase 2: Foundational (T005-T011)
3. Phase 3: US1 (T012)
4. **STOP et VALIDER**: Ouvrir Settings > Fonctionnalités, toggler, fermer/rouvrir → état restauré
5. Commit et démo si prêt

### Incremental Delivery

1. Setup + Foundational → infrastructure prête
2. US1 → page toggles fonctionnelle (MVP)
3. US2 → navigation dynamique (valeur visible immédiate)
4. US3 → sync serveur (cohérence multi-device)
5. US4 → dialogue de confirmation (sécurité UX)
6. Chaque story ajoute de la valeur sans casser les précédentes

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [US*] = rattachement à la user story
- Commit après chaque phase ou groupe logique
- `build_runner` nécessaire après chaque ajout de classe Freezed
- Penser à vérifier `/sync-doc` après commit
