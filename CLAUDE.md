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

Package base : `fr.kksdev.budget.api` — sous-packages : `config/`, `controller/`, `service/`, `repository/`, `model/`, `dto/`, `enums/`. Enums : `TransactionType`, `Frequency`, `DebtType`, `TokenStatus`, `AccountType`, `Feature`, `Currency`.

### Entites

- **User** : email (unique), password (BCrypt), name, createdAt. UUID.
- **Account** : nom, type (COURANT/EPARGNE/ESPECES), soldeInitial, icone, couleur, isDefault, actif, updatedAt. FK → User.
- **Transaction** : montant, libelle, type (DEPENSE/RECETTE), date, category (FK → Category), note, account (FK → Account), transferId (UUID, nullable), productId (UUID, nullable, FK → Product), updatedAt. FK → User.
- **Subscription** : nom, montant, frequence (MENSUEL/ANNUEL), dateDebut, actif, category (FK → Category), account (FK → Account, nullable), updatedAt. FK → User.
- **Debt** : personne, montant, sens (EMPRUNT/PRET), date, rembourse, category (FK → Category), updatedAt. FK → User.
- **Category** : nom, icone, couleur, isSystem, updatedAt. FK → User.
- **RefreshToken** : token (unique), status (ACTIVE/CONSUMED/REVOKED), createdAt, expiresAt. FK → User.
- **Product** : nom, description (nullable), icone (nullable), imageUrl (nullable), prixAchat, prixVente, stock, totalVendu, actif, createdAt, updatedAt. FK → User.
- **UserPreference** : enabledFeatures (List\<Feature\>), navOrder (List\<Feature\>), shopAccountId (UUID, nullable, FK → Account), includeShopInBalance (Boolean, default false), updatedAt. @OneToOne → User.

### Environnements

| Env | Frontend | API | apiUrl |
|-----|----------|-----|--------|
| dev | `localhost:4200` | `localhost:8080/api` | `/api` (proxy dev) |
| prod | `budget.kksdev.fr` | `budget.kksdev.fr/api` | `/api` |

### Securite

- JWT stateless. Access token (15min) dans header `Authorization: Bearer <token>`. Refresh token (30j) pour renouvellement.
- Routes publiques : `/auth/**`, `/error`, `/actuator/health`. Tout le reste necessite un JWT valide.
- Endpoints auth : `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`.
- Context path : `/api`. `JwtFilter` valide le token avant chaque requete.

### Design System SCSS (Angular)

Composants utilisent UNIQUEMENT `var(--token-name)`, jamais d'import SCSS direct. Structure dans `app/src/styles/` (tokens, themes light/dark, reset, base, utilities). Couleur primaire : Amber (#f59e0b). Police : Inter.

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

### Backend (api/)

- Java 21, Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6
- PostgreSQL 15+, Flyway migrations V1-V11
- JUnit 5, Spring Boot Test, Mockito, H2 (profil test)

### Frontend PWA (app/)

- TypeScript 5.9, Angular 21, RxJS, Angular Reactive Forms
- Angular Signals, Angular Router (lazy-loaded), Angular CDK
- SCSS design tokens, Vitest

### Mobile natif (flutter/)

- Dart >= 3.6, Flutter >= 3.27
- flutter_riverpod, go_router, drift, dio, flutter_secure_storage
- freezed, json_serializable, shimmer, intl
- flutter_test, mockito, build_runner

## Recent Changes
- 058-flutter-settings-features: Added Feature enum (Flutter), FeatureConfigNotifier, FeatureSettingsScreen, PreferenceRemoteDataSource; AppConfig extended with enabledFeatures
