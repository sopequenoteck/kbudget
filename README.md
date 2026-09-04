# k-budget

Self-hosted personal budgeting, built for people whose money does not live in
one country or one currency.

Track spending, subscriptions, debts and budgets across several accounts and
currencies. Runs on your own server. No account with us, no data leaving your
machine, no telemetry.

> 🇫🇷 [Version française](README.fr.md)

<p>
  <img src="docs/screenshots/dashboard.png" alt="Dashboard" width="383" height="829">
  <img src="docs/screenshots/transactions.png" alt="Transactions" width="386" height="831">
  <img src="docs/screenshots/budget.png" alt="Budgets" width="383" height="921">
</p>

> Screenshots are currently in French. They will be retaken once the interface
> ships in English and French together.

## Why this exists

Most budgeting apps assume one country, one currency, and a bank they can talk
to. That assumption breaks quickly if your life spans several places.

k-budget is built around three choices:

- **Several currencies, treated equally.** EUR, XOF, USD, GBP, CHF, CAD, MAD.
  Balances aggregate per currency rather than pretending to convert everything
  into one.
- **West African banks as first-class citizens.** Ecobank, Orabank, UBA, Coris,
  NSIA, Bank of Africa and others sit next to BNP Paribas, Crédit Agricole and
  Revolut. Account aggregators do not cover that region, and neither do the
  established self-hosted budgeting projects.
- **CSV import instead of bank APIs.** Open banking requires a licensed
  intermediary, which a self-hosted project cannot be. Import profiles describe
  how to read a given bank's export, and are meant to be contributed.

**It is multi-user.** One instance serves several people — onboarding is by
administrator invitation, with roles, strict per-user data isolation and a
safeguard against removing the last remaining administrator. There is no public
sign-up, by design.

## Features

- **Transactions** — Income and expenses, entry in two or three taps, monthly
  summary, recurring transactions, transfers between accounts
- **Subscriptions** — One view, monthly total, one-click payment, history
- **Debts and loans** — Partial or full repayments, configurable reminders,
  multi-currency, optional inclusion in the balance
- **Budgets** — Per category (weekly, monthly, yearly), configurable alert
  threshold, monthly snapshots, detection of out-of-budget spending
- **CSV import** — Bank profile resolution, preview, Jaro-Winkler
  deduplication, pattern-based categorisation rules
- **Accounts** — Current, savings, cash. 28 banks (France, Togo,
  international). Total balance aggregated per currency
- **Personalisation** — Toggleable features, navigation order, main currency,
  text size, notifications

## Stack

| Layer     | Technology                                     |
|-----------|------------------------------------------------|
| Backend   | Java 21, Spring Boot 4.0.2, Maven, Flyway      |
| Web       | Angular 21, TypeScript 5.9, SCSS               |
| Mobile    | Flutter ≥ 3.27, Dart ≥ 3.6, Riverpod, Drift    |
| Database  | PostgreSQL 15+                                 |
| Auth      | Spring Security + JWT                          |
| Infra     | Docker + Caddy (automatic HTTPS)               |

PostgreSQL is the only infrastructure dependency. No message broker, no cache
server, no external service.

## Getting started

**PostgreSQL is included.** Nothing else to install.

```bash
git clone https://github.com/sopequenoteck/budget.git
cd budget
cp .env.example .env
```

Set the two required values in `.env` — everything else has a working default:

```bash
openssl rand -base64 48    # paste as JWT_SECRET
                           # then pick any DB_PASSWORD
```

```bash
docker compose up -d
```

The interface is on **http://localhost:8080**. Change `APP_PORT` in `.env` if
that port is taken.

**On first start**, an administrator account is created and its generated
password is printed once in the API logs:

```bash
docker compose logs api | grep -A4 "FIRST BOOT"
```

> **Read it now.** That password is shown only at the very first start and is
> stored hashed — it cannot be recovered afterwards. Signing in will ask you to
> set your own credentials immediately.

Already have a PostgreSQL server you would rather use? Copy
`docker-compose.override.yml.example` to `docker-compose.override.yml` and set
`DB_URL` in `.env`.

Images are published for `linux/amd64` and `linux/arm64` — Raspberry Pi 4/5,
ARM NAS, ARM cloud instances and Apple Silicon all work without a local build.

<details>
<summary>Running without Docker</summary>

```bash
psql -c "CREATE USER budget_u WITH PASSWORD 'changeme';"
psql -c "CREATE DATABASE budget_db OWNER budget_u;"

cp .env.example .env

cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
cd app && npm ci && ng serve
```

