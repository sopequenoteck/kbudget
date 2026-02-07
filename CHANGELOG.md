# Changelog

Basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Ce projet suit [Semantic Versioning](https://semver.org/lang/fr/).

## [0.1.0] - 2026-02-07

### Added
- Initialisation projet Spring Boot 4.0.2 + Java 21
- Entités JPA : User, Transaction, Subscription, Debt (UUID)
- Authentification JWT (login/register) avec Spring Security
- CRUD complet Transactions (KKS-19)
- CRUD complet Subscriptions (KKS-20)
- CRUD complet Debts (KKS-21)
- Endpoint bilan mensuel des transactions (KKS-22)
- Configuration PostgreSQL avec profils dev/prod
- Migrations Flyway
- Documentation API avec springdoc-openapi + Swagger UI (KKS-001)
- Infrastructure de déploiement : Dockerfile, docker-compose, systemd, reverse proxy (Caddy/Nginx), script backup PostgreSQL
- Documentation : README, architecture, exemples API, contrat d'erreurs, guide déploiement
- Constitution projet v2.0.0 et CLAUDE.md

### Changed
- Enums déplacés dans le package `enums/`
- Mise en conformité complète de l'API (score 100%)

[0.1.0]: https://github.com/kellysossoe/budget/releases/tag/v0.1.0
