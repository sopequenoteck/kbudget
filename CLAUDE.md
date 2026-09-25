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

## Recent Changes

> Historique complet : `git log --oneline`. Seules les 5 dernieres features sont listees ici.

- **KKS-378 — Dettes et abonnements dans les catalogues** : etape 6/8 de KKS-325. `DEBT_TYPE_LABEL_KEYS` (Borrowed / Lent, jamais *loan*) et `SUBSCRIPTION_FREQUENCY_*_KEYS` a cote des enums dans `core/models`. **Mis en commun** apres une premiere version a 67 lignes dupliquees : `shared/utils/relative-due-date.utils.ts` (echeance relative, aussi pour `recurring-list`) et `ConfirmService.confirmDelete` (confirmation de suppression, aussi pour `transaction-form`) — a reutiliser plutot que d'ecrire une variante. `debt-form`, `subscription-form` et `transaction-form` restent jumeaux : toute ligne modifiee dans l'un risque de compter en duplication.
- **KKS-377 — Transactions et recurrences dans les catalogues** : etape 5/8 de KKS-325. Ecran des transactions, `transaction-form`, `recurring-list` ; pluriels ICU (« 1 charge » au lieu de « 1 charges ») et « 0 revenus » devenu « 0 recettes », seuls changements visibles. **Piege de mesure** : `transactions.ts` n'avait aucun test et figurait au lcov avec `LF:0` — ni la mesure locale ni Sonar ne comptaient ses lignes nouvelles, la couverture affichait 100 %. Verifier qu'un fichier touche a des donnees de couverture, pas seulement le pourcentage. Bouchon `IntersectionObserver` partage dans `src/testing/intersection-observer-stub.ts` (ecrans a en-tete collant).
- **KKS-374 — Textes partages d'Angular dans les catalogues** : etape 2/8 de KKS-325, **aucun changement visible**. 145 cles tirees de `shared/` et `core/`, vocabulaire `common.*` fixe pour les etapes 3 a 7. Regle nee de la relecture : **les donnees portent des cles, le template traduit** — un `translate()` dans un `computed()` ou un defaut d'`input()` n'aurait pas suivi la bascule de KKS-380 (navigation, bouton +, titres de modale etaient touches). `FEATURES.label` devient `labelKey` (`common.nav.*`). `i18n-catalogue.spec.ts` refuse desormais une cle qui nomme le widget (`bankNameLabel` etait passe). Piege CI : un spec qui rend le `Shell` fait emettre de vraies requetes a jsdom sans `provideHttpClientTesting()` — rejets non geres en CI seulement.
- **KKS-373 — Infrastructure i18n Angular et preference de langue** : etape 1/8 de KKS-325, **aucun changement visible** (francais par defaut jusqu'a KKS-380). API : `language` sur `UserPreference`, chaine BCP 47 validee par motif et **pas un enum** (ajouter une langue communautaire ne doit exiger aucune release), nullable sans defaut (V38) car `NULL` = "pas choisi", ce dont KKS-380 aura besoin pour la langue du navigateur. Angular : Transloco + MessageFormat (ICU), catalogues `/i18n/` charges a l'execution et mis en cache par le service worker, `LanguageService` (`activeLanguage`, `displayLocale`), `APP_LOCALE` supprime, pipes de formatage impurs caches par locale, catalogue d'erreurs de KKS-324 dans `errors.api.*`, `provideTranslocoTesting()` pour vitest. **Pas de reglage `interpolation` a accolade simple** : Transloco interpolerait avant MessageFormat et viderait les pluriels ICU, test a l'appui. **Quatre cycles de Quality Gate**, dont deux pieges durables : un `prettier --write` sur des fichiers existants cree de la duplication nouvelle dans les composants jumeaux ; et Sonar determine le nouveau code par `git blame`, qu'il met en cache par contenu de fichier — une ligne modifiee puis restauree reste "nouvelle". D'ou la PR #22 en commit unique (remplace #18) et `sonar.scm.forceReloadAll=true`.
- **KKS-383 — Les lignes d'un releve arrivent categorisees par l'historique** : aucun compte n'avait de regle, 104 transactions importees sur 130 restaient sans categorie. `CategorySuggestionService` : regle, puis categorie majoritaire chez le meme commercant **au meme montant** (distingue les abonnements factures sous un meme libelle), puis tous montants ; meme sens exige. Le commercant est compare par `MerchantKey` ; **le libelle nettoye affiche ne change pas**, KKS-382 s'en sert pour reconnaitre les lignes deja importees. Une correction pendant la revue se propage aux lignes du meme commercant et cree une regle `AUTO`, reconnue par **mots entiers** (une cle courte comme `Y B` ne doit pas reconnaitre `EASY BAR`). Corrige aussi un defaut ancien : `READY` -> `READY` etait refuse, donc aucune ligne prete ne pouvait etre categorisee pendant la revue. Releve reel suivant : 32 lignes nouvelles sur 54 categorisees.
