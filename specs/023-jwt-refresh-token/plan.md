# Implementation Plan: Refresh Token JWT Backend

**Branch**: `023-jwt-refresh-token` | **Date**: 2026-02-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/023-jwt-refresh-token/spec.md`

## Summary

Implémenter le mécanisme de refresh token côté backend pour permettre le renouvellement transparent des sessions JWT. Le système utilise des tokens opaques (SecureRandom 32 bytes, Base64url) stockés en base PostgreSQL avec rotation obligatoire et détection de réutilisation pour protéger contre le vol de token. Trois nouveaux endpoints : refresh, logout, et modification du login/register pour inclure le refresh token dans la réponse.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Security, Spring Data JPA, jjwt 0.12.6, Flyway
**Storage**: PostgreSQL 15+ (nouvelle table `refresh_tokens`)
**Testing**: JUnit 5 + Spring Boot Test + Mockito + H2 (tests d'intégration)
**Target Platform**: Linux server (self-hosted via Caddy)
**Project Type**: Backend API (monorepo, module `api/`)
**Performance Goals**: Opérations de refresh < 500 ms (SC-005)
**Constraints**: Single module Maven, pas de SaaS, architecture Controller → Service → Repository
**Scale/Scope**: Single-user en pratique, multi-user capable

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Nouveaux endpoints REST (refresh, logout), DTOs séparés (RefreshRequest, LogoutRequest, ErrorResponse), AuthResponse modifié |
| II. Sécurité par défaut | PASS | Refresh/logout sous `/auth/**` (public déclaré), rotation obligatoire, détection réutilisation, Bean Validation sur DTOs |
| III. Simplicité & YAGNI | PASS | Architecture Controller → Service → Repository, un seul module Maven, enum TokenStatus, Lombok |
| IV. Mobile-First UX | N/A | Feature backend uniquement, pas de modification frontend |
| V. Testabilité | PASS | Tests d'intégration sur endpoints, tests unitaires sur RefreshTokenService, pattern AAA |
| VI. Observabilité | PASS | FR-013 : logging des événements sécurité (émission, renouvellement, révocation, détection vol) via @Slf4j |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dépendance, config via profils Spring (dev/prod), secrets via env vars |

**Gate result**: PASS — aucune violation.

## Constitution Check (post-design)

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | PASS | Contrats API documentés dans contracts/auth-api.md |
| II. Sécurité par défaut | PASS | Tokens opaques 256 bits, rotation, détection vol, codes erreur différenciés |
| III. Simplicité & YAGNI | PASS | Pas de pattern complexe, pas de rate limiting (YAGNI), nettoyage via requête simple |
| V. Testabilité | PASS | Tests unitaires (service) + intégration (endpoints) planifiés |
| VI. Observabilité | PASS | Logging sécurité sur tous les événements token |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée |

**Gate result**: PASS — design conforme.

## Project Structure

### Documentation (this feature)

```text
specs/023-jwt-refresh-token/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: research findings
├── data-model.md        # Phase 1: entity definitions
├── quickstart.md        # Phase 1: dev setup guide
├── contracts/
│   └── auth-api.md      # Phase 1: API contracts
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── config/
│   ├── JwtUtil.java              # MODIFIER : renommer propriété expiration, ajouter refresh expiration
│   ├── JwtFilter.java            # Inchangé (gère déjà l'absence de token)
│   └── SecurityConfig.java       # Inchangé (/auth/** déjà public)
├── controller/
│   └── AuthController.java       # MODIFIER : ajouter endpoints refresh et logout
├── service/
│   ├── AuthService.java          # MODIFIER : générer refresh token au login/register
│   └── RefreshTokenService.java  # NOUVEAU : logique refresh, rotation, révocation
├── repository/
│   └── RefreshTokenRepository.java  # NOUVEAU : queries refresh token
├── model/
│   └── RefreshToken.java         # NOUVEAU : entité JPA
├── dto/
│   ├── request/
│   │   ├── RefreshRequest.java   # NOUVEAU : record { refreshToken }
│   │   └── LogoutRequest.java    # NOUVEAU : record { refreshToken }
│   └── response/
│       ├── AuthResponse.java     # MODIFIER : ajouter champ refreshToken
│       └── ErrorResponse.java    # NOUVEAU : record { error, message }
└── enums/
    └── TokenStatus.java          # NOUVEAU : ACTIVE, CONSUMED, REVOKED

api/src/main/resources/
├── application.yaml              # MODIFIER : access-expiration (15 min), refresh-expiration (30 j)
├── application-dev.yaml          # Inchangé
├── application-prod.yaml         # Inchangé
└── db/migration/
    └── V6__add_refresh_tokens.sql  # NOUVEAU : table refresh_tokens

api/src/test/java/fr/kksdev/budget/api/
├── service/
│   └── RefreshTokenServiceTest.java   # NOUVEAU : tests unitaires
└── controller/
    └── AuthControllerRefreshTest.java # NOUVEAU : tests d'intégration
```

**Structure Decision**: Backend uniquement, module `api/`. Suit l'architecture existante Controller → Service → Repository. Pas de modification frontend.

## Fichiers impactés (résumé)

| Fichier | Action | Détail |
|---------|--------|--------|
| `RefreshToken.java` | Créer | Entité JPA |
| `TokenStatus.java` | Créer | Enum (ACTIVE, CONSUMED, REVOKED) |
| `RefreshTokenRepository.java` | Créer | JpaRepository + queries custom |
| `RefreshTokenService.java` | Créer | Logique métier refresh token |
| `RefreshRequest.java` | Créer | DTO request |
| `LogoutRequest.java` | Créer | DTO request |
| `ErrorResponse.java` | Créer | DTO response erreur |
| `V6__add_refresh_tokens.sql` | Créer | Migration Flyway |
| `AuthResponse.java` | Modifier | Ajouter `refreshToken` |
| `AuthController.java` | Modifier | Ajouter endpoints refresh/logout |
| `AuthService.java` | Modifier | Générer refresh token au login/register |
| `JwtUtil.java` | Modifier | Renommer propriété expiration |
| `application.yaml` | Modifier | Nouvelles propriétés JWT |
| `RefreshTokenServiceTest.java` | Créer | Tests unitaires |
| `AuthControllerRefreshTest.java` | Créer | Tests d'intégration |

## Complexity Tracking

> Aucune violation de la constitution — tableau non requis.
