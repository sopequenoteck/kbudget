# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Application personnelle de gestion de budget (transactions, abonnements, dettes). API REST Spring Boot, self-hosted, single-user. PWA Angular mobile-first prévue comme frontend.

## Commandes

```bash
# Build
cd api && mvn clean compile

# Lancer l'application (profil dev)
cd api && mvn spring-boot:run

# Tests
cd api && mvn test

# Test unique
cd api && mvn test -Dtest=NomDuTest

# Build complet avec tests
cd api && mvn clean install
```

Le module Maven est dans `api/`. Toutes les commandes Maven doivent être exécutées depuis ce répertoire.

## Architecture

### Stack

- Java 21, Spring Boot 4.0.2, Maven
- PostgreSQL 15+, Spring Data JPA
- Spring Security + JWT (jjwt 0.12.6)
- Lombok pour le boilerplate

### Couches

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

- **dev** : PostgreSQL local, DDL `create-drop`, SQL visible, JWT secret hardcodé.
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
