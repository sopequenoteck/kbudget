# Quickstart: Déploiement Docker Budget App

**Feature**: 025-docker-deploy | **Date**: 2026-02-13

## Prérequis

| Composant | Version | Emplacement |
|-----------|---------|-------------|
| Docker | 24+ | Machine locale + VM Docker |
| Docker Compose | v2+ | VM Docker |
| Compte Docker Hub | `sopequenotech` | Machine locale (login) |
| VM Debian 13 | - | Docker installé |
| VM PostgreSQL | 15+ | Base `budget_db` créée |
| VM Caddy | 2+ | Auto-HTTPS configuré |

## 1. Build des images (machine locale)

```bash
# Depuis la racine du monorepo

# Build API
docker build -t sopequenotech/budget-api:v1.0.0 -f api/Dockerfile api/

# Build Frontend
docker build -t sopequenotech/budget-app:v1.0.0 -f app/Dockerfile app/

# Vérifier les tailles
docker images | grep sopequenotech
# budget-api   < 300 Mo
# budget-app   < 50 Mo
```

## 2. Publication sur Docker Hub

```bash
# Login Docker Hub
docker login

# Tag latest
docker tag sopequenotech/budget-api:v1.0.0 sopequenotech/budget-api:latest
docker tag sopequenotech/budget-app:v1.0.0 sopequenotech/budget-app:latest

# Push toutes les images
docker push sopequenotech/budget-api:v1.0.0
docker push sopequenotech/budget-api:latest
docker push sopequenotech/budget-app:v1.0.0
docker push sopequenotech/budget-app:latest
```

## 3. Déploiement sur la VM Docker

```bash
# SSH sur la VM Docker
ssh user@VM_DOCKER_IP

# Créer le répertoire de déploiement
mkdir -p ~/budget && cd ~/budget

# Copier docker-compose.yml et .env.example
# (depuis le repo ou scp)
scp docker-compose.yml user@VM_DOCKER_IP:~/budget/
scp .env.example user@VM_DOCKER_IP:~/budget/.env

# Éditer le .env avec les valeurs réelles
nano .env
```

**Contenu `.env`** :
```env
DB_URL=jdbc:postgresql://POSTGRES_VM_IP:5432/budget_db
DB_USERNAME=budget_u
DB_PASSWORD=<mot_de_passe_réel>
JWT_SECRET=<secret_jwt_256bits>
```

```bash
# Pull et démarrage
docker compose pull
docker compose up -d

# Vérifier le statut
docker compose ps
# budget-api   running (healthy)
# budget-app   running

# Vérifier les logs
docker compose logs -f api
docker compose logs -f app
```

## 4. Configuration Caddy (VM Caddy)

```bash
# SSH sur la VM Caddy
ssh user@VM_CADDY_IP

# Éditer le Caddyfile
# Remplacer VM_DOCKER_IP par l'IP réelle de la VM Docker
sudo nano /etc/caddy/Caddyfile

# Recharger Caddy
sudo systemctl reload caddy
```

## 5. Vérification

```bash
# Depuis n'importe où
curl -s https://budget.kksdev.fr/api/actuator/health
# {"status":"UP"}

curl -s -o /dev/null -w "%{http_code}" https://budget.kksdev.fr
# 200
```

## Mise à jour (déploiement suivant)

```bash
# Machine locale : build + push nouvelle version
docker build -t sopequenotech/budget-api:v1.1.0 -f api/Dockerfile api/
docker build -t sopequenotech/budget-app:v1.1.0 -f app/Dockerfile app/
docker tag sopequenotech/budget-api:v1.1.0 sopequenotech/budget-api:latest
docker tag sopequenotech/budget-app:v1.1.0 sopequenotech/budget-app:latest
docker push sopequenotech/budget-api:v1.1.0
docker push sopequenotech/budget-api:latest
docker push sopequenotech/budget-app:v1.1.0
docker push sopequenotech/budget-app:latest

# VM Docker : pull + restart
ssh user@VM_DOCKER_IP "cd ~/budget && docker compose pull && docker compose up -d"
```

## Rollback

```bash
# Sur la VM Docker
cd ~/budget

# Éditer docker-compose.yml : remplacer :latest par :v1.0.0
# Ou override en ligne :
docker compose down
docker compose pull   # (si images spécifiques dans le yml)
docker compose up -d
```

## Changement workflow développeur

Avec le profil `prod` par défaut, le développeur doit activer explicitement le profil `dev` :

```bash
# Maven
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# IntelliJ IDEA
# Run Configuration → Spring Boot → Active Profiles: dev
```
