# K-Budget

Application personnelle de gestion de budget : transactions (depenses/recettes), abonnements recurrents et suivi de dettes. Single-user, self-hosted.

Monorepo avec trois modules :

- `api/` — Backend Spring Boot (API REST)
- `app/` — Frontend Angular PWA (mobile-first)
- `flutter/` — App mobile native Flutter (`k_budget`)

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Backend | Java 21, Spring Boot 4.0.2, Maven |
| Frontend | Angular 21, TypeScript 5.9, SCSS |
| Base de donnees | PostgreSQL 15+ |
| Auth | Spring Security + JWT (jjwt 0.12.6) |
| Migrations | Flyway |
| Reverse proxy | Caddy (auto-HTTPS) |

## Prerequis

- Java 21+, Maven 3.9+, PostgreSQL 15+
- Node.js 20+, npm 10+
- Flutter >= 3.27, Dart >= 3.6

## Installation

### 1. Base de donnees

Creer la base et l'utilisateur PostgreSQL :

```sql
CREATE USER budget_u WITH PASSWORD 'changeme';
CREATE DATABASE budget_db OWNER budget_u;
```

Les tables sont creees automatiquement par Flyway au premier demarrage.

### 2. Configuration

Copier le fichier d'environnement et adapter les valeurs :

```bash
cp .env.example .env
```

Variables requises :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DB_URL` | URL JDBC PostgreSQL | `jdbc:postgresql://localhost:5432/budget_db` |
| `DB_USERNAME` | Utilisateur BDD | `budget_u` |
| `DB_PASSWORD` | Mot de passe BDD | `changeme` |
| `JWT_SECRET` | Cle secrete JWT (min 256 bits) | une chaine aleatoire longue |

### 3. Lancement

```bash
# Lancement (profil prod par defaut, ajouter -Dspring-boot.run.profiles=dev pour le dev)
cd api && mvn spring-boot:run

# Ou avec variables d'environnement explicites
DB_URL=jdbc:postgresql://localhost:5432/budget_db \
DB_USERNAME=budget_u \
DB_PASSWORD=changeme \
JWT_SECRET=ma-cle-secrete-256-bits \
cd api && mvn spring-boot:run
```

L'API demarre sur `http://localhost:8080/api`.

## Commandes

### Backend (api/)

```bash
cd api

mvn clean compile          # Compilation
mvn test                   # Tests
mvn test -Dtest=NomDuTest  # Test unique
mvn clean install          # Build complet
mvn spring-boot:run        # Lancement
```

### Frontend (app/)

```bash
cd app

ng serve                   # Dev server (http://localhost:4200)
ng build                   # Build
ng test                    # Tests unitaires
ng build --configuration production  # Build prod
```

## Endpoints API

Toutes les routes (sauf auth) necessitent un header `Authorization: Bearer <token>`.

### Authentification

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |
| POST | `/api/auth/refresh` | Renouvellement des tokens |
| POST | `/api/auth/logout` | Deconnexion (revocation du refresh token) |

### Transactions

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/transactions` | Creer une transaction |
| GET | `/api/transactions` | Lister les transactions |
| GET | `/api/transactions/{id}` | Detail d'une transaction |
| PUT | `/api/transactions/{id}` | Modifier une transaction |
| DELETE | `/api/transactions/{id}` | Supprimer une transaction |
| GET | `/api/transactions/summary?month=X&year=Y` | Bilan mensuel |

### Abonnements

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/subscriptions` | Creer un abonnement |
| GET | `/api/subscriptions` | Lister (filtre `?actif=true`) |
| GET | `/api/subscriptions/{id}` | Detail |
| PUT | `/api/subscriptions/{id}` | Modifier |
| DELETE | `/api/subscriptions/{id}` | Supprimer |

### Dettes

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/debts` | Creer une dette |
| GET | `/api/debts` | Lister (filtre `?rembourse=false`) |
| GET | `/api/debts/{id}` | Detail |
| PUT | `/api/debts/{id}` | Modifier |
| DELETE | `/api/debts/{id}` | Supprimer |

### Comptes

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/accounts` | Creer un compte |
| GET | `/api/accounts` | Lister les comptes (filtre `?includeInactive=true`) |
| GET | `/api/accounts/{id}` | Detail |
| PUT | `/api/accounts/{id}` | Modifier |
| DELETE | `/api/accounts/{id}` | Supprimer |
| POST | `/api/accounts/transfer` | Virement entre deux comptes |
| PUT | `/api/accounts/{id}/default` | Definir comme compte par defaut |

