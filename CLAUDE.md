# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Application personnelle de gestion de budget (transactions, abonnements, dettes). Self-hosted, single-user. Monorepo avec deux modules :

- `api/` — Backend Spring Boot (API REST)
- `app/` — Frontend Angular PWA mobile-first (`budget-app`)

**Gestion des issues** : toutes les issues et le suivi du projet sont sur **Linear** (identifiants `KKS-*`). Ne pas utiliser GitHub Issues.

## Commandes

### Backend (api/)

```bash
cd api && mvn clean compile       # Build
cd api && mvn spring-boot:run     # Lancer (profil dev)
cd api && mvn test                # Tests
cd api && mvn test -Dtest=NomDuTest  # Test unique
cd api && mvn clean install       # Build complet avec tests
```

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

### Stack

- **Backend** : Java 21, Spring Boot 4.0.2, Maven
- **Frontend** : Angular 21, TypeScript, SCSS
- **BDD** : PostgreSQL 15+, Spring Data JPA
- **Auth** : Spring Security + JWT (jjwt 0.12.6)
- **Infra** : Caddy (reverse proxy, auto-HTTPS)
- Lombok pour le boilerplate

### Couches backend

```
Controller (@RestController) → Service (@Service) → Repository (JpaRepository)
     ↓                                                        ↓
  DTOs (request/response)                              Entities JPA (@Entity)
```

Package base : `fr.kksdev.budget.api`

```
fr.kksdev.budget.api/
├── config/        # SecurityConfig, JwtFilter, JwtUtil
├── controller/    # REST endpoints
├── service/       # Logique métier
├── repository/    # Spring Data JPA
├── model/         # Entités JPA (User, Transaction, Subscription, Debt)
├── dto/           # Request/Response DTOs
└── enums/         # TransactionType, Frequency, DebtType
```

### Structure frontend

```
app/src/
├── app/
│   ├── core/          # Services singleton, guards, interceptors (auth)
│   ├── shared/        # Composants/pipes/directives réutilisables
│   └── features/      # Modules lazy-loaded par feature
├── environments/      # Config dev/prod (apiUrl)
└── styles/            # Design system foundation (voir section dédiée)
```

### Design System SCSS

Architecture en couches — les composants utilisent UNIQUEMENT `var(--token-name)`, jamais d'import SCSS direct.

```
app/src/styles/
├── _index.scss              # Orchestrateur @use (point d'entrée)
├── _reset.scss              # Reset minimal mobile-first (box-sizing, 100dvh, scrollbar)
├── _base.scss               # Body, typo, focus-visible, selection, headings
├── _utilities.scss          # .sr-only, .amount-income, .amount-expense
├── tokens/
│   ├── _primitives.scss     # Couche 1 : variables SCSS brutes (palettes, spacing, typo)
│   └── _tokens.scss         # Couche 2 : CSS custom properties sur :root
└── themes/
    ├── _light.scss          # Tokens sémantiques theme clair (:root, .theme-light)
    └── _dark.scss           # Tokens sémantiques theme dark (.theme-dark)
```

