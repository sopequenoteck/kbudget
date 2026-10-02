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
- Date metier seule (`AAAA-MM-JJ`) : `parseLocalDate` (`shared/utils/date.utils.ts`), jamais `new Date(x)` qui la lit a minuit UTC, soit la veille dans un fuseau en retard sur UTC. Date du jour a comparer : `toLocalIsoDate(new Date())`, jamais `toISOString()`. La suite vitest tourne par defaut en `America/Los_Angeles` (`vitest.config.ts`, surchargeable par `TZ=`) pour que la CI, en UTC, detecte ces decalages
- Texte traduit : une structure calculee (`computed()`, defaut d'`input()`, constante) porte la **cle**, le template traduit avec le pipe `transloco`. `translate()` en TypeScript seulement au moment d'un evenement (toast, erreur posee dans un handler) : ailleurs il n'est evalue qu'une fois et garderait l'ancienne langue apres une bascule (KKS-374). Exception : un `computed()` qui doit traduire en TS (valeur passee a un composant sans pipe) lit d'abord `LanguageService.activeLanguage()`, la langue **appliquee** apres chargement du catalogue, jamais la preference brute (KKS-380)
- Nom de categorie : toujours via le pipe `categoryName` (ou `categoryDisplayName` en TS), jamais `nom` brut ni le pipe `transloco` sur un nom saisi par l'utilisateur (KKS-395)
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
- **Locale d'affichage** : `displayLocaleProvider` / `intlLocaleProvider` (`features/settings/application/display_locale_provider.dart`), jamais une locale en dur dans `NumberFormat` ou `DateFormat`. `displayLocaleProvider` derive de `languageNotifierProvider` (preference serveur, langue memorisee, langue du systeme, anglais par defaut) ; changer de langue passe par `LanguageNotifier.selectLanguage`. Cles ARB selon [`docs/i18n.md`](docs/i18n.md) (KKS-398, KKS-405)
- **Nom de devise** : `currencyName(currency, l10n)` (`utils/currency_name.dart`) ; l'enum `Currency` ne porte aucun nom (KKS-401, KKS-423)
- **Nom de catégorie** : `categoryDisplayName(nom, systemKey, l10n)` (`utils/category_name.dart`) sur tout site d'affichage, `categorySystemKey` pour les modèles de budget ; jamais `nom` brut, sauf dans l'écran de gestion des catégories, qui masque les catégories système. Tri inchangé sur `nom` (KKS-424)
- **Libellé d'un enum** : fonction de traduction côté présentation (`_featureName`, `_textScaleName` dans `settings_hub_screen.dart`), jamais un getter en français dans `domain/enums` (KKS-403)
- **Texte de notification** : `buildNotificationText(notification, l10n, intlLocale)` (`utils/notification_text.dart`) pour le panneau comme pour la notification système, jamais `title` / `message` bruts ; repli sur le texte stocké sans `params`, pour un type inconnu (`type` nullable, jamais de valeur `unknown` dans l'enum) ou un paramètre requis manquant. Un service sans `BuildContext` lit `appLocalizationsProvider` / `intlLocaleProvider` à l'appel, via son fournisseur (KKS-425)
- **Navigation** : `context.push()` / `context.go()` via go_router
- **Skeleton loading** : Package `shimmer` avec widgets `_XxxSkeleton` prives
- **Code generation** : `build_runner` pour Drift, Freezed, json_serializable — fichiers `.g.dart` et `.freezed.dart` gitignores (generes localement)

### Tests Flutter

- Nommage : `should_[resultat]_when_[condition]`
- Structure : `ProviderContainer` avec `overrides` pour mocker les repositories
- Pattern : `notifier()` / `state()` helpers dans chaque fichier test
- Widget tests : `ProviderScope` + `MaterialApp.router` + `AppTheme.light`
- Localisation : `pumpApp` fournit les delegues et la locale `fr` (parametre `locale`). Un `MaterialApp` de test construit a la main doit fixer `locale: const Locale('fr')`, et tout `ProviderContainer` / `ProviderScope` dont un notifier lit `appLocalizationsProvider` recoit `displayLocaleOverride()` (`test/helpers/display_locale.dart`) : le binding de test annonce `en_US` (KKS-398, KKS-405). Un test de largeur (debordement a 360 px) charge Inter par `loadAppFonts()` (`test/helpers/app_fonts.dart`)

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

- **KKS-387 (API) — Rattrapage de l'historique** : etape 6/6 de KKS-381, partie API (l'ecran viendra apres KKS-386). `/history-cleanup` propose sans rien modifier : paires transaction importee ↔ saisie non importee selon les criteres de KKS-385 (`ImportMatchingService.inWindowOfImported`, fenetres partagees), paiements d'abonnement multiples sur une echeance (`SubscriptionPeriod`), transactions sans categorie regroupees par `MerchantKey` et sens avec suggestion (regle, historique au montant, historique du commercant), ajustements `probablyUnnecessary` au regard du dernier solde bancaire connu (KKS-384). Ecritures explicites : fusion (la saisie est conservee, recoit l'empreinte et, a defaut, le lien d'abonnement ; l'importee est supprimee ; refus si une dette serait perdue), fusion de paiements d'abonnement, categorisation d'un groupe + regle `AUTO`. Conflits `409 CLEANUP_PROPOSAL_STALE` / `CLEANUP_DEBT_LINK_MISSING`. Pas de suppression d'ajustement (l'API refuse deja de supprimer un `AJUSTEMENT`).
- **KKS-385 — Import : date d'achat et rapprochement** : etape 4/6 de KKS-381. La ligne garde la date comptable (empreinte inchangee) et gagne `purchaseDate` (`PurchaseDateSpec`), date de la transaction creee. `ImportMatchingService` rapproche, entre les passes 2 et 3 du dedoublonnage, une ligne d'une transaction **sans empreinte** du meme compte, meme type et meme montant, **sans critere de libelle**, dans une fenetre : ±8 j si la transaction est liee a un abonnement, ±2 j autour de la date d'achat, sinon de −5 a +1 j autour de la date comptable. Candidat unique → `matchedTransactionId` (la confirmation pose l'empreinte sur la transaction existante, rien n'est cree) ; plusieurs → `DUPLICATE` + `matchCandidateIds` ; `PUT` de ligne : `matchedTransactionId` / `clearMatch`. Detail `matchedTransaction` / `matchCandidates` charge en une requete filtree par utilisateur et compte. Un abonnement apprend la cle commercant de ses prelevements (`statementMerchantKey`) et l'import rattache ensuite la ligne de meme cle et meme montant. `pay()` idempotent sur l'echeance courante (`SubscriptionPeriod`, `Clock` injectee). Migration V42. `ApiContractIT.MAX_DEPTH` passe a 8.
- **KKS-384 — Import : solde verifie et compte reconnu** : etape 3/6 de KKS-381. L'en-tete du releve (`statementHeader` du profil) donne suffixe de compte (4 derniers chiffres, jamais le numero complet), solde et date du solde, stockes sur le brouillon (migration V41, colonnes nullable). Le brouillon expose `projectedBalance` et, au premier import du compte, `proposedOpeningBalance` ; `POST .../confirm` accepte un corps optionnel `applyOpeningBalance`. La reponse de confirmation porte `balanceCheck` : ecart `computed − bank` et `suspects` (transactions de la periode du releve, de sa premiere ligne a max(derniere ligne, date du solde), qu'aucune ligne n'explique, hors `AJUSTEMENT`). Le compte est associe a « cle de profil (`REGISTRY:<bankCode>` / `CUSTOM:<id>`) + suffixe » ; `/imports/detect` renvoie `accountSuffix` et `suggestedAccountId` (unique compte actif correspondant, sinon null). Calculs dans `ImportBalanceService`.
- **KKS-440 — Profils d'import en fichiers, format reconnu depuis le fichier** : partie minimale de KKS-329. Profils embarques en YAML versionne (`api/src/main/resources/import-profiles/*.yaml`, SnakeYAML `SafeConstructor`), charges par `ImportProfileRegistry` (composant Spring) ; un fichier invalide est ignore avec un WARN. `ImportProfileDetector` reconnait le format par signature de colonnes (trim, casse respectee comme a la lecture) : profils embarques, puis profils personnalises de l'utilisateur (le plus recent), puis repli sur la banque du compte. `POST /imports/detect` sans effet de bord. `StatementHeaderSpec` et `PurchaseDateSpec` : extraction pure de l'en-tete bancaire et de la date d'achat. Repertoire externe et metadonnees de contribution restent dans KKS-329.
- **KKS-439 — Traduction communautaire par pull request** : le depot accepte une nouvelle langue par PR (Weblate reporte au premier traducteur, KKS-327). `i18n-catalogue.spec.ts` decouvre tout `public/i18n/*.json` (`node:fs`) et le compare a `en.json` : aucune cle inconnue, toutes les cles pour une langue de `SUPPORTED_LANGUAGES`, memes arguments ICU (`plural` / `select` compris), ICU valide via `@messageformat/parser` (devDependency, jamais importe hors `*.spec.ts`), `availableLangs` d'`app.config.ts` = `SUPPORTED_LANGUAGES` ; la convention de cles porte sur `en.json`. Pendant Flutter `test/src/localization/arb_catalogue_test.dart` sur `app_*.arb` (placeholders par un extracteur ICU minimal, `@@locale` = nom de fichier, `supportedLanguages` = `languageNativeNames`, un ARB par langue activee ; validite ICU laissee a `gen-l10n`). `intlLocaleFor` retombe sur `en_GB`. Politique (activation a 100 % par client, jamais retiree, traduction partielle fusionnable) et liste de controle d'activation dans `docs/i18n.md` (« Adding a language »), guide « Translating k-budget » dans `CONTRIBUTING.md`.
