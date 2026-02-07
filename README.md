# Budget API

API REST de gestion de budget personnel : transactions (depenses/recettes), abonnements recurrents et suivi de dettes. Application single-user, self-hosted.

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Runtime | Java 21 |
| Framework | Spring Boot 4.0.2 |
| Build | Maven |
| Base de donnees | PostgreSQL 15+ |
| Auth | Spring Security + JWT (jjwt 0.12.6) |
| Migrations | Flyway |

## Prerequis

- Java 21+
- Maven 3.9+
- PostgreSQL 15+

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
# Profil dev (par defaut)
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

```bash
cd api

mvn clean compile          # Compilation
mvn test                   # Tests
mvn test -Dtest=NomDuTest  # Test unique
mvn clean install          # Build complet
mvn spring-boot:run        # Lancement
```

## Endpoints API

Toutes les routes (sauf auth) necessitent un header `Authorization: Bearer <token>`.

### Authentification

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |

**Inscription** `POST /api/auth/register`

```json
{
  "email": "user@example.com",
  "password": "secret123",
  "name": "Kelly"
}
```

Reponse `200` :

```json
{
  "token": "eyJhbGciOi...",
  "email": "user@example.com",
  "name": "Kelly"
}
```

**Connexion** `POST /api/auth/login`

```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

### Transactions

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/transactions` | Creer une transaction |
| GET | `/api/transactions` | Lister les transactions |
| GET | `/api/transactions/{id}` | Detail d'une transaction |
| PUT | `/api/transactions/{id}` | Modifier une transaction |
| DELETE | `/api/transactions/{id}` | Supprimer une transaction |
| GET | `/api/transactions/summary?month=X&year=Y` | Bilan mensuel |

**Creer** `POST /api/transactions`

```json
{
  "montant": 42.50,
  "libelle": "Courses Carrefour",
  "type": "DEPENSE",
  "date": "2026-02-07",
  "categorie": "Alimentation",
  "note": null
}
```

**Bilan mensuel** `GET /api/transactions/summary?month=2&year=2026`

```json
{
  "month": 2,
  "year": 2026,
  "totalRecettes": 2500.00,
  "totalDepenses": 1200.50,
  "solde": 1299.50
}
```

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

## Architecture

```
api/src/main/java/fr/kksdev/budget/api/
├── config/        # SecurityConfig, JwtFilter, JwtUtil, GlobalExceptionHandler
├── controller/    # REST endpoints (Auth, Transaction, Subscription, Debt)
├── service/       # Logique metier
├── repository/    # Spring Data JPA
├── model/         # Entites JPA (User, Transaction, Subscription, Debt)
├── dto/
│   ├── request/   # DTOs d'entree (validation Bean Validation)
│   └── response/  # DTOs de sortie
└── enums/         # TransactionType, Frequency, DebtType
```

Architecture en couches : Controller -> Service -> Repository. Les entites JPA ne sont jamais exposees directement — toujours via DTOs.

## Securite

- JWT stateless, token valide 24h
- Toutes les routes protegees sauf `/api/auth/**`
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

84 tests couvrant services, controllers, repositories et configuration. Nommage : `should_[resultat]_when_[condition]`.

## Documentation complementaire

- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive de l'API (disponible quand l'application tourne)
- **Spec OpenAPI JSON** : [http://localhost:8080/api/v3/api-docs](http://localhost:8080/api/v3/api-docs)
- [`docs/vision.md`](docs/vision.md) — Vision produit et modules fonctionnels
- [`docs/architecture.md`](docs/architecture.md) — Architecture technique detaillee
