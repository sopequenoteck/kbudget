# Feature Specification: Dockerisation et déploiement API + Frontend

**Feature Branch**: `025-docker-deploy`
**Created**: 2026-02-13
**Status**: Draft
**Input**: KKS-76 - Créer le Dockerfile API + Frontend + Docker Compose. Infra cible : VM Debian 13 avec Docker. PostgreSQL et Caddy sont sur des VMs séparées déjà fonctionnelles. Deux images Docker Hub : sopequenotech/budget-api et sopequenotech/budget-app. Docker Compose avec les 2 services, variables d'env pour config prod. Caddy sur VM séparée route /api/* vers API container et /* vers Frontend container.

## User Scenarios & Testing

### User Story 1 - Construire et publier les images Docker (Priority: P1)

En tant que développeur, je veux pouvoir construire les images Docker de l'API et du frontend depuis le monorepo et les publier sur Docker Hub afin qu'elles soient disponibles pour le déploiement sur la VM de production.

**Why this priority**: Sans images construites et publiées, aucun déploiement n'est possible. C'est le fondement de toute la chaîne.

**Independent Test**: Peut être testé en exécutant les commandes `docker build` localement et en vérifiant que les images se lancent correctement.

**Acceptance Scenarios**:

1. **Given** le code source du monorepo est à jour, **When** je lance le build Docker de l'API, **Then** une image `sopequenotech/budget-api` est produite et contient l'application Spring Boot exécutable.
2. **Given** le code source du monorepo est à jour, **When** je lance le build Docker du frontend, **Then** une image `sopequenotech/budget-app` est produite et sert l'application Angular en tant que site statique.
3. **Given** les images sont construites, **When** je les pousse sur Docker Hub, **Then** elles sont accessibles publiquement sous `sopequenotech/budget-api` et `sopequenotech/budget-app`.

---

### User Story 2 - Déployer l'application via Docker Compose (Priority: P1)

En tant qu'opérateur, je veux démarrer l'ensemble de l'application sur la VM Docker avec une seule commande (`docker compose up`) et que les services se connectent à la base de données externe PostgreSQL.

**Why this priority**: Le déploiement fonctionnel est l'objectif premier de cette feature. Il dépend de la disponibilité des images (User Story 1).

**Independent Test**: Peut être testé en lançant `docker compose up` sur la VM Docker et en vérifiant que l'API répond sur son port et que le frontend est servi.

**Acceptance Scenarios**:

1. **Given** les images sont disponibles sur Docker Hub, **When** je lance `docker compose up` sur la VM Docker, **Then** les services API et frontend démarrent sans erreur.
2. **Given** les services sont démarrés, **When** l'API démarre, **Then** elle se connecte à la base de données PostgreSQL externe en utilisant les variables d'environnement fournies.
3. **Given** les services sont démarrés, **When** j'accède au port du frontend, **Then** l'application Angular est servie correctement avec le routage SPA fonctionnel.
4. **Given** les variables d'environnement ne sont pas configurées, **When** je lance `docker compose up`, **Then** le service API échoue au démarrage avec un message d'erreur clair indiquant les variables manquantes.

---

### User Story 3 - Vérification de santé automatique (Priority: P2)

En tant qu'opérateur, je veux que Docker surveille automatiquement la santé de l'API afin de pouvoir détecter rapidement si un service est défaillant.

**Why this priority**: Le health check améliore l'observabilité mais n'est pas bloquant pour un premier déploiement fonctionnel.

**Independent Test**: Peut être testé en démarrant les services et en vérifiant que `docker compose ps` affiche un statut "healthy" pour le service API.

**Acceptance Scenarios**:

1. **Given** le service API est démarré et fonctionnel, **When** Docker exécute le health check, **Then** le service est marqué comme "healthy".
2. **Given** le service API est démarré mais la base de données est inaccessible, **When** Docker exécute le health check, **Then** le service est marqué comme "unhealthy".

---

### User Story 4 - Configuration Caddy pour le sous-domaine (Priority: P2)

