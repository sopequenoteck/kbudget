# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Application personnelle de gestion de budget (transactions, abonnements, dettes). Self-hosted, single-user. Monorepo avec trois modules :

- `api/` — Backend Spring Boot (API REST)
- `app/` — Frontend Angular PWA mobile-first (`k-budget-app`)
- `flutter/` — App mobile native Flutter (`k_budget`)

**Gestion des issues** : toutes les issues et le suivi du projet sont sur **Linear** (identifiants `KKS-*`). Ne pas utiliser GitHub Issues.

## Commandes

### Backend (api/)

```bash
cd api && mvn clean compile       # Build
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev  # Lancer (profil dev)
cd api && mvn test                # Tests
cd api && mvn test -Dtest=NomDuTest  # Test unique
cd api && mvn clean install       # Build complet avec tests
```

> **Note** : Le profil `prod` est le défaut (`spring.profiles.default=prod`). En dev, le profil `dev` doit être activé explicitement.

Le module Maven est dans `api/`. Toutes les commandes Maven doivent être exécutées depuis ce répertoire.

### Frontend (app/)

```bash
cd app && ng serve                # Dev server (http://localhost:4200)
cd app && ng build                # Build
cd app && ng test                 # Tests unitaires
cd app && ng build --configuration production  # Build prod
```

Le projet Angular est dans `app/`. Toutes les commandes Angular CLI doivent être exécutées depuis ce répertoire.

### Flutter (flutter/)

```bash
cd flutter && flutter test             # Tests unitaires + widget
cd flutter && flutter test test/src/features/  # Tests par feature
cd flutter && dart run build_runner build --delete-conflicting-outputs  # Code generation (Drift, Freezed, JSON)
cd flutter && flutter run              # Lancer sur device/simulateur
cd flutter && flutter analyze          # Analyse statique
```

Le projet Flutter est dans `flutter/`. Toutes les commandes Flutter/Dart doivent être exécutées depuis ce répertoire.

## Architecture

> Détails complets : [`README.md`](README.md) et [`docs/architecture.md`](docs/architecture.md).

### Stack

- **Backend** : Java 21, Spring Boot 4.0.2, Maven, Lombok
- **Frontend** : Angular 21, TypeScript 5.9, SCSS
- **Mobile** : Flutter >= 3.27, Dart >= 3.6, Riverpod, Drift, Dio
- **BDD** : PostgreSQL 15+ (backend), SQLite/Drift (Flutter local)
- **Auth** : Spring Security + JWT (jjwt 0.12.6) avec refresh tokens
- **Infra** : Docker + Caddy (reverse proxy, auto-HTTPS)

### Structure

```
Controller (@RestController) → Service (@Service) → Repository (JpaRepository)
     ↓                                                        ↓
  DTOs (request/response)                              Entities JPA (@Entity)
```

Package base : `fr.kksdev.budget.api` — sous-packages : `config/`, `controller/`, `service/`, `repository/`, `model/`, `dto/`, `enums/`. Enums : `TransactionType`, `Frequency`, `DebtType`, `TokenStatus`, `AccountType`, `Feature`, `Currency`, `NotificationType`, `EntityType`.

### Entites

