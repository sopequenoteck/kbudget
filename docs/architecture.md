# Budget App — Architecture technique

Ce document couvre les decisions techniques, la securite, le modele de donnees et la vision frontend.

## Structure du code

### Backend (api/)

```
api/src/main/java/fr/kksdev/budget/api/
├── config/        # SecurityConfig, ApiVersioningConfig, JwtFilter, RateLimitFilter, ClientIpResolver,
│                 PasswordResetRequiredFilter, AdminAuthorizationFilter, JwtUtil,
│                 GlobalExceptionHandler, WebSocketConfig, StompAuthInterceptor, SchedulingConfig
├── meta/          # MetaController — hors de controller/, donc hors versionnement (KKS-314)
├── controller/    # REST endpoints (Auth, Transaction, RecurringTransaction, Subscription, Debt, Category, Account, Bank, Budget, ExchangeRate, Currency, Preference, Notification, Import, User, Dev)
├── service/       # Logique metier
├── repository/    # Spring Data JPA
├── runner/        # ApplicationRunner de boot (BootstrapSeedRunner, AdminSyncRunner,
│                 #   DevCurrentMonthSeedRunner en profil dev)
├── exception/     # Exceptions metier (ConflictException, TokenExpiredException, FeatureDisabledException...)
├── util/          # ImageMimeValidator, PasswordGenerator
├── model/         # Entites JPA (User, Transaction, Subscription, Debt, Category, RefreshToken, Account, ExchangeRate, UserPreference, Notification, Budget, BudgetSnapshot, ImportDraft, ImportDraftLine, CategoryRule, ImportHistory, ImportProfile, Invitation) + Bank (record, non-persiste)
├── dto/
│   ├── request/   # DTOs d'entree (validation Bean Validation)
│   └── response/  # DTOs de sortie
└── enums/         # TransactionType, Frequency, DebtType, TokenStatus, AccountType, Feature, Currency, NotificationType, EntityType, ImportDraftStatus, ImportLineStatus, ImportProfileSource
```

### Frontend (app/)

```
app/src/
├── app/
│   ├── core/          # Services singleton, guards, interceptors
│   ├── shared/        # Composants/pipes/directives reutilisables
│   └── features/      # Modules lazy-loaded par feature
├── environments/      # Config dev/prod (apiUrl)
└── styles/            # SCSS globaux
```

Architecture en couches : Controller → Service → Repository. Les entites JPA ne sont jamais exposees directement — toujours via DTOs.

## Securite

- JWT stateless. Access token (15 min), refresh token (30 jours)
- Toutes les routes protegees sauf `/api/v1/auth/**`, `/api/actuator/health`, `/api/v1/banks`, `/api/bank-logos/**` et `/ws/**` (auth WebSocket via StompAuthInterceptor)
- Chaque requete filtre les donnees par l'utilisateur authentifie (isolation)
- Mots de passe hashes en BCrypt
- Inputs valides via Bean Validation (`@Valid`, `@NotNull`, `@Size`, `@Positive`)

### Controle d'acces admin (KKS-232 + KKS-233)

- **`User.isAdmin`** (KKS-233) : flag boolean **autoritaire en DB** (`users.is_admin`, colonne ajoutee via migration V30, defaut `FALSE`). Remplace la resolution dynamique via `ADMIN_EMAILS` pour eviter qu'un self-hoster perde son acces admin apres un changement d'email.
- **`AdminEmailResolver`** (KKS-232) : composant Spring lisant la property `app.admin-emails` (env var `ADMIN_EMAILS`, liste CSV). Normalise trim+lowercase au `@PostConstruct`. Expose `isAdminEmail(email)` + `listAdminEmails()`. Emet `WARN` au boot si la liste est vide. **Depuis KKS-233, il n'est plus utilise pour l'autorisation** — uniquement consomme par `AdminSyncRunner` et par les services d'invitation.
- **`AdminSyncRunner`** (KKS-233) : `ApplicationRunner @Order(2)`, `@Transactional`. Au boot, pour chaque email de `ADMIN_EMAILS` : si le user existe avec `isAdmin=false`, passe a `true` (promotion). **Jamais de retrogradation** (`true → false`). Idempotent.
- **`DevCurrentMonthSeedRunner`** (KKS-355) : `ApplicationRunner @Order(3)`, **`@Profile("dev")`**. Genere dix transactions sur les jours ecoules du mois courant pour `dev@local.test` et pour `demo@local.test` (miroir anglais, libelles traduits, KKS-394), en reutilisant les categories et le compte du seed de chacun — il n'en cree aucun. Idempotent (garde sur l'existence d'une transaction du mois), et jamais de date future : chaque jour cible est ramene a aujourd'hui s'il deborde, ce qui couvre le 1er du mois. **La garde de profil n'est pas un detail de configuration** : le profil `prod` est le defaut du projet, un runner mal garde injecterait de fausses transactions chez un self-hoster. Un test l'enregistre dans un contexte Spring reel et verifie que le bean n'existe pas hors du profil `dev`.

  Il existe parce que `R__dev_seed.sql` est une migration *repeatable* : elle ne rejoue que si son checksum change. Ses dates sont relatives a `CURRENT_DATE` (KKS-354), donc une base recreee est fraiche — mais une base conservee plusieurs mois se retrouve sans aucune transaction sur le mois en cours.
