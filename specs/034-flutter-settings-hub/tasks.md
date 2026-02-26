# Tasks: Settings Hub Flutter

**Input**: Design documents from `/specs/034-flutter-settings-hub/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus (SC-004 exige 100% des tests unitaires passants).

**Organization**: Tasks groupées par user story. US1 et US5 sont P1 (MVP), US2/US3 sont P2, US4 est P3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins relatifs à `flutter/`

---

## Phase 1: Setup

**Purpose**: Modèles de domaine, infrastructure partagée, constantes de routes

- [x] T001 [P] Create SettingsGroup enum and SettingsSection model with static sections list (7 items, 3 groupes) in `flutter/lib/src/features/settings/domain/settings_section.dart` — see data-model.md for fields and static data
- [x] T002 [P] Create RestartWidget wrapper (StatefulWidget with UniqueKey pattern to rebuild entire widget tree including ProviderScope) in `flutter/lib/src/common_widgets/restart_widget.dart` — see research.md R2
- [x] T003 [P] Add settings sub-route constants (settingsProfile, settingsAppearance, settingsAccounts, settingsCategories, settingsData) with paths and names to `flutter/lib/src/routing/route_names.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Widgets et écrans de base nécessaires avant toute user story

**Dépend de**: Phase 1 complète

- [x] T004 Create SettingsItem widget in `flutter/lib/src/features/settings/presentation/widgets/settings_item.dart` — Widget StatelessWidget avec: IconData icon dans un cercle coloré (Container + BoxDecoration), titre, description (max 2 lignes, ellipsis), chevron trailing pour items actifs, badge "À venir" pour placeholders (opacité réduite, pas d'InkWell), Semantics (button pour actifs, label avec "À venir" pour placeholders), utilisant uniquement les design tokens (AppSpacing, AppRadius, colorScheme)
- [x] T005 [P] Create StubSettingsScreen (generic placeholder for unimplemented sub-pages) in `flutter/lib/src/features/settings/presentation/stub_settings_screen.dart` — Scaffold avec AppBar affichant le titre passé en paramètre, body centré avec texte "À venir", bouton retour standard
- [x] T006 Wrap ProviderScope with RestartWidget in `flutter/lib/main.dart` — RestartWidget doit envelopper ProviderScope pour permettre la reconstruction complète de l'arbre au restart

**Checkpoint**: Widgets de base prêts — l'implémentation des user stories peut commencer

---

## Phase 3: User Story 1 — Navigation vers une section de réglages active (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur voit 7 items groupés par section et peut naviguer vers chaque sous-page active au tap.

**Independent Test**: Afficher le hub et vérifier que chaque carte active navigue vers la bonne route (5 routes: profile, appearance, accounts, categories, data).

### Implementation for User Story 1

- [x] T007 [US1] Create SettingsHubScreen in `flutter/lib/src/features/settings/presentation/settings_hub_screen.dart` — ConsumerWidget avec Scaffold, AppBar titre "Réglages", ListView.builder affichant les sections groupées par SettingsGroup (titre de groupe en Text avec style titleSmall + couleur primaire, puis SettingsItem pour chaque section du groupe), onTap appelle context.push(section.route) pour les items actifs, padding EdgeInsets.all(AppSpacing.space4)
- [x] T008 [US1] Update AppRouter in `flutter/lib/src/routing/app_router.dart` — Remplacer le builder SettingsScreen par SettingsHubScreen, ajouter 5 child GoRoutes sous /settings: profile, appearance, accounts, categories → StubSettingsScreen avec titre; data → StubSettingsScreen temporaire (remplacé en US5). Supprimer l'import de settings_screen.dart, ajouter les imports nécessaires
- [x] T009 [US1] Delete old settings_screen.dart in `flutter/lib/src/features/settings/presentation/settings_screen.dart` — Fichier remplacé par settings_hub_screen.dart, plus aucun import
- [x] T010 [US1] Widget tests for SettingsHubScreen in `flutter/test/src/features/settings/presentation/settings_hub_screen_test.dart` — Tests: (1) affiche 7 items avec titres corrects, (2) affiche 3 titres de groupes (Général, Gestion, Autre), (3) tap sur item "Comptes" navigue vers /settings/accounts, (4) tap sur item "Profil" navigue vers /settings/profile, (5) tap sur item placeholder ne navigue pas. Utiliser ProviderScope + MaterialApp.router avec GoRouter mock

**Checkpoint**: Le hub settings est fonctionnel — navigation vers 5 sous-pages (stubs) au premier tap

---

## Phase 4: User Story 5 — Changement de source de données (Priority: P1)

**Goal**: L'utilisateur accède à la sous-page Données, voit la source active, peut saisir/modifier l'URL serveur, et basculer entre local et serveur avec dialog de confirmation et redémarrage.

**Independent Test**: Ouvrir /settings/data, vérifier l'affichage de la source active, le champ URL, la validation, le dialog de confirmation, et le mécanisme de restart.

### Implementation for User Story 5

- [x] T011 [US5] Create DataSettingsNotifier in `flutter/lib/src/features/settings/application/data_settings_notifier.dart` — Riverpod AsyncNotifier exposant: dataMode (DataMode), serverUrl (String?), isLoading (bool), error (String?). Méthodes: loadConfig() depuis appConfigRepositoryProvider, validateUrl(String url) → bool (schéma https:// requis, ou http:// si EnvConfig.isDev), checkConnectivity(String url) → Future<bool> (réutiliser le pattern de OnboardingNotifier.checkServerConnectivity), saveServerUrl(String url) → persiste via appConfigRepositoryProvider.setServerUrl, switchDataMode(DataMode newMode) → sauvegarde via appConfigRepositoryProvider.setDataMode puis déclenche RestartWidget.restartApp(context)
- [x] T012 [US5] Create DataSettingsScreen in `flutter/lib/src/features/settings/presentation/data_settings_screen.dart` — ConsumerStatefulWidget avec Scaffold, AppBar titre "Données", body: (1) Section source active avec SegmentedButton<DataMode> local/serveur, (2) TextField pour URL serveur (pré-rempli depuis notifier, enabled toujours, validation en temps réel), (3) Bouton sauvegarder URL, (4) Dialog de confirmation AlertDialog au changement de mode: titre "Changer de source ?", body expliquant l'indépendance des sources et le redémarrage, boutons Annuler/Confirmer, (5) Message d'erreur si serveur injoignable, (6) CircularProgressIndicator pendant le test de connectivité
- [x] T013 [US5] Update AppRouter to wire DataSettingsScreen as /settings/data route (replace StubSettingsScreen) in `flutter/lib/src/routing/app_router.dart`
- [x] T014 [US5] Update apiClientProvider to read serverUrl from AppConfigRepository in `flutter/lib/src/data/remote/api_client.dart` — Transformer apiClientProvider en FutureProvider<Dio> qui lit serverUrl depuis appConfigRepositoryProvider.getServerUrl(), fallback sur EnvConfig.apiBaseUrl si null. Fichiers impactés par le changement sync→async : (1) `flutter/lib/src/data/remote/api_client.dart` (définition, Provider→FutureProvider), (2) `flutter/lib/src/data/data_mode_provider.dart` (consumer, ref.watch → ref.watch(...).when() ou await). Ce sont les 2 seuls consumers dans le codebase
- [x] T015 [US5] Widget tests for DataSettingsScreen in `flutter/test/src/features/settings/presentation/data_settings_screen_test.dart` — Tests: (1) affiche source active actuelle, (2) champ URL pré-rempli si existant, (3) validation: URL vide bloque le switch vers serveur avec message d'erreur, (4) validation: URL sans https:// affiche erreur, (5) dialog de confirmation affiché au switch, (6) annulation du dialog ne change rien, (7) confirmation déclenche le switch, (8) sélection de la source déjà active ne déclenche pas de dialog. Mocker AppConfigRepository et RestartWidget

**Checkpoint**: Switch de source de données complet — l'utilisateur peut basculer local↔serveur avec URL, dialog et restart

---

## Phase 5: User Story 2 + User Story 3 — Placeholders visuels & Cohérence thème (Priority: P2)

**Goal US2**: Les sections placeholders (Sécurité, À propos) affichent un badge "À venir" avec style atténué et ne sont pas interactives.

**Goal US3**: Le hub s'affiche correctement en thème clair et sombre avec des couleurs cohérentes.

**Independent Test US2**: Vérifier que les cartes placeholders ont le badge, l'opacité réduite, et ne déclenchent aucune navigation.

**Independent Test US3**: Basculer entre thème clair et sombre, vérifier le rendu des cartes.

### Implementation for User Stories 2 & 3

- [x] T016 [P] [US2] Verify and refine SettingsItem placeholder rendering in `flutter/lib/src/features/settings/presentation/widgets/settings_item.dart` — S'assurer que: (1) items placeholder sont wrappés dans Opacity(opacity: 0.5), (2) badge "À venir" affiché via Container avec texte stylé en chip/tag à droite, (3) pas de chevron trailing sur placeholders, (4) pas d'InkWell ni de GestureDetector (widget non-interactif), (5) pas de splash/ripple feedback
- [x] T017 [P] [US3] Verify theme token usage in SettingsItem and SettingsHubScreen — S'assurer que: (1) SettingsItem utilise colorScheme.surface, colorScheme.onSurface, colorScheme.onSurfaceVariant (pas de couleurs hardcodées sauf iconColor défini dans les données statiques), (2) SettingsHubScreen utilise theme.textTheme pour les titres de groupe, (3) badge "À venir" utilise colorScheme.surfaceContainerHighest pour le fond. Fichiers: `flutter/lib/src/features/settings/presentation/widgets/settings_item.dart` et `flutter/lib/src/features/settings/presentation/settings_hub_screen.dart`
- [x] T018 [US2] [US3] Widget tests for SettingsItem in `flutter/test/src/features/settings/presentation/widgets/settings_item_test.dart` — Tests: (1) item actif affiche chevron et pas de badge, (2) item placeholder affiche badge "À venir" et pas de chevron, (3) item placeholder a une opacité réduite (find Opacity widget), (4) tap sur item actif déclenche onTap callback, (5) item placeholder n'a pas de InkWell, (6) rendu en ThemeMode.dark sans erreur, (7) rendu en ThemeMode.light sans erreur. Tester avec MaterialApp wrappant le widget

**Checkpoint**: Items placeholders visuellement distincts, thème clair/sombre cohérent

---

## Phase 6: User Story 4 — Accessibilité (Priority: P3)

**Goal**: Chaque carte est annoncée correctement par un lecteur d'écran avec titre, description et état.

**Independent Test**: Vérifier la sémantique des cartes via les tests de widget (find.bySemanticsLabel).

### Implementation for User Story 4

- [x] T019 [US4] Verify and refine Semantics in SettingsItem in `flutter/lib/src/features/settings/presentation/widgets/settings_item.dart` — S'assurer que: (1) items actifs: Semantics(button: true, label: '$title, $description'), (2) items placeholder: Semantics(button: false, label: '$title, $description, À venir'), (3) ExcludeSemantics sur les enfants décoratifs (icône cercle)
- [x] T020 [US4] Widget tests for accessibility in `flutter/test/src/features/settings/presentation/widgets/settings_item_test.dart` — Ajouter aux tests existants: (1) item actif a SemanticsNode avec button=true et label contenant titre+description, (2) item placeholder a SemanticsNode sans button et label contenant "À venir", (3) vérifier via tester.getSemantics(find.byType(SettingsItem))

**Checkpoint**: Accessibilité complète — lecteur d'écran annonce correctement chaque carte

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales, nettoyage

- [x] T021 Run `flutter analyze` from `flutter/` directory and fix any warnings or errors in all new/modified files
- [x] T022 Run `flutter test` from `flutter/` directory and verify all tests pass (settings_hub_screen_test, data_settings_screen_test, settings_item_test)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut démarrer immédiatement. T001, T002, T003 en parallèle
- **Foundational (Phase 2)**: Dépend de Phase 1. T004 dépend de T001 (utilise SettingsSection). T005 et T006 en parallèle
- **US1 (Phase 3)**: Dépend de Phase 2. T007 dépend de T004. T008 dépend de T003+T005+T007. T009 après T008. T010 après T007
- **US5 (Phase 4)**: Dépend de Phase 3 (T008 pour la route /settings/data). T011 et T012 en parallèle. T013 après T012. T014 indépendant. T015 après T012
- **US2+US3 (Phase 5)**: T016 dépend de Phase 2 (T004). T017 dépend de Phase 2 (T004) **et** Phase 3 (T007, SettingsHubScreen). T016 peut démarrer dès Phase 2, T017 dès Phase 3. T018 après T016+T017
- **US4 (Phase 6)**: Dépend de Phase 5 (T016). T019 puis T020
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Démarre après Phase 2 — aucune dépendance inter-story
- **US5 (P1)**: Démarre après US1 (nécessite la route /settings/data dans le router)
- **US2+US3 (P2)**: T016 démarre après Phase 2 (parallélisable avec US1/US5). T017 démarre après Phase 3 (nécessite T007)
- **US4 (P3)**: Démarre après US2+US3 (raffine le même widget)

### Within Each User Story

- Modèles/notifiers avant écrans
- Écrans avant intégration router
- Tests après implémentation

### Parallel Opportunities

- Phase 1: T001 ∥ T002 ∥ T003
- Phase 2: T005 ∥ T006 (après T001)
- Phase 3: T010 peut commencer dès T007 terminé
- Phase 4: T011 ∥ T012, T014 indépendant du reste
- Phase 5: T016 parallélisable avec Phase 3/4 (dès Phase 2). T017 parallélisable avec Phase 4 (dès Phase 3). T016 ∥ T017 dès Phase 3 complète
- Phase 6: T019 puis T020 (séquentiels)

---

## Parallel Example: User Story 1

```bash
# Setup en parallèle:
Task T001: "Create SettingsSection model in flutter/lib/src/features/settings/domain/settings_section.dart"
Task T002: "Create RestartWidget in flutter/lib/src/common_widgets/restart_widget.dart"
Task T003: "Add route constants in flutter/lib/src/routing/route_names.dart"

# Après Phase 2, lancer hub + tests:
Task T007: "Create SettingsHubScreen in flutter/lib/src/features/settings/presentation/settings_hub_screen.dart"
# Puis séquentiellement:
Task T008: "Update AppRouter with sub-routes"
Task T010: "Widget tests for hub screen"
```

## Parallel Example: User Story 5

```bash
# En parallèle après Phase 3:
Task T011: "Create DataSettingsNotifier in flutter/lib/src/features/settings/application/data_settings_notifier.dart"
Task T012: "Create DataSettingsScreen in flutter/lib/src/features/settings/presentation/data_settings_screen.dart"
# Puis:
Task T013: "Wire DataSettingsScreen in AppRouter"
Task T014: "Update apiClientProvider for dynamic URL"
Task T015: "Widget tests for DataSettingsScreen"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T006)
3. Complete Phase 3: US1 — Navigation (T007-T010)
4. **STOP and VALIDATE**: Tester le hub avec 7 items, navigation vers 5 stubs
5. Commit et démo possible

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1 → Hub navigable (MVP) → Commit
3. US5 → Switch source données fonctionnel → Commit
4. US2+US3 → Placeholders visuels + thème vérifié → Commit
5. US4 → Accessibilité complète → Commit
6. Polish → Analyse + tests finaux → Commit final

### Suggested MVP Scope

**US1 seule** (Phase 1 + 2 + 3 = 10 tâches) : le hub affiche les 7 sections et la navigation fonctionne. Les placeholders sont visuellement distincts (déjà dans SettingsItem). C'est suffisant pour une première démo.

---

## Notes

- Chemins relatifs à `flutter/` (racine du projet Flutter)
- Le `SettingsItem` widget est construit complet en Phase 2 (active + placeholder + theme + semantics) car ces aspects sont intrinsèques au widget
- Les phases US2/US3/US4 sont principalement des passes de vérification et tests
- `settings_screen.dart` est supprimé (T009) — le toggle thème migre vers KKS-112
- L'`apiClientProvider` passe de synchrone à asynchrone (T014) — impact sur `authenticatedDioProvider`