**Couleur primaire** : Amber (#f59e0b). **Thèmes** : Light (défaut) + Dark. **Police** : Inter.

**Tokens sémantiques clés** :
- Layout : `--bg-primary/secondary/tertiary`, `--surface-default/raised/overlay`
- Texte : `--text-primary/secondary/tertiary/inverse`
- Bordures : `--border-default/strong`
- Primary : `--color-primary/primary-hover/primary-light/primary-contrast`
- Feedback : `--bg-success/error/warning/info`, `--text-success/error/warning/info`
- Métier : `--color-income`, `--color-expense`, `--color-debt-owe`, `--color-debt-owed`

**Basculement de thème** : changer la classe sur `<html>` (`theme-light` / `theme-dark`).

### Environnements

| Environnement | Frontend | API | apiUrl |
|---------------|----------|-----|--------|
| dev | `http://localhost:4200` | `http://localhost:8080/api` | `/api` (proxy dev) |
| prod | `https://budget.kksdev.fr` | `https://budget.kksdev.fr/api` | `/api` |

### Entités

- **User** : email (unique), password (BCrypt), name. Clé : UUID.
- **Transaction** : montant, libellé, type (DEPENSE/RECETTE), date, catégorie, note. FK → User.
- **Subscription** : nom, montant, fréquence (MENSUEL/ANNUEL), dateDebut, actif. FK → User.
- **Debt** : personne, montant, sens (JE_DOIS/ON_ME_DOIT), date, remboursé. FK → User.

Toutes les entités utilisent des UUID comme clés primaires.

### Sécurité

- JWT stateless (pas de sessions). Token dans header `Authorization: Bearer <token>`.
- Routes publiques : `/auth/**`, `/error`. Tout le reste nécessite un JWT valide.
- Context path : `/api` (tous les endpoints commencent par `/api/...`).
- `JwtFilter` valide le token et charge le User avant chaque requête authentifiée.

### Profils Spring

- **dev** : PostgreSQL local, DDL `validate`, Flyway activé, SQL visible, JWT secret via `${JWT_SECRET:...}` (valeur par défaut en fallback).
- **prod** : tout via variables d'environnement (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`), DDL `validate`.

## Constitution du projet

Le fichier `.specify/memory/constitution.md` (v2.0.0) est le document de référence. 7 principes :

1. **API-First** : toute feature via REST avant frontend. DTOs obligatoires, jamais d'entité JPA exposée.
2. **Sécurité par défaut** : JWT sur toutes les routes, filtrage par user authentifié, Bean Validation.
3. **Simplicité & YAGNI** : Controller → Service → Repository. Pas de CQRS/DDD/Event Sourcing. Un seul module Maven.
4. **Mobile-First UX** : saisie en 2-3 interactions, bouton flottant (+) sur tous les écrans.
5. **Testabilité** : tests d'intégration sur endpoints, tests unitaires sur services. Pattern AAA. Nommage : `should_[résultat]_when_[condition]`.
6. **Observabilité** : SLF4J/Logback uniquement (pas de `System.out.println`). Logger les actions au niveau INFO, erreurs au niveau ERROR.
7. **Self-Hosted Ready** : PostgreSQL seule dépendance infra. Pas de SaaS en v1.

## Conventions

- Les DTOs séparent TOUJOURS la couche API de la couche persistance
- Les enums pour les valeurs fixes du domaine (dans le package `enums/`)
- Lombok obligatoire (`@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`)
- Chaque requête filtre par le user authentifié (isolation des données)
- Les inputs sont validés via Bean Validation (`@Valid`, `@NotNull`, `@Size`)
- Branches feature : `feature/<nom>`

## Conventions Frontend (Angular)

### Signals-First

Approche **signals-first** obligatoire. Utiliser les API modernes Angular :

| Besoin | Utiliser | Ne PAS utiliser |
|--------|----------|-----------------|
| State | `signal()` | Variables classiques |
| Derived state | `computed()` | Getters manuels |
| Side effects | `effect()` | `ngOnChanges` |
| Inputs | `input()` / `input.required()` | `@Input()` |
| Outputs | `output()` | `@Output()` + `EventEmitter` |
| Queries | `viewChild()`, `viewChildren()`, `contentChild()`, `contentChildren()` | `@ViewChild()`, `@ContentChild()` |
| Two-way binding | `model()` | `@Input()` + `@Output()` combo |

### Injection

- `inject()` uniquement (pas de constructor injection)

### Composants

- Standalone obligatoire (défaut Angular 21)
- `ChangeDetectionStrategy.OnPush` sur tous les composants
- Pas de `subscribe()` manuel — utiliser `toSignal()` ou pipe `async`

### Reactive (RxJS)

- `toSignal()` pour convertir Observable → Signal
- `toObservable()` si besoin inverse
- RxJS limité aux flux HTTP et opérateurs complexes

### Linting

- ESLint + @angular-eslint configuré (`ng lint`)
- Prettier configuré (`npm run format` / `npm run format:check`)

## Active Technologies
- Backend : Java 21 + Spring Boot 4.0.2, springdoc-openapi-starter-webmvc-ui 3.0.1
- Frontend : Angular 21, TypeScript, SCSS
- TypeScript 5.8+ (Angular 21) + Angular 21 (HttpClient, Router, Signals), RxJS (HTTP uniquement) (002-auth-service)
- localStorage (clé `budget_token`) (002-auth-service)
- TypeScript 5.8+ / Angular 21 + `@angular/router` (Router, CanActivateFn, ActivatedRouteSnapshot, RouterStateSnapshot), `AuthService` (existant) (003-auth-guard)
- localStorage via AuthService (existant, pas de modification) (003-auth-guard)
- TypeScript 5.8+ / Angular 21 + `@angular/common/http` (HttpInterceptorFn, HttpHandlerFn, HttpRequest, HttpErrorResponse), `@angular/router` (Router), `AuthService` (existant) (004-jwt-interceptor)

## Recent Changes
- 005-ds-foundation: Design system SCSS foundation (tokens, themes light/dark, reset, base, utilities)
- 001-springdoc-openapi: Added Java 21 + Spring Boot 4.0.2, springdoc-openapi-starter-webmvc-ui 3.0.1
