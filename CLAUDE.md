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
- ESLint + Prettier configures (`ng lint`, `npm run format`). **Ne formater que les fichiers crees** : reformater un fichier existant en fait du nouveau code pour Sonar, et des blocs jumeaux entre composants deviennent de la duplication nouvelle (Quality Gate echoue, KKS-373). plus d'une centaine de fichiers ne passent deja pas Prettier et la CI ne le controle pas
- Locale d'affichage : `LanguageService.displayLocale()` (`fr-FR`, `en-GB`), jamais une locale en dur dans `Intl`, `toLocaleString` ou `localeCompare`. Formatages partages dans `shared/utils/locale-format.utils.ts`. Cles et glossaire : [`docs/i18n.md`](docs/i18n.md)
- Texte traduit : une structure calculee (`computed()`, defaut d'`input()`, constante) porte la **cle**, le template traduit avec le pipe `transloco`. `translate()` en TypeScript seulement au moment d'un evenement (toast, erreur posee dans un handler) : ailleurs il n'est evalue qu'une fois et garderait l'ancienne langue apres une bascule (KKS-374)
- `[innerHTML]` uniquement pour une traduction qui porte du balisage (`<strong>`), et **toute donnee utilisateur interpolee passe par `escapeHtml`** (`shared/utils/html-escape.utils.ts`) : MessageFormat n'echappe pas ses parametres et le sanitizer d'Angular laisse passer `<a>`/`<img>` (KKS-376)

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
| [`docs/i18n.md`](docs/i18n.md) | **Convention i18n et glossaire EN/FR** (KKS-328) — structure des cles `domaine.contexte.element`, listes fermees des domaines et contextes, passage Transloco → ARB, ICU, glossaire. A consulter avant toute cle ou traduction |
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

## Zones sensibles (mode auto)

Regles lues par Claude et par le classifier du mode auto. Elles etaient auparavant dans `~/.claude/settings.json`.

- **Profil prod par defaut** : le profil Spring `prod` est actif sans option. Traiter `cd api && mvn clean install` visant `main` comme adjacent a un deploiement de production.
- **Fichiers proteges** : `deploy/Caddyfile` et `deploy/nginx.conf` (proxy d'entree, frontiere de confiance `TRUSTED_PROXIES` et rate limiting), `app/src/environments/environment.prod.ts`, `.env`. Ne pas les modifier sans demande explicite.
- **Donnees utilisateurs** : donnees financieres personnelles, multi-utilisateurs. Ne jamais croiser les frontieres entre utilisateurs ni exposer les donnees d'un utilisateur a un autre.
- **Secrets CI** : `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `SONAR_TOKEN` sont des noms de secrets GitHub. Ne jamais en ecrire ni en rechercher les valeurs.

## Recent Changes

> Historique complet : `git log --oneline`. Seules les 5 dernieres features sont listees ici.

- **KKS-393 — Noms de devises dans les catalogues** : derniers textes en dur avant KKS-380. Une cle par code (`exchangeRates.value.<code>`), `SUPPORTED_CURRENCIES` / `CURRENCY_SYMBOLS` / `CURRENCY_NAME_KEYS` dans `core/models/currency.model.ts` — **seule liste de devises cote Angular**, ne pas en recreer. `CurrencyInfo.name` (francais, servi par l'API) n'est plus affiche que pour un code inconnu ; il reste servi. `Intl.DisplayNames` ecarte : il change le texte francais et n'a pas d'equivalent Flutter.
- **KKS-375 — Reglages dans les catalogues** : etape 3/8 de KKS-325, **derniere extraction par domaine** — tout `app/src` passe par les catalogues, sauf les listes de noms de devises en dur (`currency-list.ts`, `accept-invite.ts`, `flutter/.../currency.dart`), a trancher avant KKS-380. Nouveau domaine `users` (« Mon compte » = *Profile*). `ACCOUNT_TYPE_LABEL_KEYS` dans `core/models/account.model.ts` : la liste des comptes affichait le code brut `COURANT`. `FEATURES.description`, lu nulle part, supprime. Sept ecrans sans test ont recu leur spec.
- **KKS-376 — Import CSV dans les catalogues** : etape 4/8 de KKS-325. Profils, brouillons, regles, `csv-mapping`, `import-review` → `imports.*` ; statuts et origines de profil via `IMPORT_LINE_STATUS_LABEL_KEYS` / `IMPORT_PROFILE_SOURCE_LABEL_KEYS`. **Faille evitee a la relecture** : le bandeau de suggestion de regle interpolait le libelle du releve et le nom de categorie dans un `[innerHTML]` — d'ou `escapeHtml`, test d'injection verifie rouge sans lui. Deux ecrans sans test (`import-settings`, `csv-mapping`) ont recu leur spec.
- **KKS-379 — Budgets, dashboard, auth et compatibilite dans les catalogues** : etape 7/8 de KKS-325, derniere extraction par domaine. « Patrimoine total » sous `accounts.summary.netWorth` ; `dashboard.*` ne garde que le texte sans domaine (salutation, bilan du mois). `password.constants.ts` ne garde que les longueurs, les messages sont des cles ICU parametrees. `budget-chart.ts`, importe nulle part depuis la v5, est supprime. **Premier `[innerHTML]`** (`incompatible.html`) : numero de version en `<strong>` dans une phrase entiere, valeurs = numeros de version, sanitizer Angular, aucun `bypassSecurityTrust`. Six ecrans sans test (`LF:0`) ont recu leur spec.
- **KKS-378 — Dettes et abonnements dans les catalogues** : etape 6/8 de KKS-325. `DEBT_TYPE_LABEL_KEYS` (Borrowed / Lent, jamais *loan*) et `SUBSCRIPTION_FREQUENCY_*_KEYS` a cote des enums dans `core/models`. **Mis en commun** apres une premiere version a 67 lignes dupliquees : `shared/utils/relative-due-date.utils.ts` (echeance relative, aussi pour `recurring-list`) et `ConfirmService.confirmDelete` (confirmation de suppression, aussi pour `transaction-form`) — a reutiliser plutot que d'ecrire une variante. `debt-form`, `subscription-form` et `transaction-form` restent jumeaux : toute ligne modifiee dans l'un risque de compter en duplication.
