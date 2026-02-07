# Deploiement Budget

## Prerequis

- Serveur Linux (Ubuntu 22.04+, Debian 12+ recommande)
- **Option A** : Docker Engine 24+ et Docker Compose v2
- **Option B** : Java 21 JRE + PostgreSQL 15+
- Node.js 20+ et npm 10+ (pour le build frontend)
- Nom de domaine : `budget.kksdev.fr`

## Variables d'environnement

Creer un fichier `.env` a la racine du projet (ou dans `/opt/budget-api/` pour bare-metal) :

```bash
cp .env.example .env
```

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DB_URL` | URL JDBC PostgreSQL | `jdbc:postgresql://localhost:5432/budget_db` |
| `DB_USERNAME` | Utilisateur BDD | `budget_u` |
| `DB_PASSWORD` | Mot de passe BDD | un mot de passe fort |
| `JWT_SECRET` | Cle secrete JWT (min 256 bits) | voir generation ci-dessous |

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

Le build genere les fichiers statiques dans `app/dist/budget-app/browser/`. Ces fichiers doivent etre copies sur le serveur dans `/opt/budget-app/dist/`.

```bash
scp -r app/dist/budget-app/browser/* serveur:/opt/budget-app/dist/
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
sudo useradd -r -m -d /opt/budget-api -s /usr/sbin/nologin budget
```

### 4. Deployer le JAR

```bash
# Build sur la machine de dev
cd api && mvn clean package -DskipTests
scp target/api-*.jar serveur:/opt/budget-api/api.jar
```

### 5. Configurer l'environnement

```bash
sudo cp .env /opt/budget-api/.env
sudo chown budget:budget /opt/budget-api/.env
sudo chmod 600 /opt/budget-api/.env
```

Le fichier `.env` doit contenir les 4 variables (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`).

### 6. Installer le service systemd

```bash
sudo cp deploy/budget-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable budget-api
sudo systemctl start budget-api
```

### 7. Verifier

```bash
sudo systemctl status budget-api
curl http://localhost:8080/api/actuator/health
```

## Reverse proxy

### Caddy (auto-HTTPS, recommande)

Caddy gere automatiquement les certificats Let's Encrypt. Il sert a la fois le frontend Angular (fichiers statiques) et le reverse proxy vers l'API Spring Boot.

```bash
sudo apt install -y caddy

# Copier les fichiers frontend
sudo mkdir -p /opt/budget-app/dist
sudo cp -r app/dist/budget-app/browser/* /opt/budget-app/dist/

# Installer le Caddyfile
sudo cp deploy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Le Caddyfile route `/api/*` vers Spring Boot (`localhost:8080`) et sert les fichiers Angular pour toutes les autres routes, avec SPA fallback vers `index.html`.

Fichier de reference : [`deploy/Caddyfile`](../deploy/Caddyfile)

### Nginx (certbot pour SSL)

```bash
sudo apt install -y nginx
sudo cp deploy/nginx.conf /etc/nginx/sites-available/budget-api
sudo ln -s /etc/nginx/sites-available/budget-api /etc/nginx/sites-enabled/
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
| `BACKUP_DIR` | `/opt/budget-api/backups` | Repertoire de stockage |
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
0 3 * * * /opt/budget-api/deploy/backup-pg.sh >> /opt/budget-api/logs/backup.log 2>&1
```

### Restauration

```bash
gunzip -c /opt/budget-api/backups/budget_db_2026-02-07_030000.sql.gz | psql -h localhost -U budget_u budget_db
```

## Mise a jour

### Docker

```bash
git pull
docker compose build
docker compose up -d
```

### Bare-metal

```bash
# Build backend
cd api && mvn clean package -DskipTests

# Build frontend
cd app && npm ci && ng build --configuration production

# Transfert backend
scp api/target/api-*.jar serveur:/opt/budget-api/api.jar

# Transfert frontend
scp -r app/dist/budget-app/browser/* serveur:/opt/budget-app/dist/

# Redemarrage
ssh serveur "sudo systemctl restart budget-api"
```

## Notes importantes

- **Endpoint de sante** : `GET /api/actuator/health` — accessible sans JWT, utilise par les healthchecks Docker et le monitoring
- **Swagger UI** : actif en production par defaut. Pour le desactiver, ajouter `springdoc.api-docs.enabled: false` dans `application-prod.yaml`. Alternativement, proteger l'acces via le reverse proxy
- **Generation JWT_SECRET** : `openssl rand -base64 64`
- **Firewall** : ouvrir uniquement les ports 80 (HTTP), 443 (HTTPS) et 22 (SSH)

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```
