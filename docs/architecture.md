# Budget App — Architecture technique

## Stack

| Couche | Technologie |
|--------|-------------|
| Backend | Spring Boot (Java 21) — API REST |
| Build | Maven |
| Frontend | Angular PWA (mobile first) |
| Base de donnees | PostgreSQL |
| Auth | Spring Security + JWT |
| Hebergement | Serveur personnel |

## Backend — Structure par couches

Package de base : `fr.kksdev.budget.api`

```
src/main/java/fr/kksdev/budget/api/
├── config/        # SecurityConfig, JwtFilter, JwtUtil, GlobalExceptionHandler
├── controller/    # AuthController, TransactionController, SubscriptionController, DebtController
├── service/       # Logique metier
├── repository/    # Acces donnees (Spring Data JPA)
├── model/         # Entites JPA
├── dto/           # Objets de transfert (request/ + response/)
└── enums/         # TransactionType, Frequency, DebtType
```

## Modele de donnees

### User

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| email | String | Email (unique) |
| password | String | Mot de passe (hashe, BCrypt) |
| name | String | Nom de l'utilisateur |
| createdAt | LocalDateTime | Date de creation |

### Transaction

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| montant | BigDecimal | Montant |
| libelle | String | Description courte |
| type | Enum | DEPENSE / RECETTE |
| date | LocalDate | Date de la transaction |
| categorie | String | Categorie (nullable) |
| note | String | Note libre (nullable) |
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
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

### Debt

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID | Identifiant |
| personne | String | Nom de la personne |
| montant | BigDecimal | Montant |
| sens | Enum | JE_DOIS / ON_ME_DOIT |
| date | LocalDate | Date |
| rembourse | Boolean | Rembourse ou non |
| updatedAt | LocalDateTime | Date de mise a jour |
| user | User | FK → User |

## Frontend — Ecrans

| Ecran | Route | Role |
|-------|-------|------|
| Login | `/login` | Authentification |
| Dashboard | `/` | Solde du mois, resume abonnements, etat dettes |
| Transactions | `/transactions` | Liste, filtres, detail/edition |
| Abonnements | `/subscriptions` | Liste, total mensuel |
| Dettes/Prets | `/debts` | Suivi dans les deux sens |

### Bouton flottant (+)

- Visible sur tous les ecrans (sauf login)
- Ouvre un formulaire minimal : montant + libelle + type
- Saisie en 2-3 taps

## Authentification

- `POST /api/auth/login` → retourne un JWT
- Filtre Spring Security sur toutes les routes `/api/**`
- Angular : intercepteur HTTP (ajoute le token), guard sur les routes, ecran login
- Un seul user, credentials en base

## Endpoints API

### Auth

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/api/auth/register` | Inscription, retourne JWT |
| POST | `/api/auth/login` | Connexion, retourne JWT |

### Transactions

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/api/transactions` | Liste (avec filtres date, type) |
| GET | `/api/transactions/{id}` | Detail |
| POST | `/api/transactions` | Creer |
| PUT | `/api/transactions/{id}` | Modifier |
| DELETE | `/api/transactions/{id}` | Supprimer |
| GET | `/api/transactions/summary` | Bilan mensuel |

### Subscriptions

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/api/subscriptions` | Liste |
| POST | `/api/subscriptions` | Creer |
| PUT | `/api/subscriptions/{id}` | Modifier |
| DELETE | `/api/subscriptions/{id}` | Supprimer |

### Debts

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/api/debts` | Liste |
| POST | `/api/debts` | Creer |
| PUT | `/api/debts/{id}` | Modifier |
| DELETE | `/api/debts/{id}` | Supprimer |
