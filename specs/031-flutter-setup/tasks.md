# Tasks: Flutter Setup & Architecture

**Input**: Design documents from `/specs/031-flutter-setup/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-client.md, quickstart.md

**Tests**: Inclus (3 niveaux : unit, widget, integration — demande dans la spec). Convention de nommage : `should_[resultat]_when_[condition]` (constitution Principe V).

**Organization**: Taches groupees par user story pour implementation et tests independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3, US4, US5)
- Chemins relatifs a `flutter/` (racine du projet Flutter dans le monorepo)
- **Terminologie** : "Accueil" = label utilisateur visible, "dashboard" = nom technique (routes, fichiers, classes)

---

## Phase 1: Setup (Initialisation du projet)

**Purpose**: Creation du projet Flutter et configuration de base

- [x] T001 Creer le projet Flutter dans `flutter/` via `flutter create --org fr.kksdev.budget --project-name k_budget flutter` depuis la racine du monorepo
- [x] T002 Configurer `flutter/pubspec.yaml` avec toutes les dependances (flutter_riverpod, go_router, drift, drift_flutter, dio, flutter_secure_storage, local_auth, firebase_core, firebase_crashlytics, uuid, freezed_annotation, json_annotation) et dev_dependencies (build_runner, drift_dev, freezed, json_serializable, riverpod_generator, riverpod_annotation, mockito, integration_test SDK)
- [x] T003 [P] Configurer `flutter/analysis_options.yaml` avec les regles strictes (strict-casts, strict-raw-types, unawaited_futures, prefer_const_constructors, etc.)
- [x] T004 [P] Configurer `flutter/.gitignore` (ajouter config/env.dev.json, config/env.prod.json, *.g.dart, *.freezed.dart, *.gr.dart)
- [x] T005 [P] Creer les fichiers de configuration d'environnement : `flutter/config/env.example.json` (template commite), `flutter/config/env.dev.json` et `flutter/config/env.prod.json` (gitignores) avec API_BASE_URL et ENV
- [x] T006 [P] Configurer les assets web pour Drift : telecharger `sqlite3.wasm` et `drift_worker.dart.js` dans `flutter/web/`, ajouter les headers COOP/COEP dans `flutter/web/index.html`
- [x] T007 [P] Bundler la police Inter dans `flutter/assets/fonts/Inter/` (fichiers .ttf Regular 400, Medium 500, SemiBold 600, Bold 700) et declarer dans pubspec.yaml
- [x] T008 [P] Creer `flutter/.vscode/launch.json` avec les configurations de lancement dev et prod (--dart-define-from-file)
- [ ] T066 [P] Configurer Firebase : executer `flutterfire configure` pour generer `lib/firebase_options.dart`, ajouter `google-services.json` (Android) et `GoogleService-Info.plist` (iOS). Ajouter ces fichiers au `.gitignore` (credentials specifiques au projet).

**Checkpoint**: Le projet Flutter compile sans erreur avec `flutter pub get && flutter analyze`

---

## Phase 2: Foundational (Prerequis bloquants)

**Purpose**: Infrastructure partagee par toutes les user stories. DOIT etre complete avant toute implementation de story.

### Domaine partage

- [x] T009 [P] Creer les enums partages dans `lib/src/domain/enums/` : `data_mode.dart` (local, server), `app_theme.dart` (light, dark), `lock_method.dart` (biometric, pin), `transaction_type.dart` (depense, recette), `frequency.dart` (mensuel, annuel), `debt_type.dart` (emprunt, pret), `account_type.dart` (courant, epargne, especes), `currency.dart` (EUR, XOF, USD, GBP, CHF, CAD, MAD avec metadata symbole/nom/decimales)
- [x] T010 [P] Creer les domain models avec freezed dans `lib/src/domain/models/` : `app_config.dart`, `user.dart`, `account.dart`, `transaction.dart`, `category.dart`, `subscription.dart`, `debt.dart` — classes immutables avec fromJson/toJson
- [x] T011 [P] Creer les interfaces abstraites des repositories dans `lib/src/domain/repositories/` : `app_config_repository.dart`, `auth_repository.dart`, `transaction_repository.dart`, `subscription_repository.dart`, `debt_repository.dart`, `category_repository.dart`, `account_repository.dart` — operations CRUD + watchAll (Stream)

### Design System

- [x] T012 [P] Creer les constantes de design tokens dans `lib/src/constants/` : `app_colors.dart` (palettes Amber 50-900, Gray 50-900, feedback success/error/warning/info), `app_typography.dart` (Inter, 7 tailles 12-30px, 4 poids 400-700), `app_spacing.dart` (grille 4px, space-0 a space-12), `app_radius.dart` (sm 4px a round 999px), `app_shadows.dart` (sm, md, lg, colored), `app_durations.dart` (fast 120ms, normal 200ms, slow 400ms + easings)
- [x] T013 Creer le theme Flutter dans `lib/src/theme/app_theme.dart` : ThemeData light et dark portant les tokens du design system Angular (bg, text, border, surface, primary Amber), avec ColorScheme personnalise
- [x] T014 Creer `lib/src/theme/app_theme_extension.dart` : ThemeExtension custom pour les tokens metier (incomeColor, expenseColor, debtOweColor, debtOwedColor, subscriptionColor) en light et dark

### Infrastructure

- [x] T015 [P] Creer `lib/src/utils/env_config.dart` : classe statique lisant les variables `--dart-define` (API_BASE_URL, ENV) via `String.fromEnvironment`
- [x] T016 [P] Configurer l'infrastructure i18n : creer `flutter/l10n.yaml` et `lib/src/localization/app_fr.arb` avec les strings de base (titres des sections, labels de navigation, messages d'erreur generiques)
- [x] T017 Creer `lib/main.dart` : ProviderScope wrapping App, initialisation WidgetsFlutterBinding, Firebase.initializeApp (conditionnel plateforme)
- [x] T018 Creer `lib/app.dart` : MaterialApp.router avec theme light/dark (basculable via provider), GoRouter placeholder (route unique vers ecran vide), support des localisations

### Tests infrastructure

- [x] T019 [P] Creer les helpers de test dans `test/helpers/` : `mocks.dart` (mocks Mockito pour les repositories abstraits), `pump_app.dart` (helper wrapping ProviderScope + MaterialApp pour widget tests), `test/helpers/fixtures/` (donnees de test pour chaque entite)
- [x] T020 Executer `dart run build_runner build --delete-conflicting-outputs` puis `flutter analyze` — verifier que le projet compile sans erreur et que les fichiers generes (.g.dart, .freezed.dart) sont corrects

**Checkpoint**: Foundation prete — le projet compile, les tokens de design sont definis, les interfaces de repository sont en place, les tests helpers sont disponibles. Les user stories peuvent demarrer.

---

## Phase 3: User Story 1 — Choix du mode de donnees au premier lancement (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur choisit entre mode local et mode serveur au premier lancement. Le choix est persiste et reutilise aux lancements suivants.

**Independent Test**: Lancer l'app pour la premiere fois → l'onboarding s'affiche → choisir un mode → relancer → l'onboarding est saute.

### Tests US1

- [x] T021 [P] [US1] Unit test dans `test/src/features/onboarding/application/onboarding_notifier_test.dart` : tester saveDataMode persiste le choix, tester isOnboardingCompleted retourne false au premier lancement puis true apres completion, tester la verification de connectivite serveur
- [x] T022 [P] [US1] Widget test dans `test/src/features/onboarding/presentation/onboarding_screen_test.dart` : tester que les deux modes sont affiches, tester la selection et confirmation d'un mode, tester que le formulaire serveur demande une URL

### Implementation US1

- [x] T023 [US1] Implementer AppConfigRepository dans `lib/src/features/onboarding/data/app_config_repository_impl.dart` : lecture/ecriture de AppConfig via flutter_secure_storage (dataMode, serverUrl, theme, lockEnabled, lockMethod, hashedPin, onboardingCompleted)
- [x] T024 [US1] Implementer OnboardingNotifier dans `lib/src/features/onboarding/application/onboarding_notifier.dart` : gestion de l'etat d'onboarding (mode selection, server URL validation, connectivity check via dio HEAD request, persist config)
- [x] T025 [US1] Creer l'ecran OnboardingScreen dans `lib/src/features/onboarding/presentation/onboarding_screen.dart` : deux cartes (mode local, mode serveur) avec description, icone et bouton de selection. Utiliser les design tokens du theme.
- [x] T026 [US1] Creer l'ecran ServerSetupScreen dans `lib/src/features/onboarding/presentation/server_setup_screen.dart` : champ URL du serveur, bouton "Verifier la connexion", indicateur de chargement, message d'erreur si serveur injoignable, bouton retour
- [x] T027 [US1] Connecter l'onboarding au GoRouter : ajouter les routes `/onboarding` et `/onboarding/server-setup` dans `lib/src/routing/app_router.dart`, ajouter la logique de redirect (si onboarding non complete → rediriger vers /onboarding)

**Checkpoint**: Au premier lancement, l'onboarding s'affiche. L'utilisateur peut choisir local (acces direct) ou serveur (saisie URL + verification). Le choix est persiste. Au relancement, l'onboarding est saute.

---

## Phase 4: User Story 2 — Navigation et structure de l'application (Priority: P1)

**Goal**: L'utilisateur navigue entre les 4 sections (Dashboard, Transactions, Abonnements, Dettes) via une barre en bas (mobile) ou sidebar (desktop). Un FAB (+) est visible sur toutes les sections.

**Independent Test**: Apres l'onboarding, la navigation affiche 4 onglets. Chaque onglet mene a son ecran. Le FAB est visible et affiche un menu.

### Tests US2

- [x] T028 [P] [US2] Unit test dans `test/src/routing/app_router_test.dart` : tester que chaque route (/dashboard, /transactions, /subscriptions, /debts) est atteignable, tester la redirection auth/onboarding
- [x] T029 [P] [US2] Widget test dans `test/src/common_widgets/adaptive_scaffold_test.dart` : tester bottom nav en mode mobile (< 768px), tester sidebar en mode large (>= 768px), tester la visibilite du FAB

### Implementation US2

- [x] T030 [P] [US2] Creer les constantes de routes dans `lib/src/routing/route_names.dart` : paths et noms pour onboarding, dashboard, transactions, subscriptions, debts, settings, login, lock
- [x] T031 [US2] Mettre a jour la configuration GoRouter dans `lib/src/routing/app_router.dart` : ajouter ShellRoute avec les 4 branches (dashboard, transactions, subscriptions, debts), configurer les redirections (onboarding, auth), ajouter la route settings
- [x] T032 [US2] Creer le widget AdaptiveScaffold dans `lib/src/common_widgets/adaptive_scaffold.dart` : LayoutBuilder detectant la largeur (< 768px → BottomNavigationBar, >= 768px → NavigationRail/Drawer sidebar), 4 destinations avec icones et labels (Accueil, Transactions, Abonnements, Dettes)
- [x] T033 [US2] Creer le widget FabMenu dans `lib/src/common_widgets/fab_menu.dart` : FloatingActionButton (+) qui ouvre un menu contextuel (Nouvelle transaction, Nouvel abonnement, Nouvelle dette) — actions en placeholder (snackbar)
- [x] T034 [P] [US2] Creer les 4 ecrans shells placeholder dans `lib/src/features/` : `dashboard/presentation/dashboard_screen.dart`, `transactions/presentation/transaction_list_screen.dart`, `subscriptions/presentation/subscription_list_screen.dart`, `debts/presentation/debt_list_screen.dart` — chacun affiche un titre, des donnees mockees et utilise le theme
- [x] T035 [US2] Creer `lib/src/common_widgets/loading_indicator.dart` : widget d'indicateur de chargement centralise utilisant les tokens d'animation

**Checkpoint**: Apres l'onboarding, la navigation s'affiche avec 4 onglets fonctionnels. Le FAB est visible. La navigation est responsive (bottom bar / sidebar a 768px). Chaque ecran affiche un placeholder theme.

---

## Phase 5: User Story 3 — Coherence visuelle avec l'application existante (Priority: P2)

**Goal**: L'application utilise l'identite visuelle K-Budget (Amber/Gray, Inter, themes light/dark) et permet le changement de theme instantane.

**Independent Test**: Comparer visuellement l'app Flutter avec l'app Angular. Basculer le theme dans les settings et verifier le changement instantane.

### Tests US3

- [x] T036 [P] [US3] Unit test dans `test/src/theme/app_theme_test.dart` : verifier que le ThemeData light utilise les bonnes couleurs (primary amber-500 #f59e0b, bg gray-50 #f9fafb), verifier le dark theme (primary amber-400 #fbbf24, bg gray-900 #111827), verifier que le ThemeExtension contient les tokens metier (income, expense)

### Implementation US3

- [x] T037 [US3] Creer l'ecran SettingsScreen dans `lib/src/features/settings/presentation/settings_screen.dart` : toggle theme clair/sombre (avec persistance via AppConfigRepository), option changement de mode de donnees (avec avertissement de non-migration), section verrouillage (activer/desactiver biometrie/PIN)
- [x] T038 [US3] Creer un ThemeNotifier dans `lib/src/features/settings/application/theme_notifier.dart` : Riverpod Notifier qui expose le AppTheme courant, lit/ecrit dans AppConfigRepository, utilise par MaterialApp.router pour appliquer le theme reactif
- [x] T039 [US3] Connecter le ThemeNotifier a `lib/app.dart` : MaterialApp.router utilise `ref.watch(themeNotifierProvider)` pour basculer entre lightTheme et darkTheme instantanement

**Checkpoint**: L'app utilise les couleurs Amber/Gray et la police Inter. Le toggle theme dans Settings bascule instantanement light ↔ dark. Les tokens metier (income vert, expense rouge) sont corrects dans les deux themes.

---

## Phase 6: User Story 4 — Fonctionnement hors-ligne en mode local (Priority: P2)

**Goal**: En mode local, toutes les donnees sont stockees sur l'appareil via Drift (SQLite). Les operations CRUD fonctionnent sans connexion internet.

**Independent Test**: Activer le mode avion. Creer/lire/modifier/supprimer des donnees via les repositories locaux (test programmatique, les ecrans restent des shells).

### Tests US4

- [x] T040 [P] [US4] Unit test dans `test/src/features/transactions/data/transaction_local_data_source_test.dart` : tester les operations CRUD sur les DAOs Drift en memoire (insertTransaction, getAllTransactions, updateTransaction, deleteTransaction, watchAllTransactions)

### Implementation US4

- [x] T041 [US4] Creer la base de donnees Drift dans `lib/src/data/local/database.dart` : AppDatabase avec toutes les tables (categories, accounts, transactions, subscriptions, debts), migration schemaVersion 1, utilisation de `driftDatabase()` pour support multi-plateforme
- [x] T042 [US4] Creer les DAOs Drift dans `lib/src/data/local/daos/` : `category_dao.dart`, `account_dao.dart`, `transaction_dao.dart`, `subscription_dao.dart`, `debt_dao.dart` — chaque DAO implemente les queries CRUD + watchAll pour les streams reactifs
- [x] T043 [US4] Implementer les repositories locaux dans `lib/src/features/transactions/data/transaction_repository_local.dart` (et idem pour subscriptions, debts, categories, accounts dans leurs features respectives) : implementent les interfaces abstraites du domain, delegent aux DAOs, convertissent entre les Drift DataClasses et les domain models
- [x] T044 [US4] Creer le provider de mode de donnees dans `lib/src/data/data_mode_provider.dart` : Riverpod provider qui lit le DataMode depuis AppConfigRepository et expose les implementations de repository appropriees (local ou remote) — en Phase 1, seul le mode local est pleinement fonctionnel
- [x] T045 [US4] Executer `dart run build_runner build --delete-conflicting-outputs` pour generer les fichiers Drift (.g.dart), verifier la compilation

**Checkpoint**: En mode local, les repositories locaux peuvent creer, lire, modifier et supprimer des donnees dans la BDD Drift locale. Le provider de mode selectionne automatiquement les repos locaux quand DataMode.local est configure.

---

## Phase 7: User Story 5 — Connexion au serveur existant (Priority: P2)

**Goal**: En mode serveur, l'app se connecte au backend Spring Boot via l'API REST avec authentification JWT (access + refresh token). L'inscription se fait par invitation.

**Independent Test**: Pointer l'app vers un serveur K-Budget existant. Login → consulter des donnees → refresh token transparent → logout.

### Tests US5

- [x] T046 [P] [US5] Unit test dans `test/src/features/auth/application/auth_notifier_test.dart` : tester login (tokens stockes), tester logout (tokens supprimes, etat unauthenticated), tester checkAuth au demarrage (token valide → authenticated), tester refresh automatique
- [x] T047 [P] [US5] Unit test dans `test/src/features/auth/data/auth_repository_impl_test.dart` : tester les appels API (login, register, refresh, logout) via dio mocke, tester le stockage/lecture des tokens dans flutter_secure_storage mocke

### Implementation US5

- [x] T048 [P] [US5] Creer les DTOs API avec freezed + json_serializable dans `lib/src/data/remote/dtos/` : `auth_dtos.dart` (LoginRequest, RegisterRequest, RefreshRequest, LogoutRequest, AuthResponse), `transaction_dtos.dart` (TransactionRequest, TransactionResponse), `subscription_dtos.dart`, `debt_dtos.dart`, `category_dtos.dart`, `account_dtos.dart`, `error_dto.dart` (ErrorResponse)
- [x] T049 [P] [US5] Creer le client Dio configure dans `lib/src/data/remote/api_client.dart` : Riverpod provider creant un Dio avec baseUrl depuis EnvConfig, Content-Type JSON, timeout 30s
- [x] T050 [US5] Creer le JWT interceptor dans `lib/src/data/remote/jwt_interceptor.dart` : ajoute Authorization Bearer header, intercepte les 401, appelle /auth/refresh automatiquement, rejoue la requete originale, deconnecte si refresh echoue
- [x] T051 [US5] Implementer AuthRemoteDataSource dans `lib/src/features/auth/data/auth_remote_data_source.dart` : methodes login(), register(), refresh(), logout() appelant les endpoints /auth/* via dio
- [x] T052 [US5] Implementer AuthRepositoryImpl dans `lib/src/features/auth/data/auth_repository_impl.dart` : implemente AuthRepository, delegue a AuthRemoteDataSource, stocke/lit les tokens via flutter_secure_storage
- [x] T053 [US5] Implementer AuthNotifier dans `lib/src/features/auth/application/auth_notifier.dart` : Riverpod Notifier + Listenable (pour GoRouter refreshListenable), expose les etats (initial, authenticating, authenticated, unauthenticated), methodes login/logout/checkAuth
- [x] T054 [US5] Creer les remote data sources pour chaque entite dans `lib/src/data/remote/data_sources/` : `transaction_remote_data_source.dart`, `subscription_remote_data_source.dart`, `debt_remote_data_source.dart`, `category_remote_data_source.dart`, `account_remote_data_source.dart` — appels CRUD vers les endpoints REST correspondants
- [x] T055 [US5] Implementer les repositories serveur dans les features respectives : `transaction_repository_remote.dart`, `subscription_repository_remote.dart`, etc. — implementent les interfaces abstraites, delegent aux remote data sources, convertissent DTOs en domain models
- [x] T056 [US5] Creer l'ecran LoginScreen dans `lib/src/features/auth/presentation/login_screen.dart` : formulaire email + mot de passe, bouton connexion, gestion des erreurs (credentials invalides, serveur injoignable), indicateur de chargement
- [x] T057 [US5] Creer l'ecran LockScreen dans `lib/src/features/auth/presentation/lock_screen.dart` : ecran de verrouillage biometrique (local_auth) ou saisie PIN, affiche au lancement si lockEnabled dans AppConfig, supporte les deux modes (local et serveur). Inclure un lien "PIN oublie ?" qui en mode local propose une reinitialisation (efface les donnees locales apres confirmation explicite), et en mode serveur propose la deconnexion + reconnexion
- [x] T058 [US5] Connecter AuthNotifier au GoRouter dans `lib/src/routing/app_router.dart` : passer AuthNotifier comme refreshListenable, ajouter les redirections (unauthenticated en mode serveur → /login, lock enabled → /lock), ajouter les routes /login, /lock et /register
- [x] T059 [US5] Mettre a jour le data_mode_provider dans `lib/src/data/data_mode_provider.dart` : quand DataMode.server, exposer les repositories remote au lieu des repositories locaux
- [x] T060 [US5] Executer `dart run build_runner build --delete-conflicting-outputs`, verifier la compilation
- [x] T067 [US5] Creer l'ecran RegisterScreen dans `lib/src/features/auth/presentation/register_screen.dart` : formulaire email + mot de passe + nom, bouton inscription, gestion des erreurs (email deja utilise, token d'invitation invalide/expire), indicateur de chargement. Accessible via deep link d'invitation avec token pre-rempli.
- [x] T068 [P] [US5] Widget test dans `test/src/features/auth/presentation/register_screen_test.dart` : tester que le formulaire affiche les champs requis, tester la validation (email format, mot de passe min 6 chars), tester l'affichage d'erreur token expire
- [x] T069 [US5] Configurer les deep links d'invitation : ajouter la route `/invite/:token` dans GoRouter (redirige vers RegisterScreen avec token), configurer l'intent-filter dans `flutter/android/app/src/main/AndroidManifest.xml` pour App Links (`budget.kksdev.fr/invite/*`), documenter la config iOS Associated Domains (Xcode capability + fichier `apple-app-site-association` a deployer sur le serveur)
- [x] T070 [US5] Creer un dio interceptor de connectivite dans `lib/src/data/remote/connectivity_interceptor.dart` : intercepte les erreurs reseau (SocketException, TimeoutException), logue l'erreur, lance une exception metier typee (NetworkException) que les notifiers peuvent afficher comme message utilisateur explicite (FR-012)
- [x] T071 [US5] Ajouter une verification de version API dans `lib/src/data/remote/api_client.dart` : au premier appel API reussi, verifier un header de version ou un endpoint `/api/actuator/health` pour detecter les incompatibilites majeures et avertir l'utilisateur (edge case spec)

**Checkpoint**: En mode serveur, l'utilisateur peut se connecter, ses tokens sont geres automatiquement (refresh transparent), les donnees sont lues/ecrites via l'API REST. Le lock screen protege l'acces si active.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Tests d'integration end-to-end, nettoyage, validation finale

- [x] T061 [P] Integration test dans `integration_test/onboarding_flow_test.dart` : flux complet premier lancement → selection mode local → arrivee sur le dashboard. Flux mode serveur → saisie URL → login → dashboard.
- [x] T062 [P] Integration test dans `integration_test/navigation_flow_test.dart` : navigation entre les 4 onglets, verification du FAB, test responsive (resize pour verifier bascule bottom nav / sidebar)
- [x] T063 Executer `flutter analyze` et corriger tous les warnings/infos restants
- [x] T064 Executer `flutter test` et verifier que tous les tests passent (unit + widget)
- [ ] T065 Valider le quickstart.md : suivre les etapes du document pour verifier que le setup from scratch fonctionne (flutter pub get, build_runner, flutter run)
- [ ] T072 Validation manuelle des criteres de performance (SC-001 a SC-007) : mesurer le temps de lancement (SC-001 < 3s), verifier la reactivite des operations locales (SC-002 < 200ms via DevTools timeline), tester le changement de theme (SC-006 < 100ms), chronometrer le flux onboarding (SC-007 < 30s local / 60s serveur). Documenter les resultats dans un commentaire de PR.

**Checkpoint**: Tous les tests passent. Le projet compile sans warning. Le quickstart est valide. Les criteres de performance sont verifies.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dependance — demarrage immediat
- **Foundational (Phase 2)**: Depend de Phase 1 — **BLOQUE toutes les user stories**
- **US1 Onboarding (Phase 3)**: Depend de Phase 2 — premier flux utilisateur
- **US2 Navigation (Phase 4)**: Depend de Phase 2 + US1 (le router est enrichi par US1)
- **US3 Theme (Phase 5)**: Depend de Phase 2 + US2 (settings screen dans la navigation)
- **US4 Mode local (Phase 6)**: Depend de Phase 2 — independant de US3
- **US5 Mode serveur (Phase 7)**: Depend de Phase 2 + US1 (onboarding server flow) — independant de US4
- **Polish (Phase 8)**: Depend de toutes les phases precedentes

### User Story Dependencies

```
Phase 1 (Setup)
    └── Phase 2 (Foundational)
            ├── Phase 3 (US1 Onboarding) 🎯 MVP
            │       └── Phase 4 (US2 Navigation)
            │               └── Phase 5 (US3 Theme)
            ├── Phase 6 (US4 Mode local) [parallele avec US1-US3]
            └── Phase 7 (US5 Mode serveur) [apres US1, parallele avec US4]
                    └── Phase 8 (Polish)
```

### Within Each User Story

1. Tests FIRST (doivent echouer avant implementation)
2. Domain/data layer (repositories, data sources)
3. Application layer (notifiers, providers)
4. Presentation layer (screens, widgets)
5. Integration (connexion au router, providers)

### Parallel Opportunities

- Phase 1 : T003-T008, T066 en parallele (fichiers independants)
- Phase 2 : T009-T012, T015-T016, T019 en parallele (fichiers independants)
- Phase 3 : T021-T022 en parallele (tests), T023-T024 sequentiels
- Phase 4 : T028-T029 en parallele (tests), T030 + T034 en parallele
- Phase 6 et Phase 7 peuvent etre menees en parallele apres Phase 3
- Phase 7 : T067-T068 (RegisterScreen + test) en parallele avec T069 (deep links), T070 (connectivity) apres T049-T050
- Phase 8 : T061-T062 en parallele (tests d'integration independants)

---

## Parallel Example: Phase 2 (Foundational)

```
# Batch 1 — fichiers independants :
T009: Enums (lib/src/domain/enums/)
T010: Domain models (lib/src/domain/models/)
T011: Repository interfaces (lib/src/domain/repositories/)
T012: Design tokens (lib/src/constants/)
T015: EnvConfig (lib/src/utils/)
T016: i18n (l10n.yaml + ARB)
T019: Test helpers (test/helpers/)

# Batch 2 — depend des tokens :
T013: ThemeData (depend de T012)
T014: ThemeExtension (depend de T013)

# Batch 3 — depend du theme + models :
T017: main.dart
T018: app.dart (depend de T013, T015)

# Batch 4 — verification :
T020: build_runner + flutter analyze
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1: Setup → projet Flutter fonctionnel
2. Phase 2: Foundational → tokens, models, interfaces, theme
3. Phase 3: US1 → onboarding (choix du mode)
4. **STOP et VALIDER** : premier lancement → onboarding → choix → persiste → skip au relancement
5. Livrable minimal demontrant l'architecture

### Incremental Delivery

1. Setup + Foundational → socle compile ✓
2. + US1 (Onboarding) → premier flux utilisateur ✓ (MVP!)
3. + US2 (Navigation) → 4 sections accessibles avec shells ✓
4. + US3 (Theme) → identite visuelle K-Budget ✓
5. + US4 (Mode local) → donnees persistees localement ✓
6. + US5 (Mode serveur) → connexion au backend existant ✓
7. Polish → tests integration, nettoyage, validation ✓

Chaque increment est testable et livrable independamment.

---

## Notes

- [P] = fichiers differents, pas de dependances
- [USx] = rattachement a la user story pour tracabilite
- Chaque user story est testable independamment
- Commit apres chaque tache ou groupe logique
- S'arreter a tout checkpoint pour valider la story
- Les ecrans sont des **shells architecturaux** (donnees mockees) — les CRUD complets viendront dans des features futures
