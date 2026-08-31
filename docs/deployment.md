# Deploiement K-Budget

## Prerequis

- Serveur Linux (Ubuntu 22.04+, Debian 12+ recommande), architecture `amd64` ou `arm64`
- **Option A** : Docker Engine 24+ et Docker Compose v2 — les images publiees couvrent
  `linux/amd64` et `linux/arm64` (Raspberry Pi 4/5, NAS ARM, Apple Silicon, instances
  ARM cloud). Docker selectionne automatiquement la variante correspondant a l'hote.
- **Option B** : Java 21 JRE + PostgreSQL 15+
- Node.js 20+ et npm 10+ (pour le build frontend)
- Nom de domaine : `budget.kksdev.fr`

## Variables d'environnement

Creer un fichier `.env` a la racine du projet (ou dans `/opt/k-budget-api/` pour bare-metal) :

```bash
cp .env.example .env
```

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DB_URL` | URL JDBC PostgreSQL | `jdbc:postgresql://localhost:5432/budget_db` |
| `DB_USERNAME` | Utilisateur BDD | `budget_u` |
| `DB_PASSWORD` | Mot de passe BDD | un mot de passe fort |
| `JWT_SECRET` | Cle secrete JWT (min 256 bits) | voir generation ci-dessous |
| `ADMIN_EMAILS` | Liste d'emails admin separes par des virgules (cf. "Configuration admin") | `so-pequeno@live.fr,admin@example.com` |
| `BOOTSTRAP_EMAIL` | *(Optionnelle)* Email du compte admin cree au premier demarrage sur DB vide. Defaut : `admin@localhost`. Doit etre un format email valide sinon l'app echoue a demarrer (fail-fast). | `kelly@exemple.com` |
| `SWAGGER_ENABLED` | *(Optionnelle, KKS-311)* Expose la documentation OpenAPI (`/swagger-ui.html`, `/v3/api-docs`). Defaut : `false` hors profil `dev`, `true` en `dev`. Publier la surface d'API complete d'une instance exposee n'a pas de benefice en production. | `true` |
| `AVATAR_STORAGE_PATH` | *(Optionnelle, KKS-235)* Chemin disque pour le stockage des avatars utilisateurs (`POST /api/users/me/avatar`). Defaut : `./data/avatars` (relatif au cwd du process). En production bare-metal, recommandation : `/var/k-budget/avatars`. En Docker, fixee a `/app/data/avatars` par le compose (volume `api-avatars`) : ne pas la surcharger. Le dossier est cree automatiquement au demarrage si absent. | `/var/k-budget/avatars` |

### Avatars utilisateurs (KKS-235)

Les avatars sont stockes en dehors de la base PostgreSQL, sur le filesystem indique par `AVATAR_STORAGE_PATH`. Un fichier par user, nomme via UUID (cf. `users.avatar_path` en DB). Limite : 2 Mo par image, formats JPG/PNG uniquement.

**Permissions recommandees** (bare-metal) :

```bash
sudo mkdir -p /var/k-budget/avatars
sudo chown -R k-budget:k-budget /var/k-budget/avatars
sudo chmod 750 /var/k-budget/avatars
```

> Adapter `k-budget:k-budget` au user/groupe systeme reel (par defaut `budget` dans la procedure bare-metal ci-dessous, soit `chown -R budget:budget /var/k-budget/avatars`).

**Docker** : rien a configurer. Le compose fourni declare un volume nomme `api-avatars` monte sur `/app/data/avatars` et fixe `AVATAR_STORAGE_PATH` sur ce chemin. Les avatars survivent a `docker compose down`, aux mises a jour d'image et aux recreations de container par Watchtower.

Pour les stocker sur un emplacement precis de l'hote (disque dedie, sauvegarde existante), remplacer la source du volume par un bind-mount. Le chemin **container** reste `/app/data/avatars` :

```yaml
services:
  api:
    volumes:
      - /var/k-budget/avatars:/app/data/avatars
```

> Ne pas redefinir `AVATAR_STORAGE_PATH` dans `.env` en mode Docker : le point de montage ne suivrait pas et les avatars repartiraient dans la couche ephemere du container, ou ils disparaissent a chaque recreation (defaut KKS-307).

