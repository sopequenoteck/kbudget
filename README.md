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

L'API démarre sur `http://localhost:8080/api` — les endpoints métier sont servis sous `/api/v1` (KKS-313). Le frontend sur `http://localhost:4200`.

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
| [`docs/api-compatibility.md`](docs/api-compatibility.md) | **Politique de compatibilite d'API** — regles d'ecriture, procedure de rupture assumee |
| [`docs/deployment.md`](docs/deployment.md)       | Deploiement Docker, bare-metal, reverse proxy, backup                    |
| [`DESIGN.md`](DESIGN.md)                         | Reference design : principes, couleurs, patterns, tokens                  |
| **Swagger UI**                                   | `http://localhost:8080/api/swagger-ui.html` (profil `dev`)               |

## Contribuer

Les contributions passent par une pull request couverte par le
[CLA](CLA.md) — une signature par commentaire, rien a imprimer. Le pourquoi,
les conventions et les verifications attendues sont dans
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Licence

Ce depot applique **deux licences selon le repertoire**. Verifier laquelle
s'applique avant de reutiliser du code.

| Repertoire | Licence | Fichier |
|------------|---------|---------|
| `api/` — backend Spring Boot | **AGPL-3.0-only** | [`LICENSE`](LICENSE) |
| `app/` — frontend Angular | **AGPL-3.0-only** | [`LICENSE`](LICENSE) |
| `flutter/` — application mobile | **MPL-2.0** | [`flutter/LICENSE`](flutter/LICENSE) |

Tout autre fichier du depot (racine, `docs/`, `deploy/`, `scripts/`,
`.github/`) est couvert par l'**AGPL-3.0**.

### Pourquoi deux licences

**AGPL-3.0 sur le serveur et le client web.** Sa clause reseau impose de
publier les modifications a quiconque exploite le logiciel comme service. Elle
existe pour empecher un tiers de prendre ce backend, de le fermer et d'en faire
le service hebergé que ce projet a choisi de ne pas etre.

**MPL-2.0 sur l'application mobile.** Les conditions de distribution de l'App
Store — gestion des droits numeriques, limitation du nombre d'appareils — sont
incompatibles avec GPL et AGPL ; VLC en a fait les frais en 2011, retire de
l'App Store puis revenu apres passage en MPL. La MPL-2.0 est un copyleft **par
fichier** : qui modifie un fichier doit le republier sous la meme licence, mais
peut ajouter du code a cote. La protection reste reelle, sans le conflit.

Les deux licences coexistent sans se contredire : un client qui dialogue en
HTTP avec un serveur n'est pas une oeuvre derivee de ce serveur.

### Nom et logo

**Le nom « k-budget » et le logo du projet sont reserves et ne sont couverts
par aucune de ces licences.** Les licences portent sur le code, pas sur
l'identite du projet. Un fork est libre d'exister — il doit se presenter sous
un autre nom et un autre logo, afin qu'on ne puisse pas le confondre avec ce
projet ni lui en imputer le comportement.

### Actifs tiers

Les logos de banques (`api/src/main/resources/static/bank-logos/`) et la police
Inter (`flutter/assets/fonts/Inter/`) appartiennent a leurs titulaires
respectifs et **ne sont couverts par aucune des licences ci-dessus**. Leur
declaration separee est en cours (KKS-318).

### Dependances

Verifie au 2026-09-03, aucun conflit :

- **API** — Spring Boot, Commons, JJWT, Flyway et Bucket4j sous Apache-2.0,
  pilote PostgreSQL sous BSD-2-Clause, Lombok sous MIT. H2 est en `scope test`
  et n'est pas distribue, sa double licence EPL-1.0/MPL-2.0 est donc sans objet.
- **Angular** — 424 paquets MIT, 61 ISC, 32 Apache-2.0, plus BSD et 0BSD.
  Aucun copyleft.
- **Flutter** — MIT, BSD-3-Clause et BSD (auteurs Dart et Flutter).
  **Aucun copyleft**, ce qui est la condition pour la MPL-2.0.

Nuance assumee : cinq paquets npm portent une licence de **donnees** et non de
code — `caniuse-lite` (CC-BY-4.0), `spdx-exceptions` (CC-BY-3.0), `mdn-data` et
`spdx-license-ids` (CC0-1.0), `argparse` (Python-2.0). CC-BY-3.0 n'est pas
officiellement compatible GPL ; ces paquets sont des dependances de
construction, absentes du bundle livre, la question ne se pose donc pas a la
redistribution.

> Cette section decrit des choix de licence, elle ne constitue pas un avis
> juridique.
