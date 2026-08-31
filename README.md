# K-Budget

Application de gestion de budget personnel. Self-hosted, single-user, mobile-first.

Gérez vos finances au quotidien : transactions, abonnements, dettes, budgets. Multi-devises (EUR, XOF, USD, GBP, CHF, CAD, MAD), multi-comptes, import CSV bancaire.

> *English version coming soon*

<p>
  <img src="docs/screenshots/dashboard.png" alt="Dashboard" width="383" height="829">
  <img src="docs/screenshots/transactions.png" alt="Transactions" width="386" height="831">
  <img src="docs/screenshots/budget.png" alt="Budgets" width="383" height="921">
</p>

## Fonctionnalités

- **Transactions** — Dépenses et recettes, saisie rapide en 2-3 taps, bilan mensuel, transactions récurrentes, virements entre comptes
- **Abonnements** — Vue centralisée, total mensuel, paiement en un clic, historique et cumul
- **Dettes & prêts** — Suivi des remboursements (partiels ou totaux), rappels configurables, multi-devises, inclusion optionnelle dans le solde
- **Budgets** — Par catégorie (hebdo/mensuel/annuel), seuil d'alerte configurable, historique avec snapshots mensuels, detection des dépenses hors budget
- **Import CSV** — Detection automatique du profil bancaire, preview, dedup Jaro-Winkler, règles de categorisation par pattern
- **Multi-comptes** — Courant, épargné, espèces. 29 banques supportées (FR/TG/International). Solde total agrégé par devise
- **Personnalisation** — Features activables, ordre de navigation, devise principale, taille de texte, notifications

## Stack

| Couche          | Technologie                                   |
|-----------------|-----------------------------------------------|
| Backend         | Java 21, Spring Boot 4.0.2, Maven, Flyway     |
| Frontend        | Angular 21, TypeScript 5.9, SCSS              |
| Mobile          | Flutter >= 3.27, Dart >= 3.6, Riverpod, Drift |
| Base de donnees | PostgreSQL 15+                                |
| Auth            | Spring Security + JWT                         |
| Infra           | Docker + Caddy (auto-HTTPS)                   |

## Quickstart

### Docker (recommande)

```bash
git clone https://github.com/kksdev/k-budget.git
cd k-budget
cp .env.example .env   # Éditer avec vos valeurs (DB_USERNAME, DB_PASSWORD, JWT_SECRET)
docker compose up -d
```

L'API démarre sur `http://localhost:8080/api`. Le frontend sur `http://localhost:4200`.

Les images sont publiées pour `linux/amd64` et `linux/arm64` : Raspberry Pi 4/5,
NAS ARM, instances ARM cloud et Apple Silicon sont supportés sans build local.
Docker sélectionne automatiquement la variante correspondant à l'hôte.

### Manuel

```bash
# 1. PostgresSQL
psql -c "CREATE USER budget_u WITH PASSWORD 'changeme';"
psql -c "CREATE DATABASE budget_db OWNER budget_u;"

# 2. Configuration
cp .env.example .env   # Éditer les 4 variables (DB_URL, DB_USERNAME, DB_PASSWORD, JWT_SECRET)

# 3. Backend
cd api && mvn spring-boot:run

# 4. Frontend
cd app && npm ci && ng serve
```

> Pour le déploiement en production (bare-metal, Caddy, backups), voir [`docs/deployment.md`](docs/deployment.md).

## Structure du projet

```
k-budget/
├── api/           # Backend Spring Boot (API REST)
├── app/           # Frontend Angular PWA
├── flutter/       # App mobile native Flutter
├── deploy/        # Caddyfile, systemd, scripts
├── docs/          # Documentation technique
└── scripts/       # Scripts utilitaires
```

## Documentation

| Document                                         | Contenu                                                                  |
|--------------------------------------------------|--------------------------------------------------------------------------|
| [`.specify/memory/constitution.md`](.specify/memory/constitution.md) | **Constitution du projet** — principes fondateurs. Fait autorite sur toute autre documentation |
| [`docs/vision.md`](docs/vision.md)               | Vision produit, modules fonctionnels, principes UX                       |
| [`docs/architecture.md`](docs/architecture.md)   | Decisions techniques, modele de donnees (18 entites), structure frontend |
| [`docs/api-examples.md`](docs/api-examples.md)   | Exemples de requetes et reponses pour chaque endpoint                    |
| [`docs/api-errors.md`](docs/api-errors.md)       | Contrat d'erreurs HTTP et guide d'integration                            |
| [`docs/deployment.md`](docs/deployment.md)       | Deploiement Docker, bare-metal, reverse proxy, backup                    |
| [`DESIGN.md`](DESIGN.md)                         | Reference design : principes, couleurs, patterns, tokens                  |
| **Swagger UI**                                   | `http://localhost:8080/api/swagger-ui.html` (profil `dev`)               |

## Licence

<!-- TODO: définir la licence -->