- **`MetaController`** (KKS-314) : expose `GET /api/meta` — `serverVersion`
  (derivee du build via `BuildProperties`), `apiVersion`, `minClientVersion`
  (property `app.meta.min-client-version`) et `capabilities` (valeurs de
  `Feature`). **Vit hors du package `...api.controller`** : `ApiVersioningConfig`
  y prefixerait le chemin, or un client ne peut pas deviner le prefixe du serveur
  qu'il interroge — c'est precisement ce qu'il vient lui demander. Public, et
  ajoute a l'allowlist de `PasswordResetRequiredFilter` : le bloquer ferait
  conclure le client a une incompatibilite alors que le compte attend un reset.
- **`ApiVersioningConfig`** (KKS-313) : `WebMvcConfigurer` prefixant tous les controllers du package `fr.kksdev.budget.api.controller` avec `CURRENT_VERSION_PREFIX` (`/v1`), via `PathMatchConfigurer.addPathPrefix`. Le predicat cible le **package** et non l'annotation `@RestController` : `HandlerTypePredicate` combine ses selecteurs par OU, si bien qu'ajouter l'annotation elargirait la selection aux controllers des bibliotheques tierces (springdoc se retrouvait servi sous `/v1/v3/api-docs`). Restent hors versionnement : `/actuator/**`, `/error`, `/bank-logos/**`, `/ws/**` et la documentation OpenAPI. Une seule version est servie a la fois — le projet ne fera jamais coexister `/v1` et `/v2`.
- **`AdminAuthorizationFilter`** (KKS-232, refactor KKS-233) : `OncePerRequestFilter` declare via `@Bean` dans `SecurityConfig`. Matche `/v1/admin/` (via `servletPath`, avec fallback sur l'URI et retrait du context-path). Le prefixe est derive de `ApiVersioningConfig.CURRENT_VERSION_PREFIX` (KKS-313) et non ecrit en dur : un litteral se desynchroniserait au prochain changement de version, desactivant ce controle d'acces sans erreur ni test rouge. Resout le statut admin via `user.isAdmin()` (champ DB). Pour un user authentifie non-admin, retourne `ACCESS_DENIED` en 403 via le writer partage. Si non authentifie, laisse l'`ApiAuthenticationEntryPoint` retourner `UNAUTHENTICATED` en 401.
- **`PasswordResetRequiredFilter`** (KKS-233) : `OncePerRequestFilter` declare apres `JwtFilter`. Si le JWT porte le claim `mustResetCredentials: true` et que le path n'est pas dans l'allowlist (`/v1/auth/first-login-reset`, `/v1/auth/logout`, prefixes derives de `ApiVersioningConfig` — KKS-313), renvoie `403 PASSWORD_RESET_REQUIRED`. Sinon laisse passer.
- **`RateLimitFilter`** (KKS-310) : `OncePerRequestFilter` declare **avant** `JwtFilter`, limitant le debit sur les seuls endpoints d'authentification — `/v1/auth/login`, `/v1/auth/refresh`, `/v1/auth/accept-invite` et le prefixe `/v1/auth/invitations/`. Sans lui, le login offre du bruteforce sans cout et la verification d'invitation permet d'enumerer des jetons. Defauts : 5 tentatives par minute et par IP (`RATE_LIMIT_CAPACITY`, `RATE_LIMIT_WINDOW_SECONDS`), rejet en `429 TOO_MANY_REQUESTS`. **La limitation porte sur l'IP, jamais sur le compte** : verrouiller un compte apres des echecs repetes ouvrirait un deni de service cible, ou connaitre l'email de quelqu'un suffirait a l'empecher de se connecter. `/v1/auth/logout` et `/v1/auth/first-login-reset` en sont exclus, ils exigent deja un JWT valide. Compteurs Bucket4j en memoire : une instance self-hosted est un processus unique, et la constitution (principe VII) tient PostgreSQL pour seule dependance d'infrastructure — un redemarrage remet les compteurs a zero, ce qui donne a l'attaquant une fenetre, pas un contournement.
- **`ClientIpResolver`** (KKS-310) : resout l'IP a laquelle imputer une requete. **`X-Forwarded-For` n'est lu que si la requete vient d'un proxy de confiance** (`TRUSTED_PROXIES`, defaut : plages privees) : cet en-tete est fourni par le client, et le lire sans condition permettrait d'y mettre une valeur differente a chaque requete, rendant la limitation decorative. Une instance exposee sans proxy retient l'adresse TCP reelle, non falsifiable. Corollaire cote infra : les proxies de bordure (`deploy/Caddyfile`, `deploy/nginx.conf`) **ecrasent** l'en-tete au lieu de l'enrichir, sinon la valeur envoyee par le client survivrait en tete de chaine.
- **`ClockConfig`** (KKS-355) : expose `Clock.systemDefaultZone()` comme bean. Le code qui manipule des dates l'injecte plutot que d'appeler `LocalDate.now()`, ce qui rend la zone explicite et permet a un test de fournir une horloge fixe. Sans cela, un test date verifie un comportement different selon le jour ou il s'execute — sans que ce soit ni visible ni voulu.
- **Ordre des filters** (apres KKS-310) : `RateLimitFilter` → `JwtFilter` → `PasswordResetRequiredFilter` → `AdminAuthorizationFilter`. `RateLimitFilter` passe en premier parce qu'il protege des requetes qui n'ont pas encore de token a valider : le placer apres `JwtFilter` le rendrait inoperant sur le login, precisement l'endpoint qu'il existe pour proteger. `JwtFilter` refuse aussi les users dont `disabledAt != null` (401 natif).
- **Onboarding controle** : l'inscription publique (`POST /auth/register`) a ete retiree. L'onboarding se fait uniquement via invitation admin : `POST /admin/invitations` (admin cree) → `GET /auth/invitations/:token` (invite verifie) → `POST /auth/accept-invite` (invite finalise son compte + auto-login). Conformite constitution principe VII.
- **Bootstrap premier admin** (KKS-233) : `BootstrapSeedRunner` (`ApplicationRunner @Order(1)`) detecte `userRepository.count() == 0` au premier boot et cree un compte admin seed avec password aleatoire 32 chars (`SecureRandom`, alphanumerique) affiche dans les logs. Flag `passwordResetRequired=true` jusqu'au `POST /auth/first-login-reset`. Conformite principe VII : `docker compose up -d` suffit sur instance vierge.
- **Garde-fou dernier admin** : `AdminUserService.disable` refuse de desactiver le dernier admin actif avec `ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")` → HTTP 409.

## Profils Spring

| Profil | Usage | BDD | DDL |
|--------|-------|-----|-----|
| `dev` | Developpement local | PostgreSQL local, fallback config | `validate` |
| `prod` | Production | Variables d'environnement obligatoires | `validate` |
| `test` | Tests automatises | H2 en memoire | `create-drop` |

## Decisions architecturales

### JWT stateless (pas de sessions/cookies)

L'API utilise des tokens JWT sans etat serveur. Chaque requete porte son token dans le header `Authorization: Bearer <token>`. Pas de table de sessions en base, pas de cookies — le backend reste completement stateless, ce qui simplifie le deploiement et le scaling.

### Un seul module Maven (pas de multi-module)

Le projet tient dans un seul module Maven. La separation se fait par packages (`controller/`, `service/`, `repository/`, etc.), pas par modules. Un multi-module n'apporterait que de la complexite de build sans benefice reel a cette echelle.

### Flyway pour les migrations (pas de ddl-auto en prod)

En production, le schema est gere par Flyway via des scripts SQL versiones. `ddl-auto=validate` s'assure que le code et le schema sont alignes sans jamais modifier la base automatiquement. Seul le profil test utilise `create-drop` avec H2 en memoire.

### DTOs obligatoires (jamais d'entite JPA exposee)

Les entites JPA ne sont jamais retournees directement par les controllers. Des DTOs dedies (request/response) isolent la couche API de la couche persistance. Cela evite d'exposer des champs internes et permet de faire evoluer le schema sans casser le contrat API.

### Pas de CQRS, DDD tactique ou Event Sourcing

L'architecture reste en couches simples : Controller → Service → Repository. Ces patterns complexes n'apportent aucune valeur a l'echelle actuelle du projet. Si un besoin le justifie, il devra etre documente dans le plan avant implementation.

## Modele de donnees

### User

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| email | String | Email (unique) |
| password | String | Mot de passe (hashe, BCrypt) |
| name | String | Nom de l'utilisateur |
| createdAt | LocalDateTime | Date de creation |
| disabledAt | LocalDateTime | Soft-disable (nullable, NULL = actif). Si non null, `JwtFilter` bloque l'authentification |
| isAdmin | boolean | (KKS-233) Statut administrateur autoritaire en DB. Defaut `false`. Mis a `true` au seed bootstrap et par `AdminSyncRunner` pour les users listes dans `ADMIN_EMAILS`. Jamais retrograde automatiquement |
| passwordResetRequired | boolean | (KKS-233) Flag imposant le changement de credentials a la premiere connexion. Defaut `false`. Pose a `true` uniquement par `BootstrapSeedRunner` sur le compte admin seed. Remis a `false` apres `POST /auth/first-login-reset` |

> Depuis KKS-233, `isAdmin` est la **source autoritaire** du statut admin. `ADMIN_EMAILS` n'est plus consulte a chaque requete — il sert uniquement de source de promotion au demarrage via `AdminSyncRunner`.

### Invitation

| Champ | Type | Description |
|-------|------|-------------|
| id | Long | Identifiant auto (BIGSERIAL) |
| token | UUID | Token UUID v4 unique (indexe). Transmis dans le lien d'invitation |
| email | String | Email du futur invite (normalise lowercase) |
| invitedBy | User | FK → User (l'admin emetteur) |
| expiresAt | Instant | `createdAt + 7 jours` |
| usedAt | Instant | Timestamp d'acceptation (nullable) |
| revokedAt | Instant | Timestamp de revocation admin (nullable) |
| createdAt | Instant | Creation |

> Statut derive (non stocke) via `InvitationService.deriveStatus` : REVOKED > USED > EXPIRED > ACTIVE. `usedAt` et `revokedAt` sont mutuellement exclusifs.

### Account

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| nom | String | Nom du compte (max 50 car.) |
| type | Enum | COURANT / EPARGNE / ESPECES |
| soldeInitial | BigDecimal | Solde initial du compte |
| icone | String | Icone (emoji) |
| couleur | String | Couleur hexadecimale (#RRGGBB) |
| isDefault | Boolean | Compte par defaut |
| actif | Boolean | Compte actif ou non |
| currency | Currency | Devise du compte (default EUR) |
| bankCode | String | Code de la banque associee (default "OTHER") |
| bankCustomName | String | Nom personnalise si bankCode="OTHER" (nullable) |
| bankCustomLogo | String | Logo personnalise en base64 data URI (nullable) |
| statementProfileKey | String | Profil du dernier releve importe sur ce compte : `REGISTRY:<bankCode>` ou `CUSTOM:<id du profil>` (nullable, max 64) — KKS-384 |
| statementAccountSuffix | String | 4 derniers chiffres du numero de compte lu dans l'en-tete du releve (nullable, max 4) — KKS-384. Le numero complet n'est **jamais** stocke, ni en clair ni en empreinte |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

> Reconnaissance du compte (KKS-384) : `statementProfileKey` + `statementAccountSuffix` sont ecrits a la confirmation d'un import, sur le compte choisi par l'utilisateur (ils remplacent les precedents de ce compte). `POST /imports/detect` suggere l'unique compte **actif de l'utilisateur authentifie** qui porte la meme paire ; aucune suggestion s'il y en a zero ou plusieurs. Une association n'est jamais lue ni ecrite au-dela de son utilisateur. Le solde d'un compte reste `soldeInitial` + somme de ses transactions, jamais stocke.

### Transaction

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| montant | BigDecimal | Montant |
| libelle | String | Description courte |
| type | Enum | DEPENSE / RECETTE / AJUSTEMENT |
| date | LocalDate | Date de la transaction |
| category | Category | FK → Category (nullable) |
| note | String | Note libre (nullable) |
| account | Account | FK → Account |
| transferId | UUID | ID de virement (nullable, lie les 2 transactions d'un transfert) |
| debt | Debt | FK → Debt (nullable, lie la transaction a un remboursement de dette) |
| subscription | Subscription | FK → Subscription (nullable, paiement d'abonnement) |
| isRecurring | Boolean | Transaction recurrente (default false) |
| frequency | Enum | HEBDOMADAIRE / MENSUEL / ANNUEL (nullable, si isRecurring) |
| nextOccurrence | LocalDate | Prochaine occurrence (nullable, si isRecurring) |
| recurringActive | Boolean | Recurrence active (default true, si isRecurring) |
| importFingerprint | String | Empreinte SHA-256 de la ligne de releve d'origine (nullable, non exposee) — KKS-382 |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

> `importFingerprint` porte sur les donnees du fichier (date comptable, montant, sens, libelle brut), jamais sur les champs modifiables : une transaction importee puis renommee reste reconnue au reimport. Nulle pour une saisie manuelle ; posee a posteriori sur un import anterieur des qu'un releve le reconnait par son libelle. Index `(account_id, import_fingerprint)`.

### Subscription

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| nom | String | Nom de l'abonnement |
| montant | BigDecimal | Montant |
| frequence | Enum | MENSUEL / ANNUEL |
| dateDebut | LocalDate | Date de debut |
| actif | Boolean | Abonnement actif ou non |
| category | Category | FK → Category (nullable) |
| account | Account | FK → Account (nullable) |
| statementMerchantKey | String | Cle commercant (`MerchantKey`) du libelle de releve, apprise quand une ligne est rapprochee d'un de ses paiements ; nullable — KKS-385 |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

### Debt

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| personne | String | Nom de la personne |
| montant | BigDecimal | Montant |
| sens | Enum | EMPRUNT / PRET |
| date | LocalDate | Date |
| currency | Currency | Devise (default EUR) |
| rembourse | Boolean | Rembourse ou non |
| dueDate | LocalDate | Date d'echeance (nullable) |
| account | Account | FK → Account (nullable) |
| includeInBalance | Boolean | Inclure dans le solde total (default false) |
| reminderDate | LocalDate | Date du rappel (nullable) |
| reminderTime | LocalTime | Heure du rappel (nullable) |
| category | Category | FK → Category (nullable) |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

> Remboursements : les transactions de remboursement sont liees a la dette via le champ `debt` (FK `debt_id`) sur l'entite `Transaction`. `DebtPaymentResponse` est un DTO de projection (pas une entite JPA).

### Category

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| nom | String | Nom de la categorie |
| icone | String | Icone (emoji ou identifiant) |
| couleur | String | Couleur hexadecimale (#RRGGBB) |
| isSystem | Boolean | Categorie systeme (non modifiable) |
| systemKey | SystemCategoryKey | Cle stable d'une categorie systeme (`SUBSCRIPTION`, `DEBT`, `TRANSFER`, `ADJUSTMENT`), null pour une categorie utilisateur. Unique par utilisateur (KKS-395) |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

### RefreshToken

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| token | String | Token opaque (unique, max 64 car.) |
| status | Enum | ACTIVE / CONSUMED / REVOKED |
| createdAt | LocalDateTime | Date de creation |
| expiresAt | LocalDateTime | Date d'expiration |
| user | User | FK → User |

### UserPreference

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| enabledFeatures | List\<Feature\> | Features optionnelles activees (VARCHAR via converter) |
| navOrder | List\<Feature\> | Ordre des onglets de navigation (VARCHAR via converter) |
| currencies | List\<Currency\> | Ordre des devises — [0] = devise principale (VARCHAR via converter) |
| enabledNotificationTypes | List\<NotificationType\> | Types de notifications activees (nullable — null = tous actifs, opt-out) |
| timezone | String | Fuseau horaire (default "Europe/Paris") |
| textScale | TextScale | Taille de texte (SMALL/MEDIUM/LARGE, default MEDIUM) |
| language | String | Langue d'interface, code BCP 47 restreint (`en`, `fr`, `pt-BR`). Nullable sans defaut : null = pas choisi, le client suit alors le navigateur (Angular, KKS-373) ou la langue du telephone (Flutter, KKS-405). Retour a null via `DELETE /users/me/preferences/language` (KKS-380) |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | @OneToOne → User (unique, non-null) |

Enums : `Feature` — `SUBSCRIPTIONS`, `DEBTS`, `BUDGETS`. `Currency` — `EUR`, `XOF`, `USD`, `GBP`, `CHF`, `CAD`, `MAD`. `NotificationType` — `SUBSCRIPTION_DUE`, `DEBT_DUE`, `DEBT_REMINDER`, `BUDGET_THRESHOLD`, `BUDGET_EXCEEDED`. `TextScale` — `SMALL`, `MEDIUM`, `LARGE`. Converters JPA : `FeatureListConverter`, `CurrencyListConverter`, `NotificationTypeListConverter`.

### ExchangeRate

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| baseCurrency | Currency | Devise de base (enum) |
| targetCurrency | Currency | Devise cible (enum) |
| rate | BigDecimal | Taux de conversion (precision 20, scale 6, > 0) |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

Contrainte UNIQUE(user_id, base_currency, target_currency). Inversion automatique des taux lors du changement de devise principale via `rebaseRates()`.

### Notification

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| type | NotificationType | SUBSCRIPTION_DUE / DEBT_DUE / DEBT_REMINDER / BUDGET_THRESHOLD / BUDGET_EXCEEDED / RECURRING_TRANSACTION_DUE |
| entityType | EntityType | SUBSCRIPTION / DEBT / BUDGET / TRANSACTION |
| entityId | UUID | ID de l'entite liee |
| title | String | Titre de la notification |
| message | String | Corps du message |
| params | Map<String,String> (JSONB) | Parametres du texte construit par le client, null avant KKS-397 |
| read | Boolean | Lue ou non (default false) |
| readAt | LocalDateTime | Date de lecture (nullable) |
| createdAt | LocalDateTime | Date de creation |
| user | User | FK → User |

### Budget

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| montant | BigDecimal | Montant du budget |
| frequence | Enum | HEBDOMADAIRE / MENSUEL / ANNUEL |
| currency | Currency | Devise (default EUR) |
| seuilNotification | Integer | Seuil d'alerte en % (default 80) |
| actif | Boolean | Budget actif (default true) |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |
| category | Category | FK → Category. UNIQUE(user_id, category_id) |

### BudgetSnapshot

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| montantBudget | BigDecimal | Montant du budget au moment du snapshot |
| currency | Currency | Devise |
| tauxChange | BigDecimal | Taux de change applique (nullable) |
| montantDepense | BigDecimal | Montant depense sur la periode |
| mois | String | Periode au format yyyy-MM |
| createdAt | LocalDateTime | Date de creation |
| user | User | FK → User |
| category | Category | FK → Category |

### ImportDraft

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| status | Enum | PENDING / COMPLETED / EXPIRED |
| fileName | String | Nom du fichier CSV uploade |
| totalLines | Integer | Nombre total de lignes |
| readyCount | Integer | Lignes prates a importer |
| reviewCount | Integer | Lignes a revoir |
| duplicateCount | Integer | Doublons detectes |
| skippedCount | Integer | Lignes ignorees |
| alreadyImportedCount | Integer | Sous-ensemble de skippedCount : lignes ecartees d'office car deja importees (KKS-382) |
| matchedCount | Integer | Sous-ensemble de readyCount : lignes rapprochees d'une transaction existante, qui ne creeront rien ; NOT NULL defaut 0 — KKS-385 |
| profileId | UUID | Identifiant du profil utilise (nullable) |
| profileSource | Enum | ImportProfileSource (REGISTRY / CUSTOM / MANUAL) |
| statementProfileKey | String | Cle du profil du releve (voir Account) ; nullable sans en-tete exploitable — KKS-384 |
| statementAccountSuffix | String | 4 derniers chiffres du numero de compte lus dans l'en-tete (nullable) — KKS-384 |
| statementBalance | BigDecimal | Solde donne par la banque dans l'en-tete du releve (nullable) — KKS-384 |
| statementBalanceDate | LocalDate | Date de ce solde (nullable) — KKS-384 |
| createdAt | LocalDateTime | Date de creation |
| expiresAt | LocalDateTime | Date d'expiration |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |
| account | Account | FK → Account cible. UNIQUE(user_id, account_id) WHERE status = 'PENDING' |

> Solde du releve (KKS-384) : lu a l'upload dans les lignes sautees par `statementHeader` du profil (valeur illisible → `null`, jamais une erreur). `ImportBalanceService` en tire `projectedBalance` (solde de l'application a la date du solde si le brouillon est confirme : `soldeInitial` + transactions du compte datees jusqu'a cette date + lignes `READY` datees jusqu'a cette date), `proposedOpeningBalance` (premier import du compte seulement, c'est-a-dire aucun `ImportHistory` pour ce compte : le `soldeInitial` qui rend le solde de l'application egal au solde bancaire une fois ecartees les transactions de la periode que le releve n'explique pas, les futurs `suspects` — KKS-443) et, apres confirmation, le controle de solde (`balanceCheck`). Le solde de l'en-tete est lu avec `statementHeader.decimalSeparator` (un caractere, optionnel) quand le profil le declare, sinon avec le `decimalSeparator` des lignes : l'en-tete SG ecrit `1842.37 EUR` quand ses lignes ecrivent `-12,50`. Un profil sans `statementHeader` laisse tous ces champs a `null`.

### ImportDraftLine

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| draft | ImportDraft | FK → ImportDraft (CASCADE) |
| lineNumber | Integer | Numero de ligne dans le CSV |
| rawLabel | String | Libelle brut du CSV |
| cleanLabel | String | Libelle nettoye |
| amount | BigDecimal | Montant |
| date | LocalDate | Date de la ligne |
| transactionType | Enum | DEPENSE / RECETTE / AJUSTEMENT |
| status | Enum | READY / NEEDS_REVIEW / DUPLICATE / SKIPPED |
| statusMessage | String | Message technique en anglais d'une ligne illisible, repli d'affichage (nullable) |
| readError | Enum | ImportReadError (INVALID_DATE, INVALID_AMOUNT, UNREADABLE_LINE) — code traduit par le client, nullable (KKS-441) |
| readErrorValue | String(500) | Valeur brute de la cellule fautive, nullable (KKS-441) |
| skipReason | Enum | ImportSkipReason (ALREADY_IMPORTED) — SKIPPED decide par l'import, nullable si ignoree par l'utilisateur (KKS-382) |
| duplicateTransactionId | UUID | ID de la transaction doublon ou deja importee (nullable) |
| purchaseDate | LocalDate | Date d'achat lue dans le libelle brut (paiement carte) quand le profil la declare, nullable ; `date` reste la date comptable — KKS-385 |
| matchedTransactionId | UUID | Transaction existante (saisie manuelle) a laquelle la ligne est rapprochee, nullable, sans FK ; la confirmation la reverifie — KKS-385 |
| matchCandidateIds | Texte | Candidats d'un rapprochement ambigu (statut DUPLICATE) : identifiants separes par des virgules (`UuidListConverter`), nullable — KKS-385 |
| subscriptionId | UUID | Abonnement auquel la transaction creee sera rattachee, nullable, sans FK — KKS-385 |
| category | Category | FK → Category (nullable) |
| categorySource | Enum | CategorySource (RULE / HISTORY / USER), nullable sans categorie — KKS-383 |
| createdAt | LocalDateTime | Date de creation |
| updatedAt | LocalDateTime | Date de mise a jour |

> Rapprochement des saisies manuelles (KKS-385) : `ImportMatchingService`, appele par `DeduplicationService` entre l'import anterieur (passe 2) et le doublon probable (passe 3). Candidates : meme utilisateur, meme compte, sans empreinte, meme sens, meme montant, dans une fenetre autour de la date de reference (date d'achat si connue, sinon date comptable) — 8 jours si la transaction est liee a un abonnement, 2 jours autour de la date d'achat, sinon de 5 jours avant a 1 jour apres la date comptable. Le libelle n'est pas un critere. Un candidat : `matchedTransactionId` ; plusieurs : statut `DUPLICATE` et `matchCandidateIds`, rien n'est decide. A la confirmation, une ligne rapprochee ne cree rien : la transaction recoit l'empreinte, et l'abonnement lie apprend la cle commercant du libelle. La transaction creee par une ligne non rapprochee est datee de `purchaseDate` si connue, et liee a `subscriptionId`. Les colonnes sont stockees sans cle etrangere, comme `duplicateTransactionId` : supprimer une transaction ne doit pas etre bloque par un brouillon en attente. Le candidat multiple tient dans une colonne texte plutot qu'une table de jointure : il n'est jamais interroge par candidat, et se lit avec la ligne sans chargement supplementaire.
>
> `SubscriptionPaymentService.pay` est idempotent : une transaction liee a l'abonnement dans la periode courante (`SubscriptionPeriod`, comptee depuis `dateDebut`) est renvoyee au lieu d'en creer une.

### CategoryRule

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| pattern | String | Motif de correspondance (max 200, insensible a la casse) |
| category | Category | FK → Category a appliquer |
| origin | Enum | CategoryRuleOrigin (MANUAL / AUTO, default MANUAL) — KKS-383 |
| createdAt | LocalDateTime | Date de creation |
| user | User | FK → User. UNIQUE(user_id, pattern) |

> Une regle `MANUAL`, saisie par l'utilisateur, reconnait un libelle nettoye qui **contient** le motif. Une regle `AUTO` est creee quand l'utilisateur corrige une categorie pendant la revue : son motif est une cle commercant (`MerchantKey`), reconnue par **mots entiers** — une cle courte ne doit pas reconnaitre n'importe quel libelle qui la contient. Une correction ne modifie jamais une regle `MANUAL`.
>
> Ordre de categorisation d'une ligne a l'upload (`CategorySuggestionService`) : regle, puis categorie majoritaire des transactions passees de l'utilisateur chez le meme commercant **au meme montant**, puis chez le meme commercant tous montants. Meme sens exige (depense / recette) ; a egalite, la plus recente l'emporte. La cle commercant ne sert qu'a comparer : le libelle nettoye affiche, lui, ne change pas.

### ImportHistory

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| transactionCount | Integer | Nombre de transactions importees |
| fileName | String | Nom du fichier source (nullable) |
| importedAt | LocalDateTime | Date d'import |
| user | User | FK → User |
| account | Account | FK → Account cible |

### ImportProfile

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| name | String | Nom affiche |
| separator | String | Separateur CSV |
| dateFormat | String | Format de date |
| dateColumn | Integer | Index colonne date |
| amountColumn | Integer | Index colonne montant (nullable) |
| debitColumn | Integer | Index colonne debit (nullable) |
| creditColumn | Integer | Index colonne credit (nullable) |
| labelColumn | Integer | Index colonne libelle |
| encoding | String | Encodage du fichier |
| decimalSeparator | String | Separateur decimal |
| skipHeaderLines | Integer | Lignes d'en-tete a ignorer |
| createdAt | LocalDateTime | Date de creation |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

## Architecture frontend

### Projet Angular : `budget-app` (dossier `app/`)

```
app/src/app/
├── core/              # Services singleton, guards, interceptors
│   ├── auth/          # AuthService, AuthGuard, JwtInterceptor
│   └── api/           # Services HTTP par domaine
├── shared/            # Composants, pipes, directives reutilisables
└── features/          # Modules lazy-loaded
    ├── auth/          # Login
    ├── dashboard/     # Tableau de bord (soldes comptes + KPI mensuels)
    ├── transactions/  # CRUD transactions
    ├── subscriptions/ # CRUD abonnements
    ├── debts/         # CRUD dettes
    ├── budgets/       # Module Budgets (liste mensuelle, historique camembert, formulaire)
    └── settings/      # Parametres (categories, comptes, fonctionnalites)
```

### Principes

- **Lazy loading** : chaque feature est un module charge a la demande
- **PWA** : Service Worker pour usage offline et installation mobile
- **Standalone components** : composants Angular standalone (pas de NgModule par feature)
- **Reactive** : formulaires reactifs, RxJS pour les appels HTTP

### Communication avec l'API

- `apiUrl` relatif (`/api`) — le reverse proxy Caddy route vers Spring Boot
- Intercepteur HTTP ajoute le token JWT a chaque requete
- Guard protege les routes authentifiees

## Frontend — Ecrans prevus

| Ecran | Route | Role |
|-------|-------|------|
| Auth | `/auth` | Connexion, acceptation d'invitation, reset a la premiere connexion (pas d'inscription publique) |
| Dashboard | `/dashboard` | Patrimoine total (variation mensuelle), revenus/depenses du mois, budgets (conditionnel), dernieres operations |
| Transactions | `/transactions` | Liste, filtres, detail/edition |
| Abonnements | `/subscriptions` | Liste, total mensuel |
| Dettes/Prets | `/debts` | Liste, resume, filtres |
| Detail dette | `/debts/:id` | Montant restant, historique paiements, rembourser, snooze |
| Parametres | `/settings` | Parametres utilisateur |
| Budgets | `/budgets` | Vue mensuelle, historique camembert, CRUD budgets (guard BUDGETS) |

### Bouton flottant (FAB speed-dial)

- Masque sur l'ecran login et les parcours dedies a une tache : `/settings/**` et `/transactions/import/**` (`isTaskFlowRoute` du shell, constitution 4.1.0, principe IV)
- Actions contextuelles par page :
  - `/dashboard` : Transaction, Abonnement*, Dette*, Virement**
  - `/transactions`, `/subscriptions`, `/debts` (+ pages detail) : Transaction, Abonnement*, Dette*
  - `/budgets` : Budget (tap direct)
- *si feature activee | **si ≥ 2 comptes actifs
- Saisie en 2-3 taps

## Classement des surfaces Flutter

La constitution (principe VIII) impose de classer toute surface Flutter en
**Suivi / Gele / Jamais** et de verifier ce classement avant tout portage. Le
classement complet reste a etablir (KKS-333) ; les surfaces classees a ce jour :

| Surface | Etat | Motif |
|---------|------|-------|
| Onboarding et configuration serveur | **Suivi** | C'est le client Flutter qui subit le scenario que KKS-314 supprime : mis a jour par les stores face a un serveur reste en arriere. L'exclure de la detection d'incompatibilite viderait le mecanisme de son objet |
| Reinitialisation a la premiere connexion | **Suivi** | Portee par KKS-309. Le tout premier compte de chaque installation self-hostee est dans cet etat : l'exclure laisserait un utilisateur enferme dans une application qui s'ouvre et ne fonctionne pas |

## Flux d'authentification

- `POST /api/v1/auth/login` retourne un access token JWT (valide 15min) et un refresh token (valide 30j)
- Le filtre `JwtFilter` de Spring Security intercepte toutes les routes `/api/**`
- `POST /api/v1/auth/refresh` renouvelle les tokens (rotation : l'ancien refresh token est consomme)
- `POST /api/v1/auth/logout` revoque le refresh token
- Cote Angular : intercepteur HTTP ajoute le token et renouvelle automatiquement via refresh, guard protege les routes, ecran auth dedie (login, acceptation d'invitation, reset premiere connexion)
- Cote Angular, au lancement avec un access token expire (KKS-448) : l'utilisateur memorise est restaure tout de suite (le guard reste synchrone) et le refresh part en arriere-plan, differe d'un tick (lance depuis le constructeur d'`AuthService`, il traverserait l'intercepteur qui injecte ce service encore en construction : NG0200). Seul un 401 deconnecte (reponse de l'API a tout refus du refresh token, meme regle que l'intercepteur) ; reseau coupe, 5xx, 4xx d'un proxy ou 429 conservent la session. `refreshAccessToken()` est a vol unique, partage entre demarrage et intercepteur : la rotation fait revoquer toutes les sessions de l'utilisateur si un jeton deja consomme est rejoue
- Cote Flutter (KKS-309) : meme parcours, mecanique differente. La protection ne passe pas par un guard mais par le `redirect` global de `GoRouter`, pour toute route authentifiee — le contournement par navigation manuelle est donc impossible. L'etat est porte par un variant sealed `AuthState.passwordResetRequired`, et non par un booleen sur `authenticated` : un nouveau type est visible dans les `is`, un champ optionnel s'oublie.
- **Le flag peut ne pas etre connu a la connexion.** Apres redemarrage de l'application, les jetons sont restaures depuis le stockage et `mustResetCredentials` n'est ni dans le JWT ni persiste. `jwt_interceptor` intercepte alors le `403 PASSWORD_RESET_REQUIRED` au premier appel metier et bascule l'etat. La discrimination se fait sur le code d'erreur du corps : un `403 ACCESS_DENIED` ne redirige pas.
- **Longueur du mot de passe** (KKS-351) : une seule regle pour tous les parcours de creation ou de changement, portee par `PasswordPolicy` cote API et utilisee directement dans les annotations `@Size`. Les clients en derivent leur propre constante (`password.constants.ts`, `password_policy.dart`). Le login n'impose aucune longueur : il verifie un mot de passe existant, et l'imposer bloquerait un compte anterieur a un durcissement.
- Multi-utilisateurs sur une meme instance : credentials stockes en base (BCrypt), isolation stricte par user authentifie sur chaque requete

## Schema de deploiement

```
                    budget.exemple.fr
                          |
                        Caddy (auto-HTTPS)
                       /          \
          handle /api/*          handle /*
               |                     |
        reverse_proxy          fichiers statiques
        localhost:8080         /opt/budget-app/dist
         (Spring Boot)        + SPA fallback → index.html
               |
           PostgreSQL
```

- **Caddy** : reverse proxy + serveur de fichiers statiques, certificats Let's Encrypt automatiques
- **Frontend** : fichiers statiques Angular (`dist/`) servis directement par Caddy
- **Backend** : Spring Boot sur `localhost:8080`, accessible uniquement via `/api/*`
- **Domaine unique** : `budget.exemple.fr` pour frontend et API
