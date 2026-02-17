# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Application personnelle de gestion de budget (transactions, abonnements, dettes). Self-hosted, single-user. Monorepo avec deux modules :

- `api/` — Backend Spring Boot (API REST)
- `app/` — Frontend Angular PWA mobile-first (`k-budget-app`)

**Gestion des issues** : toutes les issues et le suivi du projet sont sur **Linear** (identifiants `KKS-*`). Ne pas utiliser GitHub Issues.

## Commandes

### Backend (api/)

```bash
cd api && mvn clean compile       # Build
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev  # Lancer (profil dev)
cd api && mvn test                # Tests
cd api && mvn test -Dtest=NomDuTest  # Test unique
cd api && mvn clean install       # Build complet avec tests
```

> **Note** : Le profil `prod` est le défaut (`spring.profiles.default=prod`). En dev, le profil `dev` doit être activé explicitement.

Le module Maven est dans `api/`. Toutes les commandes Maven doivent être exécutées depuis ce répertoire.

### Frontend (app/)

```bash
cd app && ng serve                # Dev server (http://localhost:4200)
cd app && ng build                # Build
cd app && ng test                 # Tests unitaires
cd app && ng build --configuration production  # Build prod
```

Le projet Angular est dans `app/`. Toutes les commandes Angular CLI doivent être exécutées depuis ce répertoire.

## Architecture

> Détails complets : [`README.md`](README.md) et [`docs/architecture.md`](docs/architecture.md).

### Stack

- **Backend** : Java 21, Spring Boot 4.0.2, Maven, Lombok
- **Frontend** : Angular 21, TypeScript 5.9, SCSS
- **BDD** : PostgreSQL 15+, Spring Data JPA, Flyway
- **Auth** : Spring Security + JWT (jjwt 0.12.6) avec refresh tokens
- **Infra** : Docker + Caddy (reverse proxy, auto-HTTPS)

### Structure

```
Controller (@RestController) → Service (@Service) → Repository (JpaRepository)
     ↓                                                        ↓
  DTOs (request/response)                              Entities JPA (@Entity)
```

Package base : `fr.kksdev.budget.api` — sous-packages : `config/`, `controller/`, `service/`, `repository/`, `model/`, `dto/`, `enums/`. Enums : `TransactionType`, `Frequency`, `DebtType`, `TokenStatus`, `AccountType`.

### Entites

- **User** : email (unique), password (BCrypt), name, createdAt. UUID.
- **Account** : nom, type (COURANT/EPARGNE/ESPECES), soldeInitial, icone, couleur, isDefault, actif, updatedAt. FK → User.
- **Transaction** : montant, libelle, type (DEPENSE/RECETTE), date, category (FK → Category), note, account (FK → Account), transferId (UUID, nullable), updatedAt. FK → User.
- **Subscription** : nom, montant, frequence (MENSUEL/ANNUEL), dateDebut, actif, category (FK → Category), account (FK → Account, nullable), updatedAt. FK → User.
- **Debt** : personne, montant, sens (EMPRUNT/PRET), date, rembourse, category (FK → Category), updatedAt. FK → User.
- **Category** : nom, icone, couleur, isSystem, updatedAt. FK → User.
- **RefreshToken** : token (unique), status (ACTIVE/CONSUMED/REVOKED), createdAt, expiresAt. FK → User.

### Environnements

| Env | Frontend | API | apiUrl |
|-----|----------|-----|--------|
| dev | `localhost:4200` | `localhost:8080/api` | `/api` (proxy dev) |
| prod | `budget.kksdev.fr` | `budget.kksdev.fr/api` | `/api` |

### Securite

- JWT stateless. Access token (15min) dans header `Authorization: Bearer <token>`. Refresh token (30j) pour renouvellement.
- Routes publiques : `/auth/**`, `/error`, `/actuator/health`. Tout le reste necessite un JWT valide.
- Endpoints auth : `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`.
- Context path : `/api`. `JwtFilter` valide le token avant chaque requete.

### Design System SCSS

Composants utilisent UNIQUEMENT `var(--token-name)`, jamais d'import SCSS direct. Structure dans `app/src/styles/` (tokens, themes light/dark, reset, base, utilities). Couleur primaire : Amber (#f59e0b). Police : Inter.

## Constitution du projet

Le fichier `.specify/memory/constitution.md` (v2.0.0) est le document de reference. 7 principes :

1. **API-First** : toute feature via REST avant frontend. DTOs obligatoires, jamais d'entite JPA exposee.
2. **Securite par defaut** : JWT sur toutes les routes, filtrage par user authentifie, Bean Validation.
3. **Simplicite & YAGNI** : Controller → Service → Repository. Pas de CQRS/DDD/Event Sourcing.
4. **Mobile-First UX** : saisie en 2-3 interactions, bouton flottant (+) sur tous les ecrans.
5. **Testabilite** : tests d'integration sur endpoints, tests unitaires sur services. Nommage : `should_[resultat]_when_[condition]`.
6. **Observabilite** : SLF4J/Logback uniquement. INFO pour actions, ERROR pour erreurs.
7. **Self-Hosted Ready** : PostgreSQL seule dependance infra.

## Conventions

- DTOs separent TOUJOURS la couche API de la couche persistance
- Enums pour les valeurs fixes du domaine (package `enums/`)
- Lombok obligatoire (`@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`)
- Chaque requete filtre par le user authentifie (isolation des donnees)
- Inputs valides via Bean Validation (`@Valid`, `@NotNull`, `@Size`)
- Branches feature : `feature/<nom>`

## Conventions Frontend (Angular)

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
- ESLint + Prettier configures (`ng lint`, `npm run format`)

## Documentation

| Document | Contenu |
|----------|---------|
| [`README.md`](README.md) | Installation, commandes, endpoints, architecture |
| [`docs/vision.md`](docs/vision.md) | Vision produit et modules fonctionnels |
| [`docs/architecture.md`](docs/architecture.md) | Decisions techniques, modele de donnees |
| [`docs/api-examples.md`](docs/api-examples.md) | Exemples requetes/reponses |
| [`docs/api-errors.md`](docs/api-errors.md) | Contrat erreurs HTTP |
| [`docs/deployment.md`](docs/deployment.md) | Guide deploiement Docker/bare-metal |
| **Swagger UI** | `http://localhost:8080/api/swagger-ui.html` |

## Active Technologies
- Java 21 + Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6 (026-bank-accounts)
- PostgreSQL 15+, Flyway migrations (V1-V6 existantes, V7 pour cette feature) (026-bank-accounts)
- Java 21 + Spring Boot 4.0.2, Spring Data JPA, Spring Security, Flyway, jjwt 0.12.6, Lombok (026-bank-accounts)
- TypeScript 5.9, Angular 21 + Angular 21, RxJS, Angular Reactive Forms (027-bank-accounts-frontend)
- N/A (frontend consomme l'API REST existante) (027-bank-accounts-frontend)
- TypeScript 5.9, Angular 21 + Angular Router, Angular Signals, SCSS design tokens (existants) (028-settings-redesign)
- localStorage (thème), AuthService.currentUser() signal (profil) (028-settings-redesign)
- TypeScript 5.9.2, Angular 21.1.0 + @angular/core, @angular/forms (ControlValueAccessor), @angular/cdk (CdkTrapFocus pour le bottom-sheet) (029-select-picker)
- N/A (composant frontend pur, pas de persistance) (029-select-picker)

## Recent Changes
- 026-bank-accounts: Added Java 21 + Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6