En tant qu'opérateur, je veux disposer de la configuration Caddy nécessaire pour router le trafic du sous-domaine vers les bons services Docker afin que l'application soit accessible en HTTPS.

**Why this priority**: La configuration Caddy est indispensable pour l'accès production mais peut être documentée et appliquée manuellement.

**Independent Test**: Peut être testé en appliquant la configuration Caddy et en vérifiant que les requêtes sont correctement routées.

**Acceptance Scenarios**:

1. **Given** la configuration Caddy est appliquée, **When** un utilisateur accède à `budget.kksdev.fr`, **Then** il est redirigé vers le frontend servi par le container app.
2. **Given** la configuration Caddy est appliquée, **When** un utilisateur accède à `budget.kksdev.fr/api/*`, **Then** la requête est proxifiée vers le container API.
3. **Given** la configuration Caddy est appliquée, **When** un utilisateur accède au site, **Then** la connexion est en HTTPS avec un certificat valide (auto-géré par Caddy).

---

### Edge Cases

- Que se passe-t-il si Docker Hub est inaccessible lors du `docker compose pull` ? Le Compose doit utiliser les images locales en cache si disponibles.
- Que se passe-t-il si la base de données PostgreSQL externe est temporairement inaccessible au démarrage ? L'API doit échouer au health check et Docker peut la redémarrer automatiquement (restart policy).
- Que se passe-t-il si les variables d'environnement sont partiellement définies ? L'API doit refuser de démarrer avec un message d'erreur explicite.
- Que se passe-t-il si le port exposé est déjà utilisé sur la VM Docker ? Docker Compose affiche une erreur claire à l'utilisateur.

## Requirements

### Functional Requirements

- **FR-001**: Le système DOIT fournir un Dockerfile multi-stage pour l'API qui compile le code source Java et produit une image légère basée sur un runtime JRE 21.
- **FR-002**: Le système DOIT fournir un Dockerfile multi-stage pour le frontend qui compile l'application Angular et produit une image serveur web servant les fichiers statiques avec support du routage SPA (fallback vers index.html).
- **FR-003**: Les images construites DOIVENT être publiables sur Docker Hub sous les noms `sopequenotech/budget-api` et `sopequenotech/budget-app`, avec double tag `latest` + tag versionné (ex: `v1.0.0`).
- **FR-004**: Le système DOIT fournir un fichier Docker Compose qui orchestre les deux services (API et frontend) en s'appuyant sur les images Docker Hub.
- **FR-005**: Le Docker Compose DOIT permettre de configurer la connexion à la base de données externe via des variables d'environnement (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`).
- **FR-006**: Le Docker Compose DOIT permettre de configurer le secret JWT via une variable d'environnement (`JWT_SECRET`).
- **FR-013**: Les variables d'environnement sensibles DOIVENT être gérées via un fichier `.env` (ignoré par git). Un fichier `.env.example` DOIT être commité comme template documenté.
- **FR-012**: L'API DOIT utiliser le profil `prod` par défaut (`spring.profiles.default=prod` dans `application.yaml`). Le Docker Compose ne contient aucune variable spécifique à Spring.
- **FR-007**: Le Docker Compose DOIT inclure un health check pour le service API qui vérifie que l'application répond correctement.
- **FR-008**: Le Docker Compose DOIT définir une politique de redémarrage automatique pour les services en cas d'échec.
- **FR-009**: Le système DOIT fournir un fichier `.dockerignore` pour chaque module afin d'exclure les fichiers inutiles du contexte de build.
- **FR-010**: Le système DOIT fournir la configuration Caddy nécessaire pour router `budget.kksdev.fr` vers les services Docker (frontend sur `/` et API sur `/api/*`).
- **FR-011**: Le frontend servi DOIT utiliser l'URL relative `/api` pour communiquer avec le backend, le routage étant assuré par Caddy.

### Key Entities

