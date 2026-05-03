# Tasks: Dockerisation et déploiement API + Frontend

**Input**: Design documents from `/specs/025-docker-deploy/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Non demandés. Validation manuelle uniquement (docker build, docker compose up, curl).

**Organization**: Tasks groupées par user story. US1 et US2 sont P1, US3 et US4 sont P2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup (Nettoyage et configuration)

**Purpose**: Préparer le repo — supprimer les fichiers obsolètes et ajuster la configuration Spring.

- [x] T001 Modifier `api/src/main/resources/application.yaml` — remplacer `spring.profiles.active: dev` par `spring.profiles.default: prod` pour que le profil prod soit le défaut (Docker) et dev soit explicite (développeur). Mettre à jour CLAUDE.md section « Commandes backend » : la commande dev devient `cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`
- [x] T002 [P] Supprimer `Dockerfile` à la racine du monorepo (remplacé par `api/Dockerfile` en Phase 2)
- [x] T003 [P] Supprimer `.dockerignore` à la racine du monorepo (remplacé par `.dockerignore` par module en Phase 2)

**Checkpoint**: Repo nettoyé, profil Spring prod par défaut. Le build Maven en dev nécessite maintenant `-Dspring-boot.run.profiles=dev`.

**Note**: L'edge case « variables d'env partiellement définies → message d'erreur explicite » est couvert nativement par Spring Boot : si `DB_URL` est absent, le profil prod échoue au démarrage avec `Failed to configure a DataSource`. Aucune validation custom requise (YAGNI).

---

## Phase 2: User Story 1 — Construire et publier les images Docker (Priority: P1) 🎯 MVP

**Goal**: Produire deux images Docker fonctionnelles (`sopequenotech/budget-api`, `sopequenotech/budget-app`) buildables localement et publiables sur Docker Hub.

**Independent Test**: Exécuter `docker build` localement pour chaque image, puis `docker run` pour vérifier que l'API démarre (logs Spring Boot) et que le frontend sert `index.html` (curl localhost).

### Implementation for User Story 1

- [x] T004 [P] [US1] Créer `api/.dockerignore` — exclure `target/`, `.idea/`, `*.md`, `.gitignore`, `src/test/` du contexte de build API
- [x] T005 [P] [US1] Créer `app/.dockerignore` — exclure `node_modules/`, `dist/`, `.angular/`, `*.md`, `.gitignore`, `e2e/`, `coverage/` du contexte de build frontend
- [x] T006 [P] [US1] Créer `api/Dockerfile` — multi-stage build : stage 1 `maven:3.9-eclipse-temurin-21` (cache deps + `mvn package -DskipTests`), stage 2 `eclipse-temurin:21-jre-jammy` (installer curl via `apt-get install -y --no-install-recommends curl`, user non-root `budget`, copie JAR, expose 8080). NE PAS inclure `--spring.profiles.active=prod` dans ENTRYPOINT (géré par `spring.profiles.default` dans application.yaml). NE PAS inclure de HEALTHCHECK dans le Dockerfile (géré par docker-compose en T011, évite la duplication — FR-007)
- [x] T007 [P] [US1] Créer `app/nginx.conf` — config Nginx : listen 80, root `/usr/share/nginx/html`, `try_files $uri $uri/ /index.html` pour SPA fallback, cache long (1y) pour assets hashés (js, css, images, fonts)
- [x] T008 [US1] Créer `app/Dockerfile` — multi-stage build : stage 1 `node:22-alpine` (`npm ci` + `ng build --configuration production`), stage 2 `nginx:alpine` (copie `dist/budget-app/browser/` vers `/usr/share/nginx/html`, copie `nginx.conf`). Expose port 80. Dépend de T007 (nginx.conf doit exister)

- [x] T014 [US1] Créer `scripts/docker-publish.sh` à la racine — script Bash qui build, tag (double tag `latest` + tag versionné passé en argument, ex: `v1.0.0`) et push les deux images sur Docker Hub (`sopequenotech/budget-api`, `sopequenotech/budget-app`). Usage : `./scripts/docker-publish.sh v1.0.0`. Dépend de T006 et T008 (les Dockerfiles doivent exister). Ajouter le script au `.gitignore` des `.dockerignore` si nécessaire

**Checkpoint**: Les deux images se buildent sans erreur. `docker images | grep sopequenotech` affiche API < 300 Mo et Frontend < 50 Mo. Chaque image peut être `docker run` individuellement. Le script `docker-publish.sh` tag et push correctement les 4 tags (2 images x 2 tags).

---

## Phase 3: User Story 2 — Déployer l'application via Docker Compose (Priority: P1)

**Goal**: Démarrer API + frontend sur la VM Docker avec `docker compose up -d`, connectés à la base PostgreSQL externe.

**Independent Test**: Lancer `docker compose up -d`, vérifier que les deux services sont `running`, que l'API répond sur le port 3001 et le frontend sur le port 3000.

### Implementation for User Story 2

- [x] T009 [P] [US2] Mettre à jour `.env.example` à la racine (fichier existant) — enrichir avec commentaires explicatifs, valeurs placeholder documentées et section par catégorie (Database, JWT). Voir data-model.md pour les détails
- [x] T010 [US2] Réécrire `docker-compose.yml` à la racine — 2 services (`api` image `sopequenotech/budget-api:latest` port `3001:8080`, `app` image `sopequenotech/budget-app:latest` port `3000:80`), env vars via `.env` implicite pour le service api (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`), volume `api-logs:/app/logs`, restart policy `unless-stopped`. PAS de service postgres ni caddy (VMs séparées). PAS de health check (US3)

