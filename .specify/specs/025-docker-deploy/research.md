# Research: Dockerisation et déploiement

**Feature**: 025-docker-deploy | **Date**: 2026-02-13

## R1 — Dockerfile API : stratégie multi-stage

**Decision** : Multi-stage build Maven → JRE runtime. Déplacer le Dockerfile existant de la racine vers `api/Dockerfile` avec le contexte `api/`.

**Rationale** :
- Le Dockerfile existant à la racine fonctionne mais utilise le contexte racine (copie `api/pom.xml`, `api/src`). En le déplaçant dans `api/`, le contexte de build est isolé et les chemins sont plus simples (`COPY pom.xml .`, `COPY src/ src/`).
- Multi-stage permet de ne garder que le JRE dans l'image finale (pas le JDK ni Maven).
- Cache Maven (`dependency:go-offline`) conservé pour accélérer les rebuilds.

**Alternatives considered** :
- Dockerfile à la racine avec contexte `.` — fonctionne mais contexte trop large, `.dockerignore` partagé
- Jib (plugin Maven pour build d'image sans Dockerfile) — sur-ingénierie pour un projet simple, moins de contrôle

**Changements vs existant** :
- Retirer `--spring.profiles.active=prod` du ENTRYPOINT (remplacé par `spring.profiles.default=prod` dans `application.yaml`)
- User non-root conservé (bonne pratique existante)
- Health check conservé dans le Dockerfile (curl sur actuator)
- Image de base : `eclipse-temurin:21-jre-jammy` conservée

## R2 — Dockerfile Frontend : Angular + Nginx

**Decision** : Multi-stage Node 22 alpine (build) → Nginx alpine (runtime). Config Nginx personnalisée pour SPA fallback.

**Rationale** :
- Stage 1 (build) : `node:22-alpine` pour `npm ci` + `ng build --configuration production`. Le dossier de sortie est `dist/budget-app/browser/`.
- Stage 2 (runtime) : `nginx:alpine` (~25 Mo). Copier le build Angular + une config `nginx.conf` custom.
- La config Nginx doit gérer le fallback SPA (`try_files $uri $uri/ /index.html`) pour que le routage Angular fonctionne.

**Alternatives considered** :
- Caddy dans le container — possible mais Nginx est plus léger et standard pour servir du statique
- Node/Express — trop lourd (~150 Mo), inutile pour du statique
- `httpd` (Apache) — plus lourd que Nginx, config moins intuitive

**Config Nginx requise** :
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache long pour assets hashés
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## R3 — Docker Compose : architecture sans PostgreSQL ni Caddy

**Decision** : Docker Compose avec 2 services uniquement (api + app), référençant les images Docker Hub. Pas de service PostgreSQL ni Caddy (VMs séparées).

**Rationale** :
- L'infra cible a 3 VMs distinctes : Docker, PostgreSQL, Caddy. Le Compose ne gère que la VM Docker.
- Les images sont tirées de Docker Hub (`image: sopequenotech/budget-api:latest`), pas construites localement (`build:`).
- Variables d'environnement via fichier `.env` référencé implicitement par Compose.

**Alternatives considered** :
- Inclure PostgreSQL dans le Compose — contredit l'infra existante (VM séparée)
- Inclure Caddy dans le Compose — contredit l'infra existante (VM séparée)
- Build local dans le Compose (`build: ./api`) — pas adapté à un déploiement prod depuis Docker Hub

**Ports hôte** :
- API : `3001:8080` (container 8080 → hôte 3001)
- Frontend : `3000:80` (container 80 → hôte 3000)

## R4 — Spring profiles : profil prod par défaut

**Decision** : Changer `spring.profiles.active: dev` en `spring.profiles.default: prod` dans `application.yaml`. Supprimer `--spring.profiles.active=prod` du Dockerfile.

**Rationale** :
- `spring.profiles.default` s'applique quand AUCUN profil actif n'est défini. En Docker, le container démarre automatiquement en prod.
- En dev, le développeur active explicitement `dev` via Maven (`-Dspring-boot.run.profiles=dev`) ou IDE.
- Aucune variable Spring dans le Docker Compose (principe de séparation infra/app).

**Alternatives considered** :
- `SPRING_PROFILES_ACTIVE=prod` dans Docker Compose — fuite Spring dans l'infra
- `--spring.profiles.active=prod` hardcodé dans Dockerfile — fonctionnel mais le profil default est plus élégant

**Impact sur le workflow dev** :
- Le développeur doit ajouter `-Dspring-boot.run.profiles=dev` au run Maven ou configurer son IDE
- Documenter ce changement dans le quickstart

## R5 — Configuration Caddy : routage VM-to-VM

**Decision** : Mettre à jour le Caddyfile pour pointer vers l'IP de la VM Docker au lieu de localhost. Le frontend est servi par le container Nginx (pas par Caddy directement).

**Rationale** :
- Caddy est sur une VM séparée, il ne peut pas accéder à `localhost:8080`.
- Caddy route `/api/*` → `VM_DOCKER_IP:3001` et `/*` → `VM_DOCKER_IP:3000`.
- L'ancienne config servait les fichiers statiques depuis le filesystem local de Caddy (`root * /opt/budget-app/dist`). Maintenant, Caddy fait du pure reverse proxy vers le container Nginx.

**Alternatives considered** :
- Garder le file_server Caddy pour le frontend — impossible, les fichiers sont dans le container Nginx
- Monter un volume partagé — complexe et fragile entre 2 VMs

## R6 — Tagging et publication des images

**Decision** : Double tag `latest` + tag versionné (ex: `v1.0.0`). Publication manuelle via `docker push`.

**Rationale** :
- `latest` permet un déploiement rapide (`docker compose pull` récupère la dernière version)
- Le tag versionné permet le rollback (`image: sopequenotech/budget-api:v0.9.0`)
- Publication manuelle acceptable sans CI/CD (projet personnel)

**Commandes de publication** :
```bash
# Build
docker build -t sopequenotech/budget-api:v1.0.0 -f api/Dockerfile api/
docker build -t sopequenotech/budget-app:v1.0.0 -f app/Dockerfile app/

# Tag latest
docker tag sopequenotech/budget-api:v1.0.0 sopequenotech/budget-api:latest
docker tag sopequenotech/budget-app:v1.0.0 sopequenotech/budget-app:latest

# Push
docker push sopequenotech/budget-api:v1.0.0
docker push sopequenotech/budget-api:latest
docker push sopequenotech/budget-app:v1.0.0
docker push sopequenotech/budget-app:latest
```

## R7 — Fichiers .dockerignore par module

**Decision** : Un `.dockerignore` par module (`api/.dockerignore`, `app/.dockerignore`). Supprimer le `.dockerignore` racine.

**Rationale** :
- Avec les Dockerfiles par module et le contexte de build par module (`docker build -f api/Dockerfile api/`), le `.dockerignore` doit être dans le répertoire contexte.
- Le `.dockerignore` racine n'est plus utilisé puisqu'aucun Dockerfile n'est à la racine.

**api/.dockerignore** :
```
target/
.idea/
*.md
.gitignore
src/test/
```

**app/.dockerignore** :
```
node_modules/
dist/
.angular/
*.md
.gitignore
e2e/
coverage/
```
