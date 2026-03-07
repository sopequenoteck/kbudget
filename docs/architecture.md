# Budget App — Architecture technique

Ce document couvre les decisions techniques, le modele de donnees et la vision frontend. Pour la stack, les endpoints API et le quickstart, voir le [`README.md`](../README.md).

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
| rembourse | Boolean | Rembourse ou non |
| dueDate | LocalDate | Date d'echeance (nullable) |
| category | Category | FK → Category (nullable) |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

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

### Product

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| nom | String | Nom du produit (max 100) |
| description | String | Description (nullable, max 500) |
| icone | String | Emoji (nullable) |
| imageUrl | String | Image en base64 data URI (nullable) — format partage Flutter/Angular |
| prixAchat | BigDecimal | Prix d'achat |
| prixVente | BigDecimal | Prix de vente |
| stock | Integer | Stock disponible (>= 0) |
| totalVendu | Integer | Total vendu (auto, default 0) |
| actif | Boolean | Toggle de visibilite (default true) |
| createdAt | LocalDateTime | Date de creation |
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
| shopAccountId | UUID | Compte associe a la boutique (nullable) |
| includeShopInBalance | Boolean | Inclure le stock boutique dans le solde total (default false) |
| currencies | List\<Currency\> | Ordre des devises — [0] = devise principale (VARCHAR via converter) |
| enabledNotificationTypes | List\<NotificationType\> | Types de notifications activees (nullable — null = tous actifs, opt-out) |
| timezone | String | Fuseau horaire (default "Europe/Paris") |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | @OneToOne → User (unique, non-null) |

Enums : `Feature` — `SUBSCRIPTIONS`, `DEBTS`, `SHOP`. `Currency` — `EUR`, `XOF`, `USD`, `GBP`, `CHF`, `CAD`, `MAD`. `NotificationType` — `SUBSCRIPTION_DUE`, `DEBT_DUE`. Converters JPA : `FeatureListConverter`, `CurrencyListConverter`, `NotificationTypeListConverter`.

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
| type | NotificationType | SUBSCRIPTION_DUE / DEBT_DUE |
| entityType | EntityType | SUBSCRIPTION / DEBT |
| entityId | UUID | ID de l'entite liee |
| title | String | Titre de la notification |
| body | String | Corps du message |
| read | Boolean | Lue ou non (default false) |
| readAt | LocalDateTime | Date de lecture (nullable) |
| createdAt | LocalDateTime | Date de creation |
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
    ├── settings/      # Parametres (categories, comptes, fonctionnalites)
    └── shop/          # Module Boutique (liste, detail, formulaire, sell/restock)
        ├── shop-list/         # Grille produits + filtres actifs/inactifs
        ├── shop-detail/       # Detail produit + historique ventes
        ├── components/        # ProductForm, SellDialog, RestockDialog
        └── shop.routes.ts     # Routing lazy-loaded
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
| Dashboard | `/dashboard` | Soldes par compte, solde total, KPI mensuels, resume abonnements, etat dettes |
| Transactions | `/transactions` | Liste, filtres, detail/edition |
| Abonnements | `/subscriptions` | Liste, total mensuel |
| Dettes/Prets | `/debts` | Suivi dans les deux sens |
| Parametres | `/settings` | Parametres utilisateur |
| Boutique | `/shop` | Grille produits, filtres actifs/inactifs |
| Detail produit | `/shop/:id` | Infos, vente, restock, historique |

### Bouton flottant (FAB speed-dial)

- Visible sur tous les ecrans (sauf login)
- Speed-dial avec actions conditionnelles : Transaction (toujours), Abonnement (si SUBSCRIPTIONS actif), Dette (si DEBTS actif), Virement (si ≥ 2 comptes actifs). Sur `/shop` : Nouveau produit + Vente rapide (si SHOP actif)
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