**Checkpoint**: `docker compose up -d` démarre les 2 services. `curl localhost:3000` retourne le HTML Angular. `curl localhost:3001/api/actuator/health` retourne `{"status":"UP"}` (si DB accessible).

---

## Phase 4: User Story 3 — Vérification de santé automatique (Priority: P2)

**Goal**: Docker surveille automatiquement la santé de l'API et affiche le statut healthy/unhealthy.

**Independent Test**: `docker compose ps` affiche `healthy` pour le service api quand la DB est accessible, `unhealthy` quand elle ne l'est pas.

### Implementation for User Story 3

- [x] T011 [US3] Ajouter la configuration health check au service `api` dans `docker-compose.yml` — test `curl -f http://localhost:8080/api/actuator/health || exit 1`, interval 30s, timeout 5s, start_period 30s, retries 3

**Checkpoint**: `docker compose ps` affiche le statut de santé du service api. Le health check détecte un service défaillant en < 60s.

---

## Phase 5: User Story 4 — Configuration Caddy pour le sous-domaine (Priority: P2)

**Goal**: Fournir la configuration Caddy pour router `budget.kksdev.fr` vers les containers Docker (VM séparée).

**Independent Test**: Appliquer le Caddyfile sur la VM Caddy, vérifier que `curl https://budget.kksdev.fr` sert le frontend et `curl https://budget.kksdev.fr/api/actuator/health` atteint l'API.

### Implementation for User Story 4

- [x] T012 [US4] Modifier `deploy/Caddyfile` — remplacer `localhost:8080` par `VM_DOCKER_IP:3001` pour l'API, remplacer le bloc `file_server` par `reverse_proxy VM_DOCKER_IP:3000` pour le frontend. Conserver les headers de sécurité existants. Ajouter un commentaire `# Remplacer VM_DOCKER_IP par l'IP réelle de la VM Docker`

**Checkpoint**: Le Caddyfile est prêt à être appliqué sur la VM Caddy. L'adresse IP est paramétrable via commentaire.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et vérification des contraintes.

- [x] T013 Vérifier les tailles des images Docker — API < 300 Mo (SC-005), Frontend < 50 Mo (SC-005). Ajuster les Dockerfiles si nécessaire (layers, exclusions)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Aucune dépendance — démarrage immédiat
- **Phase 2 (US1)**: Dépend de Phase 1 (T001 doit être fait avant T006 pour que le profil prod soit correct)
- **Phase 3 (US2)**: Dépend de Phase 2 (les images doivent exister sur Docker Hub pour le Compose)
- **Phase 4 (US3)**: Dépend de Phase 3 (modifie le docker-compose.yml créé en Phase 3)
- **Phase 5 (US4)**: Indépendant de US2/US3 — peut être fait en parallèle dès Phase 1 complète
- **Phase 6 (Polish)**: Dépend de Phase 2 (images buildées)

### User Story Dependencies

```text
Phase 1 (Setup)
    │
    ├──→ Phase 2 (US1: Images) ──→ Phase 3 (US2: Compose) ──→ Phase 4 (US3: Health check)
    │                                                              │
    │                                                              ▼
    │                                                         Phase 6 (Polish)
    └──→ Phase 5 (US4: Caddy) ─────────────────────────────────────┘
```

### Within Each User Story

- `.dockerignore` avant `Dockerfile` (optimise le contexte)
- `nginx.conf` avant `app/Dockerfile` (copié dans l'image)
- `.env.example` en parallèle de `docker-compose.yml`

### Parallel Opportunities

**Phase 1** : T002 et T003 en parallèle (fichiers indépendants)

**Phase 2 (US1)** :
- T004, T005, T006, T007 tous en parallèle (fichiers différents)
- T008 attend T007 (nginx.conf requis pour le Dockerfile frontend)

**Phase 3 (US2)** : T009 et T010 en parallèle

**Cross-story** : US4 (Caddy) en parallèle avec US2/US3

---

## Parallel Example: User Story 1

```bash
# Lancer en parallèle (fichiers indépendants) :
Task: "Créer api/.dockerignore"           # T004
Task: "Créer app/.dockerignore"           # T005
Task: "Créer api/Dockerfile"              # T006
Task: "Créer app/nginx.conf"              # T007

# Puis séquentiellement (dépendance T007) :
Task: "Créer app/Dockerfile"              # T008
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (3 tâches)
2. Compléter Phase 2: US1 — Images Docker (5 tâches)
3. **STOP et VALIDER**: `docker build` + `docker run` les deux images localement
4. Push sur Docker Hub si validé

### Incremental Delivery

1. Setup → US1 (Images) → Valider build local → **MVP!**
2. US2 (Compose) → Valider `docker compose up` sur VM
3. US3 (Health check) → Valider statut healthy/unhealthy
4. US4 (Caddy) → Valider accès HTTPS via `budget.kksdev.fr`
5. Polish → Vérifier tailles images

### Résumé

| Phase | Tâches | Parallélisables | Dépendance |
|-------|--------|-----------------|------------|
| Setup | 3 | 2 | — |
| US1 (Images) | 6 | 4 | Setup |
| US2 (Compose) | 2 | 2 | US1 |
| US3 (Health check) | 1 | 0 | US2 |
| US4 (Caddy) | 1 | 0 | Setup |
| Polish | 1 | 0 | US1 |
| **Total** | **14** | **8** | |

---

## Notes

- [P] = fichiers différents, pas de dépendance — exécutable en parallèle
- [Story] = traçabilité vers la user story
- `VM_DOCKER_IP` = placeholder à remplacer par l'IP réelle dans Caddyfile et .env
- Pas de tests automatisés — validation manuelle via docker build/run/compose
- Commiter après chaque phase complète
