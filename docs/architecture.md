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

## Frontend — Ecrans prevus

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

## Flux d'authentification

- `POST /api/auth/login` retourne un JWT (valide 24h)
- Le filtre `JwtFilter` de Spring Security intercepte toutes les routes `/api/**`
- Cote Angular : intercepteur HTTP ajoute le token, guard protege les routes, ecran login dedie
- Un seul utilisateur, credentials stockes en base (BCrypt)