**Migration d'une instance anterieure a KKS-307** : les avatars uploades avant l'ajout du volume sont perdus — ils vivaient dans la couche ephemere du container et ont disparu a la premiere recreation. Aucune recuperation possible. Apres `docker compose up -d` avec le nouveau compose, demander aux utilisateurs concernes de re-televerser leur avatar ; les `users.avatar_path` orphelins produisent un `404 AVATAR_NOT_FOUND` jusque-la, sans autre effet sur l'application.

## Configuration admin

L'instance identifie les administrateurs via la variable d'environnement `ADMIN_EMAILS`. Elle contient une liste d'emails separes par des virgules ; chaque email est normalise (trim + lowercase) au demarrage.

```bash
ADMIN_EMAILS=so-pequeno@live.fr,autre-admin@example.com
```

- Un user dont l'email figure dans `ADMIN_EMAILS` et dont `disabled_at IS NULL` peut appeler les endpoints `/api/admin/*` (invitations, desactivation de users).
- Les users non-admin recoivent 403 sur ces endpoints.
- Si `ADMIN_EMAILS` est vide OU si aucun user actif ne correspond a un email de la liste, un `WARN` est emis au boot : aucune invitation ne peut etre emise tant qu'un admin valide n'est pas configure.
- **Pas d'inscription publique** : l'onboarding se fait exclusivement via le flux d'invitation (`POST /api/admin/invitations` puis acceptation via `POST /api/auth/accept-invite`). L'admin transmet le lien manuellement (Signal, SMS, face-a-face) — l'application n'envoie pas d'email.
- **Changement d'admin** : modifier `ADMIN_EMAILS` dans l'env puis redemarrer. Pas de rechargement a chaud.
- **Garde-fou dernier admin** : un admin ne peut pas se desactiver s'il est le seul admin actif (HTTP 409 `LAST_ADMIN_CANNOT_BE_DISABLED`).
- **Source d'autorite du role admin** : le statut admin est stocke directement en base (`users.is_admin`). `ADMIN_EMAILS` sert uniquement de source de promotion au demarrage : au boot, les users dont l'email figure dans la liste sont promus `isAdmin=true` s'ils ne le sont pas deja. `ADMIN_EMAILS` ne retrograde **jamais** un admin existant. Consequence : apres un changement d'email (via `/api/auth/first-login-reset`), le user conserve son acces admin meme si son nouvel email n'apparait pas dans `ADMIN_EMAILS`.

## Premier demarrage sur instance vierge (self-hoster)

Sur une instance avec une base PostgreSQL vide, l'app amorce automatiquement un compte admin au premier boot afin de permettre l'acces initial. Aucune commande manuelle n'est requise.

### Procedure

1. **Lancer l'application** :

   ```bash
   docker compose up -d
   ```

2. **Recuperer le mot de passe initial** genere au premier boot :

   ```bash
   docker compose logs api | grep -A 5 "FIRST BOOT"
   ```

   Le log affiche une banniere encadree du type :

   ```
   ================================================
    FIRST BOOT — Admin account created
     Email:    admin@localhost
     Password: xQ9mK3vP7nR2wL8t5sH4jD8fG1bN6cY3
    CHANGE THESE CREDENTIALS IMMEDIATELY
   ================================================
   ```

   Par defaut l'email est `admin@localhost`. Pour personnaliser, definir `BOOTSTRAP_EMAIL=votre@email.com` dans `.env` **avant le premier `docker compose up`** (apres le premier boot, la variable est sans effet — le compte est cree une seule fois dans la vie de l'instance).

3. **Se connecter sur l'UI** : ouvrir l'URL publique (ex : `https://budget.kksdev.fr`) et saisir les credentials initiaux. L'application redirige automatiquement vers un ecran dedie de reset forcé.

4. **Completer le formulaire de reset** : saisir l'email definitif, un nouveau mot de passe personnel (8 chars min) et un nom d'affichage. Apres validation, acces complet a l'application.

5. **(Optionnel) Purger les logs du premier boot** si la sortie est persistee par un agent externe (Datadog, Loki, journalctl avec persistance, etc.) :

   ```bash
   docker compose logs --no-log-prefix api > /dev/null
   ```

   Les logs stdout ephemeres Docker n'ont pas besoin de purge explicite.

### Proprietes de securite

