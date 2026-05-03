# Data Model: Dockerisation et déploiement

**Feature**: 025-docker-deploy | **Date**: 2026-02-13

> Cette feature ne modifie pas le modèle de données de l'application (aucune table, entité ou migration Flyway). Les "entités" ci-dessous sont des artefacts d'infrastructure.

## Entités Infrastructure

### Image API (`sopequenotech/budget-api`)

| Attribut | Valeur |
|----------|--------|
| Base image (build) | `maven:3.9-eclipse-temurin-21` |
| Base image (runtime) | `eclipse-temurin:21-jre-jammy` |
| Port interne | 8080 |
| Port hôte | 3001 |
| User | `budget` (non-root) |
| Health check | `curl -f http://localhost:8080/api/actuator/health` |
| Profil Spring | `prod` (défaut via `spring.profiles.default`) |
| Logs | stdout/stderr + `/app/logs/budget-api.log` (logback rotatif) |
| Taille cible | < 300 Mo |

**Variables d'environnement requises** :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DB_URL` | URL JDBC PostgreSQL | `jdbc:postgresql://192.168.1.X:5432/budget_db` |
| `DB_USERNAME` | Utilisateur PostgreSQL | `budget_u` |
| `DB_PASSWORD` | Mot de passe PostgreSQL | `***` |
| `JWT_SECRET` | Secret JWT (256 bits min) | `***` |

### Image Frontend (`sopequenotech/budget-app`)

| Attribut | Valeur |
|----------|--------|
| Base image (build) | `node:22-alpine` |
| Base image (runtime) | `nginx:alpine` |
| Port interne | 80 |
| Port hôte | 3000 |
| Config | `nginx.conf` custom (SPA fallback) |
| Build output | `dist/budget-app/browser/` |
| Taille cible | < 50 Mo |

**Aucune variable d'environnement** : le frontend utilise l'URL relative `/api` gérée par Caddy.

### Docker Compose

| Attribut | Valeur |
|----------|--------|
| Services | `api`, `app` |
| Images | Docker Hub (`sopequenotech/budget-api:latest`, `sopequenotech/budget-app:latest`) |
| Env file | `.env` (implicite, même répertoire) |
| Restart policy | `unless-stopped` |
| Volumes | `api-logs:/app/logs` (API uniquement) |

### Configuration Caddy (VM séparée)

| Route | Destination |
|-------|-------------|
| `budget.kksdev.fr/api/*` | `reverse_proxy VM_DOCKER_IP:3001` |
| `budget.kksdev.fr/*` | `reverse_proxy VM_DOCKER_IP:3000` |

Headers de sécurité : `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `-Server`.

## Schéma de tags Docker

```text
sopequenotech/budget-api:latest     ← toujours la dernière version
sopequenotech/budget-api:v1.0.0     ← version spécifique (rollback)
sopequenotech/budget-app:latest
sopequenotech/budget-app:v1.0.0
```

## Fichiers de configuration

### .env.example

```env
# Base de données PostgreSQL (VM séparée)
DB_URL=jdbc:postgresql://POSTGRES_VM_IP:5432/budget_db
DB_USERNAME=budget_u
DB_PASSWORD=changeme

# JWT Secret (256 bits minimum)
JWT_SECRET=changeme-use-a-strong-random-secret
```

### Matrice des fichiers

| Fichier | Module | Action |
|---------|--------|--------|
| `api/Dockerfile` | API | Créer (déplacé depuis racine) |
| `api/.dockerignore` | API | Créer |
| `app/Dockerfile` | Frontend | Créer |
| `app/.dockerignore` | Frontend | Créer |
| `app/nginx.conf` | Frontend | Créer |
| `docker-compose.yml` | Racine | Réécrire |
| `.env.example` | Racine | Créer |
| `deploy/Caddyfile` | Infra | Modifier |
| `Dockerfile` | Racine | Supprimer |
| `.dockerignore` | Racine | Supprimer |
| `application.yaml` | API | Modifier (profiles) |