- **Image API** (`sopequenotech/budget-api`): Image Docker contenant l'application Spring Boot compilée, basée sur JRE 21. Expose un port HTTP. Se connecte à une base PostgreSQL externe.
- **Image Frontend** (`sopequenotech/budget-app`): Image Docker contenant le build Angular servi par Nginx (image `nginx:alpine`). Expose le port 80. Gère le routage SPA via configuration Nginx (fallback vers `index.html`).
- **Docker Compose**: Fichier d'orchestration définissant les deux services, leurs variables d'environnement, ports exposés (frontend: 3000, API: 3001), health checks et politique de redémarrage.
- **Configuration Caddy**: Bloc de configuration pour le reverse proxy qui route le trafic HTTPS vers les containers Docker (`VM_DOCKER_IP:3000` pour le frontend, `VM_DOCKER_IP:3001` pour l'API).

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'opérateur peut déployer l'intégralité de l'application (API + frontend) en une seule commande en moins de 2 minutes (hors téléchargement initial des images).
- **SC-002**: L'application est accessible en HTTPS sur `budget.kksdev.fr` avec le frontend fonctionnel et l'API répondant sur `/api`.
- **SC-003**: Après un redémarrage de la VM Docker, les services redémarrent automatiquement sans intervention manuelle.
- **SC-004**: Le health check détecte un service API défaillant en moins de 60 secondes.
- **SC-005**: Les images Docker construites ont une taille raisonnable (inférieure à 300 Mo pour l'API, inférieure à 50 Mo pour le frontend).

## Assumptions

- PostgreSQL est déjà installé et accessible sur une VM séparée avec les bases de données créées.
- Caddy est déjà installé et fonctionnel sur une VM séparée avec auto-HTTPS configuré.
- Docker et Docker Compose sont installés sur la VM Debian 13 cible.
- Le développeur dispose d'un accès push au compte Docker Hub `sopequenotech`.
- Le sous-domaine `budget.kksdev.fr` est déjà configuré au niveau DNS pour pointer vers la VM Caddy.
- Le réseau entre la VM Caddy et la VM Docker est fonctionnel (même réseau privé ou accès IP direct).
- Le réseau entre la VM Docker et la VM PostgreSQL est fonctionnel.

## Clarifications

### Session 2026-02-13

- Q: CORS est-il pris en compte ? → A: Non nécessaire. L'architecture Caddy (même origine pour frontend et API sur `budget.kksdev.fr`) élimine les requêtes cross-origin. Aucune configuration CORS requise.
- Q: Quel serveur web pour le container frontend ? → A: Nginx (image `nginx:alpine`) avec configuration SPA fallback.
- Q: Comment activer le profil Spring prod dans le container ? → A: Profil `prod` par défaut via `spring.profiles.default=prod` dans `application.properties`. Le profil `dev` est activé explicitement côté développeur. Aucune variable Spring dans le Docker Compose.
- Q: Quels ports les containers exposent-ils sur l'hôte ? → A: Frontend: 3000 (container 80 → hôte 3000), API: 3001 (container 8080 → hôte 3001). Ports non-privilégiés.
- Q: Quelle stratégie de tagging pour les images Docker Hub ? → A: Double tag `latest` + tag versionné (ex: `v1.0.0`). Permet rollback vers une version précise.
- Q: Comment gérer les variables d'environnement sensibles ? → A: Fichier `.env` référencé par le Compose, ignoré par git. Un `.env.example` commité sert de template documenté.
- Q: Le CI/CD doit-il faire partie de cette feature ? → A: Non, exclu. Déploiement manuel d'abord, CI/CD dans une feature dédiée ultérieure une fois le déploiement validé en prod.

## Scope Boundaries

### Inclus

- Dockerfiles multi-stage pour API et frontend
- Docker Compose pour orchestration sur la VM
- Fichiers `.dockerignore`
- Health check API dans le Compose
- Configuration Caddy pour le routage
- Variables d'environnement pour la configuration prod

### Exclus

- Pipeline CI/CD (build automatique, push automatique) — prévu en feature dédiée après validation du déploiement manuel
- Gestion des secrets avancée (Vault, Docker Secrets)
- Monitoring avancé (Prometheus, Grafana)
- Scaling horizontal ou load balancing
- Backup de la base de données
- Installation de Docker, Caddy ou PostgreSQL sur les VMs