</details>

For production deployment — bare metal, Caddy, backups — see
[`docs/deployment.md`](docs/deployment.md).

## The mobile app

The Flutter app is free software. **You can build it yourself from this
repository, and that build is functionally identical to the one on the
stores** — nothing is withheld based on where the binary came from.

It is also sold on the app stores. Buying it there funds the project; it buys
convenience and updates, not capability.

## Project structure

```
budget/
├── api/         # Spring Boot backend (REST API)
├── app/         # Angular PWA
├── flutter/     # Native mobile app
├── deploy/      # Caddyfile, systemd units, scripts
├── docs/        # Technical documentation
└── scripts/     # Utilities
```

## Documentation

| Document | Contents |
|----------|----------|
| [`.specify/memory/constitution.md`](.specify/memory/constitution.md) | **Project constitution** — founding principles. Authoritative over all other documentation |
| [`docs/architecture.md`](docs/architecture.md) | Technical decisions, security, data model, frontend structure |
| [`docs/vision.md`](docs/vision.md) | Product vision and functional modules |
| [`docs/api-examples.md`](docs/api-examples.md) | Request and response examples per endpoint |
| [`docs/api-errors.md`](docs/api-errors.md) | HTTP error contract |
| [`docs/api-compatibility.md`](docs/api-compatibility.md) | **API compatibility policy** — the six writing rules and the deliberate-break procedure |
| [`docs/deployment.md`](docs/deployment.md) | Docker and bare-metal deployment |
| [`DESIGN.md`](DESIGN.md) | Design reference: principles, colours, patterns, tokens |
| **Swagger UI** | `http://localhost:8080/api/swagger-ui.html` — `dev` profile only |

## Contributing

Contributions are welcome. **Bank import profiles are the most useful place to
start**, and they need no Java: describing how your bank formats its CSV export
helps everyone who banks there.

Pull requests must be covered by the [CLA](CLA.md) — signed by posting a
comment, nothing to print or email. [`CONTRIBUTING.md`](CONTRIBUTING.md)
explains how to run the project, what is expected of a change, why the CLA
exists and what it does not mean.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

Found a security issue? Read [`SECURITY.md`](SECURITY.md) and report it
privately rather than opening an issue.

## Licence

This repository uses **two licences, by directory**. Check which one applies
before reusing code.

| Directory | Licence | File |
|-----------|---------|------|
| `api/` — Spring Boot backend | **AGPL-3.0-only** | [`LICENSE`](LICENSE) |
| `app/` — Angular frontend | **AGPL-3.0-only** | [`LICENSE`](LICENSE) |
| `flutter/` — mobile app | **MPL-2.0** | [`flutter/LICENSE`](flutter/LICENSE) |

Everything else in the repository (root, `docs/`, `deploy/`, `scripts/`,
`.github/`) is under the **AGPL-3.0**, except the items listed in
[`NOTICE`](NOTICE).

### Why two licences

**AGPL-3.0 on the server and web client.** Its network clause requires anyone
running the software as a service to publish their modifications. It exists to
stop a third party from taking this backend, closing it, and running the hosted
service this project chose not to be.

**MPL-2.0 on the mobile app.** App Store distribution terms — digital rights
management, device count limits — are incompatible with the GPL and AGPL. VLC
was pulled from the App Store in 2011 for that reason, and returned only after
moving to the MPL. MPL-2.0 is a **per-file** copyleft: modify a file and you
must publish it, but you may add code alongside. The protection holds without
the conflict.

The two coexist without contradiction: a client talking HTTP to a server is not
a derivative work of that server.

### Name and logo

**The name "k-budget" and the project logo are reserved** and are not covered
by either licence. Licences cover code, not identity. A fork is free to
exist — under a different name and logo, so that it cannot be mistaken for this
project.

### Third-party assets

Bank logos and the Inter typeface belong to their respective owners and are
**not covered by either licence**. They are listed in [`NOTICE`](NOTICE).

Bank logos are present in two copies, one per client:
`api/src/main/resources/static/bank-logos/` and `flutter/assets/banks/`. Inter
is under the SIL Open Font License 1.1, whose text ships in
[`flutter/assets/fonts/Inter/OFL.txt`](flutter/assets/fonts/Inter/OFL.txt) and
is embedded in the distributed application.

> This section describes licensing choices. It is not legal advice.
