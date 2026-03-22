# Implementation Plan: Dockerisation et déploiement API + Frontend

**Branch**: `025-docker-deploy` | **Date**: 2026-02-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/025-docker-deploy/spec.md`

## Summary

Containeriser l'API Spring Boot et le frontend Angular dans deux images Docker Hub distinctes, orchestrées par Docker Compose sur une VM Debian 13. PostgreSQL et Caddy sont sur des VMs séparées. Le Compose expose les ports 3001 (API) et 3000 (frontend) que Caddy reverse-proxy depuis `budget.kksdev.fr`.

**Approche** : Adapter le Dockerfile API existant (racine → `api/Dockerfile`), créer un nouveau Dockerfile frontend multi-stage (Node → Nginx), réécrire le `docker-compose.yml` pour référencer les images Docker Hub, et mettre à jour la configuration Caddy pour le routage VM-to-VM.

## Technical Context

**Language/Version**: Java 21 (API) + TypeScript 5.9.2 / Angular 21.1.0 (Frontend)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Docker, Nginx alpine
**Storage**: PostgreSQL 15+ (VM séparée, externe au Docker Compose)
**Testing**: Validation manuelle (docker build, docker compose up, curl health check)
**Target Platform**: VM Debian 13 avec Docker + Docker Compose
**Project Type**: Web monorepo (`api/` + `app/`)
**Performance Goals**: Deploy < 2 min, Image API < 300 Mo, Image Frontend < 50 Mo
**Constraints**: Pas de CI/CD, pas de SaaS, PostgreSQL seule dépendance infra
**Scale/Scope**: Single user, 2 images Docker, 1 Docker Compose, 3 VMs (Docker, PostgreSQL, Caddy)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| I. API-First | N/A | Pas de nouvel endpoint. L'API existante est containerisée telle quelle. |
| II. Sécurité par défaut | PASS | Secrets via `.env` (ignoré git), jamais hardcodés. JWT_SECRET en variable d'env. |
| III. Simplicité & YAGNI | PASS | Dockerfiles simples, pas d'orchestration complexe (K8s, Swarm). Compose minimal. |
| IV. Mobile-First UX | N/A | Pas de changement frontend. |
| V. Testabilité | PASS | Health check pour validation automatique. Build vérifiable localement. |
| VI. Observabilité | PASS | Health check Docker + logs Spring via stdout/stderr du container + logback prod (fichier rotatif). |
| VII. Self-Hosted Ready | PASS | C'est l'objectif de cette feature. Docker + PostgreSQL, pas de SaaS. |

**Résultat** : Tous les gates passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/025-docker-deploy/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 : décisions techniques Docker
├── data-model.md        # Phase 1 : entités infrastructure
├── quickstart.md        # Phase 1 : guide de déploiement
└── tasks.md             # Phase 2 : /speckit.tasks
```

### Source Code (fichiers à créer/modifier)

```text
/ (racine du monorepo)
├── api/
│   ├── Dockerfile              # [CRÉER] Multi-stage Maven → JRE 21 (déplacé depuis racine)
│   └── .dockerignore           # [CRÉER] Ignore files inutiles au build API
├── app/
│   ├── Dockerfile              # [CRÉER] Multi-stage Node → Nginx alpine
│   ├── .dockerignore           # [CRÉER] Ignore files inutiles au build frontend
│   └── nginx.conf              # [CRÉER] Config Nginx SPA fallback
├── docker-compose.yml          # [RÉÉCRIRE] 2 services depuis Docker Hub images
├── .env.example                # [CRÉER] Template variables d'environnement
├── deploy/
│   └── Caddyfile               # [MODIFIER] Routage VM-to-VM (IP Docker VM)
├── Dockerfile                  # [SUPPRIMER] Remplacé par api/Dockerfile
└── .dockerignore               # [SUPPRIMER] Remplacé par api/.dockerignore + app/.dockerignore
```

### Modifications code applicatif

```text
api/src/main/resources/
└── application.yaml            # [MODIFIER] profiles.active:dev → profiles.default:prod
```

**Structure Decision** : Dockerfiles par module (`api/Dockerfile`, `app/Dockerfile`) pour que chaque image ait son propre contexte de build isolé. Le `docker-compose.yml` à la racine référence les images Docker Hub (pas de build local).

## Changements par rapport à l'existant

| Fichier existant | Action | Raison |
|------------------|--------|--------|
| `Dockerfile` (racine) | Supprimer | Remplacé par `api/Dockerfile` avec contexte isolé |
| `.dockerignore` (racine) | Supprimer | Remplacé par `.dockerignore` par module |
| `docker-compose.yml` | Réécrire | Retirer postgres (VM séparée), retirer caddy (VM séparée), ajouter service frontend, référencer images Docker Hub, ports 3000/3001 |
| `deploy/Caddyfile` | Modifier | Pointer vers `VM_DOCKER_IP:3001` (API) et `VM_DOCKER_IP:3000` (frontend) au lieu de localhost |
| `application.yaml` | Modifier | `spring.profiles.active: dev` → `spring.profiles.default: prod` |

## Architecture de déploiement

```text
┌─────────────────────────────┐
│      VM Caddy (existante)   │
│  budget.kksdev.fr (HTTPS)   │
│                             │
│  /api/* → VM_DOCKER:3001    │
│  /*     → VM_DOCKER:3000    │
└──────────┬──────────────────┘
           │ réseau privé
┌──────────▼──────────────────┐     ┌─────────────────────────┐
│      VM Docker (Debian 13)  │     │   VM PostgreSQL         │
│                             │     │   (existante)           │
│  ┌─────────────────────┐    │     │                         │
│  │ budget-api (:3001)  │────│─────│→ :5432/budget_db        │
│  │ Spring Boot + JRE   │    │     │                         │
│  └─────────────────────┘    │     └─────────────────────────┘
│  ┌─────────────────────┐    │
│  │ budget-app (:3000)  │    │
│  │ Nginx + Angular     │    │
│  └─────────────────────┘    │
│                             │
│  docker-compose.yml         │
│  .env (secrets)             │
└─────────────────────────────┘
```

## Workflow de déploiement

```text
Développeur (local)                    VM Docker (prod)
─────────────────                      ─────────────────
1. docker build -t sopequenotech/budget-api:v1.0.0 -f api/Dockerfile api/
2. docker build -t sopequenotech/budget-app:v1.0.0 -f app/Dockerfile app/
3. docker tag ... :latest (x2)
4. docker push (x4 tags)
                                       5. docker compose pull
                                       6. docker compose up -d
```

## Complexity Tracking

Aucune violation de la constitution à justifier.