- **User** : email (unique), password (BCrypt), name, createdAt. UUID.
- **Account** : nom, type (COURANT/EPARGNE/ESPECES), soldeInitial, icone, couleur, isDefault, actif, bankCode (String, default "OTHER"), bankCustomName (String, nullable), bankCustomLogo (String/TEXT, nullable), updatedAt. FK → User.
- **Transaction** : montant, libelle, type (DEPENSE/RECETTE), date, category (FK → Category), note, account (FK → Account), transferId (UUID, nullable), product (FK → Product, nullable), debt (FK → Debt, nullable), subscription (FK → Subscription, nullable), isRecurring (Boolean, default false), frequency (Frequency, nullable), nextOccurrence (LocalDate, nullable), recurringActive (Boolean, default true), updatedAt. FK → User.
- **Subscription** : nom, montant, frequence (MENSUEL/ANNUEL), dateDebut, actif, category (FK → Category), account (FK → Account, nullable), updatedAt. FK → User.
- **Debt** : personne, montant, sens (EMPRUNT/PRET), date, currency (Currency, default EUR), rembourse, dueDate (LocalDate, nullable), account (FK → Account, nullable), includeInBalance (Boolean, default false), reminderDate (LocalDate, nullable), reminderTime (LocalTime, nullable), category (FK → Category), updatedAt. FK → User.
- **Category** : nom, icone, couleur, isSystem, updatedAt. FK → User.
- **RefreshToken** : token (unique), status (ACTIVE/CONSUMED/REVOKED), createdAt, expiresAt. FK → User.
- **Product** : nom, description (nullable), icone (nullable), imageUrl (nullable), prixAchat, prixVente, stock, totalVendu, actif, createdAt, updatedAt. FK → User.
- **UserPreference** : enabledFeatures (List\<Feature\>), navOrder (List\<Feature\>), shopAccountId (UUID, nullable, FK → Account), includeShopInBalance (Boolean, default false), currencies (List\<Currency\>, default [EUR]), enabledNotificationTypes (List\<NotificationType\>, nullable), timezone (String, default "Europe/Paris"), updatedAt. @OneToOne → User.
- **ExchangeRate** : baseCurrency (Currency), targetCurrency (Currency), rate (BigDecimal, precision 20 scale 6), updatedAt. UNIQUE(user_id, base_currency, target_currency). FK → User.
- **Notification** : type (NotificationType), entityType (EntityType), entityId (UUID), title, body, read (Boolean, default false), readAt (LocalDateTime, nullable), createdAt. FK → User.
- **Budget** : montant, frequence (HEBDOMADAIRE/MENSUEL/ANNUEL), currency (Currency, default EUR), seuilNotification (Integer, default 80), actif (Boolean, default true), updatedAt. UNIQUE(user_id, category_id). FK → User + Category.
- **BudgetSnapshot** : montantBudget, currency, tauxChange (nullable), montantDepense, mois (String yyyy-MM), createdAt. FK → User + Category.

### Environnements

| Env | Frontend | API | apiUrl |
|-----|----------|-----|--------|
| dev | `localhost:4200` | `localhost:8080/api` | `/api` (proxy dev) |
| prod | `budget.kksdev.fr` | `budget.kksdev.fr/api` | `/api` |

### Securite

- JWT stateless. Access token (15min) dans header `Authorization: Bearer <token>`. Refresh token (30j) pour renouvellement.
- Routes publiques : `/auth/**`, `/error`, `/actuator/health`, `/ws/**` (auth WebSocket via STOMP CONNECT frame). Tout le reste necessite un JWT valide.
- Endpoints auth : `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`.
- Context path : `/api`. `JwtFilter` valide le token avant chaque requete.

### Design System

