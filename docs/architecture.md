# Budget App — Architecture technique

Ce document couvre les decisions techniques, la securite, le modele de donnees et la vision frontend.

## Structure du code

### Backend (api/)

```
api/src/main/java/fr/kksdev/budget/api/
├── config/        # SecurityConfig, JwtFilter, JwtUtil, GlobalExceptionHandler, WebSocketConfig, StompAuthInterceptor, SchedulingConfig
├── controller/    # REST endpoints (Auth, Transaction, RecurringTransaction, Subscription, Debt, Category, Account, Bank, Budget, ExchangeRate, Currency, Preference, Notification, Import, User, Dev)
├── service/       # Logique metier
├── repository/    # Spring Data JPA
├── model/         # Entites JPA (User, Transaction, Subscription, Debt, Category, RefreshToken, Account, ExchangeRate, UserPreference, Notification, Budget, BudgetSnapshot, ImportDraft, ImportDraftLine, CategoryRule, ImportHistory, ImportProfile) + Bank (record, non-persiste)
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
- Toutes les routes protegees sauf `/api/auth/**`, `/api/actuator/health`, `/api/banks`, `/api/bank-logos/**` et `/ws/**` (auth WebSocket via StompAuthInterceptor)
- Chaque requete filtre les donnees par l'utilisateur authentifie (isolation)
- Mots de passe hashes en BCrypt
- Inputs valides via Bean Validation (`@Valid`, `@NotNull`, `@Size`, `@Positive`)

### Controle d'acces admin (KKS-232)

- **`AdminEmailResolver`** : composant Spring lisant la property `app.admin-emails` (env var `ADMIN_EMAILS`, liste CSV). Normalise trim+lowercase au `@PostConstruct`. Expose `isAdminEmail(email)`. Emet `WARN` au boot si la liste est vide.
- **`AdminAuthorizationFilter`** : `OncePerRequestFilter` declare via `@Bean` dans `SecurityConfig`. Matche `/admin/**` (via `servletPath`, context-path `/api` strippe). Pour un user authentifie non-admin → `response.sendError(403)`. Si non authentifie, laisse passer (401 natif via `HttpStatusEntryPoint`).
- **Ordre des filters** : `JwtFilter` → `AdminAuthorizationFilter` (`.addFilterAfter(...)`). `JwtFilter` refuse aussi les users dont `disabledAt != null` (401 natif).
- **Onboarding controle** : l'inscription publique (`POST /auth/register`) a ete retiree. L'onboarding se fait uniquement via invitation admin : `POST /admin/invitations` (admin cree) → `GET /auth/invitations/:token` (invite verifie) → `POST /auth/accept-invite` (invite finalise son compte + auto-login). Conformite constitution principe VII.
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

Le projet tient dans un seul module Maven. La separation se fait par packages (`controller/`, `service/`, `repository/`, etc.), pas par modules. Un multi-module n'apporterait que de la complexite de build sans benefice reel pour une application single-user.

### Flyway pour les migrations (pas de ddl-auto en prod)

En production, le schema est gere par Flyway via des scripts SQL versiones. `ddl-auto=validate` s'assure que le code et le schema sont alignes sans jamais modifier la base automatiquement. Seul le profil test utilise `create-drop` avec H2 en memoire.

### DTOs obligatoires (jamais d'entite JPA exposee)

Les entites JPA ne sont jamais retournees directement par les controllers. Des DTOs dedies (request/response) isolent la couche API de la couche persistance. Cela evite d'exposer des champs internes et permet de faire evoluer le schema sans casser le contrat API.

### Pas de CQRS, DDD tactique ou Event Sourcing

L'architecture reste en couches simples : Controller → Service → Repository. Ces patterns complexes n'apportent aucune valeur pour une application single-user de gestion de budget. Si un besoin le justifie, il devra etre documente dans le plan avant implementation.

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

> Le flag admin n'est **pas** stocke en DB (YAGNI, principe III). Il est derive a chaque requete via `AdminEmailResolver` en comparant `user.email` avec la property `app.admin-emails` (env var `ADMIN_EMAILS`).

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
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

### Transaction

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| montant | BigDecimal | Montant |
| libelle | String | Description courte |
| type | Enum | DEPENSE / RECETTE |
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
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

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
| type | NotificationType | SUBSCRIPTION_DUE / DEBT_DUE / DEBT_REMINDER / BUDGET_THRESHOLD / BUDGET_EXCEEDED |
| entityType | EntityType | SUBSCRIPTION / DEBT |
| entityId | UUID | ID de l'entite liee |
| title | String | Titre de la notification |
| body | String | Corps du message |
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
| profileId | UUID | Identifiant du profil utilise (nullable) |
| profileSource | Enum | ImportProfileSource (REGISTRY / CUSTOM / MANUAL) |
| createdAt | LocalDateTime | Date de creation |
| expiresAt | LocalDateTime | Date d'expiration |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |
| account | Account | FK → Account cible. UNIQUE(user_id, account_id) WHERE status = 'PENDING' |

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
| transactionType | Enum | DEPENSE / RECETTE |
| status | Enum | READY / NEEDS_REVIEW / DUPLICATE / SKIPPED |
| statusMessage | String | Message de statut (nullable) |
| duplicateTransactionId | UUID | ID de la transaction doublon (nullable) |
| category | Category | FK → Category (nullable) |
| createdAt | LocalDateTime | Date de creation |
| updatedAt | LocalDateTime | Date de mise a jour |

### CategoryRule

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| pattern | String | Motif de correspondance (max 200, insensible a la casse) |
| category | Category | FK → Category a appliquer |
| createdAt | LocalDateTime | Date de creation |
| user | User | FK → User. UNIQUE(user_id, pattern) |

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
| Auth | `/auth` | Inscription et connexion (toggle login/register) |
| Dashboard | `/dashboard` | Patrimoine total (variation mensuelle), revenus/depenses du mois, budgets (conditionnel), dernieres operations |
| Transactions | `/transactions` | Liste, filtres, detail/edition |
| Abonnements | `/subscriptions` | Liste, total mensuel |
| Dettes/Prets | `/debts` | Liste, resume, filtres |
| Detail dette | `/debts/:id` | Montant restant, historique paiements, rembourser, snooze |
| Parametres | `/settings` | Parametres utilisateur |
| Budgets | `/budgets` | Vue mensuelle, historique camembert, CRUD budgets (guard BUDGETS) |

### Bouton flottant (FAB speed-dial)

- Masque sur `/settings/**` et ecran login
- Actions contextuelles par page :
  - `/dashboard` : Transaction, Abonnement*, Dette*, Virement**
  - `/transactions`, `/subscriptions`, `/debts` (+ pages detail) : Transaction, Abonnement*, Dette*
  - `/budgets` : Budget (tap direct)
- *si feature activee | **si ≥ 2 comptes actifs
- Saisie en 2-3 taps

## Flux d'authentification

- `POST /api/auth/login` retourne un access token JWT (valide 15min) et un refresh token (valide 30j)
- Le filtre `JwtFilter` de Spring Security intercepte toutes les routes `/api/**`
- `POST /api/auth/refresh` renouvelle les tokens (rotation : l'ancien refresh token est consomme)
- `POST /api/auth/logout` revoque le refresh token
- Cote Angular : intercepteur HTTP ajoute le token et renouvelle automatiquement via refresh, guard protege les routes, ecran auth dedie (login/register)
- Un seul utilisateur, credentials stockes en base (BCrypt)

## Schema de deploiement

```
                    budget.kksdev.fr
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
- **Domaine unique** : `budget.kksdev.fr` pour frontend et API
