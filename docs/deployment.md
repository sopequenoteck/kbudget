# Running k-budget

Everything needed to install, update, back up and troubleshoot a self-hosted
instance. No prior knowledge of the project is assumed.

> 🇫🇷 [Version française](deployment.fr.md)

- [Install](#install)
- [HTTPS and reverse proxy](#https-and-reverse-proxy)
- [Updating](#updating)
- [Backup and restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Running without Docker](#running-without-docker)
- [Environment variables](#environment-variables)

## Install

**Requirements**: Docker with the Compose plugin. That is all — PostgreSQL
comes with the stack. Roughly 1 GB of RAM and 2 GB of disk are enough to start.

```bash
git clone https://github.com/sopequenoteck/budget.git
cd budget
cp .env.example .env
```

Set the two required values in `.env`:

```bash
openssl rand -base64 48    # paste as JWT_SECRET
                           # then choose any DB_PASSWORD
```

Everything else has a working default. Then:

```bash
docker compose up -d
```

The interface is on **http://localhost:8080**. If that port is taken, change
`APP_PORT` in `.env`.

### Finding the first administrator password

On the very first start, the application creates an administrator account and
prints its generated password:

```bash
docker compose logs api | grep -A4 "FIRST BOOT"
```

```
================================================
 FIRST BOOT — Admin account created
 Email:    admin@localhost
 Password: <generated>
 CHANGE THESE CREDENTIALS IMMEDIATELY
================================================
```

> **Read it now.** This banner is printed **only at the very first start**, and
> the password is stored hashed — it cannot be recovered afterwards. If you miss
> it, see [Lost administrator password](#lost-administrator-password).

Signing in redirects you straight to a screen that requires setting your own
email and password. That is expected: the seeded account is a way in, not an
account to keep.

### Adding other people

**There is no public sign-up** — by design. An administrator invites people
from **Settings → Users**, and the invitee receives a link to set their own
password. Each user's data is strictly isolated from the others'.

## HTTPS and reverse proxy

The compose file serves plain HTTP on `APP_PORT`. On a local network or over a
VPN, that is often enough and you can skip this section.

To expose the instance on the internet, put a reverse proxy in front.
[`deploy/Caddyfile`](../deploy/Caddyfile) is a working example — Caddy obtains
and renews TLS certificates on its own. [`deploy/nginx.conf`](../deploy/nginx.conf)
covers nginx with certbot.

Two things matter whichever proxy you choose:

**`TRUSTED_PROXIES` must contain the network the proxy connects from.** The
default covers private ranges, which is enough when the proxy runs on the same
host. Otherwise every request appears to come from the proxy's address, and
rate limiting applies to everyone at once instead of per client.

**The edge proxy must overwrite `X-Forwarded-For`, not append to it.** Both
supplied configurations do. Appending would let a client forge the first hop —
the one the API trusts — and bypass rate limiting.

You should **not** need `CORS_ALLOWED_ORIGINS`: the web client proxies `/api/`
to the API, so the browser only ever sees one origin. Set it only if you serve
the frontend from a different domain than the API.

## Updating

**Back up first.** Always. See [Backup and restore](#backup-and-restore).

Then read the [release notes](../CHANGELOG.md) — a major version means a
deliberate break, and the entry says what it requires of you.

```bash
# 1. Back up
./deploy/backup.sh

# 2. Pin the new version in docker-compose.yml
#    image: ghcr.io/sopequenoteck/k-budget-api:6.3.1

# 3. Pull and restart
docker compose pull
docker compose up -d
```

Database migrations run automatically at startup.

### Which tag to use

Images are published to **GHCR**, `ghcr.io/sopequenoteck/k-budget-*`. Docker Hub
(`sopequenotech/k-budget-*`) is kept as a mirror. Prefer GHCR: Docker Hub
applies download quotas to anonymous users, which is exactly how a self-hoster
pulls.

| Tag | Moves when | Use it |
|-----|-----------|--------|
| `6.3.1` | never | **Recommended.** You decide when to update |
| `6.3` | a patch is released in the 6.3 series | Fixes without feature changes |
| `latest` | every release | Not recommended — see below |

`docker-compose.yml` ships with a pinned version on purpose. Following `latest`
means a restart can apply a database migration you did not choose, at a moment
you did not choose.

**Watchtower and other auto-updaters are not recommended** for the same reason:
an unattended update that fails mid-migration leaves an instance in a state
nobody was watching, and the person who has to diagnose it is you.

### If a migration fails

The API stops and logs the failing migration. Nothing is silently half-applied
— Flyway runs each migration in a transaction where the database allows it.

1. Read `docker compose logs api` and find the Flyway error
2. Restore the backup you took before updating
3. Go back to the previous image version
4. Open an issue with the migration name and the error

## Backup and restore

Two things need saving: the **database** and the **avatars**. Restoring only
the database leaves accounts whose picture has vanished.

### Backing up

```bash
./deploy/backup.sh
```

Writes `db_<timestamp>.sql.gz` and, when there are any, `avatars_<timestamp>.tar.gz`
into `./backups`, and deletes files older than 14 days.

```bash
BACKUP_DIR=/mnt/nas RETENTION_DAYS=30 ./deploy/backup.sh
```

Daily at 03:00, from the directory holding `docker-compose.yml`:

```cron
0 3 * * * cd /path/to/budget && ./deploy/backup.sh >> backups/backup.log 2>&1
```

> A backup that has never been restored is a hypothesis, not a backup. Restore
> one into a throwaway copy at least once.

### Restoring

```bash
./deploy/restore.sh 2026-09-04_140207
```

Run it without arguments to list what is available. The script stops the API,
recreates the schema, restores the database and the avatars, restarts, and
asks for confirmation first — `FORCE=1` skips the prompt for scripted use.

**Check the application answers before considering it done:**

```bash
curl -s http://localhost:8080/api/meta
```

### Your data is yours alone

Nobody else holds a copy. There is no vendor, no support desk, no recovery
procedure outside your own backups. That is the trade of self-hosting.

## Troubleshooting

### The API will not start

```bash
docker compose logs api | tail -50
```

| What you see | Cause |
|---|---|
| `JWT_SECRET is not set` / `still holds the example value` / `too short` | Generate one: `openssl rand -base64 48` |
| `Connection refused` to the database | The `db` service is not healthy yet — `docker compose ps` |
| A Flyway error | See [If a migration fails](#if-a-migration-fails) |
| `exec format error` | Wrong architecture. Images are published for amd64 and arm64; check `docker version --format '{{.Server.Arch}}'` |

### `403 Invalid CORS request` when signing in

The browser reaches the API on a different origin than the one the API allows.
With the supplied compose this should not happen — if it does, you are likely
serving the frontend separately. Set `CORS_ALLOWED_ORIGINS` to the exact origin,
scheme and port included.

### The mobile app will not connect

1. The server URL must include the scheme: `https://budget.example.com`, not
   `budget.example.com`
2. `https://<your-server>/api/meta` must answer from the phone's network
3. A self-signed certificate will be rejected — use a real one, Caddy gets you
   one automatically
4. If the app reports an incompatibility, compare its version with
   `minClientVersion` from `/api/meta`

### Lost administrator password

The banner only ever appears once. If no administrator can sign in, reset the
password directly in the database:

```bash
# Generate a BCrypt hash of your new password, then:
docker compose exec -T db psql -U budget_u -d budget_db \
  -c "UPDATE users SET password = '<bcrypt-hash>', password_reset_required = true WHERE email = 'admin@localhost';"
```

Setting `password_reset_required` forces the change screen at next sign-in.

## Running without Docker

Requires Java 21, PostgreSQL 15+ and Node 22.

```bash
psql -c "CREATE USER budget_u WITH PASSWORD 'changeme';"
psql -c "CREATE DATABASE budget_db OWNER budget_u;"

cp .env.example .env    # set DB_URL, DB_USERNAME, DB_PASSWORD, JWT_SECRET

cd api && mvn clean package && java -jar target/api-*.jar
cd app && npm ci && npm run build    # serve dist/ with any web server
```

A systemd unit is provided in [`deploy/k-budget-api.service`](../deploy/k-budget-api.service).
The backup scripts work here too with `MODE=native`.

## Environment variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `JWT_SECRET` | **yes** | — | Token signing key. The API refuses to start if missing, shorter than 32 characters, or still the example value |
| `DB_PASSWORD` | **yes** | — | Database password. Written into the PostgreSQL volume at first start |
| `APP_PORT` | no | `8080` | Port the web interface listens on |
| `DB_NAME` | no | `budget_db` | Database name |
| `DB_USERNAME` | no | `budget_u` | Database user |
| `DB_URL` | no | built from the above | JDBC URL. Only for an external database, via `docker-compose.override.yml` |
| `ADMIN_EMAILS` | no | empty | Comma-separated emails promoted to administrator at startup |
| `CORS_ALLOWED_ORIGINS` | no | empty | Unnecessary with the supplied compose. Only when the frontend is served from another domain |
| `MIN_CLIENT_VERSION` | no | `6.0.0` | Oldest client version accepted, exposed by `/api/meta`. Raise it only on a deliberate contract break |
| `RATE_LIMIT_CAPACITY` | no | `5` | Authentication attempts per window, per IP |
| `RATE_LIMIT_WINDOW_SECONDS` | no | `60` | Length of that window |
| `TRUSTED_PROXIES` | no | private ranges | IP prefixes whose `X-Forwarded-For` is trusted. Never set this to trust everything — the header is client-supplied, and trusting it unconditionally makes rate limiting bypassable |
| `AVATAR_STORAGE_PATH` | no | `/app/data/avatars` | Fixed inside the container; the `api-avatars` volume mounts onto it |
