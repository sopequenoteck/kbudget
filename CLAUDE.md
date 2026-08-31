# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

App de gestion de budget. Self-hosted, multi-user (groupe restreint, ~16 comptes actifs, pas d'inscription publique). Isolation stricte des données par user (principe #2 de la constitution). Issues sur **Linear** (`KKS-*`), pas GitHub Issues.

## Commandes

### Backend (api/)

```bash
cd api && mvn clean compile       # Build
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev  # Lancer (profil dev)
cd api && mvn test                # Tests
cd api && mvn test -Dtest=NomDuTest  # Test unique
cd api && mvn verify              # Tests + rapport couverture jacoco (target/site/jacoco/)
cd api && mvn clean install       # Build complet avec tests
```

> Le profil `prod` est le défaut. En dev, activer `dev` explicitement. Toutes les commandes Maven depuis `api/`.

### Frontend (app/)

```bash
cd app && ng serve                # Dev server (http://localhost:4200)
cd app && ng build                # Build
cd app && npm test                # Tests unitaires (vitest)
cd app && npm run test:coverage   # Tests + rapport de couverture (lcov)
cd app && ng build --configuration production  # Build prod
cd app && ng lint                 # ESLint
```

> Toutes les commandes Angular CLI depuis `app/`.

### Flutter (flutter/)

```bash
cd flutter && flutter test             # Tests unitaires + widget
cd flutter && flutter test test/src/features/  # Tests par feature
cd flutter && dart run build_runner build --delete-conflicting-outputs  # Code generation (Drift, Freezed, JSON)
cd flutter && flutter run              # Lancer sur device/simulateur
cd flutter && flutter analyze          # Analyse statique
```

> Toutes les commandes Flutter/Dart depuis `flutter/`.

## Constitution du projet

Le fichier `.specify/memory/constitution.md` (v4.0.0) est le document de reference. 8 principes :

1. **API-First** : l'API est la source de verite unique pour tous les clients. DTOs obligatoires, jamais d'entite JPA exposee. Une seule version d'API servie a la fois + `/api/meta` pour la detection d'incompatibilite. Jamais retirer/renommer un champ de reponse.
2. **Securite par defaut** : JWT sur toutes les routes, filtrage par user authentifie, Bean Validation.
3. **Simplicite & YAGNI** : Controller → Service → Repository. Pas de CQRS/DDD/Event Sourcing.
4. **Mobile-First UX** : saisie en 2-3 interactions, bouton flottant (+) sur tous les ecrans. L'instance de l'utilisateur sera souvent injoignable : degrader proprement, le cache n'est jamais source de verite.
5. **Testabilite** : tests d'integration sur endpoints, tests unitaires sur services. Nommage : `should_[resultat]_when_[condition]`. La suite doit tourner chez un contributeur externe.
6. **Observabilite** : SLF4J/Logback uniquement. INFO pour actions, ERROR pour erreurs. Logs et messages techniques en anglais.
7. **Self-Hosted & Distribution ouverte** : PostgreSQL seule dependance infra. AGPL-3.0 (`api/`, `app/`), MPL-2.0 (`flutter/`). Aucun bridage selon l'origine du build. Anglais par defaut, francais a parite.
8. **Angular, client de reference** : toute feature nait cote Angular. Flutter n'a jamais d'obligation de parite — frontiere a 3 etats **Suivi / Gele / Jamais**. Verifier l'etat d'une surface avant tout portage.

## Conventions backend

- DTOs separent TOUJOURS la couche API de la couche persistance
- Enums pour les valeurs fixes du domaine (package `enums/`)
- Lombok obligatoire (`@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`)
- Chaque requete filtre par le user authentifie (isolation des donnees)
- Inputs valides via Bean Validation (`@Valid`, `@NotNull`, `@Size`)
- Branches feature : `feature/<nom>`

## Conventions Angular

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

### Design System

Source de verite : [`DESIGN.md`](DESIGN.md). Quiet utility dark-first. 4 canaux couleur : amber (action), vert (revenu), rouge (depense), gris (structure). Police : Inter.

- `var(--token-name)` uniquement, jamais de hex/rgba hardcode dans les composants
- Patterns partages dans `_list-patterns.scss` et `_bottom-sheet.scss` — les reutiliser, pas les reinventer
- Avant modification frontend : lire `DESIGN.md` et verifier la conformite
- Commande `/design-check` pour audit de coherence design

## Conventions Flutter

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
- **Design tokens** : Constantes dans `flutter/lib/src/constants/` (AppColors, AppSpacing, AppTypography, AppRadius, AppShadows, AppDurations) — jamais de valeurs hardcodees
- **Navigation** : `context.push()` / `context.go()` via go_router
- **Skeleton loading** : Package `shimmer` avec widgets `_XxxSkeleton` prives
- **Code generation** : `build_runner` pour Drift, Freezed, json_serializable — fichiers `.g.dart` et `.freezed.dart` gitignores (generes localement)

### Tests Flutter

- Nommage : `should_[resultat]_when_[condition]`
- Structure : `ProviderContainer` avec `overrides` pour mocker les repositories
- Pattern : `notifier()` / `state()` helpers dans chaque fichier test
- Widget tests : `ProviderScope` + `MaterialApp.router` + `AppTheme.light`

## Documentation

| Document | Contenu |
|----------|---------|
| [`docs/architecture.md`](docs/architecture.md) | Structure du code, securite, profils Spring, decisions techniques, modele de donnees (19 entites) |
| [`docs/vision.md`](docs/vision.md) | Vision produit, modules fonctionnels |
| [`docs/api-examples.md`](docs/api-examples.md) | Exemples requetes/reponses par endpoint |
| [`docs/api-errors.md`](docs/api-errors.md) | Contrat erreurs HTTP |
| [`docs/deployment.md`](docs/deployment.md) | Deploiement Docker/bare-metal |
| [`DESIGN.md`](DESIGN.md) | Reference design : principes, couleurs, patterns, tokens |
| [`DESIGN-REFONTE.md`](DESIGN-REFONTE.md) | Changelog design : 20 sessions de decisions et justifications |
| [`docs/direction.md`](docs/direction.md) | **Direction produit (2026-08-26)** : ouverture open source, positionnement, decisions et alternatives ecartees |
| [`docs/roadmap-v2.md`](docs/roadmap-v2.md) | *(archive)* Roadmap V2 : bilan de livraison, decisions historiques. Ne decrit plus la trajectoire |
| [`docs/dette-technique.md`](docs/dette-technique.md) | Registre des dettes techniques identifiees |
| [`docs/pwa-install.md`](docs/pwa-install.md) | Guide d'installation PWA (Android/iOS) |
| [`docs/manual-test-plan.md`](docs/manual-test-plan.md) | Plan de tests manuels (Angular + Flutter) |
| **Swagger UI** | `http://localhost:8080/api/swagger-ui.html` — profil `dev` uniquement. Desactivee par defaut ailleurs, reactivable via `SWAGGER_ENABLED=true` (KKS-311) |

## Recent Changes

> Historique complet : `git log --oneline`. Seules les 5 dernieres features sont listees ici.

- **KKS-308 — Images Docker multi-architecture (v5.4.0)** : images publiees en `linux/amd64` + `linux/arm64`. Les stages de build des deux Dockerfiles sont epingles sur `--platform=$BUILDPLATFORM` : le JAR Maven et le bundle Angular etant independants de l'architecture cible, ils ne passent jamais sous emulation QEMU. Cout mesure : +49 s sur `build-and-push` (5m13s -> 6m02s). `setup-qemu-action` requis pour les `RUN` du runtime arm64 de l'API.
- **KKS-311 — OpenAPI restreinte au profil dev (v5.3.2)** : springdoc desactive par defaut, actif en profil `dev`, reactivable via `SWAGGER_ENABLED=true`. Handler dedie pour `NoResourceFoundException` : une route inconnue repond 404 `NOT_FOUND` au lieu de 500 avec trace ERROR.
- **KKS-307 — Persistance des avatars en Docker (v5.3.2)** : volume nomme `api-avatars` monte sur `/app/data/avatars`. Les fichiers disparaissaient a chaque recreation du container, donc a chaque mise a jour d'image par Watchtower. Reprise des permissions a l'entrypoint, comme `logs`.
- **v5.3.0 — Direction produit open source (constitution v4.0.0)** : `docs/direction.md` acte l'ouverture open source vers la communaute self-hosted, differenciation sur la zone francophone. Constitution v4.0.0 : 8 principes, dont la frontiere Angular (reference) / Flutter (non-paritaire, 3 etats Suivi/Gele/Jamais). `docs/roadmap-v2.md` archive.
- **v5.2.0 — Contrat unifie des erreurs API** : `GlobalExceptionHandler` retourne `{ error, message }` pour toute erreur geree, avec detail structure par champ sur les erreurs de validation (`ValidationErrorDetail`). Verrou transactionnel `ActiveAdminInvariantLock` (`pg_advisory_xact_lock`) empechant deux suppressions concurrentes de desactiver tous les administrateurs actifs.