Document de reference unique : [`docs/design-tokens.md`](docs/design-tokens.md). Couleur primaire : Amber (#f59e0b). Couleur secondaire : Indigo (#4f46e5). Police : Inter. 7 categories de tokens : couleurs, typographie, spacing, radius, ombres, animations, platform-specific.

**Angular** : Composants utilisent UNIQUEMENT `var(--token-name)`, jamais d'import SCSS direct. Structure dans `app/src/styles/` (tokens, themes light/dark, reset, base, utilities).

**Flutter** : Constantes dans `flutter/lib/src/constants/` (AppColors, AppSpacing, AppTypography, AppRadius, AppShadows, AppDurations). Theme dans `flutter/lib/src/theme/` (AppTheme, AppThemeExtension).

### Architecture Flutter (flutter/)

```
flutter/lib/src/
├── common_widgets/    # Widgets partagés (AdaptiveScaffold, AppModal, SelectPicker, EmojiInput, ColorPalettePicker, AppFormField...)
├── constants/         # Design tokens (AppSpacing, AppColors, AppTypography, AppRadius...)
├── data/
│   ├── local/         # Drift database, DAOs, mappers
│   └── remote/        # Dio client, interceptors, remote data sources
├── domain/
│   ├── enums/         # TransactionType, Frequency, DebtType, Currency, Feature...
│   ├── models/        # Freezed models (Account, Transaction...) + ListState<T>
│   └── repositories/  # Interfaces abstraites (contrats)
├── features/          # Modules par feature
│   └── [feature]/
│       ├── application/   # Riverpod notifiers + state (Freezed)
│       ├── data/          # Implémentations repositories (local + remote)
│       └── presentation/  # Screens + widgets
├── localization/      # i18n
├── routing/           # Go Router (routes, redirects, shell)
├── theme/             # AppTheme (light/dark) + AppThemeExtension
└── utils/             # Helpers (amount_formatter, color_utils...)
```

**Data mode** : Strategy pattern via `dataModeProvider` — bascule transparente entre `TransactionRepositoryLocal` (Drift) et `TransactionRepositoryRemote` (Dio) selon la config utilisateur.

## Constitution du projet

Le fichier `.specify/memory/constitution.md` (v2.1.0) est le document de reference. 7 principes :

1. **API-First** : toute feature via REST avant frontend. DTOs obligatoires, jamais d'entite JPA exposee.
2. **Securite par defaut** : JWT sur toutes les routes, filtrage par user authentifie, Bean Validation.
3. **Simplicite & YAGNI** : Controller → Service → Repository. Pas de CQRS/DDD/Event Sourcing.
4. **Mobile-First UX** : saisie en 2-3 interactions, bouton flottant (+) sur tous les ecrans.
5. **Testabilite** : tests d'integration sur endpoints, tests unitaires sur services. Nommage : `should_[resultat]_when_[condition]`.
6. **Observabilite** : SLF4J/Logback uniquement. INFO pour actions, ERROR pour erreurs.
7. **Self-Hosted Ready** : PostgreSQL seule dependance infra.

## Conventions

- DTOs separent TOUJOURS la couche API de la couche persistance
- Enums pour les valeurs fixes du domaine (package `enums/`)
- Lombok obligatoire (`@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`)
- Chaque requete filtre par le user authentifie (isolation des donnees)
- Inputs valides via Bean Validation (`@Valid`, `@NotNull`, `@Size`)
- Branches feature : `feature/<nom>`

## Conventions Frontend (Angular)

### Signals-First

Approche **signals-first** obligatoire :

| Besoin | Utiliser | Ne PAS utiliser |
|--------|----------|-----------------|
| State | `signal()` | Variables classiques |
| Derived state | `computed()` | Getters manuels |
| Side effects | `effect()` | `ngOnChanges` |
| Inputs | `input()` / `input.required()` | `@Input()` |
| Outputs | `output()` | `@Output()` + `EventEmitter` |
| Queries | `viewChild()`, `contentChild()` | `@ViewChild()`, `@ContentChild()` |
| Two-way binding | `model()` | `@Input()` + `@Output()` combo |

### Regles

- `inject()` uniquement (pas de constructor injection)
- Standalone obligatoire, `ChangeDetectionStrategy.OnPush` sur tous les composants
- Pas de `subscribe()` manuel — utiliser `toSignal()`, `firstValueFrom()` ou pipe `async`
- RxJS limite aux flux HTTP et operateurs complexes
- ESLint + Prettier configures (`ng lint`, `npm run format`)

## Conventions Frontend (Flutter)

### Riverpod-First

| Besoin | Utiliser | Ne PAS utiliser |
|--------|----------|-----------------|
| State management | `Notifier` + `NotifierProvider` | `ChangeNotifier`, `setState` |
| Async data | `FutureProvider` / `StreamProvider` | `FutureBuilder`, `StreamBuilder` |
| State immutable | `Freezed` (`@freezed`) | Classes mutables |
| DI | `ref.watch()` / `ref.read()` | `Provider.of()`, `GetIt` |
| Parameterized | `FutureProvider.family` | Provider avec constructeur |

### Patterns obligatoires

- **CRUD Notifier** : `Notifier<ListState<T>>` avec `loadItems()`, `create()`, `update()`, `delete()`, `loadMore()` — pagination client-side via `_refreshPage()`
- **ListState\<T\>** : Freezed model generique (`items`, `isLoading`, `error`, `currentPage`, `hasMore`, `mutatingIds`)
- **Repository abstrait** : Interface dans `domain/repositories/`, implementations dans `features/[feature]/data/` (local + remote)
- **Data mode provider** : Strategy pattern — `dataModeProvider` bascule entre `RepositoryLocal` (Drift) et `RepositoryRemote` (Dio)
- **Widgets** : `ConsumerWidget` (lecture state), `ConsumerStatefulWidget` (stateful + Riverpod), `StatelessWidget` (UI pure)
- **Design tokens** : Utiliser `AppSpacing`, `AppColors`, `AppRadius` etc. — jamais de valeurs hardcodées
- **Navigation** : `context.push()` / `context.go()` via go_router
- **Skeleton loading** : Package `shimmer` avec widgets `_XxxSkeleton` privés
- **Code generation** : `build_runner` pour Drift, Freezed, json_serializable — fichiers `.g.dart` et `.freezed.dart` commits

### Tests Flutter

- Nommage : `should_[résultat]_when_[condition]`
- Structure : `ProviderContainer` avec `overrides` pour mocker les repositories
- Pattern : `notifier()` / `state()` helpers dans chaque fichier test
- Widget tests : `ProviderScope` + `MaterialApp.router` + `AppTheme.light`

## Documentation

| Document | Contenu |
|----------|---------|
| [`README.md`](README.md) | Installation, commandes, endpoints, architecture |
| [`docs/vision.md`](docs/vision.md) | Vision produit et modules fonctionnels |
| [`docs/architecture.md`](docs/architecture.md) | Decisions techniques, modele de donnees |
| [`docs/api-examples.md`](docs/api-examples.md) | Exemples requetes/reponses |
| [`docs/api-errors.md`](docs/api-errors.md) | Contrat erreurs HTTP |
| [`docs/deployment.md`](docs/deployment.md) | Guide deploiement Docker/bare-metal |
| [`docs/design-tokens.md`](docs/design-tokens.md) | Reference unique design tokens partages (couleurs, typo, spacing, radius, ombres, animations) |
| **Swagger UI** | `http://localhost:8080/api/swagger-ui.html` |

## Active Technologies
- Dart >= 3.6, Flutter >= 3.27 + flutter_riverpod, go_router, freezed, shimmer, intl (043-flutter-transactions-list)
- Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider` (043-flutter-transactions-list)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, shimmer, intl (043-flutter-transactions-list)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, freezed, go_router, intl (044-flutter-transaction-form)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, intl (045-flutter-subscription-form)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, freezed, go_router, intl, shimmer (046-flutter-subscriptions-list)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, freezed, go_router, shimmer, intl (048-flutter-debts-list)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, freezed, json_serializable, go_router, dio, shimmer (049-flutter-settings-profile)
- Serveur uniquement (pas de Drift/SQLite pour le profil — données toujours fraîches depuis l'API) (049-flutter-settings-profile)
- Serveur uniquement (opération atomique, pas de stockage local) (050-flutter-transfer-form)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, build_runner (051-flutter-settings-appearance)
- FlutterSecureStorage (AppConfig JSON sérialisé) (051-flutter-settings-appearance)
- Dart >= 3.6, Flutter >= 3.27 (stable) + `emoji_picker_flutter: ^4.4.0` (déjà ajouté au pubspec.yaml) (052-flutter-emoji-input)
- N/A (widget UI pur, pas de persistance) (052-flutter-emoji-input)
- Dart >= 3.6 + Flutter >= 3.27, flutter_riverpod, go_router, freezed, dio, emoji_picker_flutter, shimmer, intl (053-flutter-settings-accounts)
- API REST uniquement (pas de Drift pour cette feature) (053-flutter-settings-accounts)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, emoji_picker_flutter, shimmer, intl (054-flutter-settings-categories)
- API REST uniquement (pas de Drift pour cette feature — données toujours fraîches depuis l'API) (054-flutter-settings-categories)
- Java 21 + Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, jjwt 0.12.6 (055-backend-feature-toggles)
- PostgreSQL 15+ (nouvelle table `user_preferences`) (055-backend-feature-toggles)
- PostgreSQL 15+ (Flyway V10) (056-backend-product-crud)
- Java 21 + Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6 (057-backend-product-sales)
- PostgreSQL 15+ (Flyway V11) (057-backend-product-sales)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, dio, flutter_secure_storage (058-flutter-settings-features)
- FlutterSecureStorage (AppConfig JSON) + API REST (mode serveur) (058-flutter-settings-features)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, flutter_secure_storage (059-flutter-settings-bottom-nav)
- FlutterSecureStorage (AppConfig JSON sérialisé) + API REST (mode serveur) (059-flutter-settings-bottom-nav)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl (060-flutter-shop-products)
- API REST uniquement (pas de Drift/SQLite pour cette feature) (060-flutter-shop-products)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, dio, image_picker, path_provider (061-flutter-product-form)
- API REST uniquement (pas de Drift/SQLite — remote only). Images envoyees en base64 data URI ; fichier local conserve uniquement pour le preview rapide. (061-flutter-product-form)
- TypeScript 5.9 (Angular SCSS), Dart >= 3.6 (Flutter) + Angular 21 (SCSS tokens), Flutter >= 3.27 (Dart constants + ThemeData) (063-shared-design-tokens)
- N/A (fichiers statiques de configuration) (063-shared-design-tokens)
- TypeScript 5.9, Angular 21 + Angular CDK (`@angular/cdk/drag-drop` pour le DnD), Angular Signals, Angular Router (064-angular-feature-toggles)
- Server-only (API REST `GET/PUT /users/me/preferences`) — pas de stockage local (064-angular-feature-toggles)
- TypeScript 5.9, Angular 21 + Angular HttpClient, Angular Router, Angular Signals (065-angular-data-settings)
- N/A (pas de persistance locale, lecture seule depuis le serveur) (065-angular-data-settings)
- TypeScript 5.9 + Angular 21, Angular Reactive Forms, Angular Signals (066-angular-transfer-form)
- N/A (server-only, pas de stockage local) (066-angular-transfer-form)
- TypeScript 5.9, Angular 21 + Angular Router, Angular Signals, Angular CDK (deja present) (067-angular-responsive-nav)
- N/A (pas de persistance, reutilise PreferenceService existant) (067-angular-responsive-nav)
- TypeScript 5.9 (Angular), Java 21 (backend modification mineure) + Angular 21, Angular Reactive Forms, Angular Router, Angular Signals (068-angular-shop-module)
- Server-only (API REST, pas de stockage local) (068-angular-shop-module)
- TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter) + `@ng-icons/core` + `@ng-icons/phosphor-icons` v33.1.0 (Angular), `phosphor_flutter` v2.1.0 (Flutter) (069-phosphor-icons-migration)
- N/A (aucun changement de modele de donnees) (069-phosphor-icons-migration)
- Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter) + Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio (070-currency-dashboard)
- PostgreSQL 15+ (nouvelle table `exchange_rates`, enrichissement `user_preferences`), SQLite/Drift non utilise (taux serveur uniquement) (070-currency-dashboard)
- Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter) + Spring Boot 4.0.2, Spring WebSocket + STOMP, Angular 21 + @stomp/stompjs, Flutter >= 3.27 + stomp_dart_client + flutter_local_notifications (072-notification-system)
- PostgreSQL 15+ (table `notifications`, enrichissement `user_preferences`) (072-notification-system)
- PostgreSQL 15+ (Flyway V17) (073-backend-budget-categories)
- TypeScript 5.9 + Angular 21, Angular Reactive Forms, ng2-charts (Chart.js), @ng-icons/phosphor-icons (074-angular-budget-categories)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, drift, dio, fl_chart (nouveau), shimmer, intl, phosphor_flutter (075-flutter-budget-categories)
- SQLite/Drift (local) + API REST/Dio (remote) via strategy pattern `dataModeProvider` (075-flutter-budget-categories)
- Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter) + Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, ng2-charts, fl_chart (076-budget-category-tracking)
- PostgreSQL 15+ (Flyway V18) (077-backend-debt-enhancements)
- TypeScript 5.9, Angular 21 + Angular Reactive Forms, Angular Signals, Angular Router, @ng-icons/phosphor-icons (078-angular-debt-enhancements)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl, phosphor_flutter (079-flutter-debt-enhancements)
- Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter) + Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio, Phosphor Icons (080-debt-enhancements)
- PostgreSQL 15+ (Flyway V18), SQLite/Drift non utilisé (server-only pour les opérations de dette) (080-debt-enhancements)
- PostgreSQL 15+ (Flyway V19) (081-backend-bank-accounts)
- TypeScript 5.9 + Angular 21, Angular Reactive Forms, Angular Signals, @ng-icons/phosphor-icons (082-angular-bank-accounts)
- Server-only (API REST GET /banks + GET/PATCH /accounts) — pas de stockage local, cache signal dans BankService (082-angular-bank-accounts)
- Dart >= 3.6, Flutter >= 3.27 (stable) + flutter_riverpod, go_router, freezed, json_serializable, dio, flutter_svg (nouveau), image_picker, shimmer, phosphor_flutter (083-flutter-bank-accounts)
- SQLite/Drift (table Accounts enrichie +3 colonnes) + API REST/Dio (GET /api/banks, GET/POST/PUT /api/accounts) (083-flutter-bank-accounts)
- Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter) + Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio, flutter_svg (084-bank-accounts)
- PostgreSQL 15+ (Flyway V19), SQLite/Drift (migration v3, +3 colonnes) (084-bank-accounts)
- PostgreSQL 15+ (Flyway V20) (085-recurring-transactions-backend)
- TypeScript 5.9 + Angular 21, Angular Router, Angular Signals, @ng-icons/phosphor-icons (086-angular-recurring-transactions)
- N/A (server-only, consomme API REST) (086-angular-recurring-transactions)
- N/A (server-only, consomme API REST POST /transactions/recurring) (087-angular-recurring-form)

### Backend (api/)

- Java 21, Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6
- PostgreSQL 15+, Flyway migrations V1-V19
- JUnit 5, Spring Boot Test, Mockito, H2 (profil test)

### Frontend PWA (app/)

- TypeScript 5.9, Angular 21, RxJS, Angular Reactive Forms
- Angular Signals, Angular Router (lazy-loaded), Angular CDK
- SCSS design tokens, Vitest

### Mobile natif (flutter/)

- Dart >= 3.6, Flutter >= 3.27
- flutter_riverpod, go_router, drift, dio, flutter_secure_storage, image_picker, path_provider, phosphor_flutter
- freezed, json_serializable, shimmer, intl
- flutter_test, mockito, build_runner

## Recent Changes
- 058-flutter-settings-features: Added Feature enum (Flutter), FeatureConfigNotifier, FeatureSettingsScreen, PreferenceRemoteDataSource; AppConfig extended with enabledFeatures
- 059-flutter-settings-bottom-nav: Feature.outlinedIcon added; AppConfig extended with navOrder; AppConfigRepository/Impl extended with getNavOrder/setNavOrder; FeatureConfigNotifier extended with navOrder state + reorderNavigation(); FeatureSettingsScreen renamed to "Fonctionnalités & Navigation" + section Navigation (drag & drop ReorderableListView + _BottomNavPreview); _ShellScaffold uses navOrder for ordered bottom nav
- 060-flutter-shop-products: ProductListScreen + ProductListNotifier (CrudNotifier pattern) + ProductRepository (remote only); fix FAB speed dial — RenderBox.localToGlobal() remplace CompositedTransformFollower/LayerLink
- 061-flutter-product-form: ProductForm (ConsumerStatefulWidget) + DecimalTextInputFormatter; image_picker + path_provider ajoutés; ModalType.product ajouté; ProductListScreen câblé (create/edit via ModalNotifier)
- 062-flutter-product-detail: ProductDetailScreen (ConsumerWidget) + RestockDialog; sell/restock/getSales ajoutés au data layer (DTO, data source, repository, notifier + productSalesProvider); route /shop/:id; ProductListScreen tap → navigation détail; fix ProductService.getSalesHistory() → RECETTE + DEPENSE
- 063-shared-design-tokens: docs/design-tokens.md créé (source de vérité unique, 7 catégories). Angular: +palette Indigo, +secondary tokens (light/dark), subscription blue→violet, +space-9/11, +radius-xxl. Flutter: +Indigo palette, feedback/business colors harmonisés (green/red), +lineHeights, +fontMono, shadows harmonisées, +easeDefault+resolve() reduced-motion, +secondaryColor; AppTheme remplace valeurs hardcodées par AppRadius/AppSpacing
- 064-angular-feature-toggles: PreferenceService (signal-based, GET/PUT /users/me/preferences) + featureGuard (CanActivateFn paramétré); Settings > Fonctionnalités (toggle, DnD navOrder, confirmation dialog); sidebar dynamique via computed() + @for; FAB filtré par features; ShopPlaceholder /shop; 11 tests unitaires
- 065-angular-data-settings: HealthService (signal-based, GET /actuator/health); DataSettings component (statut serveur, reload avec confirmation); route /settings/data; fix tokens CSS dark mode (--bg-warning, --text-warning)
- 066-angular-transfer-form: TransferForm (standalone, OnPush, Reactive Forms) + differentAccountsValidator (cross-field); AccountService.transfer() POST /accounts/transfer; FAB TRANSFER_ACTION conditionnel (≥ 2 comptes actifs); Shell @case('transfer') + onTransferSaved(); 7 tests unitaires
- 067-angular-responsive-nav: BottomNav component (mobile < 768px); Shell refactorisé — sidebar desktop / bottom nav mobile; FAB repositionné au-dessus de la bottom nav; token --bottom-nav-height: 64px; icônes 24px (Phosphor standard)
- 068-angular-shop-module: ProductService + ShopList + ProductForm + ShopDetail + SellDialog + RestockDialog; backend GET /products?includeInactive + POST sell with SellRequest; ModalType +product +sell; routes /shop, /shop/:id; filtre actifs/inactifs; sell (detail 1u + FAB Nu) / restock actions; sales history; FAB conditionnel /shop; image sync Flutter↔Angular via base64 data URI — ImageUtils (flutter) + compressImage canvas (Angular, maxWidth=1024, quality=0.85)
- 069-phosphor-icons-migration: All system icons migrated to Phosphor Icons — phosphor_flutter v2.1.0 (Flutter, ~60 icons), @ng-icons/core + @ng-icons/phosphor-icons v33.1.0 (Angular, ~20 emojis); docs/design-tokens.md section Icons ajoutée; icon-mapping.md créé; 525 tests Flutter passent
- 073-backend-budget-categories: Budget + BudgetSnapshot entities; Flyway V17; BudgetService (CRUD, overview mensuel, history avec snapshots lazy, normalisation HEBDO/MENSUEL/ANNUEL, multi-devise); 7 endpoints /budgets; Feature.BUDGETS; 41 tests (25 service + 16 controller)
- 074-angular-budget-categories: BudgetService Angular + BudgetListComponent + BudgetForm + graphiques ng2-charts; 7 endpoints /budgets consommés
- 075-flutter-budget-categories: BudgetListScreen + BudgetDetailScreen + BudgetForm (CRUD + overview mensuel + historique fl_chart); BudgetNotifier (CrudNotifier pattern); local (Drift) + remote (Dio) via dataModeProvider; 20 tests unitaires BudgetNotifier; localisation 18 clés l10n; fix Currency lookup → byNameOrDefault(); fix _hasExistingData shop
- 076-budget-category-tracking: Unbudgeted spending tracking (backend currency field + multi-currency aggregation, Angular budget-list section, Flutter UnbudgetedDetailSheet + AppColors.unbudgetedGray + UnbudgetedItemDto); MonthSelector.didUpdateWidget(); snapshot cleanup on budget delete; null guard checkThresholdsForCategory; JavaDoc getHistory() @Transactional
- 077-backend-debt-enhancements: DebtService — repayment tracking (POST /debts/{id}/repay, GET /debts/{id}/payments), account association with currency forcing/conversion, snooze reminders (POST /debts/{id}/snooze); NotificationScheduler — DEBT_REMINDER type + checkDebtReminders() minutely job; AccountService — GET /accounts/total-balance aggregating accounts + debts by currency; Flyway V18; guard: debt transaction type immutable; ~55 tests (418 total)
- 078-angular-debt-enhancements: DebtService Angular (repay, payments, snooze, totalBalance); DebtDetailComponent (montant restant, barre progression, historique paiements, badge remboursé); RepayDialog + SnoozeDialog; DebtListComponent câblé; toast feedback; 9 tests unitaires
- 079-flutter-debt-enhancements: DebtDetailScreen (montant restant, barre progression, historique paiements, badge remboursé); RepayBottomSheet (compte + montant); SnoozeDialog; DebtForm enrichi (compte, rappel, includeInBalance); NotificationPanel — actions Rembourser/Reporter; routes /debts/:id; DebtPayment model; 37 tests passent
- 080-debt-enhancements: Spec consolidée cross-plateforme (KKS-194/195/196) — 76 tâches documentées, 423 tests backend + 37 tests Flutter validés. Spec rétroactive couvrant KKS-077/078/079.
- 081-backend-bank-accounts: Bank record + BankRegistry (29 banques statiques FR/TG/International); BankService (getAllBanks trié, resolveBank); BankController GET /banks (public); Account enrichi (+bankCode, bankCustomName, bankCustomLogo); AccountRequest/Response enrichis (+7 champs bank résolus); Flyway V19; 29 logos SVG dans static/bank-logos/; 442 tests (27 nouveaux)
- 082-angular-bank-accounts: BankService Angular (GET /banks, cache signal); BankSelect composant (groupement FR/TG/International, recherche temps réel); AccountBankIcon composant (résolution logo : SVG banque / data URI custom / emoji fallback); AccountForm enrichi (sélecteur banque, masquage conditionnel icône/couleur, upload logo custom compressé); image.utils.ts (compressImage partagé entre AccountForm et ProductForm); SelectPicker étendu (+imageUrl sur SelectPickerItem); AccountModel enrichi (+7 champs bank); 347 tests passent
- 083-flutter-bank-accounts: Bank model (Freezed) + BankResponse DTO; BankRemoteDataSource (GET /api/banks); BankRepository (interface + remote); banksProvider (FutureProvider); Account enrichi +7 champs bank; Drift migration v3 (+3 colonnes); BankSelectPicker (bottom sheet groupée FR/TG/International, recherche temps réel); AccountBankIcon (cascade SVG/base64/emoji); AccountFormScreen enrichi (sélecteur banque, masquage conditionnel, upload logo custom 512px); SelectPickerItem +imageUrl; AccountListTile + HeroAccountSection + 5 formulaires mis à jour; 29 logos SVG embarqués; 9 tests widget; 604 tests passent
- 085-recurring-transactions-backend: RecurringTransactionController (5 endpoints /transactions/recurring); RecurringTransactionService (create, listActive, validate, skip, deactivate); SubscriptionPaymentService (pay, getPayments, getTotalPaid); SubscriptionController +3 endpoints (pay/payments/total); Flyway V20 (+isRecurring, frequency, nextOccurrence, recurringActive, subscription_id sur transactions); Transaction enrichie (+product FK, +debt FK ManyToOne, +subscription FK); CategoryResponse.from() + AccountSummary.from() static factories (dédupliquent 5 services); count query countBySubscriptionIdAndUserId; EntityType +RECURRING_TRANSACTION; NotificationType +RECURRING_TRANSACTION_DUE; NotificationScheduler +checkRecurringTransactions(); 488 tests passent
- 086-angular-recurring-transactions: RecurringTransactionService (signal-based, loadActive/validate/skip/deactivate); SubscriptionService enrichi (pay, getPayments, getTotalPaid); RecurringList component (liste triée overdue/today/upcoming, 3 actions); SubscriptionDetail component (infos, payer, historique paiements + total cumulé); NotificationPanel gère RECURRING_TRANSACTION_DUE (Valider/Passer) et SUBSCRIPTION_DUE (Payer); 375 tests passent
- 087-angular-recurring-form: TransactionForm enrichi avec toggle récurrente (isRecurring, frequency, nextOccurrence) ; RecurringTransactionService.create() + RecurringTransactionRequest ; ModalService.asRecurring signal ; action "Rendre récurrente" (phosphorRepeat) dans la liste des transactions avec pré-remplissage du formulaire ; 4 nouveaux tests (379 total)
