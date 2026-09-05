# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

App de gestion de budget. Self-hosted, multi-user (groupe restreint, ~16 comptes actifs, pas d'inscription publique). Isolation stricte des données par user (principe #2 de la constitution). Le suivi vit sur **Linear** (`KKS-*`). GitHub Issues n'est pas le tableau du projet mais **la porte d'entree des contributeurs externes**, qui n'ont pas acces a Linear : trois modeles dans `.github/ISSUE_TEMPLATE/`, et ce qui merite un ticket en recoit un cote Linear.

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

> **Maven doit tourner sous Java 21**, la version de la CI. `java -version` peut
> afficher 21 pendant que Maven utilise un autre JDK — c'est `JAVA_HOME` qui
> decide, verifier avec `mvn -version`. Un JDK plus recent fait echouer
> l'instrumentation JaCoCo sur une erreur opaque ; le `maven-enforcer-plugin`
> intercepte le cas et affiche la marche a suivre.

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

1. **API-First** : l'API est la source de verite unique pour tous les clients. DTOs obligatoires, jamais d'entite JPA exposee. Endpoints metier servis sous `/api/v1` (KKS-313) — une seule version servie a la fois, jamais deux en parallele. `/api/meta` pour la detection d'incompatibilite. Jamais retirer/renommer un champ de reponse — voir [`docs/api-compatibility.md`](docs/api-compatibility.md) pour les six regles et la procedure de rupture assumee.
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
| [`.specify/memory/constitution.md`](.specify/memory/constitution.md) | **Constitution du projet** (v4.0.0) — principes fondateurs. Fait autorite sur toute autre documentation |
| [`docs/architecture.md`](docs/architecture.md) | Structure du code, securite, profils Spring, decisions techniques, modele de donnees (18 entites) |
| [`docs/vision.md`](docs/vision.md) | Vision produit, modules fonctionnels |
| [`docs/api-examples.md`](docs/api-examples.md) | Exemples requetes/reponses par endpoint |
| [`docs/api-errors.md`](docs/api-errors.md) | Contrat erreurs HTTP |
| [`docs/api-compatibility.md`](docs/api-compatibility.md) | **Politique de compatibilite d'API** (KKS-315) — les six regles d'ecriture et la procedure de rupture assumee. A consulter avant toute modification de DTO, de migration Flyway ou de parsing client |
| [`docs/deployment.md`](docs/deployment.md) | Deploiement Docker/bare-metal |
| [`DESIGN.md`](DESIGN.md) | Reference design : principes, couleurs, patterns, tokens |
| [`DESIGN-REFONTE.md`](DESIGN-REFONTE.md) | Changelog design : 20 sessions de decisions et justifications |
| [`docs/direction.md`](docs/direction.md) | **Direction produit (2026-08-26)** : ouverture open source, positionnement, decisions et alternatives ecartees |
| [`docs/roadmap-v2.md`](docs/roadmap-v2.md) | *(archive)* Roadmap V2 : bilan de livraison, decisions historiques. Ne decrit plus la trajectoire |
| [`docs/dette-technique.md`](docs/dette-technique.md) | Registre des dettes techniques identifiees |
| [`docs/pwa-install.md`](docs/pwa-install.md) | Guide d'installation PWA (Android/iOS) |
| [`docs/manual-test-plan.md`](docs/manual-test-plan.md) | Plan de tests manuels (Angular + Flutter) |
| **Swagger UI** | `http://localhost:8080/api/swagger-ui.html` — profil `dev` uniquement. Desactivee par defaut ailleurs, reactivable via `SWAGGER_ENABLED=true` (KKS-311) |

## Processus de release

La version vit dans **quatre** fichiers, tous a incrementer ensemble :

| Fichier | Format |
|---------|--------|
| `VERSION` | `6.1.0` |
| `api/pom.xml` | `<version>` du projet, pas celle du parent Spring Boot |
| `app/package.json` | champ `version` |
| `flutter/pubspec.yaml` | `6.1.0+2` — le `+N` suit le rythme des depots sur les stores, pas celui des releases |

Le workflow `version-check` compare les quatre sur toute PR vers `main` et nomme
le fichier fautif. Avant KKS-314, `flutter/pubspec.yaml` etait fige a `1.0.0+1`
et hors du controle : l'incoherence n'apparaissait qu'apres publication, dans le
champ `serverVersion` de `/api/meta`.

Le reste du processus :

1. Mettre a jour `CHANGELOG.md` — bloc `Unreleased` promu, liens de comparaison
2. Commit sur `develop`, puis PR `develop` -> `main` (le push direct sur `main`
   est bloque)
3. **Ne jamais pousser le tag** : la CI le cree au merge, apres le gate de tests
   et la publication des images. Un tag `vX.Y.Z` implique donc qu'une image
   `:X.Y.Z` existe

## Recent Changes

> Historique complet : `git log --oneline`. Seules les 5 dernieres features sont listees ici.

- **KKS-353 — Depot recree sous le nom `kbudget`, historique reecrit** : une photo d'avatar d'un utilisateur reel dormait dans l'historique git, avec un mot de passe de base de dev et 48 commits portant une ligne `Co-Authored-By`. `git-filter-repo` a traite les trois en un passage — mais **le `push --force` n'a rien resolu** : GitHub maintient un ref en lecture seule par pull request, `refs/pull/N/head`, qu'aucun push ne peut ecraser ni supprimer. Un clone `--mirror` recuperait encore tout. Le depot a donc ete **recree de zero** et l'ancien supprime, seule voie dont le resultat soit verifiable sans dependre du support GitHub. **Verifier toute reecriture d'historique sur un clone `--mirror`** : un clone ordinaire ne recupere pas `refs/pull/*` et donne un resultat faussement vert. Le renommage a corrige au passage la seule incoherence de nom restante — les artefacts publies (`k-budget-api`, `k-budget-app`, `k_budget`) ne dependent pas du nom du depot et n'ont pas bouge. Corollaire durable : toute donnee sensible qui passe par une pull request devient indelebile.
- **KKS-354 — Donnees de dev en dates relatives et sur deux utilisateurs** : le seed `R__dev_seed.sql` figeait ses 43 transactions sur des dates absolues d'avril, si bien qu'une capture prise en septembre montrait une application vide. Les dates sont desormais exprimees en `CURRENT_DATE - INTERVAL 'N days'`, et deux comptes coexistent pour montrer l'isolation par utilisateur. Piege consigne : `/budgets` redirigeait silencieusement vers le dashboard parce que `BUDGETS` manquait dans `enabled_features` — une capture nommee `budgets.png` montrait en fait le dashboard.
- **KKS-351 — Une seule longueur minimale de mot de passe, 12 caracteres** : le projet en appliquait quatre — 12 au changement et a la premiere connexion, 8 a l'acceptation d'invitation, 6 annonces au login pour verifier un mot de passe existant. L'ecran Angular de premiere connexion annoncait 8 face a un serveur exigeant 12 : la saisie passait cote client puis echouait en 400, et `mapAuthError` affichait le message brut de Bean Validation, en anglais. **Changement de comportement** : l'acceptation d'invitation passe de 8 a 12, un client ancien verra une acceptation refusee. La valeur ne vit plus qu'a un endroit par stack (`PasswordPolicy`, `password.constants.ts`, `password_policy.dart`) contre quatorze fichiers auparavant. Les `VALIDATION_ERROR` se formulent depuis `details` (`field`/`code`), jamais depuis le `message` anglais.
- **KKS-312 — DT-006 resolue : la CI APP ne depend plus du runner self-hosted** : la suite echouait a 415 tests sur 507 des que deux `.spec.ts` partageaient un worker vitest. **La cause n'etait pas celle documentee** : `setupFiles` ne s'executait jamais, `src/test-setup.ts` etant absent de l'`include` de `tsconfig.spec.json` — le plugin Angular rend une sortie vide pour un fichier hors de son programme TypeScript, et vitest charge un module vide sans erreur. Sans lui, les hooks de nettoyage du TestBed n'etaient jamais poses ; l'init manuelle dans 47 specs compensait le symptome. `setupTestBed()` d'analog les remplace. Le job `test-app` du gate de release passe sur `ubuntu-latest`, et `ci-app.yml` gagne un job de tests sur runner GitHub — le seul qu'une PR de fork puisse executer. Le job Sonar reste self-hosted : il joint SonarQube par le reseau Docker interne, ce qui n'a rien a voir avec DT-006.
- **KKS-309 — Ecran de reinitialisation a la premiere connexion (Flutter)** : un compte provisionne par l'administrateur — dont l'admin seed cree au premier demarrage de toute installation — se connectait, entrait dans le dashboard, puis voyait chaque appel rejete en 403 sans aucune sortie. La racine n'etait pas l'ecran manquant : le DTO `AuthResponse` cote Flutter ne declarait pas `mustResetCredentials`, pourtant servi par l'API. Etat represente par un variant sealed dedie plutot qu'un booleen sur `authenticated` — un nouveau type est visible dans les `is`, un champ optionnel s'oublie. Redirection dans le `redirect` global de GoRouter, a l'interieur du bloc `dataMode == server`, donc inatteignable en mode local. `jwt_interceptor` intercepte le 403 `PASSWORD_RESET_REQUIRED` pour le cas ou le flag n'a pas ete vu a la connexion.