### Categories

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/categories` | Creer une categorie |
| GET | `/api/categories` | Lister les categories |
| GET | `/api/categories/{id}` | Detail |
| PUT | `/api/categories/{id}` | Modifier |
| DELETE | `/api/categories/{id}` | Supprimer |

### Produits

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/products` | Creer un produit |
| GET | `/api/products` | Lister les produits actifs |
| GET | `/api/products/{id}` | Detail d'un produit |
| PUT | `/api/products/{id}` | Modifier un produit |
| DELETE | `/api/products/{id}` | Supprimer un produit |
| POST | `/api/products/{id}/sell` | Vendre 1 unité (stock -1, transaction RECETTE) |
| POST | `/api/products/{id}/restock` | Réapprovisionner (stock +qty, transaction DEPENSE) |
| GET | `/api/products/{id}/sales` | Historique des transactions liées au produit |

### Preferences utilisateur

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/api/users/me/preferences` | Consulter les preferences (features activees + ordre nav) |
| PUT | `/api/users/me/preferences` | Mettre a jour les preferences |

Pour les exemples de payloads (request/response), voir [`docs/api-examples.md`](docs/api-examples.md).

## Architecture

### Structure monorepo

```
budget/
├── api/           # Backend Spring Boot
├── app/           # Frontend Angular PWA (k-budget-app)
├── flutter/       # App mobile native Flutter (k_budget)
├── scripts/       # Scripts utilitaires (Python, maintenance)
├── deploy/        # Caddyfile, systemd, scripts
└── docs/          # Documentation
```

### Backend (api/)

```
api/src/main/java/fr/kksdev/budget/api/
├── config/        # SecurityConfig, JwtFilter, JwtUtil, GlobalExceptionHandler
├── controller/    # REST endpoints (Auth, Transaction, Subscription, Debt, Category, Account, Product, Preference)
├── service/       # Logique metier
├── repository/    # Spring Data JPA
├── model/         # Entites JPA (User, Transaction, Subscription, Debt, Category, RefreshToken, Account, Product, UserPreference)
├── dto/
│   ├── request/   # DTOs d'entree (validation Bean Validation)
│   └── response/  # DTOs de sortie
└── enums/         # TransactionType, Frequency, DebtType, TokenStatus, AccountType, Feature, Currency
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

Architecture en couches : Controller -> Service -> Repository. Les entites JPA ne sont jamais exposees directement — toujours via DTOs.

## Securite

- JWT stateless, access token valide 15 minutes, refresh token valide 30 jours
- Toutes les routes protegees sauf `/api/auth/**` et `/api/actuator/health`
- Chaque requete filtre les donnees par l'utilisateur authentifie (isolation)
- Mots de passe hashes en BCrypt
- Inputs valides via Bean Validation (`@Valid`, `@NotNull`, `@Size`, `@Positive`)

## Profils Spring

| Profil | Usage | BDD | DDL |
|--------|-------|-----|-----|
| `dev` | Developpement local | PostgreSQL local, fallback config | `validate` |
| `prod` | Production | Variables d'environnement obligatoires | `validate` |
| `test` | Tests automatises | H2 en memoire | `create-drop` |

## Tests

```bash
cd api && mvn test
```

211 tests couvrant services, controllers, repositories et configuration. Nommage : `should_[resultat]_when_[condition]`.

## Documentation complementaire

- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive de l'API (disponible quand l'application tourne)
- **Spec OpenAPI JSON** : [http://localhost:8080/api/v3/api-docs](http://localhost:8080/api/v3/api-docs)
- [`docs/vision.md`](docs/vision.md) — Vision produit et modules fonctionnels
- [`docs/architecture.md`](docs/architecture.md) — Decisions techniques, modele de donnees et ecrans frontend
- [`docs/api-examples.md`](docs/api-examples.md) — Exemples de requetes et reponses pour chaque endpoint
- [`docs/api-errors.md`](docs/api-errors.md) — Contrat d'erreurs HTTP et guide d'integration frontend
- [`docs/deployment.md`](docs/deployment.md) — Guide de deploiement (Docker, bare-metal, reverse proxy, backup)