- Le mot de passe initial est aleatoire 32 chars alphanumeriques, genere via `SecureRandom` — jamais dans le code ni dans le repo.
- Tant que le reset n'a pas ete effectue, le JWT emis par le login n'autorise que l'endpoint `POST /api/auth/first-login-reset` et `POST /api/auth/logout`. Tous les autres endpoints protegés renvoient **403 `PASSWORD_RESET_REQUIRED`**.
- Apres le reset, le user conserve son role admin meme si le nouvel email n'est pas dans `ADMIN_EMAILS` (cf. "Configuration admin").
- Si le container redemarre avant le reset : le meme mot de passe reste valide en base (pas de regeneration, condition `users.count() == 0` assure l'idempotence).
- Aucun seed n'est effectue si des users existent deja en DB.

### Restauration d'acces en cas de perte du mot de passe admin

Si l'unique admin a perdu son mot de passe apres avoir complete le reset initial, la procedure de bootstrap ne s'applique plus (DB non vide). La recuperation se fait actuellement via intervention directe en base. Un ticket dedie pourra ajouter une commande CLI de reset ulterieurement.

Generer un `JWT_SECRET` securise :

```bash
openssl rand -base64 64
```

## Build frontend

```bash
cd app
npm ci
ng build --configuration production
```

Le build genere les fichiers statiques dans `app/dist/k-budget-app/browser/`. Ces fichiers doivent etre copies sur le serveur dans `/opt/k-budget-app/dist/`.

```bash
scp -r app/dist/k-budget-app/browser/* serveur:/opt/k-budget-app/dist/
```

## Option A : Docker Compose (recommande)

### 1. Configurer .env

```bash
cp .env.example .env
# Editer .env avec vos valeurs
```

Le `DB_URL` est gere automatiquement par Docker Compose (hostname `postgres`). Vous devez configurer uniquement `DB_USERNAME`, `DB_PASSWORD` et `JWT_SECRET`.

### 2. Lancer

```bash
docker compose up -d
```

Le premier lancement build l'image et demarre PostgreSQL puis l'API.

### 3. Verifier

```bash
# Sante de l'API
curl http://localhost:8080/api/actuator/health

# Statut des conteneurs
docker compose ps

# Logs
docker compose logs -f api
```

### 4. Activer le reverse proxy (optionnel)

Decommentez le service `caddy` dans `docker-compose.yml` et les volumes associes, puis editez `deploy/Caddyfile` avec votre domaine.

**Important** : dans le Caddyfile, remplacez `localhost:8080` par `api:8080` (nom du service Docker).

```bash
docker compose up -d
```

## Option B : Bare-metal (JAR + systemd)

### 1. Installer les prerequis

```bash
# Java 21 JRE
sudo apt install -y temurin-21-jre

# PostgreSQL 15
sudo apt install -y postgresql-15
```

### 2. Configurer PostgreSQL

```sql
CREATE USER budget_u WITH PASSWORD 'votre_mot_de_passe';
CREATE DATABASE budget_db OWNER budget_u;
```

### 3. Creer l'utilisateur systeme

```bash
sudo useradd -r -m -d /opt/k-budget-api -s /usr/sbin/nologin budget
```

### 4. Deployer le JAR

```bash
# Build sur la machine de dev
cd api && mvn clean package -DskipTests
scp target/api-*.jar serveur:/opt/k-budget-api/api.jar
```

### 5. Configurer l'environnement

```bash
sudo cp .env /opt/k-budget-api/.env
sudo chown budget:budget /opt/k-budget-api/.env
sudo chmod 600 /opt/k-budget-api/.env
```

Le fichier `.env` doit contenir les 4 variables (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`).

### 6. Installer le service systemd

```bash
sudo cp deploy/k-budget-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable k-budget-api
sudo systemctl start k-budget-api
```

### 7. Verifier

```bash
sudo systemctl status k-budget-api
curl http://localhost:8080/api/actuator/health
```

## Reverse proxy

### Caddy (auto-HTTPS, recommande)

Caddy gere automatiquement les certificats Let's Encrypt. Il sert a la fois le frontend Angular (fichiers statiques) et le reverse proxy vers l'API Spring Boot.

```bash
sudo apt install -y caddy

# Copier les fichiers frontend
sudo mkdir -p /opt/k-budget-app/dist
sudo cp -r app/dist/k-budget-app/browser/* /opt/k-budget-app/dist/

# Installer le Caddyfile
sudo cp deploy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Le Caddyfile route `/api/*` vers Spring Boot (`localhost:8080`) et sert les fichiers Angular pour toutes les autres routes, avec SPA fallback vers `index.html`.

Fichier de reference : [`deploy/Caddyfile`](../deploy/Caddyfile)

### Nginx (certbot pour SSL)

```bash
sudo apt install -y nginx
sudo cp deploy/nginx.conf /etc/nginx/sites-available/k-budget-api
sudo ln -s /etc/nginx/sites-available/k-budget-api /etc/nginx/sites-enabled/
# Editer : remplacer budget.kksdev.fr par votre domaine
sudo nginx -t && sudo systemctl reload nginx

# Generer le certificat SSL
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d budget.kksdev.fr
```

Fichier de reference : [`deploy/nginx.conf`](../deploy/nginx.conf)

## Backup PostgreSQL

### Script

Le script `deploy/backup-pg.sh` effectue un `pg_dump` compresse avec rotation automatique.

Variables configurables :

| Variable | Defaut | Description |
|----------|--------|-------------|
| `BACKUP_DIR` | `/opt/k-budget-api/backups` | Repertoire de stockage |
| `BACKUP_RETENTION_DAYS` | `7` | Jours de retention |
| `DB_NAME` | `budget_db` | Nom de la base |
| `DB_HOST` | `localhost` | Hote PostgreSQL |
| `DB_PORT` | `5432` | Port PostgreSQL |
| `DB_USER` | `budget_u` | Utilisateur PostgreSQL |

### Authentification

Configurer `~/.pgpass` pour eviter de saisir le mot de passe :

```bash
echo "localhost:5432:budget_db:budget_u:votre_mot_de_passe" >> ~/.pgpass
chmod 600 ~/.pgpass
```

### Cron (backup quotidien a 3h)

```bash
crontab -e
# Ajouter :
0 3 * * * /opt/k-budget-api/deploy/backup-pg.sh >> /opt/k-budget-api/logs/backup.log 2>&1
```

### Restauration

```bash
gunzip -c /opt/k-budget-api/backups/budget_db_2026-02-07_030000.sql.gz | psql -h localhost -U budget_u budget_db
```

## Backup avatars (KKS-235)

Les avatars utilisateurs sont stockes hors-DB sur le filesystem (cf. `AVATAR_STORAGE_PATH`). **Inclure ce dossier dans la strategie de backup** au meme titre que la DB — un dump PostgreSQL seul ne restaure que la reference (`users.avatar_path`), pas les binaires.

### Bare-metal — backup quotidien (avatars + DB)

```bash
# Cron quotidien a 3h05 (apres le dump PostgreSQL de 3h)
5 3 * * * tar czf /opt/k-budget-api/backups/avatars_$(date +\%F).tar.gz -C /var/k-budget avatars/ && find /opt/k-budget-api/backups/avatars_*.tar.gz -mtime +7 -delete
```

### Bare-metal — restauration

```bash
sudo tar xzf /opt/k-budget-api/backups/avatars_2026-04-27.tar.gz -C /var/k-budget/
sudo chown -R budget:budget /var/k-budget/avatars
sudo chmod 750 /var/k-budget/avatars
```

### Docker — backup du volume `api-avatars`

Le volume ne se sauvegarde pas avec un `tar` direct sur l'hote : passer par un container ephemere monte sur les memes volumes que l'API. `--volumes-from` evite d'avoir a deviner le nom du volume (prefixe par le nom du projet compose).

```bash
# Cron quotidien a 3h05. Le `cd` est indispensable : cron ne s'execute pas
# dans le repertoire du docker-compose.yml, dont `docker compose` a besoin.
5 3 * * * cd /opt/k-budget && docker run --rm --volumes-from $(docker compose ps -q api) -v /opt/k-budget-api/backups:/backup alpine tar czf /backup/avatars_$(date +\%F).tar.gz -C /app/data/avatars . && find /opt/k-budget-api/backups/avatars_*.tar.gz -mtime +7 -delete
```

### Docker — restauration

```bash
docker compose stop api
docker run --rm --volumes-from $(docker compose ps -aq api) \
  -v /opt/k-budget-api/backups:/backup alpine \
  sh -c 'rm -rf /app/data/avatars/* && tar xzf /backup/avatars_2026-04-27.tar.gz -C /app/data/avatars'
docker compose start api
```

> Pas de `chown` manuel a prevoir : l'entrypoint de l'image reajuste les permissions du volume au demarrage.

> Apres restauration, verifier que les chemins en DB (`users.avatar_path`) correspondent aux fichiers physiques. Tout `avatar_path` orphelin produit un `404 AVATAR_NOT_FOUND` cote API.

## Mise a jour

### Docker (prod — mise a jour manuelle)

```bash
git pull
docker compose build
docker compose up -d
```

### VM de test — deploiement continu (Watchtower)

Sur la VM de test, Watchtower surveille Docker Hub et redeploie automatiquement
des qu'une nouvelle image `:latest` est publiee (workflow `docker-publish.yml`
sur push `main`). Aucune action manuelle requise a chaque release.

Demarrage de Watchtower (installation initiale uniquement) :

```bash
docker compose -f docker-compose.yml -f docker-compose.watchtower.yml up -d
```

Fichier de reference : [`docker-compose.watchtower.yml`](../docker-compose.watchtower.yml)

### Bare-metal

```bash
# Build backend
cd api && mvn clean package -DskipTests

# Build frontend
cd app && npm ci && ng build --configuration production

# Transfert backend
scp api/target/api-*.jar serveur:/opt/k-budget-api/api.jar

# Transfert frontend
scp -r app/dist/k-budget-app/browser/* serveur:/opt/k-budget-app/dist/

# Redemarrage
ssh serveur "sudo systemctl restart k-budget-api"
```

## Notes importantes

- **Endpoint de sante** : `GET /api/actuator/health` — accessible sans JWT, utilise par les healthchecks Docker et le monitoring
- **Swagger UI** : desactivee par defaut hors profil `dev` (KKS-311). Les routes `/swagger-ui.html` et `/v3/api-docs` ne sont pas mappees et repondent 404. Pour l'activer volontairement sur une instance — developpement d'un client tiers, exploration de l'API — definir `SWAGGER_ENABLED=true` ; penser alors a restreindre l'acces via le reverse proxy
- **Generation JWT_SECRET** : `openssl rand -base64 64`
- **Firewall** : ouvrir uniquement les ports 80 (HTTP), 443 (HTTPS) et 22 (SSH)

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## CI/CD (GitHub Actions + SonarQube)

L'analyse qualite et la couverture des 3 stacks (API, Angular, Flutter) tournent
via GitHub Actions (`.github/workflows/ci.yml`) avec scan SonarQube self-hosted.

- **Sur PR** vers `main`/`develop` : Quality Gate **bloquant** (`sonar.qualitygate.wait`) —
  le merge est bloque si la qualite du *new code* regresse.
- **Sur push** vers `main`/`develop` : scan de reference non bloquant (alimente le dashboard).

SonarQube etant self-hosted sur un reseau prive, le scan tourne sur un **runner
GitHub self-hosted** (les runners cloud ne peuvent pas joindre le serveur Sonar).

### Prerequis a configurer

| Element | Ou | Detail |
|---------|-----|--------|
| Runner self-hosted | Box homelab | Enregistre sur le repo, sur le reseau Docker `ci-stack_ci-net` (pour joindre SonarQube) |
| Secret `SONAR_TOKEN` | Settings repo → Secrets | Token utilisateur SonarQube |
| Variable `SONAR_HOST_URL` | Settings repo → Variables | URL interne du serveur (ex `http://sonarqube:9000`) |
| Quality Gate "Clean as You Code" | UI SonarQube | Couverture exigee sur le *new code* uniquement (pas l'existant) |
| Plugin `sonar-flutter` | Serveur SonarQube | `extensions/plugins/` — requis pour l'analyse Dart (non supportee nativement) |
| Required status checks | Settings repo → Branches | Rendre les 3 jobs CI obligatoires pour bloquer reellement le merge |

Les `projectKey` Sonar sont `kbudget-api`, `kbudget-app`, `kbudget-flutter`
(declares dans les `sonar-project.properties` respectifs et le workflow).
