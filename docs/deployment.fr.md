# Exploiter k-budget

Tout ce qu'il faut pour installer, mettre a jour, sauvegarder et depanner une
instance auto-hebergee. Aucune connaissance prealable du projet n'est supposee.

> 🇬🇧 [English version](deployment.md)

- [Installation](#installation)
- [HTTPS et reverse proxy](#https-et-reverse-proxy)
- [Mise a jour](#mise-a-jour)
- [Sauvegarde et restauration](#sauvegarde-et-restauration)
- [Depannage](#depannage)
- [Sans Docker](#sans-docker)
- [Variables d'environnement](#variables-denvironnement)

## Installation

**Prerequis** : Docker avec le plugin Compose. C'est tout — PostgreSQL est
fourni avec la pile. Environ 1 Go de RAM et 2 Go de disque suffisent pour
demarrer.

```bash
git clone https://github.com/sopequenoteck/budget.git
cd budget
cp .env.example .env
```

Renseignez les deux valeurs obligatoires dans `.env` :

```bash
openssl rand -base64 48    # a coller dans JWT_SECRET
                           # puis choisir un DB_PASSWORD
```

Tout le reste a un defaut utilisable. Ensuite :

```bash
docker compose up -d
```

L'interface est sur **http://localhost:8080**. Si ce port est pris, changez
`APP_PORT` dans `.env`.

### Trouver le mot de passe du premier administrateur

Au tout premier demarrage, l'application cree un compte administrateur et
affiche son mot de passe genere :

```bash
docker compose logs api | grep -A4 "FIRST BOOT"
```

```
================================================
 FIRST BOOT — Admin account created
 Email:    admin@localhost
 Password: <genere>
 CHANGE THESE CREDENTIALS IMMEDIATELY
================================================
```

> **Notez-le tout de suite.** Ce bandeau n'apparait **qu'au tout premier
> demarrage**, et le mot de passe n'est stocke que hashe : il est
> irrecuperable ensuite. Si vous l'avez manque, voir
> [Mot de passe administrateur perdu](#mot-de-passe-administrateur-perdu).

La connexion redirige immediatement vers un ecran qui impose de definir vos
propres email et mot de passe. C'est voulu : le compte initial est une porte
d'entree, pas un compte a conserver.

### Ajouter d'autres personnes

**Il n'y a pas d'inscription publique**, et c'est delibere. Un administrateur
invite depuis **Parametres → Utilisateurs**, et l'invite recoit un lien pour
definir son propre mot de passe. Les donnees de chaque utilisateur sont
strictement isolees de celles des autres.

## HTTPS et reverse proxy

Le compose sert du HTTP en clair sur `APP_PORT`. Sur un reseau local ou via un
VPN, c'est souvent suffisant et cette section peut etre ignoree.

Pour exposer l'instance sur Internet, placez un reverse proxy devant.
[`deploy/Caddyfile`](../deploy/Caddyfile) est un exemple fonctionnel — Caddy
obtient et renouvelle les certificats TLS tout seul.
[`deploy/nginx.conf`](../deploy/nginx.conf) couvre nginx avec certbot.

Deux points comptent quel que soit le proxy choisi :

**`TRUSTED_PROXIES` doit contenir le reseau depuis lequel le proxy se
connecte.** Le defaut couvre les plages privees, ce qui suffit quand le proxy
tourne sur le meme hote. Sinon, toutes les requetes semblent venir de son
adresse et la limitation de debit s'applique a tout le monde ensemble au lieu
de par client.

**Le proxy de bordure doit ecraser `X-Forwarded-For`, pas l'enrichir.** Les
deux configurations fournies le font. L'enrichir laisserait un client forger le
premier maillon — celui auquel l'API fait confiance — et contourner la
limitation.

Vous ne devriez **pas** avoir besoin de `CORS_ALLOWED_ORIGINS` : le client web
proxifie `/api/` vers l'API, le navigateur ne voit donc qu'une seule origine. A
renseigner uniquement si le frontend est servi depuis un autre domaine.

## Mise a jour

**Sauvegardez d'abord.** Toujours. Voir
[Sauvegarde et restauration](#sauvegarde-et-restauration).

Lisez ensuite les [notes de version](../CHANGELOG.md) — une version majeure
signale une rupture assumee, et l'entree dit ce qu'elle exige de vous.

```bash
# 1. Sauvegarder
./deploy/backup.sh

# 2. Epingler la nouvelle version dans docker-compose.yml
#    image: ghcr.io/sopequenoteck/k-budget-api:6.3.1

# 3. Recuperer et redemarrer
docker compose pull
docker compose up -d
```

Les migrations de base s'executent automatiquement au demarrage.

### Quel tag utiliser

Les images sont publiees sur **GHCR**, `ghcr.io/sopequenoteck/k-budget-*`.
Docker Hub (`sopequenotech/k-budget-*`) est conserve en miroir. Preferez GHCR :
Docker Hub applique des quotas de telechargement aux utilisateurs anonymes,
ce qui est exactement le mode d'acces d'un self-hoster.

| Tag | Bouge quand | A utiliser |
|-----|-------------|------------|
| `6.3.1` | jamais | **Recommande.** Vous decidez quand mettre a jour |
| `6.3` | un correctif sort dans la serie 6.3 | Correctifs sans changement de fonctionnalites |
| `latest` | a chaque release | Deconseille — voir ci-dessous |

`docker-compose.yml` est livre avec une version epinglee, volontairement.
Suivre `latest` signifie qu'un redemarrage peut appliquer une migration de base
que vous n'avez pas choisie, a un moment que vous n'avez pas choisi.

**Watchtower et les autres outils de mise a jour automatique sont
deconseilles** pour la meme raison : une mise a jour non surveillee qui echoue
en pleine migration laisse une instance dans un etat que personne ne regardait,
et la personne qui doit diagnostiquer, c'est vous.

### Si une migration echoue

L'API s'arrete et journalise la migration fautive. Rien n'est applique a
moitie en silence — Flyway execute chaque migration dans une transaction
lorsque la base le permet.

1. Lire `docker compose logs api` et reperer l'erreur Flyway
2. Restaurer la sauvegarde prise avant la mise a jour
3. Revenir a la version d'image precedente
4. Ouvrir une issue avec le nom de la migration et l'erreur

## Sauvegarde et restauration

Deux choses sont a sauvegarder : la **base** et les **avatars**. Restaurer la
base seule laisse des comptes dont la photo a disparu.

### Sauvegarder

```bash
./deploy/backup.sh
```

Ecrit `db_<horodatage>.sql.gz` et, s'il y en a, `avatars_<horodatage>.tar.gz`
dans `./backups`, et supprime les fichiers de plus de 14 jours.

```bash
BACKUP_DIR=/mnt/nas RETENTION_DAYS=30 ./deploy/backup.sh
```

Chaque jour a 3h, depuis le repertoire qui contient `docker-compose.yml` :

```cron
0 3 * * * cd /chemin/vers/budget && ./deploy/backup.sh >> backups/backup.log 2>&1
```

> Une sauvegarde qu'on n'a jamais restauree est une hypothese, pas une
> sauvegarde. Restaurez-en une dans une copie jetable au moins une fois.

### Restaurer

```bash
./deploy/restore.sh 2026-09-04_140207
```

Lancez-le sans argument pour lister les sauvegardes disponibles. Le script
arrete l'API, recree le schema, restaure la base et les avatars, redemarre, et
demande confirmation avant d'agir — `FORCE=1` saute la question pour un usage
scripte.

**Verifiez que l'application repond avant de considerer l'operation reussie :**

```bash
curl -s http://localhost:8080/api/meta
```

### Vos donnees n'appartiennent qu'a vous

Personne d'autre n'en detient de copie. Il n'y a pas d'editeur, pas de support,
pas de procedure de recuperation en dehors de vos propres sauvegardes. C'est le
marche de l'auto-hebergement.

## Depannage

### L'API ne demarre pas

```bash
docker compose logs api | tail -50
```

| Ce que vous voyez | Cause |
|---|---|
| `JWT_SECRET is not set` / `still holds the example value` / `too short` | En generer un : `openssl rand -base64 48` |
| `Connection refused` vers la base | Le service `db` n'est pas encore healthy — `docker compose ps` |
| Une erreur Flyway | Voir [Si une migration echoue](#si-une-migration-echoue) |
| `exec format error` | Mauvaise architecture. Les images existent en amd64 et arm64 ; verifier avec `docker version --format '{{.Server.Arch}}'` |

### `403 Invalid CORS request` a la connexion

Le navigateur joint l'API sur une origine differente de celle qu'elle autorise.
Avec le compose fourni, cela ne devrait pas arriver — si c'est le cas, vous
servez sans doute le frontend separement. Renseignez `CORS_ALLOWED_ORIGINS`
avec l'origine exacte, schema et port compris.

### L'application mobile ne se connecte pas

1. L'URL du serveur doit inclure le schema : `https://budget.exemple.fr`, pas
   `budget.exemple.fr`
2. `https://<votre-serveur>/api/meta` doit repondre depuis le reseau du telephone
3. Un certificat auto-signe sera rejete — utilisez-en un vrai, Caddy en obtient
   un automatiquement
4. Si l'app signale une incompatibilite, comparer sa version avec
   `minClientVersion` renvoye par `/api/meta`

### Mot de passe administrateur perdu

Le bandeau n'apparait qu'une fois. Si plus aucun administrateur ne peut se
connecter, reinitialiser le mot de passe directement en base :

```bash
# Generer un hash BCrypt du nouveau mot de passe, puis :
docker compose exec -T db psql -U budget_u -d budget_db \
  -c "UPDATE users SET password = '<hash-bcrypt>', password_reset_required = true WHERE email = 'admin@localhost';"
```

Positionner `password_reset_required` force l'ecran de changement a la
prochaine connexion.

## Sans Docker

Necessite Java 21, PostgreSQL 15+ et Node 22.

```bash
psql -c "CREATE USER budget_u WITH PASSWORD 'changeme';"
psql -c "CREATE DATABASE budget_db OWNER budget_u;"

cp .env.example .env    # renseigner DB_URL, DB_USERNAME, DB_PASSWORD, JWT_SECRET

cd api && mvn clean package && java -jar target/api-*.jar
cd app && npm ci && npm run build    # servir dist/ avec n'importe quel serveur
```

Une unite systemd est fournie dans
[`deploy/k-budget-api.service`](../deploy/k-budget-api.service). Les scripts de
sauvegarde fonctionnent aussi avec `MODE=native`.

## Variables d'environnement

| Variable | Obligatoire | Defaut | Role |
|----------|-------------|--------|------|
| `JWT_SECRET` | **oui** | — | Cle de signature des jetons. L'API refuse de demarrer si elle est absente, plus courte que 32 caracteres, ou encore egale a la valeur d'exemple |
| `DB_PASSWORD` | **oui** | — | Mot de passe de la base. Ecrit dans le volume PostgreSQL au premier demarrage |
| `APP_PORT` | non | `8080` | Port d'ecoute de l'interface web |
| `DB_NAME` | non | `budget_db` | Nom de la base |
| `DB_USERNAME` | non | `budget_u` | Utilisateur de la base |
| `DB_URL` | non | construit depuis les precedentes | URL JDBC. Uniquement pour une base externe, via `docker-compose.override.yml` |
| `ADMIN_EMAILS` | non | vide | Emails promus administrateurs au demarrage, separes par des virgules |
| `CORS_ALLOWED_ORIGINS` | non | vide | Inutile avec le compose fourni. Uniquement si le frontend est servi depuis un autre domaine |
| `MIN_CLIENT_VERSION` | non | `6.0.0` | Version de client la plus ancienne acceptee, exposee par `/api/meta`. Ne la relever qu'a une rupture de contrat assumee |
| `RATE_LIMIT_CAPACITY` | non | `5` | Tentatives d'authentification par fenetre et par IP |
| `RATE_LIMIT_WINDOW_SECONDS` | non | `60` | Duree de cette fenetre |
| `TRUSTED_PROXIES` | non | plages privees | Prefixes d'IP dont le `X-Forwarded-For` est cru. Ne jamais faire confiance a tout : l'en-tete est fourni par le client, le croire sans condition rend la limitation contournable |
| `AVATAR_STORAGE_PATH` | non | `/app/data/avatars` | Fixe dans le container ; le volume `api-avatars` est monte dessus |
